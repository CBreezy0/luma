import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:path_provider/path_provider.dart';

import '../camera/camera_models.dart';
import 'library_db.dart';
import 'library_models.dart';
import 'photo_record.dart';

class LumaPhotoQueryResult {
  final int totalCount;
  final List<LumaPhoto> photos;

  const LumaPhotoQueryResult({required this.totalCount, required this.photos});
}

class LumaLibraryRepository {
  static const String _rootFolder = 'LumaLibrary';
  static const String _legacyIndexFileName = 'library_index.json';
  static const List<String> _folders = <String>[
    'Originals',
    'Edited',
    'RAW',
    'JPG',
    'Thumbnails',
  ];

  final Directory? _rootDirectoryOverride;
  final String _isarName;

  Directory? _rootDirectory;
  LumaLibraryDb? _db;
  final Random _random = Random();

  LumaLibraryRepository({
    Directory? rootDirectoryOverride,
    String isarName = 'luma_library',
  }) : _rootDirectoryOverride = rootDirectoryOverride,
       _isarName = isarName;

  Future<void> initialize() async {
    final root = await _resolveRootDirectory();
    for (final folder in _folders) {
      await Directory(_join(root.path, folder)).create(recursive: true);
    }
    final db = await _dbInstance();
    await db.initialize();
    await _migrateLegacyIndexIfNeeded();
  }

  Future<void> close() async {
    final db = _db;
    _db = null;
    await db?.close();
  }

  Future<List<LumaPhoto>> getAllPhotos() async {
    await initialize();
    final db = await _dbInstance();
    final records = await db.getAll();
    final photos = records.map(_photoFromRecord).toList(growable: true)
      ..sort((a, b) => b.captureDateMs.compareTo(a.captureDateMs));
    return List<LumaPhoto>.unmodifiable(photos);
  }

  Future<List<LumaPhoto>> getPhotosSortedByDate({
    bool newestFirst = true,
    int offset = 0,
    int? limit,
  }) async {
    await initialize();
    final db = await _dbInstance();
    final records = await db.getAllSortedByDate(
      newestFirst: newestFirst,
      offset: offset,
      limit: limit,
    );
    return List<LumaPhoto>.unmodifiable(
      records.map(_photoFromRecord).toList(growable: false),
    );
  }

  Future<List<LumaPhoto>> getFavorites({int offset = 0, int? limit}) async {
    await initialize();
    final db = await _dbInstance();
    final records = await db.getFavorites(offset: offset, limit: limit);
    return List<LumaPhoto>.unmodifiable(
      records.map(_photoFromRecord).toList(growable: false),
    );
  }

  Future<List<LumaPhoto>> getPhotosByRating(
    int minimumRating, {
    int offset = 0,
    int? limit,
  }) async {
    await initialize();
    final db = await _dbInstance();
    final records = await db.getByRatingAtLeast(
      minimumRating,
      offset: offset,
      limit: limit,
    );
    return List<LumaPhoto>.unmodifiable(
      records.map(_photoFromRecord).toList(growable: false),
    );
  }

