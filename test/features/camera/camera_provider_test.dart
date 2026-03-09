import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:luma/features/camera/camera_controller.dart';
import 'package:luma/features/camera/camera_models.dart';
import 'package:luma/features/camera/camera_provider.dart';
import 'package:luma/features/camera/look_registry.dart';

void main() {
  test('initializeCamera clears loading and marks ready', () async {
    final bridge = _FakeCameraBridge();
    final controller = CameraUiController(
      bridge: bridge,
      simulations: kLumaFilmSimulations,
    );
    addTearDown(controller.dispose);

    expect(controller.state.isInitializing, isTrue);

    await controller.initializeCamera();

    expect(controller.state.isInitializing, isFalse);
    expect(controller.state.isReady, isTrue);
  });

  test(
    'initializeCamera failure clears loading and sets error state',
    () async {
      final bridge = _FailingInitializeBridge();
      final controller = CameraUiController(
        bridge: bridge,
        simulations: kLumaFilmSimulations,
      );
      addTearDown(controller.dispose);

      expect(controller.state.isInitializing, isTrue);

      await controller.initializeCamera();

      expect(controller.state.isInitializing, isFalse);
      expect(controller.state.isReady, isFalse);
      expect(controller.state.errorMessage, contains('Camera unavailable'));
    },
  );

  test('selected look updates and propagates to bridge', () async {
    final bridge = _FakeCameraBridge();
    final controller = CameraUiController(
      bridge: bridge,
      simulations: kLumaFilmSimulations,
    );
    addTearDown(controller.dispose);

    await controller.initializeCamera();
    await controller.setSimulation('ember');

    expect(controller.state.selectedSimulationId, 'ember');
    expect(bridge.lastSimulationId, 'ember');
  });

  test('look strength updates and clamps in provider state', () async {
    final bridge = _FakeCameraBridge();
    final controller = CameraUiController(
      bridge: bridge,
      simulations: kLumaFilmSimulations,
    );
    addTearDown(controller.dispose);

    await controller.initializeCamera();
    await controller.setLookStrength(0.42);
    expect(controller.state.lookStrength, closeTo(0.42, 0.0001));
    expect(bridge.lookStrength, closeTo(0.42, 0.0001));

    await controller.setLookStrength(2.0);
    expect(controller.state.lookStrength, kCameraLookStrengthMax);
    expect(bridge.lookStrength, kCameraLookStrengthMax);
  });

  test('capture format updates and propagates to bridge', () async {
    final bridge = _FakeCameraBridge();
    final controller = CameraUiController(
      bridge: bridge,
      simulations: kLumaFilmSimulations,
    );
    addTearDown(controller.dispose);

    await controller.initializeCamera();
    await controller.startCamera();
    await controller.setCaptureFormat(CameraCaptureFormat.raw);

    expect(controller.state.captureFormat, CameraCaptureFormat.raw);
    expect(bridge.captureFormat, CameraCaptureFormat.raw);
  });

  test('focus point toggles AE/AF lock state', () async {
    final bridge = _FakeCameraBridge();
    final controller = CameraUiController(
      bridge: bridge,
      simulations: kLumaFilmSimulations,
    );
    addTearDown(controller.dispose);

    await controller.initializeCamera();
    await controller.startCamera();

    await controller.setFocusPoint(x: 0.2, y: 0.8, lock: true);
    expect(controller.state.isAeAfLocked, isTrue);
    expect(bridge.focusX, closeTo(0.2, 0.0001));
    expect(bridge.focusY, closeTo(0.8, 0.0001));
    expect(bridge.isAeAfLocked, isTrue);

    await controller.setFocusPoint(x: 0.4, y: 0.6, lock: false);
    expect(controller.state.isAeAfLocked, isFalse);
    expect(bridge.isAeAfLocked, isFalse);
  });

  test('exposure bias updates and clamps in provider state', () async {
    final bridge = _FakeCameraBridge();
    final controller = CameraUiController(
      bridge: bridge,
      simulations: kLumaFilmSimulations,
    );
    addTearDown(controller.dispose);

    await controller.initializeCamera();
    await controller.setExposureBias(0.8);
    expect(controller.state.exposureBias, closeTo(0.8, 0.0001));
    expect(bridge.exposureBias, closeTo(0.8, 0.0001));

    await controller.setExposureBias(4.0);
    expect(controller.state.exposureBias, kCameraExposureBiasMax);
    expect(bridge.exposureBias, kCameraExposureBiasMax);
  });

  test('capture updates lastCapture and latest thumbnail', () async {
    final bridge = _FakeCameraBridge();
    final controller = CameraUiController(
      bridge: bridge,
      simulations: kLumaFilmSimulations,
    );
    addTearDown(controller.dispose);

    await controller.initializeCamera();
    await controller.startCamera();
    final result = await controller.capturePhoto();

    expect(result, isNotNull);
    expect(controller.state.lastCapture?.simulationId, kDefaultSimulationId);
    expect(controller.state.latestThumbnail, isNotNull);
  });

  test('capture is blocked while camera is initializing', () async {
    final bridge = _FakeCameraBridge();
    final controller = CameraUiController(
      bridge: bridge,
      simulations: kLumaFilmSimulations,
    );
    addTearDown(controller.dispose);

    final result = await controller.capturePhoto();

    expect(result, isNull);
    expect(controller.state.isCapturing, isFalse);
    expect(bridge.captureCalls, 0);
  });

  test(
    'capture failure sets provider error and resets capture state',
    () async {
      final bridge = _FailingCaptureBridge();
      final controller = CameraUiController(
        bridge: bridge,
        simulations: kLumaFilmSimulations,
      );
      addTearDown(controller.dispose);

      await controller.initializeCamera();
      await controller.startCamera();
      final result = await controller.capturePhoto();

      expect(result, isNull);
      expect(controller.state.isCapturing, isFalse);
      expect(controller.state.errorMessage, contains('Capture failed'));
      expect(controller.state.lastCapture, isNull);
    },
  );

  test('capture is locked while a capture is in progress', () async {
    final bridge = _DelayedCaptureBridge();
    final controller = CameraUiController(
      bridge: bridge,
      simulations: kLumaFilmSimulations,
    );
    addTearDown(controller.dispose);

    await controller.initializeCamera();
    await controller.startCamera();

    final firstCapture = controller.capturePhoto();
    expect(controller.state.isCapturing, isTrue);

    final secondCapture = await controller.capturePhoto();
    expect(secondCapture, isNull);
    expect(bridge.captureCalls, 1);

    bridge.releaseCapture();
    final firstResult = await firstCapture;
    expect(firstResult, isNotNull);
    expect(controller.state.isCapturing, isFalse);
  });
}

