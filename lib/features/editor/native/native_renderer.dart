import 'package:flutter/services.dart';

class NativeRenderer {
  static const MethodChannel _channel = MethodChannel('luma/native_renderer');

  static Future<PreviewResult> renderPreview({
    required String assetId,
    required Map<String, double> values,
    required int maxSide,
    required double quality,
    String? assetPath,
    String previewTier = 'final',
    int requestId = 0,
    Map<String, double>? presetValues,
    double? presetIntensity,
    String? presetBlendMode,
    double? cropAspect,
    int rotationTurns = 0,
    double straightenDegrees = 0,
    Rect? cropRect,
  }) async {
    final crop = <String, dynamic>{
      'rotationTurns': rotationTurns,
      'straighten': straightenDegrees,
    };
    if (cropAspect != null) {
      crop['aspect'] = cropAspect;
    }
    if (cropRect != null) {
      crop['rect'] = {
        'x': cropRect.left,
        'y': cropRect.top,
        'w': cropRect.width,
        'h': cropRect.height,
      };
    }

    final result = await _channel.invokeMethod<dynamic>('renderPreview', {
      'assetId': assetId,
      'values': values,
      'maxSide': maxSide,
      'quality': quality,
      if (assetPath != null) 'assetPath': assetPath,
      'previewTier': previewTier,
      'requestId': requestId,
      if (presetValues != null) 'presetValues': presetValues,
      if (presetIntensity != null) 'presetIntensity': presetIntensity,
      if (presetBlendMode != null) 'presetBlendMode': presetBlendMode,
      'crop': crop,
    });

    if (result == null) {
      throw StateError('Native renderPreview returned null');
    }

    if (result is Uint8List) {
      return PreviewResult(requestId: requestId, bytes: result);
    }
    if (result is Map) {
      final id = result['requestId'];
      final bytes = result['bytes'];
      if (bytes is Uint8List) {
        final parsedId = (id is int) ? id : requestId;
        return PreviewResult(requestId: parsedId, bytes: bytes);
      }
    }
    throw StateError('Native renderPreview returned unexpected result type');
  }

  static Future<void> exportFullRes({
    required String assetId,
    required Map<String, double> values,
    required double quality,
    String? assetPath,
    double? cropAspect,
    int rotationTurns = 0,
    double straightenDegrees = 0,
    Rect? cropRect,
  }) async {
    final crop = <String, dynamic>{
      'rotationTurns': rotationTurns,
      'straighten': straightenDegrees,
    };
    if (cropAspect != null) {
      crop['aspect'] = cropAspect;
    }
    if (cropRect != null) {
      crop['rect'] = {
        'x': cropRect.left,
        'y': cropRect.top,
        'w': cropRect.width,
        'h': cropRect.height,
      };
    }

    await _channel.invokeMethod<void>('exportFullRes', {
      'assetId': assetId,
      'values': values,
      'quality': quality,
      if (assetPath != null) 'assetPath': assetPath,
      'crop': crop,
    });
  }
}

class PreviewResult {
  final int requestId;
  final Uint8List bytes;

  const PreviewResult({required this.requestId, required this.bytes});
}
