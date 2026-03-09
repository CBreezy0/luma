import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:luma/features/library/library_models.dart';
import 'package:luma/features/library/library_repository.dart';
import 'package:luma/features/library/thumbnail_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final isarCorePresent = _isLocalIsarCorePresent();

  late Directory tempDir;
  late LumaLibraryRepository repository;

  setUp(() async {
    if (!isarCorePresent) return;
    tempDir = await Directory.systemTemp.createTemp(
      'luma_thumbnail_service_test_',
    );
    repository = LumaLibraryRepository(
      rootDirectoryOverride: tempDir,
      isarName: 'luma_thumb_${DateTime.now().microsecondsSinceEpoch}',
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

  test('thumbnailPathForPhotoId uses Thumbnails directory', () async {
    final path = await repository.thumbnailPathForPhotoId('photo_test');
    final expectedSuffix =
        '${Platform.pathSeparator}Thumbnails${Platform.pathSeparator}photo_test_grid.jpg';
    expect(path.endsWith(expectedSuffix), isTrue);
  }, skip: !isarCorePresent);

  test('enqueueForPhotoId avoids duplicate generation work', () async {
    final sourcePath = '${tempDir.path}${Platform.pathSeparator}source.jpg';
    await _writeSourceImage(sourcePath);
    await repository.savePhoto(
      _buildPhoto(
        photoId: 'photo_duplicate',
        captureDateMs: 1000,
        sourcePath: sourcePath,
      ),
    );

    var generatorCalls = 0;
    final service = LibraryThumbnailService(
      repository: repository,
      generator: (sourcePath, size, quality) async {
        generatorCalls += 1;
        await Future<void>.delayed(const Duration(milliseconds: 50));
        return Uint8List.fromList(<int>[1, 2, 3, 4]);
      },
    );
    final updateCompleter = Completer<void>();
    final subscription = service.updates.listen((photoId) {
      if (photoId == 'photo_duplicate' && !updateCompleter.isCompleted) {
        updateCompleter.complete();
      }
    });

    await Future.wait([
      service.enqueueForPhotoId('photo_duplicate'),
      service.enqueueForPhotoId('photo_duplicate'),
      service.enqueueForPhotoId('photo_duplicate'),
    ]);

    await updateCompleter.future.timeout(const Duration(seconds: 2));
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(generatorCalls, 1);
    final updated = await repository.photoById('photo_duplicate');
    expect(updated?.thumbnailPath, isNotNull);
    expect(File(updated!.thumbnailPath!).existsSync(), isTrue);

    await subscription.cancel();
    await service.dispose();
  }, skip: !isarCorePresent);
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

Future<void> _writeSourceImage(String path) async {
  final image = img.Image(width: 20, height: 20);
  img.fill(image, color: img.ColorRgb8(140, 90, 45));
  final bytes = img.encodeJpg(image, quality: 90);
  final file = File(path);
  await file.parent.create(recursive: true);
  await file.writeAsBytes(bytes, flush: true);
}

LumaPhoto _buildPhoto({
  required String photoId,
  required int captureDateMs,
  required String sourcePath,
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
    isFavorite: false,
    rating: 0,
    colorLabel: LumaColorLabel.none,
    imported: false,
    originalPath: sourcePath,
    workingPath: sourcePath,
    versions: List<LumaPhotoVersion>.unmodifiable(<LumaPhotoVersion>[version]),
    activeVersionId: version.versionId,
  );
}
