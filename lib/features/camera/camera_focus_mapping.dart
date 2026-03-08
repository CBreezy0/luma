import 'dart:ui';

Offset normalizePreviewTapPosition({
  required Offset localPosition,
  required Size previewSize,
}) {
  if (previewSize.width <= 0 || previewSize.height <= 0) {
    return const Offset(0.5, 0.5);
  }
  final x = (localPosition.dx / previewSize.width).clamp(0.0, 1.0).toDouble();
  final y = (localPosition.dy / previewSize.height).clamp(0.0, 1.0).toDouble();
  return Offset(x, y);
}
