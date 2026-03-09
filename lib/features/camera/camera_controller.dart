import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'camera_models.dart';

@immutable
class CameraInitializeResult {
  final bool isReady;
  final bool supportsUltraWide;
  final bool supportsRawCapture;
  final bool supportsAppleProRAWCapture;
  final CameraLensMode activeLensMode;
  final bool isAeAfLocked;
  final double exposureBias;
  final double lookStrength;
  final CameraCaptureFormat captureFormat;
  final List<CameraCaptureFormat> availableCaptureFormats;
  final double zoomFactor;
  final double minZoomFactor;
  final double maxZoomFactor;
  final double megapixels;
  final List<CameraPhotoResolution> availablePhotoResolutions;
  final CameraPhotoResolution? selectedPhotoResolution;
  final bool supportsManualFocus;
  final double focusDistance;
  final bool isManualFocusActive;

  const CameraInitializeResult({
    required this.isReady,
    required this.supportsUltraWide,
    required this.supportsRawCapture,
    required this.supportsAppleProRAWCapture,
    required this.activeLensMode,
    required this.isAeAfLocked,
    required this.exposureBias,
    required this.lookStrength,
    required this.captureFormat,
    required this.availableCaptureFormats,
    required this.zoomFactor,
    required this.minZoomFactor,
    required this.maxZoomFactor,
    required this.megapixels,
    required this.availablePhotoResolutions,
    required this.selectedPhotoResolution,
    required this.supportsManualFocus,
    required this.focusDistance,
    required this.isManualFocusActive,
  });
}

@immutable
class CameraZoomUpdate {
  final double zoomFactor;
  final double minZoomFactor;
  final double maxZoomFactor;
  final double megapixels;
  final List<CameraPhotoResolution> availablePhotoResolutions;
  final CameraPhotoResolution? selectedPhotoResolution;

  const CameraZoomUpdate({
    required this.zoomFactor,
    required this.minZoomFactor,
    required this.maxZoomFactor,
    required this.megapixels,
    required this.availablePhotoResolutions,
    required this.selectedPhotoResolution,
  });

  factory CameraZoomUpdate.fromMap(Map<dynamic, dynamic>? map) {
    final zoomFactorRaw = (map?['zoomFactor'] as num?)?.toDouble() ?? 1.0;
    final minZoomRaw =
        (map?['minZoomFactor'] as num?)?.toDouble() ??
        kCameraZoomFactorMinDefault;
    final maxZoomRaw =
        (map?['maxZoomFactor'] as num?)?.toDouble() ??
        kCameraZoomFactorMaxDefault;
    final minZoom = minZoomRaw > 0 ? minZoomRaw : kCameraZoomFactorMinDefault;
    final maxZoom = maxZoomRaw >= minZoom ? maxZoomRaw : minZoom;
    final megapixelsRaw = (map?['megapixels'] as num?)?.toDouble() ?? 12.0;
    final availablePhotoResolutions = _photoResolutionsFromPayload(
      map?['availablePhotoResolutions'],
    );
    final selectedPhotoResolution =
        CameraPhotoResolution.fromMap(
          map?['selectedPhotoResolution'] as Map<dynamic, dynamic>?,
        ) ??
        (availablePhotoResolutions.isNotEmpty
            ? availablePhotoResolutions.first
            : null);
    return CameraZoomUpdate(
      zoomFactor: zoomFactorRaw.clamp(minZoom, maxZoom).toDouble(),
      minZoomFactor: minZoom,
      maxZoomFactor: maxZoom,
      megapixels: megapixelsRaw.isFinite && megapixelsRaw > 0
          ? megapixelsRaw
          : 12.0,
      availablePhotoResolutions: availablePhotoResolutions,
      selectedPhotoResolution: selectedPhotoResolution,
    );
  }
}

@immutable
class CameraManualFocusUpdate {
  final bool supportsManualFocus;
  final double focusDistance;
  final bool isManualFocusActive;

  const CameraManualFocusUpdate({
    required this.supportsManualFocus,
    required this.focusDistance,
    required this.isManualFocusActive,
  });

  factory CameraManualFocusUpdate.fromMap(Map<dynamic, dynamic>? map) {
    final supports = (map?['supportsManualFocus'] as bool?) ?? false;
    final distanceRaw =
        (map?['focusDistance'] as num?)?.toDouble() ?? kCameraFocusDistanceMin;
    final distance = distanceRaw
        .clamp(kCameraFocusDistanceMin, kCameraFocusDistanceMax)
        .toDouble();
    final active = (map?['isManualFocusActive'] as bool?) ?? false;
    return CameraManualFocusUpdate(
      supportsManualFocus: supports,
      focusDistance: distance,
      isManualFocusActive: supports && active,
    );
  }
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
  Future<CameraZoomUpdate> setPhotoResolution(CameraPhotoResolution resolution);
  Future<CameraZoomUpdate> setZoomFactor(double factor);
  Future<CameraManualFocusUpdate> setManualFocusDistance(double distance);
  Future<double> setExposureBias(double bias);
  Future<CameraCaptureResult> capturePhoto();
  Future<Uint8List?> latestThumbnail();
  Stream<List<double>> histogramStream();
  Stream<CameraZoomUpdate> zoomStream();
  Future<void> disposeCamera();
}

