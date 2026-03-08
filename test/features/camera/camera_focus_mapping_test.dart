import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:luma/features/camera/camera_focus_mapping.dart';

void main() {
  test('normalizePreviewTapPosition maps coordinates into 0..1 range', () {
    final size = const Size(400, 800);

    final center = normalizePreviewTapPosition(
      localPosition: const Offset(200, 400),
      previewSize: size,
    );
    expect(center.dx, closeTo(0.5, 0.0001));
    expect(center.dy, closeTo(0.5, 0.0001));

    final clamped = normalizePreviewTapPosition(
      localPosition: const Offset(-20, 920),
      previewSize: size,
    );
    expect(clamped.dx, 0.0);
    expect(clamped.dy, 1.0);
  });
}
