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

enum CameraCaptureFormat { heic, jpg, raw, proRaw, rawPlusHeic, rawPlusJpg }

enum CameraCaptureState { idle, capturing }

const double kCameraExposureBiasMin = -2.0;
const double kCameraExposureBiasMax = 2.0;
const double kCameraLookStrengthMin = 0.0;
const double kCameraLookStrengthMax = 1.0;
const double kCameraZoomFactorMinDefault = 1.0;
const double kCameraZoomFactorMaxDefault = 5.0;
const double kCameraFocusDistanceMin = 0.0;
const double kCameraFocusDistanceMax = 1.0;
const CameraPhotoResolution kDefaultPhotoResolution = CameraPhotoResolution(
  width: 4000,
  height: 3000,
);

@immutable
class CameraPhotoResolution {
  final int width;
  final int height;

  const CameraPhotoResolution({required this.width, required this.height});

  double get megapixels => (width * height) / 1000000.0;
  int get displayMegapixels => canonicalMegapixelValue(megapixels);

  String get wireValue => '${width}x$height';

  String get label => megapixelLabelForValue(megapixels);

  static int canonicalMegapixelValue(double value) {
    final safeValue = value.isFinite && value > 0 ? value : 12.0;
    const tiers = <int>[12, 24, 48];
    for (final tier in tiers) {
      final tolerance = switch (tier) {
        48 => 8.0,
        24 => 4.0,
        _ => 2.0,
      };
      if ((safeValue - tier).abs() <= tolerance) {
        return tier;
      }
    }
    return safeValue.round();
  }

  static String megapixelLabelForValue(double value) {
    return '${canonicalMegapixelValue(value)} MP';
  }

  static CameraPhotoResolution? fromMap(Map<dynamic, dynamic>? map) {
    final width = (map?['width'] as num?)?.toInt();
    final height = (map?['height'] as num?)?.toInt();
    if (width == null || height == null || width <= 0 || height <= 0) {
      return null;
    }
    return CameraPhotoResolution(width: width, height: height);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is CameraPhotoResolution &&
            runtimeType == other.runtimeType &&
            width == other.width &&
            height == other.height;
  }

  @override
  int get hashCode => Object.hash(width, height);
}

@immutable
class CameraCaptureResult {
  final String? localIdentifier;
  final String? filePath;
  final String simulationId;
  final double lookStrength;
  final String mimeType;
  final String? rawFilePath;
  final String? rawMimeType;
  final double? iso;
  final String? shutterSpeed;
  final double? aperture;
  final double? focalLength;
  final String? lens;
  final int? width;
  final int? height;
  final String? location;
  final int capturedAtMs;
  final CameraCaptureFormat captureFormat;