class MethodChannelCameraBridge implements CameraBridge {
  static const MethodChannel _channel = MethodChannel('luma/camera');
  static const EventChannel _histogramChannel = EventChannel(
    'luma/camera_histogram',
  );
  static const EventChannel _zoomChannel = EventChannel('luma/camera_zoom');

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
    final supportsAppleProRAWCapture =
        (response?['supportsAppleProRAWCapture'] as bool?) ?? false;
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
    final availableCaptureFormats = _captureFormatsFromPayload(
      response?['availableCaptureFormats'],
      supportsRawCapture: supportsRawCapture,
      supportsAppleProRAWCapture: supportsAppleProRAWCapture,
    );
    final zoom = CameraZoomUpdate.fromMap(response);
    final manualFocus = CameraManualFocusUpdate.fromMap(response);
    return CameraInitializeResult(
      isReady: isReady,
      supportsUltraWide: supportsUltraWide,
      supportsRawCapture: supportsRawCapture,
      supportsAppleProRAWCapture: supportsAppleProRAWCapture,
      activeLensMode: activeLens,
      isAeAfLocked: isAeAfLocked,
      exposureBias: exposureBias,
      lookStrength: lookStrength
          .clamp(kCameraLookStrengthMin, kCameraLookStrengthMax)
          .toDouble(),
      captureFormat: captureFormat,
      availableCaptureFormats: availableCaptureFormats,
      zoomFactor: zoom.zoomFactor,
      minZoomFactor: zoom.minZoomFactor,
      maxZoomFactor: zoom.maxZoomFactor,
      megapixels: zoom.megapixels,
      availablePhotoResolutions: zoom.availablePhotoResolutions,
      selectedPhotoResolution: zoom.selectedPhotoResolution,
      supportsManualFocus: manualFocus.supportsManualFocus,
      focusDistance: manualFocus.focusDistance,
      isManualFocusActive: manualFocus.isManualFocusActive,
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
  Future<CameraZoomUpdate> setPhotoResolution(
    CameraPhotoResolution resolution,
  ) async {
    final response = await _channel.invokeMapMethod<String, dynamic>(
      'setPhotoResolution',
      {'width': resolution.width, 'height': resolution.height},
    );
    return CameraZoomUpdate.fromMap(response);
  }

  @override
  Future<CameraZoomUpdate> setZoomFactor(double factor) async {
    final response = await _channel.invokeMapMethod<String, dynamic>(
      'setZoomFactor',
      {'zoomFactor': factor},
    );
    return CameraZoomUpdate.fromMap(response);
  }

  @override
  Future<CameraManualFocusUpdate> setManualFocusDistance(
    double distance,
  ) async {
    final response = await _channel.invokeMapMethod<String, dynamic>(
      'setManualFocusDistance',
      {'focusDistance': distance},
    );
    return CameraManualFocusUpdate.fromMap(response);
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
  Stream<CameraZoomUpdate> zoomStream() {
    return _zoomChannel.receiveBroadcastStream().map(
      (event) => CameraZoomUpdate.fromMap(
        event is Map<dynamic, dynamic> ? event : null,
      ),
    );
  }

  @override
  Future<void> disposeCamera() async {
    await _channel.invokeMethod<void>('disposeCamera');
  }
}

List<CameraCaptureFormat> _captureFormatsFromPayload(
  dynamic raw, {
  required bool supportsRawCapture,
  required bool supportsAppleProRAWCapture,
}) {
  final formats = <CameraCaptureFormat>[];
  if (raw is List) {
    for (final item in raw) {
      formats.add(cameraCaptureFormatFromWire(item as String?));
    }
  }
  if (formats.isEmpty) {
    formats.add(CameraCaptureFormat.heic);
    formats.add(CameraCaptureFormat.jpg);
    if (supportsRawCapture) {
      formats.add(CameraCaptureFormat.raw);
    }
    if (supportsAppleProRAWCapture) {
      formats.add(CameraCaptureFormat.proRaw);
    }
  }
  final unique = <CameraCaptureFormat>[];
  for (final format in formats) {
    if (!unique.contains(format)) {
      unique.add(format);
    }
  }
  return List<CameraCaptureFormat>.unmodifiable(unique);
}

List<CameraPhotoResolution> _photoResolutionsFromPayload(dynamic raw) {
  if (raw is! List) {
    return const <CameraPhotoResolution>[];
  }
  final resolutions = <CameraPhotoResolution>[];
  for (final item in raw) {
    final resolution = CameraPhotoResolution.fromMap(
      item as Map<dynamic, dynamic>?,
    );
    if (resolution != null && !resolutions.contains(resolution)) {
      resolutions.add(resolution);
    }
  }
  resolutions.sort(
    (left, right) => left.megapixels.compareTo(right.megapixels),
  );
  return List<CameraPhotoResolution>.unmodifiable(resolutions);
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
