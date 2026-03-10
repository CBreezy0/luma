import 'dart:io';

import 'package:isar/isar.dart';

import 'photo_record.dart';

class LumaLibraryDb {
  final Directory directory;
  final String name;

  Isar? _isar;
  LumaLibraryDb({required this.directory, required this.name});

  Future<void> initialize() async {
    await _isarInstance();
  }

  Future<void> close() async {
    final isar = _isar;
    _isar = null;
    if (isar == null) return;
    isar.close();
  }

  Future<int> countAll() async {
    final isar = await _isarInstance();
    return isar.photoRecords.count();
  }

  Future<List<PhotoRecord>> getAll() async {
    final isar = await _isarInstance();
    return isar.photoRecords.where().findAll();
  }

  Future<List<PhotoRecord>> getAllSortedByDate({
    required bool newestFirst,
    int offset = 0,
    int? limit,
  }) async {
    final isar = await _isarInstance();
    final safeOffset = offset < 0 ? 0 : offset;
    final safeLimit = limit == null ? null : (limit < 0 ? 0 : limit);

    final query = newestFirst
        ? isar.photoRecords.where().sortByCaptureDateMsDesc()
        : isar.photoRecords.where().sortByCaptureDateMs();
    if (safeLimit != null) {
      return query.offset(safeOffset).limit(safeLimit).findAll();
    }
    return query.offset(safeOffset).findAll();
  }

  Future<List<PhotoRecord>> getFavorites({int offset = 0, int? limit}) async {
    final isar = await _isarInstance();
    final safeOffset = offset < 0 ? 0 : offset;
    final safeLimit = limit == null ? null : (limit < 0 ? 0 : limit);

    final query = isar.photoRecords
        .where()
        .isFavoriteEqualTo(true)
        .sortByCaptureDateMsDesc();
    if (safeLimit != null) {
      return query.offset(safeOffset).limit(safeLimit).findAll();
    }
    return query.offset(safeOffset).findAll();
  }

  Future<List<PhotoRecord>> getByRatingAtLeast(
    int minimumRating, {
    int offset = 0,
    int? limit,
  }) async {
    final isar = await _isarInstance();
    final safeOffset = offset < 0 ? 0 : offset;
    final safeLimit = limit == null ? null : (limit < 0 ? 0 : limit);
    final safeRating = minimumRating.clamp(0, 5);

    final query = isar.photoRecords
        .where()
        .ratingGreaterThan(safeRating, include: true)
        .sortByCaptureDateMsDesc();
    if (safeLimit != null) {
      return query.offset(safeOffset).limit(safeLimit).findAll();
    }
    return query.offset(safeOffset).findAll();
  }

  Future<List<PhotoRecord>> getByColorLabel(
    String colorLabel, {
    int offset = 0,
    int? limit,
  }) async {
    final isar = await _isarInstance();
    final safeOffset = offset < 0 ? 0 : offset;
    final safeLimit = limit == null ? null : (limit < 0 ? 0 : limit);

    final query = isar.photoRecords
        .where()
        .colorLabelEqualTo(colorLabel)
        .sortByCaptureDateMsDesc();
    if (safeLimit != null) {
      return query.offset(safeOffset).limit(safeLimit).findAll();
    }
    return query.offset(safeOffset).findAll();
  }

  Future<List<PhotoRecord>> getImported({int offset = 0, int? limit}) async {
    final isar = await _isarInstance();
    final safeOffset = offset < 0 ? 0 : offset;
    final safeLimit = limit == null ? null : (limit < 0 ? 0 : limit);

    final query = isar.photoRecords
        .where()
        .isImportedEqualTo(true)
        .sortByCaptureDateMsDesc();
    if (safeLimit != null) {
      return query.offset(safeOffset).limit(safeLimit).findAll();
    }
    return query.offset(safeOffset).findAll();
  }

