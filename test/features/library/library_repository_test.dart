import 'dart:io';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:luma/features/camera/camera_models.dart';
import 'package:luma/features/library/library_models.dart';
import 'package:luma/features/library/library_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final isarCorePresent = _isLocalIsarCorePresent();

  late Directory tempDir;
  late LumaLibraryRepository repository;

  setUp(() async {
    if (!isarCorePresent) return;
    tempDir = await Directory.systemTemp.createTemp('luma_library_test_');
    repository = LumaLibraryRepository(
      rootDirectoryOverride: tempDir,
      isarName: 'luma_test_${DateTime.now().microsecondsSinceEpoch}',
    );
    await repository.initialize();
  });

  tearDown(() async {
    if (!isarCorePresent) return;
    await repository.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test(
    'savePhoto and getPhotosSortedByDate return newest first',
    () async {
      final older = _buildPhoto(
        photoId: 'older',
        captureDateMs: 1000,
        isFavorite: false,
        rating: 1,
      );
      final newer = _buildPhoto(
        photoId: 'newer',
        captureDateMs: 2000,
        isFavorite: true,
        rating: 5,
      );

      await repository.savePhoto(older);
      await repository.savePhoto(newer);

      final sorted = await repository.getPhotosSortedByDate();
      expect(sorted.length, 2);
      expect(sorted.first.photoId, 'newer');
      expect(sorted.last.photoId, 'older');
    },
    skip: !isarCorePresent,
  );

  test('getFavorites returns only favorite records', () async {
    await repository.savePhoto(
      _buildPhoto(
        photoId: 'favorite',
        captureDateMs: 1000,
        isFavorite: true,
        rating: 3,
      ),
    );
    await repository.savePhoto(
      _buildPhoto(
        photoId: 'normal',
        captureDateMs: 2000,
        isFavorite: false,
        rating: 4,
      ),
    );

    final favorites = await repository.getFavorites();
    expect(favorites.length, 1);
    expect(favorites.single.photoId, 'favorite');
  }, skip: !isarCorePresent);

  test('getPhotosByRating filters by minimum rating', () async {
    await repository.savePhoto(
      _buildPhoto(
        photoId: 'low',
        captureDateMs: 1000,
        isFavorite: false,
        rating: 2,
      ),
    );
    await repository.savePhoto(
      _buildPhoto(
        photoId: 'high',
        captureDateMs: 2000,
        isFavorite: false,
        rating: 5,
      ),
    );

    final rated = await repository.getPhotosByRating(4);
    expect(rated.length, 1);
    expect(rated.single.photoId, 'high');
  }, skip: !isarCorePresent);

  test('deletePhoto removes metadata record', () async {
    await repository.savePhoto(
      _buildPhoto(
        photoId: 'to-delete',
        captureDateMs: 1000,
        isFavorite: false,
        rating: 1,
      ),
    );

    await repository.deletePhoto('to-delete');
    final all = await repository.getAllPhotos();
    expect(all, isEmpty);
  }, skip: !isarCorePresent);

  test('addCapturedPhoto preserves capture metadata fields', () async {
    final source = File('${tempDir.path}/capture.heic');
    await source.writeAsBytes(const <int>[1, 2, 3, 4, 5]);

    final saved = await repository.addCapturedPhoto(
      CameraCaptureResult(
        localIdentifier: 'asset-id',
        filePath: source.path,
        simulationId: 'original',
        lookStrength: 1.0,
        mimeType: 'image/heic',
        iso: 160,
        shutterSpeed: '1/60',
        aperture: 1.78,
        focalLength: 6.86,
        lens: 'Wide',
        width: 4032,
        height: 3024,
        location: '40.71280, -74.00600',
        capturedAtMs: 123456789,
        captureFormat: CameraCaptureFormat.heic,
      ),
    );

    final loaded = await repository.photoById(saved.photoId);
    expect(loaded, isNotNull);
    expect(loaded!.iso, 160);
    expect(loaded.shutterSpeed, '1/60');
    expect(loaded.aperture, 1.78);
    expect(loaded.focalLength, 6.86);
    expect(loaded.lens, 'Wide');
    expect(loaded.location, '40.71280, -74.00600');
    expect(loaded.width, 4032);
    expect(loaded.height, 3024);
  }, skip: !isarCorePresent);

  test(
    'updatePhotos applies batch favorite/rating/color label changes',
    () async {
      await repository.savePhoto(
        _buildPhoto(
          photoId: 'batch-1',
          captureDateMs: 1000,
          isFavorite: false,
          rating: 0,
        ),
      );
      await repository.savePhoto(
        _buildPhoto(
          photoId: 'batch-2',
          captureDateMs: 2000,
          isFavorite: false,
          rating: 0,
        ),
      );

      await repository.updatePhotos({'batch-1', 'batch-2'}, (photo) {
        return photo.copyWith(
          isFavorite: true,
          rating: 4,
          colorLabel: LumaColorLabel.green,
        );
      });

      final all = await repository.getAllPhotos();
      expect(all.length, 2);
      for (final photo in all) {
        expect(photo.isFavorite, isTrue);
        expect(photo.rating, 4);
        expect(photo.colorLabel, LumaColorLabel.green);
      }
    },
    skip: !isarCorePresent,
  );

  test(
    'migrates legacy library_index.json into database once',
    () async {
      await repository.close();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
      tempDir = await Directory.systemTemp.createTemp(
        'luma_library_migrate_test_',
      );

      final legacyRepository = LumaLibraryRepository(
        rootDirectoryOverride: tempDir,
        isarName: 'luma_migrate_${DateTime.now().microsecondsSinceEpoch}',
      );
      final legacyPhoto = _buildPhoto(
        photoId: 'legacy-photo',
        captureDateMs: 12345,
        isFavorite: true,
        rating: 5,
      );
      final legacyFile = File('${tempDir.path}/library_index.json');
      await legacyFile.writeAsString(jsonEncode([legacyPhoto.toJson()]));

      await legacyRepository.initialize();
      final migrated = await legacyRepository.getAllPhotos();

      expect(migrated.length, 1);
      expect(migrated.single.photoId, 'legacy-photo');
      expect(await legacyFile.exists(), isFalse);

      await legacyRepository.close();
    },
    skip: !isarCorePresent,
  );
}

bool _isLocalIsarCorePresent() {
  final cwd = Directory.current.path;
  final candidates = <String>['libisar.dylib', 'libisar.so', 'isar.dll'];
  for (final file in candidates) {
    if (File('$cwd/$file').existsSync()) {
      return true;
    }
  }
  return false;
}

LumaPhoto _buildPhoto({
  required String photoId,
  required int captureDateMs,
  required bool isFavorite,
  required int rating,
}) {
  final version = LumaPhotoVersion(
    versionId: 'original-$photoId',
    name: 'Original',
    createdAtMs: captureDateMs,
    instructions: const <LumaEditInstruction>[],
    renderedPath: null,
  );

  return LumaPhoto(
    photoId: photoId,
    captureIdentifier: photoId,
    captureDateMs: captureDateMs,
    format: LumaPhotoFormat.jpg,
    isFavorite: isFavorite,
    rating: rating,
    colorLabel: LumaColorLabel.none,
    imported: false,
    originalPath: '/tmp/$photoId.jpg',
    workingPath: '/tmp/$photoId.jpg',
    versions: List<LumaPhotoVersion>.unmodifiable([version]),
    activeVersionId: version.versionId,
  );
}
