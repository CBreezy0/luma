import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'camera_models.dart';

@immutable
class CameraInitializeResult {
  final bool isReady;
  final bool supportsUltraWide;
  final bool supportsRawCapture;
  final CameraLensMode activeLensMode;
  final bool isAeAfLocked;
  final double exposureBias;
  final double lookStrength;
  final CameraCaptureFormat captureFormat;

  const CameraInitializeResult({
    required this.isReady,
    required this.supportsUltraWide,
    required this.supportsRawCapture,
    required this.activeLensMode,
    required this.isAeAfLocked,
    required this.exposureBias,
    required this.lookStrength,
    required this.captureFormat,
  });
}

abstract class CameraBridge {
  Future<CameraInitializeResult> initializeCamera();
  Future<void> startCamera();
  Future<void> stopCamera();
  Future<void> setSimulation({
    required String simulationId,
    required double intensity,
  });
  Future<void> setFocusPoint({
    required double x,
    required double y,
    bool lock = false,
  });
  Future<double> setLookStrength(double strength);
  Future<void> setFlashMode(CameraFlashMode mode);
  Future<CameraLensMode> setLensMode(CameraLensMode mode);
  Future<CameraCaptureFormat> setCaptureFormat(CameraCaptureFormat format);
  Future<double> setExposureBias(double bias);
  Future<CameraCaptureResult> capturePhoto();
  Future<Uint8List?> latestThumbnail();
  Stream<List<double>> histogramStream();
  Future<void> disposeCamera();
}

class MethodChannelCameraBridge implements CameraBridge {
  static const MethodChannel _channel = MethodChannel('luma/camera');
  static const EventChannel _histogramChannel = EventChannel(
    'luma/camera_histogram',
  );

  const MethodChannelCameraBridge();

  @override
  Future<CameraInitializeResult> initializeCamera() async {
    final response = await _channel.invokeMapMethod<String, dynamic>(
      'initializeCamera',
    );
    final isReady = (response?['isReady'] as bool?) ?? true;
    final supportsUltraWide =
        (response?['supportsUltraWide'] as bool?) ?? false;
    final supportsRawCapture =
        (response?['supportsRawCapture'] as bool?) ?? false;
    final activeLens = cameraLensModeFromWire(
      response?['activeLensMode'] as String?,
    );
    final isAeAfLocked = (response?['isAeAfLocked'] as bool?) ?? false;
    final exposureBias = (response?['exposureBias'] as num?)?.toDouble() ?? 0.0;
    final lookStrength =
        (response?['lookStrength'] as num?)?.toDouble() ??
        kCameraLookStrengthMax;
    final captureFormat = cameraCaptureFormatFromWire(
      response?['captureFormat'] as String?,
    );
    return CameraInitializeResult(
      isReady: isReady,
      supportsUltraWide: supportsUltraWide,
      supportsRawCapture: supportsRawCapture,
      activeLensMode: activeLens,
      isAeAfLocked: isAeAfLocked,
      exposureBias: exposureBias,
      lookStrength: lookStrength
          .clamp(kCameraLookStrengthMin, kCameraLookStrengthMax)
          .toDouble(),
      captureFormat: captureFormat,
    );
  }

  @override
  Future<void> startCamera() async {
    await _channel.invokeMethod<void>('startCamera');
  }

  @override
  Future<void> stopCamera() async {
    await _channel.invokeMethod<void>('stopCamera');
  }

  @override
  Future<void> setSimulation({
    required String simulationId,
    required double intensity,
  }) async {
    await _channel.invokeMethod<void>('setSimulation', {
      'simulationId': simulationId,
      'intensity': intensity,
    });
  }

  @override
  Future<void> setFocusPoint({
    required double x,
    required double y,
    bool lock = false,
  }) async {
    await _channel.invokeMethod<void>('setFocusPoint', {
      'x': x,
      'y': y,
      'lock': lock,
    });
  }

  @override
  Future<double> setLookStrength(double strength) async {
    final response = await _channel.invokeMapMethod<String, dynamic>(
      'setLookStrength',
      {'strength': strength},
    );
    return (response?['lookStrength'] as num?)?.toDouble() ?? strength;
  }

  @override
  Future<void> setFlashMode(CameraFlashMode mode) async {
    await _channel.invokeMethod<void>('setFlashMode', {
      'flashMode': mode.wireValue,
    });
  }

  @override
  Future<CameraLensMode> setLensMode(CameraLensMode mode) async {
    final response = await _channel.invokeMapMethod<String, dynamic>(
      'setLensMode',
      {'lensMode': mode.wireValue},
    );
    return cameraLensModeFromWire(response?['activeLensMode'] as String?);
  }

  @override
  Future<CameraCaptureFormat> setCaptureFormat(
    CameraCaptureFormat format,
  ) async {
    final response = await _channel.invokeMapMethod<String, dynamic>(
      'setCaptureFormat',
      {'captureFormat': format.wireValue},
    );
    return cameraCaptureFormatFromWire(response?['captureFormat'] as String?);
  }

  @override
  Future<double> setExposureBias(double bias) async {
    final response = await _channel.invokeMapMethod<String, dynamic>(
      'setExposureBias',
      {'bias': bias},
    );
    return (response?['exposureBias'] as num?)?.toDouble() ?? bias;
  }

  @override
  Future<CameraCaptureResult> capturePhoto() async {
    final response = await _channel.invokeMapMethod<dynamic, dynamic>(
      'capturePhoto',
    );
    if (response == null) {
      throw StateError('capturePhoto returned null');
    }
    return CameraCaptureResult.fromMap(response);
  }

  @override
  Future<Uint8List?> latestThumbnail() async {
    final response = await _channel.invokeMethod<dynamic>('latestThumbnail');
    if (response == null) return null;
    if (response is Uint8List) return response;
    if (response is ByteData) return response.buffer.asUint8List();
    return null;
  }

  @override
  Stream<List<double>> histogramStream() {
    return _histogramChannel
        .receiveBroadcastStream()
        .map(parseCameraHistogramPayload)
        .where((bins) => bins.isNotEmpty);
  }

  @override
  Future<void> disposeCamera() async {
    await _channel.invokeMethod<void>('disposeCamera');
  }
}

List<double> parseCameraHistogramPayload(dynamic payload) {
  final dynamic rawBins;
  if (payload is List) {
    rawBins = payload;
  } else if (payload is Map) {
    rawBins = payload['bins'];
  } else {
    return const <double>[];
  }

  if (rawBins is! List) return const <double>[];

  final parsed = <double>[];
  for (final value in rawBins) {
    final numValue = switch (value) {
      num v => v.toDouble(),
      String s => double.tryParse(s),
      _ => null,
    };
    if (numValue == null || !numValue.isFinite) continue;
    parsed.add(numValue.clamp(0.0, 1.0));
    if (parsed.length >= 128) break;
  }
  return parsed;
}