  Future<List<LumaPhoto>> getPhotosByAlbum(
    LumaSmartAlbum album, {
    int offset = 0,
    int? limit,
  }) async {
    await initialize();
    final db = await _dbInstance();

    Future<List<PhotoRecord>> fetch() {
      switch (album) {
        case LumaSmartAlbum.all:
          return db.getAllSortedByDate(
            newestFirst: true,
            offset: offset,
            limit: limit,
          );
        case LumaSmartAlbum.favorites:
          return db.getFavorites(offset: offset, limit: limit);
        case LumaSmartAlbum.raw:
          return db.getRaw(offset: offset, limit: limit);
        case LumaSmartAlbum.edited:
          return db.getEdited(offset: offset, limit: limit);
        case LumaSmartAlbum.imported:
          return db.getImported(offset: offset, limit: limit);
        case LumaSmartAlbum.recentlyEdited:
        case LumaSmartAlbum.portrait:
        case LumaSmartAlbum.landscape:
          return db.getAllSortedByDate(
            newestFirst: true,
            offset: 0,
            limit: null,
          );
      }
    }

    final records = await fetch();
    Iterable<LumaPhoto> photos = records.map(_photoFromRecord);

    if (album == LumaSmartAlbum.recentlyEdited) {
      final threshold = DateTime.now()
          .subtract(const Duration(days: 7))
          .millisecondsSinceEpoch;
      photos = photos.where((photo) {
        final editedAt = photo.lastEditedAtMs;
        return editedAt != null && editedAt >= threshold;
      });
    } else if (album == LumaSmartAlbum.portrait) {
      photos = photos.where((photo) => photo.isPortrait);
    } else if (album == LumaSmartAlbum.landscape) {
      photos = photos.where((photo) => photo.isLandscape);
    }

    final list = photos.toList(growable: false);
    if (album == LumaSmartAlbum.recentlyEdited ||
        album == LumaSmartAlbum.portrait ||
        album == LumaSmartAlbum.landscape) {
      return _slicePhotos(list, offset: offset, limit: limit);
    }
    return List<LumaPhoto>.unmodifiable(list);
  }

  Future<List<LumaPhoto>> queryPhotos({
    required LumaPhotoSort sort,
    required LumaSmartAlbum album,
    required int minimumRating,
    required String searchQuery,
    required int offset,
    required int limit,
  }) async {
    final result = await queryPhotosPage(
      sort: sort,
      album: album,
      minimumRating: minimumRating,
      searchQuery: searchQuery,
      offset: offset,
      limit: limit,
    );
    return result.photos;
  }

  Future<LumaPhotoQueryResult> queryPhotosPage({
    required LumaPhotoSort sort,
    required LumaSmartAlbum album,
    required int minimumRating,
    required String searchQuery,
    required int offset,
    required int limit,
  }) async {
    await initialize();
    final normalizedQuery = searchQuery.trim();
    final isDefaultFastPath =
        normalizedQuery.isEmpty &&
        minimumRating <= 0 &&
        album == LumaSmartAlbum.all &&
        (sort == LumaPhotoSort.newest || sort == LumaPhotoSort.oldest);

    if (isDefaultFastPath) {
      final totalCount = await countPhotos(
        album: album,
        minimumRating: minimumRating,
        searchQuery: searchQuery,
      );
      final photos = await getPhotosSortedByDate(
        newestFirst: sort == LumaPhotoSort.newest,
        offset: offset,
        limit: limit,
      );
      return LumaPhotoQueryResult(totalCount: totalCount, photos: photos);
    }

    final sorted = await _queryFilteredSortedPhotos(
      sort: sort,
      album: album,
      minimumRating: minimumRating,
      searchQuery: searchQuery,
    );
    final page = _slicePhotos(sorted, offset: offset, limit: max(1, limit));
    return LumaPhotoQueryResult(totalCount: sorted.length, photos: page);
  }

  Future<int> countPhotos({
    required LumaSmartAlbum album,
    required int minimumRating,
    required String searchQuery,
  }) async {
    await initialize();
    final normalizedQuery = searchQuery.trim();
    final isDefaultFastPath =
        normalizedQuery.isEmpty &&
        minimumRating <= 0 &&
        album == LumaSmartAlbum.all;
    if (isDefaultFastPath) {
      final db = await _dbInstance();
      return db.countAll();
    }

    final result = await queryPhotosPage(
      sort: LumaPhotoSort.newest,
      album: album,
      minimumRating: minimumRating,
      searchQuery: searchQuery,
      offset: 0,
      limit: 1,
    );
    return result.totalCount;
  }

  Future<void> savePhoto(LumaPhoto photo) async {
    await initialize();
    final db = await _dbInstance();
    await db.put(_recordFromPhoto(photo));
  }

  Future<void> deletePhoto(String photoId) async {
    await removePhotos({photoId});
  }

