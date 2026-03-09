import 'package:flutter/services.dart';

class NativeShareBridge {
  static const MethodChannel _channel = MethodChannel('luma/native_share');

  static Future<void> shareFiles(List<String> paths, {String? subject}) async {
    final sanitized = paths.where((path) => path.trim().isNotEmpty).toList();
    if (sanitized.isEmpty) {
      throw ArgumentError('No files available to share.');
    }
    await _channel.invokeMethod<void>('shareFiles', {
      'paths': sanitized,
      if (subject != null && subject.trim().isNotEmpty) 'subject': subject,
    });
  }

  static Future<void> saveFilesToPhotos(List<String> paths) async {
    final sanitized = paths.where((path) => path.trim().isNotEmpty).toList();
    if (sanitized.isEmpty) {
      throw ArgumentError('No files available to save.');
    }
    await _channel.invokeMethod<void>('saveFilesToPhotos', {
      'paths': sanitized,
    });
  }
}
