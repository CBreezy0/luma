import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luma/features/camera/camera_controller.dart';
import 'package:luma/features/camera/camera_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('luma/camera');
  final calls = <MethodCall>[];

  setUp(() {
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          if (call.method == 'setLensMode') {
            return {'activeLensMode': 'wide'};
          }
          if (call.method == 'setExposureBias') {
            return {'exposureBias': 0.6};
          }
          if (call.method == 'setLookStrength') {
            return {'lookStrength': 0.7};
          }
          if (call.method == 'setFocusPoint') {
            return {'x': 0.3, 'y': 0.4, 'isAeAfLocked': true};
          }
          if (call.method == 'setCaptureFormat') {
            final requested =
                (call.arguments as Map<dynamic, dynamic>?)?['captureFormat'];
            if (requested == 'raw_plus_heic') {
              return {'captureFormat': 'raw_plus_heic'};
            }
            return {'captureFormat': 'raw'};
          }
          if (call.method == 'setPhotoResolution') {
            return {
              'zoomFactor': 1.0,
              'minZoomFactor': 0.5,
              'maxZoomFactor': 5.0,
              'megapixels': 24.0,
              'availablePhotoResolutions': [
                {'width': 4032, 'height': 3024},
                {'width': 5712, 'height': 4284},
              ],
              'selectedPhotoResolution': {'width': 5712, 'height': 4284},
            };
          }
          if (call.method == 'setZoomFactor') {
            return {
              'zoomFactor': 3.0,
              'minZoomFactor': 0.5,
              'maxZoomFactor': 5.0,
              'megapixels': 24.0,
              'availablePhotoResolutions': [
                {'width': 4032, 'height': 3024},
                {'width': 5712, 'height': 4284},
              ],
              'selectedPhotoResolution': {'width': 5712, 'height': 4284},
            };
          }
          if (call.method == 'setManualFocusDistance') {
            return {
              'supportsManualFocus': true,
              'focusDistance': 0.72,
              'isManualFocusActive': true,
            };
          }
          if (call.method == 'capturePhoto') {
            return {
              'filePath': '/tmp/capture.heic',
              'localIdentifier': 'photo-id',
              'width': 3024,
              'height': 4032,
              'simulationId': 'original',
              'lookStrength': 0.85,
              'mimeType': 'image/heic',
              'iso': 125.0,
              'shutterSpeed': '1/120',
              'aperture': 1.78,
              'focalLength': 6.86,
              'lens': 'Wide',
              'location': '40.71280, -74.00600',
              'captureFormat': 'heic',
              'capturedAt': 1,
            };
          }
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('setSimulation sends expected method and arguments', () async {
    const bridge = MethodChannelCameraBridge();
    await bridge.setSimulation(simulationId: 'ember', intensity: 0.82);

    expect(calls, hasLength(1));
    expect(calls.first.method, 'setSimulation');
    expect(calls.first.arguments, {'simulationId': 'ember', 'intensity': 0.82});
  });

  test('setLensMode maps response to enum', () async {
    const bridge = MethodChannelCameraBridge();
    final mode = await bridge.setLensMode(CameraLensMode.ultraWide);

    expect(calls, hasLength(1));
    expect(calls.first.method, 'setLensMode');
    expect(calls.first.arguments, {'lensMode': 'ultraWide'});
    expect(mode, CameraLensMode.wide);
  });

  test('setExposureBias sends method and returns clamped bias', () async {
    const bridge = MethodChannelCameraBridge();
    final applied = await bridge.setExposureBias(0.9);

    expect(calls, hasLength(1));
    expect(calls.first.method, 'setExposureBias');
    expect(calls.first.arguments, {'bias': 0.9});
    expect(applied, 0.6);
  });

  test('setLookStrength sends method and returns mapped strength', () async {
    const bridge = MethodChannelCameraBridge();
    final applied = await bridge.setLookStrength(0.9);

    expect(calls, hasLength(1));
    expect(calls.first.method, 'setLookStrength');
    expect(calls.first.arguments, {'strength': 0.9});
    expect(applied, 0.7);
  });

  test('setFocusPoint sends normalized coordinates and lock flag', () async {
    const bridge = MethodChannelCameraBridge();
    await bridge.setFocusPoint(x: 0.3, y: 0.4, lock: true);

    expect(calls, hasLength(1));
    expect(calls.first.method, 'setFocusPoint');
    expect(calls.first.arguments, {'x': 0.3, 'y': 0.4, 'lock': true});
  });

  test('capturePhoto maps camera metadata payload', () async {
    const bridge = MethodChannelCameraBridge();
    final result = await bridge.capturePhoto();

    expect(result.filePath, '/tmp/capture.heic');
    expect(result.localIdentifier, 'photo-id');
    expect(result.width, 3024);
    expect(result.height, 4032);
    expect(result.simulationId, 'original');
    expect(result.lookStrength, 0.85);
    expect(result.iso, 125.0);
    expect(result.shutterSpeed, '1/120');
    expect(result.aperture, 1.78);
    expect(result.focalLength, 6.86);
    expect(result.lens, 'Wide');
    expect(result.location, '40.71280, -74.00600');
    expect(result.captureFormat, CameraCaptureFormat.heic);
    expect(result.capturedAtMs, 1);
  });

  test('setCaptureFormat sends method and maps response enum', () async {
    const bridge = MethodChannelCameraBridge();
    final format = await bridge.setCaptureFormat(CameraCaptureFormat.raw);

    expect(calls, hasLength(1));
    expect(calls.first.method, 'setCaptureFormat');
    expect(calls.first.arguments, {'captureFormat': 'raw'});
    expect(format, CameraCaptureFormat.raw);
  });

  test('setCaptureFormat preserves raw plus processed wire values', () async {
    const bridge = MethodChannelCameraBridge();
    final format = await bridge.setCaptureFormat(
      CameraCaptureFormat.rawPlusHeic,
    );

    expect(calls, hasLength(1));
    expect(calls.first.method, 'setCaptureFormat');
    expect(calls.first.arguments, {'captureFormat': 'raw_plus_heic'});
    expect(format, CameraCaptureFormat.rawPlusHeic);
  });

  test('setZoomFactor sends method and maps zoom payload', () async {
    const bridge = MethodChannelCameraBridge();
    final zoom = await bridge.setZoomFactor(3.4);

    expect(calls, hasLength(1));
    expect(calls.first.method, 'setZoomFactor');
    expect(calls.first.arguments, {'zoomFactor': 3.4});
    expect(zoom.zoomFactor, 3.0);
    expect(zoom.minZoomFactor, 0.5);
    expect(zoom.maxZoomFactor, 5.0);
    expect(
      zoom.selectedPhotoResolution,
      const CameraPhotoResolution(width: 5712, height: 4284),
    );
    expect(zoom.availablePhotoResolutions, hasLength(2));
  });

  test('setPhotoResolution sends method and maps response payload', () async {
    const bridge = MethodChannelCameraBridge();
    final zoom = await bridge.setPhotoResolution(
      const CameraPhotoResolution(width: 5712, height: 4284),
    );

    expect(calls, hasLength(1));
    expect(calls.first.method, 'setPhotoResolution');
    expect(calls.first.arguments, {'width': 5712, 'height': 4284});
    expect(zoom.megapixels, closeTo(24.0, 0.0001));
    expect(
      zoom.selectedPhotoResolution,
      const CameraPhotoResolution(width: 5712, height: 4284),
    );
  });

  test('setManualFocusDistance sends method and maps payload', () async {
    const bridge = MethodChannelCameraBridge();
    final focus = await bridge.setManualFocusDistance(0.72);

    expect(calls, hasLength(1));
    expect(calls.first.method, 'setManualFocusDistance');
    expect(calls.first.arguments, {'focusDistance': 0.72});
    expect(focus.supportsManualFocus, isTrue);
    expect(focus.focusDistance, closeTo(0.72, 0.0001));
    expect(focus.isManualFocusActive, isTrue);
  });
}