  Future<List<PhotoRecord>> getRaw({int offset = 0, int? limit}) async {
    final isar = await _isarInstance();
    final safeOffset = offset < 0 ? 0 : offset;
    final safeLimit = limit == null ? null : (limit < 0 ? 0 : limit);

    final query = isar.photoRecords
        .where()
        .isRawEqualTo(true)
        .sortByCaptureDateMsDesc();
    if (safeLimit != null) {
      return query.offset(safeOffset).limit(safeLimit).findAll();
    }
    return query.offset(safeOffset).findAll();
  }

  Future<List<PhotoRecord>> getEdited({int offset = 0, int? limit}) async {
    final isar = await _isarInstance();
    final safeOffset = offset < 0 ? 0 : offset;
    final safeLimit = limit == null ? null : (limit < 0 ? 0 : limit);

    final query = isar.photoRecords
        .where()
        .isEditedEqualTo(true)
        .sortByCaptureDateMsDesc();
    if (safeLimit != null) {
      return query.offset(safeOffset).limit(safeLimit).findAll();
    }
    return query.offset(safeOffset).findAll();
  }

  Future<List<PhotoRecord>> getRecent({
    required int sinceMs,
    int offset = 0,
    int? limit,
  }) async {
    final isar = await _isarInstance();
    final safeOffset = offset < 0 ? 0 : offset;
    final safeLimit = limit == null ? null : (limit < 0 ? 0 : limit);

    final query = isar.photoRecords
        .where()
        .captureDateMsGreaterThan(sinceMs, include: true)
        .sortByCaptureDateMsDesc();
    if (safeLimit != null) {
      return query.offset(safeOffset).limit(safeLimit).findAll();
    }
    return query.offset(safeOffset).findAll();
  }

  Future<PhotoRecord?> getByPhotoId(String photoId) async {
    final isar = await _isarInstance();
    return isar.photoRecords.where().photoIdEqualTo(photoId).findFirst();
  }

  Future<List<PhotoRecord>> getByPhotoIds(Set<String> photoIds) async {
    if (photoIds.isEmpty) return const <PhotoRecord>[];
    final isar = await _isarInstance();
    return isar.photoRecords.where().anyOf(photoIds.toList(growable: false), (
      q,
      id,
    ) {
      return q.photoIdEqualTo(id);
    }).findAll();
  }

  Future<List<PhotoRecord>> getMissingThumbnails({int limit = 500}) async {
    final isar = await _isarInstance();
    final query = isar.photoRecords
        .filter()
        .group((q) => q.thumbnailPathIsNull().or().thumbnailPathEqualTo(''))
        .sortByCaptureDateMsDesc();
    if (limit <= 0) {
      return query.findAll();
    }
    return query.limit(limit).findAll();
  }

  Future<void> put(PhotoRecord record) async {
    final isar = await _isarInstance();
    await isar.writeTxn(() async {
      await isar.photoRecords.put(record);
    });
  }

  Future<void> putAll(List<PhotoRecord> records) async {
    if (records.isEmpty) return;
    final isar = await _isarInstance();
    await isar.writeTxn(() async {
      await isar.photoRecords.putAll(records);
    });
  }

  Future<void> clear() async {
    final isar = await _isarInstance();
    await isar.writeTxn(() async {
      await isar.photoRecords.clear();
    });
  }

  Future<void> deleteByPhotoIds(Set<String> photoIds) async {
    if (photoIds.isEmpty) return;
    final isar = await _isarInstance();
    final records = await getByPhotoIds(photoIds);
    final ids = records.map((record) => record.id).toList(growable: false);
    await isar.writeTxn(() async {
      await isar.photoRecords.deleteAll(ids);
    });
  }

  Future<void> updateThumbnailPath(String photoId, String thumbnailPath) async {
    final record = await getByPhotoId(photoId);
    if (record == null) return;
    record.thumbnailPath = thumbnailPath;
    await put(record);
  }

  Future<Isar> _isarInstance() async {
    final cached = _isar;
    if (cached != null && cached.isOpen) return cached;

    final existing = Isar.getInstance(name);
    if (existing != null && existing.isOpen) {
      _isar = existing;
      return existing;
    }

    final opened = await Isar.open(
      [PhotoRecordSchema],
      directory: directory.path,
      name: name,
      inspector: false,
    );
    _isar = opened;
    return opened;
  }
}