  Future<void> updatePhotoMetadata(
    String photoId, {
    bool? isFavorite,
    int? rating,
    LumaColorLabel? colorLabel,
    String? location,
    double? iso,
    String? shutterSpeed,
    double? aperture,
    double? focalLength,
    String? lens,
    int? width,
    int? height,
  }) async {
    final photo = await photoById(photoId);
    if (photo == null) return;
    final updated = photo.copyWith(
      isFavorite: isFavorite,
      rating: rating,
      colorLabel: colorLabel,
      location: location,
      iso: iso,
      shutterSpeed: shutterSpeed,
      aperture: aperture,
      focalLength: focalLength,
      lens: lens,
      width: width,
      height: height,
    );
    await savePhoto(updated);
  }

  Future<void> setThumbnailPath(String photoId, String thumbnailPath) async {
    await initialize();
    final db = await _dbInstance();
    await db.updateThumbnailPath(photoId, thumbnailPath);
  }

  Future<String> thumbnailPathForPhotoId(String photoId) async {
    final root = await _resolveRootDirectory();
    return _join(root.path, 'Thumbnails', '${photoId}_grid.jpg');
  }

  Future<List<LumaPhoto>> getPhotosMissingThumbnails({int limit = 500}) async {
    await initialize();
    final db = await _dbInstance();
    final missing = await db.getMissingThumbnails(limit: limit);
    return List<LumaPhoto>.unmodifiable(
      missing.map(_photoFromRecord).toList(growable: false),
    );
  }

  Future<List<LumaPhoto>> loadPhotos() async {
    return getAllPhotos();
  }

  Future<void> savePhotos(List<LumaPhoto> photos) async {
    await initialize();
    final db = await _dbInstance();
    await db.clear();
    final records = photos.map(_recordFromPhoto).toList(growable: false);
    await db.putAll(records);
  }

  Future<LumaPhoto> addCapturedPhoto(CameraCaptureResult capture) async {
    final sourcePath = capture.filePath;
    if (sourcePath == null || sourcePath.isEmpty) {
      throw ArgumentError('Captured photo missing file path.');
    }

    final format = _formatFromCapture(capture);
    final photo = await _preparePhotoFromPath(
      sourcePath,
      format: format,
      imported: false,
      captureDateMs: capture.capturedAtMs,
      importedDateMs: 0,
      width: capture.width,
      height: capture.height,
      lens: capture.lens,
      iso: capture.iso,
      shutterSpeed: capture.shutterSpeed,
      aperture: capture.aperture,
      focalLength: capture.focalLength,
      location: capture.location,
      simulationId: capture.simulationId,
    );
    await savePhoto(photo);
    await _preserveRawCompanionIfPresent(
      rawSourcePath: capture.rawFilePath,
      photoId: photo.photoId,
    );
    return photo;
  }

  Future<List<LumaPhoto>> importPhotoPaths(List<String> paths) async {
    final imported = <LumaPhoto>[];
    for (var index = 0; index < paths.length; index += 1) {
      final sourcePath = paths[index];
      if (sourcePath.isEmpty) continue;
      final format = _formatFromPath(sourcePath);
      final nowMs = DateTime.now().millisecondsSinceEpoch + index;
      final photo = await _preparePhotoFromPath(
        sourcePath,
        format: format,
        imported: true,
        captureDateMs: nowMs,
        importedDateMs: nowMs,
        width: null,
        height: null,
        lens: null,
        iso: null,
        shutterSpeed: null,
        aperture: null,
        focalLength: null,
        location: null,
        simulationId: null,
      );
      imported.add(photo);
    }
    if (imported.isEmpty) return const <LumaPhoto>[];
    final db = await _dbInstance();
    await db.putAll(imported.map(_recordFromPhoto).toList(growable: false));
    return imported;
  }

  Future<void> upsertPhoto(LumaPhoto photo) async {
    await savePhoto(photo);
  }

