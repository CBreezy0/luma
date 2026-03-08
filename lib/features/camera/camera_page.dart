import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'camera_models.dart';
import 'camera_provider.dart';
import 'camera_ui.dart';
import '../editor/editor_navigation.dart';
import 'camera_focus_mapping.dart';
import 'look_registry.dart';

class CameraPage extends ConsumerStatefulWidget {
  const CameraPage({super.key});

  @override
  ConsumerState<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends ConsumerState<CameraPage>
    with WidgetsBindingObserver {
  static const Duration _captureFlashVisibleDuration = Duration(
    milliseconds: 60,
  );
  static const Duration _captureFlashAnimationDuration = Duration(
    milliseconds: 60,
  );
  static const Duration _focusIndicatorVisibleDuration = Duration(seconds: 1);
  static const Duration _focusIndicatorFadeDuration = Duration(
    milliseconds: 180,
  );
  static const double _lookViewportFraction = 0.35;
  late final PageController _lookController;
  bool _showCaptureFlash = false;
  bool _bootstrapped = false;
  bool _openingEditor = false;
  bool _shutterLocked = false;
  Offset? _focusIndicatorPosition;
  bool _showFocusIndicator = false;
  Timer? _focusIndicatorTimer;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _lookController = PageController(
      initialPage: lumaSimulationIndexById(kDefaultSimulationId),
      viewportFraction: _lookViewportFraction,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_bootstrap());
    });
  }

  Future<void> _bootstrap() async {
    if (_bootstrapped || defaultTargetPlatform != TargetPlatform.iOS) return;
    _bootstrapped = true;
    final controller = ref.read(cameraUiControllerProvider.notifier);
    await controller.initializeCamera();
    if (!mounted) return;
    final initState = ref.read(cameraUiControllerProvider);
    if (!initState.isReady) return;
    await controller.startCamera();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (defaultTargetPlatform != TargetPlatform.iOS) return;
    final controller = ref.read(cameraUiControllerProvider.notifier);
    if (state == AppLifecycleState.resumed) {
      unawaited(controller.startCamera());
      return;
    }
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      unawaited(controller.stopCamera());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _focusIndicatorTimer?.cancel();
    _lookController.dispose();
    final controller = ref.read(cameraUiControllerProvider.notifier);
    unawaited(controller.stopCamera());
    unawaited(controller.disposeCamera());
    super.dispose();
  }

  Future<void> _capture() async {
    final state = ref.read(cameraUiControllerProvider);
    if (state.isInitializing ||
        !state.isReady ||
        state.isCapturing ||
        _shutterLocked ||
        _openingEditor) {
      return;
    }

    if (mounted) {
      setState(() {
        _shutterLocked = true;
      });
    } else {
      _shutterLocked = true;
    }
    final controller = ref.read(cameraUiControllerProvider.notifier);
    unawaited(_playShutterFlash());
    try {
      final result = await controller.capturePhoto();
      if (result != null) {
        ref.read(capturedPhotosProvider.notifier).update((captures) {
          return List<CameraCaptureResult>.unmodifiable([...captures, result]);
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _shutterLocked = false;
        });
      } else {
        _shutterLocked = false;
      }
    }
  }

  Future<void> _playShutterFlash() async {
    if (!mounted) return;
    setState(() => _showCaptureFlash = true);
    await Future<void>.delayed(_captureFlashVisibleDuration);
    if (!mounted) return;
    setState(() => _showCaptureFlash = false);
  }

  Future<void> _openEditorFromCapture(CameraCaptureResult result) async {
    if (!mounted || _openingEditor) return;
    final hasLocalIdentifier =
        result.localIdentifier != null && result.localIdentifier!.isNotEmpty;
    final hasFilePath = result.filePath != null && result.filePath!.isNotEmpty;
    if (!hasLocalIdentifier && !hasFilePath) return;

    setState(() {
      _openingEditor = true;
    });
    final controller = ref.read(cameraUiControllerProvider.notifier);
    try {
      await controller.stopCamera();
      if (!mounted) return;

      final assetId = hasLocalIdentifier
          ? result.localIdentifier!
          : 'camera:${result.capturedAtMs}';
      await Navigator.of(context).push(
        buildEditorRoute(
          assetId: assetId,
          sourceFilePath: hasFilePath ? result.filePath : null,
          initialSimulationId: result.simulationId,
          initialLookStrength: result.lookStrength,
          capturedAtMs: result.capturedAtMs,
        ),
      );
      if (!mounted) return;
      await controller.startCamera();
      await controller.refreshLatestThumbnail();
    } finally {
      if (mounted) {
        setState(() {
          _openingEditor = false;
        });
      } else {
        _openingEditor = false;
      }
    }
  }

  Future<void> _importFromLibrary() async {
    if (_openingEditor) return;
    final selected = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      requestFullMetadata: false,
    );
    if (selected == null) return;
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final state = ref.read(cameraUiControllerProvider);
    final result = CameraCaptureResult(
      filePath: selected.path,
      simulationId: state.selectedSimulationId,
      lookStrength: state.lookStrength,
      mimeType: _mimeTypeForPath(selected.path),
      width: null,
      height: null,
      capturedAtMs: nowMs,
      captureFormat: CameraCaptureFormat.jpg,
    );
    ref.read(capturedPhotosProvider.notifier).update((captures) {
      return List<CameraCaptureResult>.unmodifiable([...captures, result]);
    });
  }

  String _mimeTypeForPath(String path) {
    final extension = path.split('.').last.toLowerCase();
    return switch (extension) {
      'png' => 'image/png',
      'heic' => 'image/heic',
      'heif' => 'image/heif',
      'dng' => 'image/x-adobe-dng',
      _ => 'image/jpeg',
    };
  }

  Future<void> _handlePreviewTap(Offset localPosition, Size previewSize) async {
    final state = ref.read(cameraUiControllerProvider);
    if (state.isInitializing || !state.isReady || _openingEditor) return;

    final normalized = normalizePreviewTapPosition(
      localPosition: localPosition,
      previewSize: previewSize,
    );
    final controller = ref.read(cameraUiControllerProvider.notifier);
    await controller.setFocusPoint(
      x: normalized.dx,
      y: normalized.dy,
      lock: false,
    );
    if (!mounted) return;
    _showTransientFocusIndicator(normalized);
  }

  Future<void> _handlePreviewLongPress(
    Offset localPosition,
    Size previewSize,
  ) async {
    final state = ref.read(cameraUiControllerProvider);
    if (state.isInitializing || !state.isReady || _openingEditor) return;

    final normalized = normalizePreviewTapPosition(
      localPosition: localPosition,
      previewSize: previewSize,
    );
    final controller = ref.read(cameraUiControllerProvider.notifier);
    await controller.setFocusPoint(
      x: normalized.dx,
      y: normalized.dy,
      lock: true,
    );
    if (!mounted) return;
    _focusIndicatorTimer?.cancel();
    setState(() {
      _showFocusIndicator = false;
    });
  }

  void _showTransientFocusIndicator(Offset normalized) {
    _focusIndicatorTimer?.cancel();
    setState(() {
      _focusIndicatorPosition = normalized;
      _showFocusIndicator = true;
    });
    _focusIndicatorTimer = Timer(_focusIndicatorVisibleDuration, () {
      if (!mounted) return;
      setState(() {
        _showFocusIndicator = false;
      });
    });
  }

  String _flashLabel(CameraFlashMode mode) {
    switch (mode) {
      case CameraFlashMode.auto:
        return 'AUTO';
      case CameraFlashMode.off:
        return 'OFF';
      case CameraFlashMode.on:
        return 'ON';
    }
  }

  void _toggleCaptureFormat(
    CameraUiState state,
    CameraUiController controller,
  ) {
    final target = state.captureFormat == CameraCaptureFormat.jpg
        ? CameraCaptureFormat.raw
        : CameraCaptureFormat.jpg;
    unawaited(controller.setCaptureFormat(target));
  }

  void _handleBackPressed() {
    if (!mounted) return;
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (defaultTargetPlatform != TargetPlatform.iOS) {
      return Scaffold(
        backgroundColor: const Color(0xFF101010),
        appBar: AppBar(
          backgroundColor: const Color(0xFF101010),
          foregroundColor: Colors.white,
          elevation: 0,
          title: const Text('Camera'),
        ),
        body: const Center(
          child: Text(
            'Camera is available on iOS.',
            style: TextStyle(color: Colors.white70),
          ),
        ),
      );
    }

    final state = ref.watch(cameraUiControllerProvider);
    final controller = ref.read(cameraUiControllerProvider.notifier);
    final capturedPhotos = ref.watch(capturedPhotosProvider);
    final selectedIndex = lumaSimulationIndexById(state.selectedSimulationId);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          _CameraInteractivePreview(
            onTapAt: _handlePreviewTap,
            onLongPressAt: _handlePreviewLongPress,
          ),
          const _CameraGradientOverlay(),
          CameraHistogramOverlay(bins: state.histogram),
          _CameraFocusIndicator(
            normalizedPosition: _focusIndicatorPosition,
            visible: _showFocusIndicator,
            isLocked: state.isAeAfLocked,
          ),
          if (_showCaptureFlash)
            IgnorePointer(
              child: AnimatedOpacity(
                opacity: _showCaptureFlash ? 0.16 : 0,
                duration: _captureFlashAnimationDuration,
                child: const ColoredBox(color: Colors.white),
              ),
            ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 18),
              child: Column(
                children: [
                  CameraTopBar(onBack: _handleBackPressed, formatLabel: 'HEIC'),
                  const SizedBox(height: 8),
                  _CameraLockBanner(isLocked: state.isAeAfLocked),
                  const Spacer(),
                  if (state.errorMessage != null) ...[
                    _CameraErrorPill(message: state.errorMessage!),
                    const SizedBox(height: 12),
                  ],
                  CameraLookSelector(
                    simulations: kLumaFilmSimulations,
                    selectedIndex: selectedIndex,
                    controller: _lookController,
                    onPageChanged: (index) {
                      HapticFeedback.selectionClick();
                      unawaited(
                        controller.setSimulation(
                          kLumaFilmSimulations[index].id,
                        ),
                      );
                    },
                  ),
                  CameraLookStrengthSlider(
                    value: state.lookStrength,
                    enabled:
                        state.isReady &&
                        !state.isInitializing &&
                        !state.isCapturing &&
                        !_openingEditor,
                    onChanged: (strength) {
                      unawaited(controller.setLookStrength(strength));
                    },
                  ),
                  CameraExposureSlider(
                    value: state.exposureBias,
                    enabled:
                        state.isReady &&
                        !state.isInitializing &&
                        !state.isCapturing &&
                        !_openingEditor,
                    onChanged: (bias) {
                      unawaited(controller.setExposureBias(bias));
                    },
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CameraLibraryButton(
                            onTap: _importFromLibrary,
                            thumbnailBytes: state.latestThumbnail,
                            captureCount: capturedPhotos.length,
                            enabled:
                                state.isReady &&
                                !state.isInitializing &&
                                !state.isCapturing &&
                                !_openingEditor,
                          ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: _importFromLibrary,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.38),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.18),
                                ),
                              ),
                              child: Text(
                                'Import Photo',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ),
                          ),
                          if (capturedPhotos.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: () => unawaited(
                                _openEditorFromCapture(capturedPhotos.last),
                              ),
                              child: CameraLabelPill(
                                label: 'LAST ${capturedPhotos.length}',
                              ),
                            ),
                          ],
                        ],
                      ),
                      const Spacer(),
                      CameraShutterButton(
                        enabled:
                            state.isReady &&
                            !state.isInitializing &&
                            !state.isCapturing &&
                            !_shutterLocked &&
                            !_openingEditor,
                        onPressed: _capture,
                      ),
                      const Spacer(),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CameraIconControl(
                            label: state.captureFormat.label,
                            enabled: state.supportsRawCapture,
                            onTap: state.supportsRawCapture
                                ? () => _toggleCaptureFormat(state, controller)
                                : null,
                          ),
                          const SizedBox(height: 8),
                          CameraIconControl(
                            label: _flashLabel(state.flashMode),
                            onTap: () => unawaited(controller.cycleFlashMode()),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (state.isInitializing)
            Center(
              child: Container(
                width: 40,
                height: 40,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.35),
                  shape: BoxShape.circle,
                ),
                child: const CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
                ),
              ),
            ),
          if (!state.isInitializing && !state.isReady)
            _CameraUnavailableOverlay(
              message: state.errorMessage ?? 'Camera unavailable.',
            ),
        ],
      ),
    );
  }
}

