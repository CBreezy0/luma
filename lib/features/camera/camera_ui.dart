import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'camera_models.dart';

class CameraPreviewSurface extends StatelessWidget {
  const CameraPreviewSurface({super.key});

  @override
  Widget build(BuildContext context) {
    if (defaultTargetPlatform != TargetPlatform.iOS) {
      return const ColoredBox(color: Colors.black);
    }
    return const UiKitView(
      viewType: 'luma/camera_preview',
      creationParamsCodec: StandardMessageCodec(),
    );
  }
}

class CameraTopBar extends StatelessWidget {
  final VoidCallback onBack;
  final String formatLabel;
  final Widget? trailing;

  const CameraTopBar({
    super.key,
    required this.onBack,
    required this.formatLabel,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _IconCircleButton(
          icon: Icons.arrow_back_ios_new_rounded,
          onTap: onBack,
        ),
        const Spacer(),
        CameraLabelPill(label: formatLabel),
        const Spacer(),
        trailing ?? const SizedBox(width: 34, height: 34),
      ],
    );
  }
}

class CameraLibraryButton extends StatelessWidget {
  final VoidCallback? onTap;
  final Uint8List? thumbnailBytes;
  final int captureCount;
  final bool enabled;

  const CameraLibraryButton({
    super.key,
    required this.onTap,
    this.thumbnailBytes,
    this.captureCount = 0,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 120),
        opacity: enabled ? 1.0 : 0.45,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF242424),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.16),
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: thumbnailBytes == null
                      ? Icon(
                          Icons.photo_library_outlined,
                          size: 18,
                          color: Colors.white.withValues(alpha: 0.74),
                        )
                      : Image.memory(thumbnailBytes!, fit: BoxFit.cover),
                ),
              ),
              if (captureCount > 0)
                Positioned(
                  right: -4,
                  top: -4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: const Color(0xFF171717)),
                    ),
                    child: Text(
                      '$captureCount',
                      style: const TextStyle(
                        color: Color(0xFF171717),
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class CameraLabelPill extends StatelessWidget {
  final String label;

  const CameraLabelPill({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.32),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          color: Color(0xFFF2F2F2),
          fontSize: 10,
          letterSpacing: 1.0,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class CameraShutterButton extends StatelessWidget {
  final bool enabled;
  final VoidCallback onPressed;

  const CameraShutterButton({
    super.key,
    required this.enabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onPressed : null,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 120),
        opacity: enabled ? 1.0 : 0.45,
        child: Container(
          width: 86,
          height: 86,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.9),
              width: 3,
            ),
          ),
          alignment: Alignment.center,
          child: Container(
            width: 70,
            height: 70,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

class CameraIconControl extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool enabled;

  const CameraIconControl({
    super.key,
    required this.label,
    required this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 140),
        opacity: enabled ? 1 : 0.45,
        child: Container(
          constraints: const BoxConstraints(minWidth: 44),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.7,
            ),
          ),
        ),
      ),
    );
  }
}

class CameraLookSelector extends StatelessWidget {
  final List<LumaFilmSimulation> simulations;
  final int selectedIndex;
  final PageController controller;
  final ValueChanged<int> onPageChanged;

  const CameraLookSelector({
    super.key,
    required this.simulations,
    required this.selectedIndex,
    required this.controller,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: PageView.builder(
        controller: controller,
        itemCount: simulations.length,
        onPageChanged: onPageChanged,
        itemBuilder: (context, index) {
          final look = simulations[index];
          final active = index == selectedIndex;
          return Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              curve: Curves.easeOut,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                color: active
                    ? Colors.white.withValues(alpha: 0.16)
                    : Colors.transparent,
              ),
              child: Text(
                look.name.toUpperCase(),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: active ? 0.95 : 0.5),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.0,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class CameraLookStrengthSlider extends StatelessWidget {
  final double value;
  final bool enabled;
  final ValueChanged<double> onChanged;

  const CameraLookStrengthSlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final safeValue = value
        .clamp(kCameraLookStrengthMin, kCameraLookStrengthMax)
        .toDouble();
    final percentage = (safeValue * 100).round();

    return SizedBox(
      width: 220,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'LOOK $percentage%',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.9,
            ),
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 1.5,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
              overlayShape: SliderComponentShape.noOverlay,
              activeTrackColor: Colors.white.withValues(alpha: 0.7),
              inactiveTrackColor: Colors.white.withValues(alpha: 0.2),
              thumbColor: Colors.white.withValues(alpha: 0.9),
              disabledActiveTrackColor: Colors.white.withValues(alpha: 0.32),
              disabledInactiveTrackColor: Colors.white.withValues(alpha: 0.14),
              disabledThumbColor: Colors.white.withValues(alpha: 0.42),
            ),
            child: Slider(
              min: kCameraLookStrengthMin,
              max: kCameraLookStrengthMax,
              value: safeValue,
              onChanged: enabled ? onChanged : null,
            ),
          ),
        ],
      ),
    );
  }
}

