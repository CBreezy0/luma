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
            return {'captureFormat': 'raw'};
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
              'captureFormat': 'jpg',
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
    expect(result.captureFormat, CameraCaptureFormat.jpg);
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
}