class _CameraGradientOverlay extends StatelessWidget {
  const _CameraGradientOverlay();

  @override
  Widget build(BuildContext context) {
    return const IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0x66000000),
              Color(0x00000000),
              Color(0x22000000),
              Color(0x77000000),
            ],
            stops: [0.0, 0.35, 0.62, 1.0],
          ),
        ),
      ),
    );
  }
}

class _CameraInteractivePreview extends StatelessWidget {
  final Future<void> Function(Offset localPosition, Size previewSize) onTapAt;
  final Future<void> Function(Offset localPosition, Size previewSize)
  onLongPressAt;

  const _CameraInteractivePreview({
    required this.onTapAt,
    required this.onLongPressAt,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final previewSize = Size(constraints.maxWidth, constraints.maxHeight);
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapUp: (details) {
            unawaited(onTapAt(details.localPosition, previewSize));
          },
          onLongPressStart: (details) {
            unawaited(onLongPressAt(details.localPosition, previewSize));
          },
          child: const CameraPreviewSurface(),
        );
      },
    );
  }
}

class _CameraFocusIndicator extends StatelessWidget {
  final Offset? normalizedPosition;
  final bool visible;
  final bool isLocked;

  const _CameraFocusIndicator({
    required this.normalizedPosition,
    required this.visible,
    required this.isLocked,
  });

  @override
  Widget build(BuildContext context) {
    final point = normalizedPosition;
    if (point == null) return const SizedBox.shrink();
    return IgnorePointer(
      child: AnimatedOpacity(
        duration: _CameraPageState._focusIndicatorFadeDuration,
        opacity: visible ? 1.0 : 0.0,
        child: Align(
          alignment: Alignment((point.dx * 2) - 1, (point.dy * 2) - 1),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.9),
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              if (isLocked) ...[
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.38),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.18),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    'AE/AF LOCK',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CameraErrorPill extends StatelessWidget {
  final String message;

  const _CameraErrorPill({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 11,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class _CameraLockBanner extends StatelessWidget {
  final bool isLocked;

  const _CameraLockBanner({required this.isLocked});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 24,
      child: AnimatedOpacity(
        opacity: isLocked ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 180),
        child: IgnorePointer(
          child: Center(child: CameraLabelPill(label: 'AE/AF LOCK')),
        ),
      ),
    );
  }
}

class _CameraUnavailableOverlay extends StatelessWidget {
  final String message;

  const _CameraUnavailableOverlay({required this.message});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: ColoredBox(
        color: Colors.black.withValues(alpha: 0.68),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'CAMERA UNAVAILABLE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