class CameraExposureSlider extends StatelessWidget {
  final double value;
  final bool enabled;
  final ValueChanged<double> onChanged;

  const CameraExposureSlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final safeValue = value
        .clamp(kCameraExposureBiasMin, kCameraExposureBiasMax)
        .toDouble();
    final valueText = safeValue >= 0
        ? '+${safeValue.toStringAsFixed(1)}'
        : safeValue.toStringAsFixed(1);

    return SizedBox(
      width: 220,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'EV $valueText',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.9,
            ),
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 1.5,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
              overlayShape: SliderComponentShape.noOverlay,
              activeTrackColor: Colors.white.withValues(alpha: 0.7),
              inactiveTrackColor: Colors.white.withValues(alpha: 0.2),
              thumbColor: Colors.white.withValues(alpha: 0.9),
              disabledActiveTrackColor: Colors.white.withValues(alpha: 0.32),
              disabledInactiveTrackColor: Colors.white.withValues(alpha: 0.14),
              disabledThumbColor: Colors.white.withValues(alpha: 0.42),
            ),
            child: Slider(
              min: kCameraExposureBiasMin,
              max: kCameraExposureBiasMax,
              value: safeValue,
              onChanged: enabled ? onChanged : null,
            ),
          ),
        ],
      ),
    );
  }
}

class CameraHistogramOverlay extends StatelessWidget {
  final List<double> bins;

  const CameraHistogramOverlay({super.key, required this.bins});

  @override
  Widget build(BuildContext context) {
    if (bins.isEmpty) return const SizedBox.shrink();
    return IgnorePointer(
      child: Align(
        alignment: Alignment.topRight,
        child: Padding(
          padding: const EdgeInsets.only(top: 64, right: 14),
          child: Container(
            width: 120,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            clipBehavior: Clip.antiAlias,
            child: CustomPaint(
              painter: _HistogramPainter(bins: bins),
              size: const Size(120, 40),
            ),
          ),
        ),
      ),
    );
  }
}

class _HistogramPainter extends CustomPainter {
  final List<double> bins;

  const _HistogramPainter({required this.bins});

  @override
  void paint(Canvas canvas, Size size) {
    if (bins.isEmpty || size.isEmpty) return;
    final barSpace = size.width / bins.length;
    final strokeWidth = (barSpace * 0.65).clamp(0.6, 1.2);
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.24)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;

    for (var i = 0; i < bins.length; i++) {
      final value = bins[i].clamp(0.0, 1.0);
      final x = (i + 0.5) * barSpace;
      final height = value * size.height;
      canvas.drawLine(
        Offset(x, size.height),
        Offset(x, size.height - height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _HistogramPainter oldDelegate) {
    if (identical(oldDelegate.bins, bins)) return false;
    if (oldDelegate.bins.length != bins.length) return true;
    for (var i = 0; i < bins.length; i++) {
      if ((oldDelegate.bins[i] - bins[i]).abs() > 0.01) return true;
    }
    return false;
  }
}

class _IconCircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _IconCircleButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black.withValues(alpha: 0.35),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: Icon(icon, color: Colors.white.withValues(alpha: 0.9), size: 15),
      ),
    );
  }
}