  Future<void> updatePhotos(
    Set<String> photoIds,
    LumaPhoto Function(LumaPhoto photo) transform,
  ) async {
    if (photoIds.isEmpty) return;
    final db = await _dbInstance();
    final records = await db.getByPhotoIds(photoIds);
    if (records.isEmpty) return;
    final updates = records
        .map(_photoFromRecord)
        .map(transform)
        .map(_recordFromPhoto)
        .toList(growable: false);
    await db.putAll(updates);
  }

  Future<void> removePhotos(Set<String> photoIds) async {
    if (photoIds.isEmpty) return;
    await initialize();
    final db = await _dbInstance();
    final records = await db.getByPhotoIds(photoIds);

    for (final record in records) {
      await _safeDeleteFile(record.originalFilePath);
      await _safeDeleteFile(record.editedFilePath);
      await _safeDeleteFile(record.thumbnailPath);
      final versions = _decodeVersions(record.versionsJson);
      for (final version in versions) {
        await _safeDeleteFile(version.renderedPath);
      }
    }

    await db.deleteByPhotoIds(photoIds);
  }

  Future<LumaPhoto?> photoById(String photoId) async {
    await initialize();
    final db = await _dbInstance();
    final record = await db.getByPhotoId(photoId);
    if (record == null) return null;
    return _photoFromRecord(record);
  }

  Future<String?> exportPhoto(String photoId) async {
    final photo = await photoById(photoId);
    if (photo == null) return null;
    final sourcePath = photo.workingPath.isNotEmpty
        ? photo.workingPath
        : photo.originalPath;
    if (sourcePath.isEmpty) return null;
    final sourceFile = File(sourcePath);
    if (!await sourceFile.exists()) return null;

    final tempRoot = await getTemporaryDirectory();
    final exportDirectory = Directory(_join(tempRoot.path, 'LumaExports'));
    await exportDirectory.create(recursive: true);
    final ext = _normalizedExtension(sourcePath, photo.format);
    final exportPath = _join(
      exportDirectory.path,
      '${photo.photoId}_${DateTime.now().millisecondsSinceEpoch}.$ext',
    );
    await _copyFile(sourcePath, exportPath);
    return exportPath;
  }

  Future<LumaPhoto> duplicateActiveVersion(String photoId) async {
    final photo = await photoById(photoId);
    if (photo == null) {
      throw StateError('Photo not found: $photoId');
    }
    final active = photo.versions.firstWhere(
      (version) => version.versionId == photo.activeVersionId,
      orElse: () => photo.versions.first,
    );
    final duplicate = active.copyWith(
      versionId: _versionId(photoId),
      name: '${active.name} Copy',
      createdAtMs: DateTime.now().millisecondsSinceEpoch,
      instructions: List<LumaEditInstruction>.from(active.instructions),
    );
    final updated = photo.copyWith(
      versions: List<LumaPhotoVersion>.unmodifiable([
        ...photo.versions,
        duplicate,
      ]),
      activeVersionId: duplicate.versionId,
      lastEditedAtMs: DateTime.now().millisecondsSinceEpoch,
    );
    await upsertPhoto(updated);
    return updated;
  }

  Future<LumaPhoto> revertToOriginalVersion(String photoId) async {
    final photo = await photoById(photoId);
    if (photo == null) {
      throw StateError('Photo not found: $photoId');
    }
    if (photo.versions.isEmpty) {
      return photo;
    }
    final original = photo.versions.first;
    final updated = photo.copyWith(activeVersionId: original.versionId);
    await upsertPhoto(updated);
    return updated;
  }

  Future<LumaPhoto> addEditVersion(
    String photoId,
    List<LumaEditInstruction> instructions,
  ) async {
    final photo = await photoById(photoId);
    if (photo == null) {
      throw StateError('Photo not found: $photoId');
    }
    final count = photo.versions.length + 1;
    final version = LumaPhotoVersion(
      versionId: _versionId(photoId),
      name: 'Edit $count',
      createdAtMs: DateTime.now().millisecondsSinceEpoch,
      instructions: instructions,
      renderedPath: null,
    );
    final updated = photo.copyWith(
      versions: List<LumaPhotoVersion>.unmodifiable([
        ...photo.versions,
        version,
      ]),
      activeVersionId: version.versionId,
      lastEditedAtMs: DateTime.now().millisecondsSinceEpoch,
    );
    await upsertPhoto(updated);
    return updated;
  }

