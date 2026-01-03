import 'package:flutter/services.dart';

class NativeRenderer {
  static const MethodChannel _channel = MethodChannel('luma/native_renderer');

  static Future<Uint8List> renderPreview({
    required String assetId,
    required Map<String, double> values,
    required int maxSide,
    required double quality,
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

    final result = await _channel.invokeMethod<Uint8List>('renderPreview', {
      'assetId': assetId,
      'values': values,
      'maxSide': maxSide,
      'quality': quality,
      'crop': crop,
    });

    if (result == null) {
      throw StateError('Native renderPreview returned null');
    }

    return result;
  }

  static Future<void> exportFullRes({
    required String assetId,
    required Map<String, double> values,
    required double quality,
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
      'crop': crop,
    });
  }
}
