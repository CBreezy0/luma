import 'package:flutter/services.dart';

class SampleImage {
  final String id;
  final String title;
  final String assetPath;

  const SampleImage({
    required this.id,
    required this.title,
    required this.assetPath,
  });
}

class SampleImages {
  static const List<SampleImage> items = [
    SampleImage(
      id: 'sample:coastal_light',
      title: 'Coastal Light',
      assetPath: 'assets/samples/sample_01.png',
    ),
    SampleImage(
      id: 'sample:midnight_blue',
      title: 'Midnight Blue',
      assetPath: 'assets/samples/sample_02.png',
    ),
  ];

  static SampleImage? byId(String id) {
    for (final item in items) {
      if (item.id == id) return item;
    }
    return null;
  }

  static Future<Uint8List> loadBytes(String assetPath) async {
    final data = await rootBundle.load(assetPath);
    return data.buffer.asUint8List();
  }
}