  Future<void> applyBatchEdits(
    Set<String> photoIds,
    List<LumaEditInstruction> instructions,
  ) async {
    if (photoIds.isEmpty || instructions.isEmpty) return;
    await updatePhotos(photoIds, (photo) {
      final createdAtMs = DateTime.now().millisecondsSinceEpoch;
      final version = LumaPhotoVersion(
        versionId: _versionId(photo.photoId),
        name: 'Edit ${photo.versions.length + 1}',
        createdAtMs: createdAtMs,
        instructions: List<LumaEditInstruction>.from(instructions),
        renderedPath: null,
      );
      return photo.copyWith(
        versions: List<LumaPhotoVersion>.unmodifiable([
          ...photo.versions,
          version,
        ]),
        activeVersionId: version.versionId,
        lastEditedAtMs: createdAtMs,
      );
    });
  }

  Future<List<LumaPhoto>> searchPhotos(String query) async {
    return queryPhotos(
      sort: LumaPhotoSort.newest,
      album: LumaSmartAlbum.all,
      minimumRating: 0,
      searchQuery: query,
      offset: 0,
      limit: 100000000,
    );
  }

  Future<List<LumaPhoto>> _queryFilteredSortedPhotos({
    required LumaPhotoSort sort,
    required LumaSmartAlbum album,
    required int minimumRating,
    required String searchQuery,
  }) async {
    Iterable<LumaPhoto> filtered = await getPhotosByAlbum(album);

    if (minimumRating > 0) {
      filtered = filtered.where((photo) => photo.rating >= minimumRating);
    }

    final normalizedQuery = searchQuery.trim().toLowerCase();
    if (normalizedQuery.isNotEmpty) {
      filtered = filtered.where((photo) {
        final id = photo.photoId.toLowerCase();
        final captureId = photo.captureIdentifier.toLowerCase();
        final lens = photo.lens?.toLowerCase() ?? '';
        final location = photo.location?.toLowerCase() ?? '';
        final resolution = photo.width != null && photo.height != null
            ? '${photo.width}x${photo.height}'
            : '';
        return id.contains(normalizedQuery) ||
            captureId.contains(normalizedQuery) ||
            lens.contains(normalizedQuery) ||
            location.contains(normalizedQuery) ||
            resolution.contains(normalizedQuery);
      });
    }

    final sorted = filtered.toList(growable: true);
    switch (sort) {
      case LumaPhotoSort.newest:
        sorted.sort((a, b) => b.captureDateMs.compareTo(a.captureDateMs));
      case LumaPhotoSort.oldest:
        sorted.sort((a, b) => a.captureDateMs.compareTo(b.captureDateMs));
      case LumaPhotoSort.ratingHigh:
        sorted.sort((a, b) {
          final byRating = b.rating.compareTo(a.rating);
          if (byRating != 0) return byRating;
          return b.captureDateMs.compareTo(a.captureDateMs);
        });
      case LumaPhotoSort.favoritesFirst:
        sorted.sort((a, b) {
          if (a.isFavorite != b.isFavorite) {
            return a.isFavorite ? -1 : 1;
          }
          return b.captureDateMs.compareTo(a.captureDateMs);
        });
    }
    return List<LumaPhoto>.unmodifiable(sorted);
  }

