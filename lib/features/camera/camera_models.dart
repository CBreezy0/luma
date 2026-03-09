import 'package:flutter/foundation.dart';

@immutable
class LumaFilmSimulation {
  final String id;
  final String name;
  final double intensity;
  final String? iconToken;

  const LumaFilmSimulation({
    required this.id,
    required this.name,
    this.intensity = 1.0,
    this.iconToken,
  });
}

enum CameraLensMode { wide, ultraWide }

enum CameraFlashMode { auto, off, on }

enum CameraCaptureFormat { jpg, raw }

enum CameraCaptureState { idle, capturing }

const double kCameraExposureBiasMin = -1.5;
const double kCameraExposureBiasMax = 1.5;
const double kCameraLookStrengthMin = 0.0;
const double kCameraLookStrengthMax = 1.0;

@immutable
class CameraCaptureResult {
  final String? localIdentifier;
  final String? filePath;
  final String simulationId;
  final double lookStrength;
  final String mimeType;
  final int? width;
  final int? height;
  final int capturedAtMs;
  final CameraCaptureFormat captureFormat;

  const CameraCaptureResult({
    required this.simulationId,
    required this.lookStrength,
    required this.mimeType,
    required this.capturedAtMs,
    required this.captureFormat,
    this.localIdentifier,
    this.filePath,
    this.width,
    this.height,
  });

  factory CameraCaptureResult.fromMap(Map<dynamic, dynamic> map) {
    final localIdentifierValue = map['localIdentifier'];
    final filePathValue = map['filePath'];
    return CameraCaptureResult(
      localIdentifier: localIdentifierValue is String
          ? localIdentifierValue
          : null,
      filePath: filePathValue is String ? filePathValue : null,
      simulationId:
          (map['simulationId'] as String?) ??
          (map['lookId'] as String?) ??
          'original',
      lookStrength:
          (map['lookStrength'] as num?)
              ?.toDouble()
              .clamp(kCameraLookStrengthMin, kCameraLookStrengthMax)
              .toDouble() ??
          kCameraLookStrengthMax,
      mimeType: (map['mimeType'] as String?) ?? 'image/heic',
      width: (map['width'] as num?)?.toInt(),
      height: (map['height'] as num?)?.toInt(),
      capturedAtMs:
          (map['capturedAt'] as num?)?.toInt() ??
          (map['savedAtMs'] as num?)?.toInt() ??
          DateTime.now().millisecondsSinceEpoch,
      captureFormat: cameraCaptureFormatFromWire(
        map['captureFormat'] as String?,
      ),
    );
  }
}

@immutable
class CameraUiState {
  final String selectedSimulationId;
  final double lookStrength;
  final CameraFlashMode flashMode;
  final CameraLensMode lensMode;
  final bool isAeAfLocked;
  final double exposureBias;
  final CameraCaptureState captureState;
  final List<double> histogram;
  final bool isInitializing;
  final bool isReady;
  final bool supportsUltraWide;
  final bool supportsRawCapture;
  final CameraCaptureFormat captureFormat;
  final String? errorMessage;
  final Uint8List? latestThumbnail;
  final CameraCaptureResult? lastCapture;

  const CameraUiState({
    required this.selectedSimulationId,
    required this.lookStrength,
    required this.flashMode,
    required this.lensMode,
    required this.isAeAfLocked,
    required this.exposureBias,
    required this.captureState,
    required this.histogram,
    required this.isInitializing,
    required this.isReady,
    required this.supportsUltraWide,
    required this.supportsRawCapture,
    required this.captureFormat,
    this.errorMessage,
    this.latestThumbnail,
    this.lastCapture,
  });

  factory CameraUiState.initial({required String selectedSimulationId}) {
    return CameraUiState(
      selectedSimulationId: selectedSimulationId,
      lookStrength: 1.0,
      flashMode: CameraFlashMode.auto,
      lensMode: CameraLensMode.wide,
      isAeAfLocked: false,
      exposureBias: 0,
      captureState: CameraCaptureState.idle,
      histogram: const [],
      isInitializing: true,
      isReady: false,
      supportsUltraWide: false,
      supportsRawCapture: false,
      captureFormat: CameraCaptureFormat.jpg,
    );
  }