  const CameraCaptureResult({
    required this.simulationId,
    required this.lookStrength,
    required this.mimeType,
    required this.capturedAtMs,
    required this.captureFormat,
    this.rawFilePath,
    this.rawMimeType,
    this.iso,
    this.shutterSpeed,
    this.aperture,
    this.focalLength,
    this.lens,
    this.localIdentifier,
    this.filePath,
    this.width,
    this.height,
    this.location,
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
      rawFilePath: map['rawFilePath'] as String?,
      rawMimeType: map['rawMimeType'] as String?,
      iso: (map['iso'] as num?)?.toDouble(),
      shutterSpeed: map['shutterSpeed'] as String?,
      aperture: (map['aperture'] as num?)?.toDouble(),
      focalLength: (map['focalLength'] as num?)?.toDouble(),
      lens: map['lens'] as String?,
      width: (map['width'] as num?)?.toInt(),
      height: (map['height'] as num?)?.toInt(),
      location: map['location'] as String?,
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
  final bool supportsAppleProRAWCapture;
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
  final int captureFeedbackVersion;
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
    required this.supportsAppleProRAWCapture,
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
    required this.captureFeedbackVersion,
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
      supportsAppleProRAWCapture: false,
      captureFormat: CameraCaptureFormat.heic,
      availableCaptureFormats: const [
        CameraCaptureFormat.heic,
        CameraCaptureFormat.jpg,
      ],
      zoomFactor: 1.0,
      minZoomFactor: kCameraZoomFactorMinDefault,
      maxZoomFactor: kCameraZoomFactorMaxDefault,
      megapixels: kDefaultPhotoResolution.megapixels,
      availablePhotoResolutions: const [kDefaultPhotoResolution],
      selectedPhotoResolution: kDefaultPhotoResolution,
      supportsManualFocus: false,
      focusDistance: kCameraFocusDistanceMin,
      isManualFocusActive: false,
      captureFeedbackVersion: 0,
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
    bool? supportsAppleProRAWCapture,
    CameraCaptureFormat? captureFormat,
    List<CameraCaptureFormat>? availableCaptureFormats,
    double? zoomFactor,
    double? minZoomFactor,
    double? maxZoomFactor,
    double? megapixels,
    List<CameraPhotoResolution>? availablePhotoResolutions,
    CameraPhotoResolution? selectedPhotoResolution,
    bool? supportsManualFocus,
    double? focusDistance,
    bool? isManualFocusActive,
    int? captureFeedbackVersion,
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
      supportsAppleProRAWCapture:
          supportsAppleProRAWCapture ?? this.supportsAppleProRAWCapture,
      captureFormat: captureFormat ?? this.captureFormat,
      availableCaptureFormats:
          availableCaptureFormats ?? this.availableCaptureFormats,
      zoomFactor: zoomFactor ?? this.zoomFactor,
      minZoomFactor: minZoomFactor ?? this.minZoomFactor,
      maxZoomFactor: maxZoomFactor ?? this.maxZoomFactor,
      megapixels: megapixels ?? this.megapixels,
      availablePhotoResolutions:
          availablePhotoResolutions ?? this.availablePhotoResolutions,
      selectedPhotoResolution:
          selectedPhotoResolution ?? this.selectedPhotoResolution,
      supportsManualFocus: supportsManualFocus ?? this.supportsManualFocus,
      focusDistance: focusDistance ?? this.focusDistance,
      isManualFocusActive: isManualFocusActive ?? this.isManualFocusActive,
      captureFeedbackVersion:
          captureFeedbackVersion ?? this.captureFeedbackVersion,
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
      case CameraCaptureFormat.heic:
        return 'heic';
      case CameraCaptureFormat.jpg:
        return 'jpg';
      case CameraCaptureFormat.raw:
        return 'raw';
      case CameraCaptureFormat.proRaw:
        return 'pro_raw';
      case CameraCaptureFormat.rawPlusHeic:
        return 'raw_plus_heic';
      case CameraCaptureFormat.rawPlusJpg:
        return 'raw_plus_jpg';
    }
  }

  String get label {
    switch (this) {
      case CameraCaptureFormat.heic:
        return 'HEIC';
      case CameraCaptureFormat.jpg:
        return 'JPEG';
      case CameraCaptureFormat.raw:
        return 'RAW';
      case CameraCaptureFormat.proRaw:
        return 'PRORAW';
      case CameraCaptureFormat.rawPlusHeic:
        return 'RAW+HEIC';
      case CameraCaptureFormat.rawPlusJpg:
        return 'RAW+JPEG';
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
    case 'raw_plus_heic':
    case 'raw_plus_processed':
      return CameraCaptureFormat.rawPlusHeic;
    case 'heic':
      return CameraCaptureFormat.heic;
    case 'raw_plus_jpg':
      return CameraCaptureFormat.rawPlusJpg;
    case 'raw':
      return CameraCaptureFormat.raw;
    case 'pro_raw':
    case 'proraw':
    case 'apple_proraw':
      return CameraCaptureFormat.proRaw;
    case 'jpg':
    default:
      return CameraCaptureFormat.jpg;
  }
}