  Future<LumaPhoto> _preparePhotoFromPath(
    String sourcePath, {
    required LumaPhotoFormat format,
    required bool imported,
    required int captureDateMs,
    required int importedDateMs,
    required int? width,
    required int? height,
    required String? lens,
    required double? iso,
    required String? shutterSpeed,
    required double? aperture,
    required double? focalLength,
    required String? location,
    required String? simulationId,
  }) async {
    await initialize();

    final sourceFile = File(sourcePath);
    if (!await sourceFile.exists()) {
      throw ArgumentError('File not found: $sourcePath');
    }

    final ext = _normalizedExtension(sourcePath, format);
    final photoId = _photoId();
    final captureIdentifier = _captureIdentifier(sourcePath, captureDateMs);

    final root = await _resolveRootDirectory();
    final originalPath = _join(root.path, 'Originals', '$photoId.$ext');
    final workingFolder = format == LumaPhotoFormat.raw ? 'RAW' : 'JPG';
    final workingPath = _join(root.path, workingFolder, '$photoId.$ext');

    await _copyFile(sourcePath, originalPath);
    await _copyFile(originalPath, workingPath);

    final originalVersion = LumaPhotoVersion(
      versionId: 'original-$photoId',
      name: 'Original',
      createdAtMs: captureDateMs,
      instructions: const <LumaEditInstruction>[],
      renderedPath: null,
    );

    return LumaPhoto(
      photoId: photoId,
      captureIdentifier: captureIdentifier,
      captureDateMs: captureDateMs,
      iso: iso,
      shutterSpeed: shutterSpeed,
      aperture: aperture,
      focalLength: focalLength,
      lens: lens,
      width: width,
      height: height,
      format: format,
      isFavorite: false,
      rating: 0,
      colorLabel: LumaColorLabel.none,
      location: location,
      imported: imported,
      originalPath: originalPath,
      workingPath: workingPath,
      thumbnailPath: null,
      lastEditedAtMs: null,
      versions: List<LumaPhotoVersion>.unmodifiable([originalVersion]),
      activeVersionId: originalVersion.versionId,
    );
  }

  Future<void> _preserveRawCompanionIfPresent({
    required String? rawSourcePath,
    required String photoId,
  }) async {
    if (rawSourcePath == null || rawSourcePath.isEmpty) return;
    final rawSource = File(rawSourcePath);
    if (!await rawSource.exists()) return;

    final root = await _resolveRootDirectory();
    final rawExt = _normalizedExtension(rawSourcePath, LumaPhotoFormat.raw);
    final originalRawPath = _join(
      root.path,
      'Originals',
      '${photoId}_raw.$rawExt',
    );
    final workingRawPath = _join(root.path, 'RAW', '${photoId}_raw.$rawExt');

    await _copyFile(rawSourcePath, originalRawPath);
    await _copyFile(originalRawPath, workingRawPath);
  }

  PhotoRecord _recordFromPhoto(LumaPhoto photo) {
    final record = PhotoRecord()
      ..photoId = photo.photoId
      ..captureDateMs = photo.captureDateMs
      ..captureIdentifier = photo.captureIdentifier
      ..originalFilePath = photo.originalPath
      ..editedFilePath = photo.workingPath
      ..thumbnailPath = photo.thumbnailPath
      ..importedDateMs = photo.imported ? photo.captureDateMs : 0
      ..iso = photo.iso
      ..shutterSpeed = photo.shutterSpeed
      ..aperture = photo.aperture
      ..focalLength = photo.focalLength
      ..lens = photo.lens
      ..resolution = _resolutionText(photo.width, photo.height)
      ..format = photo.format.wireValue
      ..isFavorite = photo.isFavorite
      ..rating = photo.rating
      ..colorLabel = photo.colorLabel.wireValue
      ..location = photo.location
      ..albumTagsJson = null
      ..simulationId = null
      ..isImported = photo.imported
      ..isRaw = photo.format == LumaPhotoFormat.raw
      ..isEdited = photo.isEdited
      ..hasEdits = photo.isEdited
      ..width = photo.width
      ..height = photo.height
      ..lastEditedAtMs = photo.lastEditedAtMs
      ..activeVersionId = photo.activeVersionId
      ..versionsJson = jsonEncode(
        photo.versions
            .map((version) => version.toJson())
            .toList(growable: false),
      );
    return record;
  }

