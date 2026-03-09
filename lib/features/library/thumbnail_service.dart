import 'dart:async';
import 'dart:collection';
import 'dart:isolate';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

import 'library_models.dart';
import 'library_repository.dart';

typedef ThumbnailBytesGenerator =
    Future<Uint8List?> Function(String sourcePath, int size, int quality);

class LibraryThumbnailService {
  final LumaLibraryRepository _repository;
  final int _gridSize;
  final int _jpegQuality;
  final ThumbnailBytesGenerator _generator;

  final Queue<String> _queue = Queue<String>();
  final Set<String> _queuedPhotoIds = <String>{};
  final StreamController<String> _updates =
      StreamController<String>.broadcast();

  bool _isProcessing = false;
  bool _disposed = false;

  LibraryThumbnailService({
    required LumaLibraryRepository repository,
    int gridSize = 360,
    int jpegQuality = 82,
    ThumbnailBytesGenerator? generator,
  }) : _repository = repository,
       _gridSize = gridSize,
       _jpegQuality = jpegQuality,
       _generator = generator ?? _defaultThumbnailGenerator;

  Stream<String> get updates => _updates.stream;

  @visibleForTesting
  int get queuedCount => _queuedPhotoIds.length;

  Future<void> dispose() async {
    _disposed = true;
    _queue.clear();
    _queuedPhotoIds.clear();
    await _updates.close();
  }

  Future<void> enqueueForPhotoId(String photoId) async {
    if (_disposed || photoId.isEmpty) return;
    if (!_queuedPhotoIds.add(photoId)) return;

    try {
      final photo = await _repository.photoById(photoId);
      if (_disposed || photo == null) {
        _queuedPhotoIds.remove(photoId);
        return;
      }
      if (await _hasValidThumbnail(photo)) {
        _queuedPhotoIds.remove(photoId);
        return;
      }

      _queue.add(photoId);
      unawaited(_processQueue());
    } catch (_) {
      _queuedPhotoIds.remove(photoId);
    }
  }

  Future<void> enqueueForPhotos(Iterable<LumaPhoto> photos) async {
    if (_disposed) return;
    for (final photo in photos) {
      if (_disposed) return;
      await enqueueForPhotoId(photo.photoId);
    }
  }

  Future<void> enqueueMissingThumbnails({int limit = 500}) async {
    if (_disposed) return;
    final missing = await _repository.getPhotosMissingThumbnails(limit: limit);
    await enqueueForPhotos(missing);
  }

  Future<void> _processQueue() async {
    if (_disposed || _isProcessing) return;
    _isProcessing = true;
    try {
      while (!_disposed && _queue.isNotEmpty) {
        final photoId = _queue.removeFirst();
        try {
          await _generateForPhotoId(photoId);
        } finally {
          _queuedPhotoIds.remove(photoId);
        }
      }
    } finally {
      _isProcessing = false;
    }
  }

  Future<void> _generateForPhotoId(String photoId) async {
    final photo = await _repository.photoById(photoId);
    if (photo == null) return;

    if (await _hasValidThumbnail(photo)) {
      final existing = photo.thumbnailPath;
      if (existing != null && existing.isNotEmpty) {
        _updates.add(photo.photoId);
      }
      return;
    }

    final sourcePath = photo.workingPath.isNotEmpty
        ? photo.workingPath
        : photo.originalPath;
    if (sourcePath.isEmpty) return;
    final sourceFile = File(sourcePath);
    if (!await sourceFile.exists()) return;

    final outputPath = await _repository.thumbnailPathForPhotoId(photo.photoId);

    final generated = await _generator(sourcePath, _gridSize, _jpegQuality);
    if (generated == null || generated.isEmpty) return;

    final outputFile = File(outputPath);
    await outputFile.parent.create(recursive: true);
    await outputFile.writeAsBytes(generated, flush: true);

    await _repository.setThumbnailPath(photo.photoId, outputPath);
    if (!_disposed) {
      _updates.add(photo.photoId);
    }
  }

  Future<bool> _hasValidThumbnail(LumaPhoto photo) async {
    final thumbPath = photo.thumbnailPath;
    if (thumbPath == null || thumbPath.isEmpty) return false;
    final file = File(thumbPath);
    if (!await file.exists()) return false;
    final stat = await file.stat();
    return stat.size > 0;
  }
}

Future<Uint8List?> _defaultThumbnailGenerator(
  String sourcePath,
  int size,
  int quality,
) {
  return Isolate.run(() {
    final file = File(sourcePath);
    if (!file.existsSync()) return null;
    final bytes = file.readAsBytesSync();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return null;
    final square = img.copyResizeCropSquare(decoded, size: size);
    final jpg = img.encodeJpg(square, quality: quality);
    return Uint8List.fromList(jpg);
  });
}