  bool get isCapturing => captureState == CameraCaptureState.capturing;

  CameraUiState copyWith({
    String? selectedSimulationId,
    double? lookStrength,
    CameraFlashMode? flashMode,
    CameraLensMode? lensMode,
    bool? isAeAfLocked,
    double? exposureBias,
    CameraCaptureState? captureState,
    List<double>? histogram,
    bool? isInitializing,
    bool? isReady,
    bool? supportsUltraWide,
    bool? supportsRawCapture,
    CameraCaptureFormat? captureFormat,
    Object? errorMessage = _cameraUnset,
    Object? latestThumbnail = _cameraUnset,
    Object? lastCapture = _cameraUnset,
  }) {
    return CameraUiState(
      selectedSimulationId: selectedSimulationId ?? this.selectedSimulationId,
      lookStrength: lookStrength ?? this.lookStrength,
      flashMode: flashMode ?? this.flashMode,
      lensMode: lensMode ?? this.lensMode,
      isAeAfLocked: isAeAfLocked ?? this.isAeAfLocked,
      exposureBias: exposureBias ?? this.exposureBias,
      captureState: captureState ?? this.captureState,
      histogram: histogram ?? this.histogram,
      isInitializing: isInitializing ?? this.isInitializing,
      isReady: isReady ?? this.isReady,
      supportsUltraWide: supportsUltraWide ?? this.supportsUltraWide,
      supportsRawCapture: supportsRawCapture ?? this.supportsRawCapture,
      captureFormat: captureFormat ?? this.captureFormat,
      errorMessage: identical(errorMessage, _cameraUnset)
          ? this.errorMessage
          : errorMessage as String?,
      latestThumbnail: identical(latestThumbnail, _cameraUnset)
          ? this.latestThumbnail
          : latestThumbnail as Uint8List?,
      lastCapture: identical(lastCapture, _cameraUnset)
          ? this.lastCapture
          : lastCapture as CameraCaptureResult?,
    );
  }
}

const Object _cameraUnset = Object();

extension CameraFlashModeCodec on CameraFlashMode {
  String get wireValue {
    switch (this) {
      case CameraFlashMode.auto:
        return 'auto';
      case CameraFlashMode.off:
        return 'off';
      case CameraFlashMode.on:
        return 'on';
    }
  }
}

extension CameraLensModeCodec on CameraLensMode {
  String get wireValue {
    switch (this) {
      case CameraLensMode.wide:
        return 'wide';
      case CameraLensMode.ultraWide:
        return 'ultraWide';
    }
  }
}

extension CameraCaptureFormatCodec on CameraCaptureFormat {
  String get wireValue {
    switch (this) {
      case CameraCaptureFormat.jpg:
        return 'jpg';
      case CameraCaptureFormat.raw:
        return 'raw';
    }
  }

  String get label {
    switch (this) {
      case CameraCaptureFormat.jpg:
        return 'JPG';
      case CameraCaptureFormat.raw:
        return 'RAW';
    }
  }
}

CameraFlashMode cameraFlashModeFromWire(String? value) {
  switch (value) {
    case 'off':
      return CameraFlashMode.off;
    case 'on':
      return CameraFlashMode.on;
    default:
      return CameraFlashMode.auto;
  }
}

CameraLensMode cameraLensModeFromWire(String? value) {
  switch (value) {
    case 'ultraWide':
      return CameraLensMode.ultraWide;
    default:
      return CameraLensMode.wide;
  }
}

CameraCaptureFormat cameraCaptureFormatFromWire(String? value) {
  switch (value) {
    case 'raw':
      return CameraCaptureFormat.raw;
    default:
      return CameraCaptureFormat.jpg;
  }
}