  LumaPhoto _photoFromRecord(PhotoRecord record) {
    final versions = _decodeVersions(record.versionsJson);
    final fallbackOriginal = LumaPhotoVersion(
      versionId: 'original-${record.photoId}',
      name: 'Original',
      createdAtMs: record.captureDateMs,
      instructions: const <LumaEditInstruction>[],
      renderedPath: null,
    );
    final effectiveVersions = versions.isEmpty
        ? <LumaPhotoVersion>[fallbackOriginal]
        : versions;

    final widthHeight = _parseResolution(
      resolution: record.resolution,
      width: record.width,
      height: record.height,
    );

    return LumaPhoto(
      photoId: record.photoId,
      captureIdentifier: record.captureIdentifier,
      captureDateMs: record.captureDateMs,
      iso: record.iso,
      shutterSpeed: record.shutterSpeed,
      aperture: record.aperture,
      focalLength: record.focalLength,
      lens: record.lens,
      width: widthHeight.$1,
      height: widthHeight.$2,
      format: lumaPhotoFormatFromWire(record.format),
      isFavorite: record.isFavorite,
      rating: record.rating,
      colorLabel: lumaColorLabelFromWire(record.colorLabel),
      location: record.location,
      imported: record.isImported,
      originalPath: record.originalFilePath,
      workingPath: record.editedFilePath ?? record.originalFilePath,
      thumbnailPath: record.thumbnailPath,
      lastEditedAtMs: record.lastEditedAtMs,
      versions: List<LumaPhotoVersion>.unmodifiable(effectiveVersions),
      activeVersionId:
          record.activeVersionId ?? effectiveVersions.last.versionId,
    );
  }

  List<LumaPhotoVersion> _decodeVersions(String? rawJson) {
    if (rawJson == null || rawJson.trim().isEmpty) {
      return const <LumaPhotoVersion>[];
    }
    try {
      final decoded = jsonDecode(rawJson);
      if (decoded is! List) return const <LumaPhotoVersion>[];
      return decoded
          .whereType<Map>()
          .map(
            (item) =>
                LumaPhotoVersion.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(growable: false);
    } catch (_) {
      return const <LumaPhotoVersion>[];
    }
  }

  String? _resolutionText(int? width, int? height) {
    if (width == null || height == null) return null;
    return '${width}x$height';
  }

  (int?, int?) _parseResolution({
    required String? resolution,
    required int? width,
    required int? height,
  }) {
    if (width != null && height != null) {
      return (width, height);
    }
    if (resolution == null) return (width, height);
    final parts = resolution.toLowerCase().split('x');
    if (parts.length != 2) return (width, height);
    final parsedW = int.tryParse(parts[0].trim());
    final parsedH = int.tryParse(parts[1].trim());
    return (parsedW ?? width, parsedH ?? height);
  }

  Future<void> _migrateLegacyIndexIfNeeded() async {
    final root = await _resolveRootDirectory();
    final legacy = File(_join(root.path, _legacyIndexFileName));
    if (!await legacy.exists()) return;

    final db = await _dbInstance();
    final hasRows = await db.countAll() > 0;
    if (hasRows) {
      await legacy.delete();
      return;
    }

    try {
      final raw = await legacy.readAsString();
      if (raw.trim().isEmpty) {
        await legacy.delete();
        return;
      }
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        await legacy.delete();
        return;
      }
      final photos = decoded
          .whereType<Map>()
          .map((item) => LumaPhoto.fromJson(Map<String, dynamic>.from(item)))
          .toList(growable: false);
      await db.putAll(photos.map(_recordFromPhoto).toList(growable: false));
      await legacy.delete();
    } catch (_) {
      // Keep legacy file in place if migration fails.
    }
  }

  LumaPhotoFormat _formatFromCapture(CameraCaptureResult capture) {
    if (capture.captureFormat == CameraCaptureFormat.raw) {
      return LumaPhotoFormat.raw;
    }
    final mime = capture.mimeType.toLowerCase();
    if (mime.contains('heic') || mime.contains('heif')) {
      return LumaPhotoFormat.heic;
    }
    if (mime.contains('png')) {
      return LumaPhotoFormat.png;
    }
    return LumaPhotoFormat.jpg;
  }