class _FakeCameraBridge implements CameraBridge {
  String? lastSimulationId;
  double lookStrength = 1.0;
  double exposureBias = 0;
  double focusX = 0.5;
  double focusY = 0.5;
  bool isAeAfLocked = false;
  CameraFlashMode flashMode = CameraFlashMode.auto;
  CameraLensMode lensMode = CameraLensMode.wide;
  CameraCaptureFormat captureFormat = CameraCaptureFormat.jpg;
  int captureCalls = 0;

  @override
  Future<CameraCaptureResult> capturePhoto() async {
    captureCalls += 1;
    return CameraCaptureResult(
      localIdentifier: 'fake-id',
      filePath: '/tmp/fake.heic',
      simulationId: lastSimulationId ?? kDefaultSimulationId,
      lookStrength: lookStrength,
      mimeType: 'image/heic',
      width: 1000,
      height: 750,
      capturedAtMs: DateTime.now().millisecondsSinceEpoch,
      captureFormat: captureFormat,
    );
  }

  @override
  Future<void> disposeCamera() async {}

  @override
  Future<CameraInitializeResult> initializeCamera() async {
    return const CameraInitializeResult(
      isReady: true,
      supportsUltraWide: true,
      supportsRawCapture: true,
      activeLensMode: CameraLensMode.wide,
      isAeAfLocked: false,
      exposureBias: 0,
      lookStrength: 1.0,
      captureFormat: CameraCaptureFormat.jpg,
    );
  }

  @override
  Future<Uint8List?> latestThumbnail() async {
    return Uint8List.fromList(<int>[0, 1, 2, 3]);
  }

  @override
  Stream<List<double>> histogramStream() {
    return const Stream<List<double>>.empty();
  }

  @override
  Future<CameraLensMode> setLensMode(CameraLensMode mode) async {
    lensMode = mode;
    isAeAfLocked = false;
    return lensMode;
  }

  @override
  Future<void> setFocusPoint({
    required double x,
    required double y,
    bool lock = false,
  }) async {
    focusX = x.clamp(0.0, 1.0).toDouble();
    focusY = y.clamp(0.0, 1.0).toDouble();
    isAeAfLocked = lock;
  }

  @override
  Future<double> setLookStrength(double strength) async {
    lookStrength = strength
        .clamp(kCameraLookStrengthMin, kCameraLookStrengthMax)
        .toDouble();
    return lookStrength;
  }

  @override
  Future<double> setExposureBias(double bias) async {
    exposureBias = bias
        .clamp(kCameraExposureBiasMin, kCameraExposureBiasMax)
        .toDouble();
    return exposureBias;
  }

  @override
  Future<void> setFlashMode(CameraFlashMode mode) async {
    flashMode = mode;
  }

  @override
  Future<CameraCaptureFormat> setCaptureFormat(
    CameraCaptureFormat format,
  ) async {
    captureFormat = format;
    return captureFormat;
  }

  @override
  Future<void> setSimulation({
    required String simulationId,
    required double intensity,
  }) async {
    lastSimulationId = simulationId;
  }

  @override
  Future<void> startCamera() async {}

  @override
  Future<void> stopCamera() async {}
}

class _FailingInitializeBridge extends _FakeCameraBridge {
  @override
  Future<CameraInitializeResult> initializeCamera() async {
    throw StateError('Permission denied');
  }
}

class _FailingCaptureBridge extends _FakeCameraBridge {
  @override
  Future<CameraCaptureResult> capturePhoto() async {
    throw StateError('Native capture failed');
  }
}

class _DelayedCaptureBridge extends _FakeCameraBridge {
  final Completer<void> _captureCompleter = Completer<void>();

  @override
  Future<CameraCaptureResult> capturePhoto() async {
    captureCalls += 1;
    await _captureCompleter.future;
    return CameraCaptureResult(
      localIdentifier: 'fake-id',
      filePath: '/tmp/fake.heic',
      simulationId: lastSimulationId ?? kDefaultSimulationId,
      lookStrength: lookStrength,
      mimeType: 'image/heic',
      width: 1000,
      height: 750,
      capturedAtMs: DateTime.now().millisecondsSinceEpoch,
      captureFormat: captureFormat,
    );
  }

  void releaseCapture() {
    if (!_captureCompleter.isCompleted) {
      _captureCompleter.complete();
    }
  }
}
