import 'package:flutter_test/flutter_test.dart';
import 'package:luma/features/camera/camera_controller.dart';

void main() {
  test('parseCameraHistogramPayload parses and clamps bins', () {
    final parsed = parseCameraHistogramPayload({
      'bins': [0, 0.5, 1.2, -0.3, '0.25', null, 'bad'],
    });

    expect(parsed, <double>[0.0, 0.5, 1.0, 0.0, 0.25]);
  });
}