  LumaPhotoFormat _formatFromPath(String path) {
    final extension = _extension(path);
    switch (extension) {
      case 'dng':
      case 'raw':
        return LumaPhotoFormat.raw;
      case 'heic':
      case 'heif':
        return LumaPhotoFormat.heic;
      case 'png':
        return LumaPhotoFormat.png;
      case 'jpg':
      case 'jpeg':
        return LumaPhotoFormat.jpg;
      default:
        return LumaPhotoFormat.unknown;
    }
  }

  String _normalizedExtension(String path, LumaPhotoFormat format) {
    final ext = _extension(path);
    if (ext.isNotEmpty) return ext;
    switch (format) {
      case LumaPhotoFormat.raw:
        return 'dng';
      case LumaPhotoFormat.heic:
        return 'heic';
      case LumaPhotoFormat.png:
        return 'png';
      case LumaPhotoFormat.jpg:
      case LumaPhotoFormat.unknown:
        return 'jpg';
    }
  }

  String _captureIdentifier(String sourcePath, int captureDateMs) {
    final name = sourcePath.split(Platform.pathSeparator).last;
    final dot = name.lastIndexOf('.');
    final stem = dot > 0 ? name.substring(0, dot) : name;
    final normalized = stem.trim();
    if (normalized.isNotEmpty) return normalized;
    return 'IMG_$captureDateMs';
  }

  String _photoId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final randomSuffix = _random
        .nextInt(1 << 20)
        .toRadixString(16)
        .padLeft(5, '0');
    return 'photo_${timestamp}_$randomSuffix';
  }

  String _versionId(String photoId) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final randomSuffix = _random
        .nextInt(1 << 16)
        .toRadixString(16)
        .padLeft(4, '0');
    return 'v_${photoId}_$timestamp$randomSuffix';
  }

  Future<LumaLibraryDb> _dbInstance() async {
    final cached = _db;
    if (cached != null) return cached;

    final root = await _resolveRootDirectory();
    final db = LumaLibraryDb(directory: root, name: _isarName);
    _db = db;
    return db;
  }

  Future<Directory> _resolveRootDirectory() async {
    final cached = _rootDirectory;
    if (cached != null) return cached;

    final rootOverride = _rootDirectoryOverride;
    if (rootOverride != null) {
      final root = rootOverride;
      await root.create(recursive: true);
      _rootDirectory = root;
      return root;
    }

    final docs = await getApplicationDocumentsDirectory();
    final root = Directory(_join(docs.path, _rootFolder));
    await root.create(recursive: true);
    _rootDirectory = root;
    return root;
  }

  List<LumaPhoto> _slicePhotos(
    List<LumaPhoto> photos, {
    required int offset,
    int? limit,
  }) {
    final safeOffset = max(0, offset);
    if (safeOffset >= photos.length) {
      return const <LumaPhoto>[];
    }
    final safeLimit = limit == null ? null : max(0, limit);
    final end = safeLimit == null
        ? photos.length
        : min(photos.length, safeOffset + safeLimit);
    return List<LumaPhoto>.unmodifiable(photos.sublist(safeOffset, end));
  }

  String _join(String first, [String? second, String? third]) {
    final parts = <String>[first];
    if (second != null && second.isNotEmpty) parts.add(second);
    if (third != null && third.isNotEmpty) parts.add(third);
    return parts.join(Platform.pathSeparator);
  }

  String _extension(String path) {
    final name = path.split(Platform.pathSeparator).last;
    final index = name.lastIndexOf('.');
    if (index < 0 || index == name.length - 1) return '';
    return name.substring(index + 1).toLowerCase();
  }

  Future<void> _copyFile(String fromPath, String toPath) async {
    final target = File(toPath);
    await target.parent.create(recursive: true);
    if (await target.exists()) {
      await target.delete();
    }
    await File(fromPath).copy(toPath);
  }

  Future<void> _safeDeleteFile(String? path) async {
    if (path == null || path.isEmpty) return;
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
