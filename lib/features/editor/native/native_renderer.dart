import 'package:flutter/services.dart';

class NativeRenderer {
  static const MethodChannel _channel = MethodChannel('luma/native_renderer');

  static Future<Uint8List> renderPreview({
    required String assetId,
    required Map<String, double> values,
    required int maxSide,
    required double quality,
  }) async {
    final result = await _channel.invokeMethod<Uint8List>('renderPreview', {
      'assetId': assetId,
      'values': values,
      'maxSide': maxSide,
      'quality': quality,
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
  }) async {
    await _channel.invokeMethod<void>('exportFullRes', {
      'assetId': assetId,
      'values': values,
      'quality': quality,
    });
  }
}
