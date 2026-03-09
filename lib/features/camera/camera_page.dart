import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'camera_models.dart';
import 'camera_provider.dart';
import 'camera_ui.dart';
import 'luma_gallery_page.dart';
import '../library/library_provider.dart';
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
  static const bool _enableShutterSound = false;
  static const Duration _captureFlashVisibleDuration = Duration(
    milliseconds: 60,
  );
  static const Duration _captureFlashAnimationDuration = Duration(
    milliseconds: 60,
  );
  static const Duration _shutterPulseDuration = Duration(milliseconds: 140);
  static const Duration _reticleVisibleDuration = Duration(seconds: 2);
  static const Duration _focusIndicatorFadeDuration = Duration(
    milliseconds: 180,
  );
  static const double _reticleDragSensitivity = 170;
  static const List<double> _quickZoomLevels = <double>[0.5, 1.0, 3.0, 5.0];
  static const double _lookViewportFraction = 0.35;
  late final PageController _lookController;
  bool _showCaptureFlash = false;
  bool _showShutterPulse = false;
  bool _bootstrapped = false;
  bool _openingEditor = false;
  bool _shutterLocked = false;
  Offset? _reticlePosition;
  bool _reticleVisible = false;
  int _reticleAnimationNonce = 0;
  bool _isDraggingReticleExposure = false;
  bool _showManualFocusSlider = false;
  double _reticleDragStartDy = 0;
  double _reticleDragStartBias = 0;
  Timer? _reticleVisibilityTimer;
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
    _reticleVisibilityTimer?.cancel();
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
    try {
      final result = await controller.capturePhoto();
      if (result != null) {
        await ref.read(lumaLibraryProvider.notifier).saveCapturedPhoto(result);
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

  Future<void> _playCaptureFeedback() async {
    if (!mounted) return;
    setState(() {
      _showShutterPulse = true;
    });
    unawaited(HapticFeedback.lightImpact());
    if (_enableShutterSound) {
      unawaited(SystemSound.play(SystemSoundType.click));
    }
    unawaited(_playShutterFlash());
    await Future<void>.delayed(_shutterPulseDuration);
    if (!mounted) return;
    setState(() {
      _showShutterPulse = false;
    });
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
    List<XFile> selected = const <XFile>[];
    try {
      selected = await _imagePicker.pickMultiImage(requestFullMetadata: false);
    } catch (_) {
      final fallback = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        requestFullMetadata: false,
      );
      if (fallback != null) {
        selected = <XFile>[fallback];
      }
    }
    if (selected.isEmpty) return;

    final paths = selected
        .map((item) => item.path)
        .where((path) => path.isNotEmpty)
        .toList(growable: false);
    if (paths.isEmpty) return;

    await ref.read(lumaLibraryProvider.notifier).importPhotoPaths(paths);
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final state = ref.read(cameraUiControllerProvider);
    ref.read(capturedPhotosProvider.notifier).update((captures) {
      final importedResults = <CameraCaptureResult>[];
      for (var i = 0; i < paths.length; i += 1) {
        final path = paths[i];
        importedResults.add(
          CameraCaptureResult(
            filePath: path,
            simulationId: state.selectedSimulationId,
            lookStrength: state.lookStrength,
            mimeType: _mimeTypeForPath(path),
            width: null,
            height: null,
            capturedAtMs: nowMs + i,
            captureFormat: CameraCaptureFormat.jpg,
          ),
        );
      }
      return List<CameraCaptureResult>.unmodifiable([
        ...captures,
        ...importedResults,
      ]);
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
    await controller.focusWithAutoExposure(x: normalized.dx, y: normalized.dy);
    if (!mounted) return;
    setState(() {
      _showManualFocusSlider = false;
    });
    _showReticle(normalized);
  }

  void _showReticle(Offset normalized) {
    _reticleVisibilityTimer?.cancel();
    setState(() {
      _reticlePosition = normalized;
      _reticleVisible = true;
      _reticleAnimationNonce += 1;
    });
    _scheduleReticleAutoHide();
  }

  void _scheduleReticleAutoHide() {
    _reticleVisibilityTimer?.cancel();
    if (_isDraggingReticleExposure) return;
    if (_showManualFocusSlider) return;
    final state = ref.read(cameraUiControllerProvider);
    if (state.isAeAfLocked) return;
    _reticleVisibilityTimer = Timer(_reticleVisibleDuration, () {
      if (!mounted) return;
      setState(() {
        _reticleVisible = false;
      });
    });
  }

  Future<void> _toggleReticleLock() async {
    final point = _reticlePosition;
    if (point == null) return;
    final state = ref.read(cameraUiControllerProvider);
    if (state.isInitializing || !state.isReady || _openingEditor) return;
    final controller = ref.read(cameraUiControllerProvider.notifier);
    await controller.toggleAeAfLock(x: point.dx, y: point.dy);
    if (!mounted) return;
    setState(() {
      _reticleVisible = true;
      _showManualFocusSlider = state.supportsManualFocus;
    });
    _scheduleReticleAutoHide();
  }

  void _toggleManualFocusSlider() {
    final state = ref.read(cameraUiControllerProvider);
    if (!state.supportsManualFocus) return;
    setState(() {
      _showManualFocusSlider = !_showManualFocusSlider;
      _reticlePosition ??= const Offset(0.5, 0.5);
      _reticleVisible = true;
      _reticleAnimationNonce += 1;
    });
    _scheduleReticleAutoHide();
  }

  void _handleReticleExposureDragStart(DragStartDetails details) {
    _reticleVisibilityTimer?.cancel();
    final state = ref.read(cameraUiControllerProvider);
    _reticleDragStartDy = details.globalPosition.dy;
    _reticleDragStartBias = state.exposureBias;
    setState(() {
      _isDraggingReticleExposure = true;
      _reticleVisible = true;
    });
  }

  void _handleReticleExposureDragUpdate(DragUpdateDetails details) {
    if (!_isDraggingReticleExposure) return;
    final deltaY = _reticleDragStartDy - details.globalPosition.dy;
    final deltaBias =
        (deltaY / _reticleDragSensitivity) *
        (kCameraExposureBiasMax - kCameraExposureBiasMin);
    final targetBias = (_reticleDragStartBias + deltaBias).clamp(
      kCameraExposureBiasMin,
      kCameraExposureBiasMax,
    );
    final controller = ref.read(cameraUiControllerProvider.notifier);
    unawaited(controller.setExposureBias(targetBias.toDouble()));
  }

  void _handleReticleExposureDragEnd([DragEndDetails? _]) {
    if (!_isDraggingReticleExposure) return;
    setState(() {
      _isDraggingReticleExposure = false;
    });
    _scheduleReticleAutoHide();
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

  bool _canOpenCaptureFormatPicker(CameraUiState state) {
    return state.availableCaptureFormats.length > 1 &&
        state.isReady &&
        !state.isInitializing &&
        !state.isCapturing &&
        !_openingEditor;
  }

  bool _canOpenResolutionPicker(CameraUiState state) {
    return state.availablePhotoResolutions.length > 1 &&
        state.isReady &&
        !state.isInitializing &&
        !state.isCapturing &&
        !_openingEditor;
  }

  Future<void> _openCaptureFormatPicker(
    CameraUiState state,
    CameraUiController controller,
  ) async {
    if (!_canOpenCaptureFormatPicker(state)) return;
    final selected = await _showCameraSelectionSheet<CameraCaptureFormat>(
      title: 'Capture Format',
      options: state.availableCaptureFormats,
      selected: state.captureFormat,
      labelFor: (format) => format.label,
      subtitleFor: (format) {
        switch (format) {
          case CameraCaptureFormat.heic:
            return 'Smaller files with high efficiency compression.';
          case CameraCaptureFormat.jpg:
            return 'Most compatible processed capture output.';
          case CameraCaptureFormat.raw:
            return 'Single-frame Bayer RAW capture at 12 MP.';
          case CameraCaptureFormat.proRaw:
            return 'Apple ProRAW capture at 48 MP on supported devices.';
          case CameraCaptureFormat.rawPlusHeic:
            return 'RAW negative with a processed HEIC companion.';
          case CameraCaptureFormat.rawPlusJpg:
            return 'RAW negative with a processed JPEG companion.';
        }
      },
    );
    if (!mounted || selected == null || selected == state.captureFormat) return;
    HapticFeedback.selectionClick();
    await controller.setCaptureFormat(selected);
  }

  Future<void> _openResolutionPicker(
    CameraUiState state,
    CameraUiController controller,
  ) async {
    if (!_canOpenResolutionPicker(state)) return;
    final currentSelection =
        state.selectedPhotoResolution ?? state.availablePhotoResolutions.first;
    final selected = await _showCameraSelectionSheet<CameraPhotoResolution>(
      title: 'Photo Resolution',
      options: state.availablePhotoResolutions,
      selected: currentSelection,
      labelFor: (resolution) => resolution.label,
      subtitleFor: (resolution) => '${resolution.width} x ${resolution.height}',
    );
    if (!mounted ||
        selected == null ||
        selected == state.selectedPhotoResolution) {
      return;
    }
    HapticFeedback.selectionClick();
    await controller.setPhotoResolution(selected);
  }

  Future<T?> _showCameraSelectionSheet<T>({
    required String title,
    required List<T> options,
    required T selected,
    required String Function(T value) labelFor,
    String? Function(T value)? subtitleFor,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _CameraSelectionSheet<T>(
          title: title,
          options: options,
          selected: selected,
          labelFor: labelFor,
          subtitleFor: subtitleFor,
        );
      },
    );
  }

  List<double> _availableQuickZoomLevels(CameraUiState state) {
    final min = state.minZoomFactor;
    final max = state.maxZoomFactor;
    final levels = _quickZoomLevels
        .where((level) {
          return level >= (min - 0.001) && level <= (max + 0.001);
        })
        .toList(growable: false);
    if (levels.isEmpty) {
      final fallback = state.zoomFactor.clamp(min, max).toDouble();
      return <double>[fallback];
    }
    return levels;
  }

  Future<void> _openGallery() async {
    if (_openingEditor) return;
    final controller = ref.read(cameraUiControllerProvider.notifier);
    await controller.stopCamera();
    if (!mounted) return;
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const LumaGalleryPage()));
    if (!mounted) return;
    await controller.startCamera();
    await controller.refreshLatestThumbnail();
  }

  void _handleBackPressed() {
    if (!mounted) return;
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
      return;
    }
    unawaited(_openGallery());
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

    ref.listen<CameraUiState>(cameraUiControllerProvider, (previous, next) {
      if ((next.captureFeedbackVersion -
              (previous?.captureFeedbackVersion ?? 0)) >
          0) {
        unawaited(_playCaptureFeedback());
      }
    });

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          _CameraInteractivePreview(onTapAt: _handlePreviewTap),
          const _CameraGradientOverlay(),
          CameraHistogramOverlay(bins: state.histogram),
          _CameraFocusReticle(
            normalizedPosition: _reticlePosition,
            visible: _reticleVisible,
            isLocked: state.isAeAfLocked,
            exposureBias: state.exposureBias,
            showManualFocusRail:
                _showManualFocusSlider &&
                state.supportsManualFocus &&
                state.isReady &&
                !state.isInitializing,
            focusDistance: state.focusDistance,
            animationNonce: _reticleAnimationNonce,
            onLongPress: _toggleReticleLock,
            onVerticalDragStart: _handleReticleExposureDragStart,
            onVerticalDragUpdate: _handleReticleExposureDragUpdate,
            onVerticalDragEnd: _handleReticleExposureDragEnd,
            onManualFocusChanged: (value) {
              unawaited(controller.setManualFocusDistance(value));
            },
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
                  CameraTopBar(
                    onBack: _handleBackPressed,
                    formatLabel: state.captureFormat.label,
                    onFormatTap: _canOpenCaptureFormatPicker(state)
                        ? () => unawaited(
                            _openCaptureFormatPicker(state, controller),
                          )
                        : null,
                  ),
                  const SizedBox(height: 6),
                  CameraResolutionPill(
                    label:
                        state.selectedPhotoResolution?.label ??
                        CameraPhotoResolution.megapixelLabelForValue(
                          state.megapixels,
                        ),
                    enabled: _canOpenResolutionPicker(state),
                    onTap: _canOpenResolutionPicker(state)
                        ? () => unawaited(
                            _openResolutionPicker(state, controller),
                          )
                        : null,
                  ),
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
                  const SizedBox(height: 8),
                  CameraQuickZoomSelector(
                    levels: _availableQuickZoomLevels(state),
                    currentZoom: state.zoomFactor,
                    enabled:
                        state.isReady &&
                        !state.isInitializing &&
                        !state.isCapturing &&
                        !_openingEditor,
                    onSelected: (level) {
                      HapticFeedback.selectionClick();
                      unawaited(controller.setQuickZoomLevel(level));
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
                            onTap: _openGallery,
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
                        isAnimating: _showShutterPulse,
                        onPressed: _capture,
                      ),
                      const Spacer(),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CameraIconControl(
                            label: 'FOCUS',
                            enabled:
                                state.supportsManualFocus &&
                                state.isReady &&
                                !state.isInitializing &&
                                !state.isCapturing &&
                                !_openingEditor,
                            onTap: state.supportsManualFocus
                                ? _toggleManualFocusSlider
                                : null,
                          ),
                          const SizedBox(height: 8),
                          CameraIconControl(
                            label: state.captureFormat.label,
                            enabled: _canOpenCaptureFormatPicker(state),
                            onTap: _canOpenCaptureFormatPicker(state)
                                ? () => unawaited(
                                    _openCaptureFormatPicker(state, controller),
                                  )
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

  const _CameraInteractivePreview({required this.onTapAt});

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
          child: const CameraPreviewSurface(),
        );
      },
    );
  }
}

class _CameraFocusReticle extends StatelessWidget {
  final Offset? normalizedPosition;
  final bool visible;
  final bool isLocked;
  final double exposureBias;
  final bool showManualFocusRail;
  final double focusDistance;
  final int animationNonce;
  final VoidCallback onLongPress;
  final GestureDragStartCallback onVerticalDragStart;
  final GestureDragUpdateCallback onVerticalDragUpdate;
  final GestureDragEndCallback onVerticalDragEnd;
  final ValueChanged<double> onManualFocusChanged;

  const _CameraFocusReticle({
    required this.normalizedPosition,
    required this.visible,
    required this.isLocked,
    required this.exposureBias,
    required this.showManualFocusRail,
    required this.focusDistance,
    required this.animationNonce,
    required this.onLongPress,
    required this.onVerticalDragStart,
    required this.onVerticalDragUpdate,
    required this.onVerticalDragEnd,
    required this.onManualFocusChanged,
  });

  @override
  Widget build(BuildContext context) {
    final point = normalizedPosition;
    if (point == null) return const SizedBox.shrink();
    return IgnorePointer(
      ignoring: !visible,
      child: AnimatedOpacity(
        duration: _CameraPageState._focusIndicatorFadeDuration,
        opacity: visible ? 1.0 : 0.0,
        child: Align(
          alignment: Alignment((point.dx * 2) - 1, (point.dy * 2) - 1),
          child: TweenAnimationBuilder<double>(
            key: ValueKey<int>(animationNonce),
            tween: Tween<double>(begin: 1.3, end: 1.0),
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            builder: (context, scale, child) {
              return Transform.scale(scale: scale, child: child);
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onVerticalDragStart: onVerticalDragStart,
                  onVerticalDragUpdate: onVerticalDragUpdate,
                  onVerticalDragEnd: onVerticalDragEnd,
                  onLongPress: onLongPress,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _ReticleBox(isLocked: isLocked),
                      const SizedBox(width: 8),
                      _ReticleExposureRail(exposureBias: exposureBias),
                    ],
                  ),
                ),
                if (showManualFocusRail) ...[
                  const SizedBox(width: 8),
                  _ReticleManualFocusRail(
                    focusDistance: focusDistance,
                    onChanged: onManualFocusChanged,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ReticleBox extends StatelessWidget {
  final bool isLocked;

  const _ReticleBox({required this.isLocked});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 70,
      height: 70,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.92),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(10),
          color: Colors.transparent,
        ),
        child: Center(
          child: Container(
            width: isLocked ? 7 : 6,
            height: isLocked ? 7 : 6,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.94),
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}

class _ReticleExposureRail extends StatelessWidget {
  final double exposureBias;

  const _ReticleExposureRail({required this.exposureBias});

  @override
  Widget build(BuildContext context) {
    final clampedBias = exposureBias
        .clamp(kCameraExposureBiasMin, kCameraExposureBiasMax)
        .toDouble();
    final normalized =
        (clampedBias - kCameraExposureBiasMin) /
        (kCameraExposureBiasMax - kCameraExposureBiasMin);

    return Container(
      width: 36,
      height: 106,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.36),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Align(
            alignment: Alignment.center,
            child: Container(
              width: 1.2,
              color: Colors.white.withValues(alpha: 0.42),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Text(
              '+2',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.74),
                fontSize: 9,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Text(
              '-2',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.74),
                fontSize: 9,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Positioned(
            top: (1.0 - normalized) * 74 + 12,
            left: 8,
            right: 8,
            child: Container(
              height: 2,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          Align(
            alignment: Alignment.center,
            child: Container(
              margin: const EdgeInsets.only(top: 78),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                clampedBias >= 0
                    ? '+${clampedBias.toStringAsFixed(1)}'
                    : clampedBias.toStringAsFixed(1),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.92),
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReticleManualFocusRail extends StatelessWidget {
  final double focusDistance;
  final ValueChanged<double> onChanged;

  const _ReticleManualFocusRail({
    required this.focusDistance,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final safeFocus = focusDistance
        .clamp(kCameraFocusDistanceMin, kCameraFocusDistanceMax)
        .toDouble();
    const trackTop = 16.0;
    const trackBottom = 90.0;
    const trackRange = trackBottom - trackTop;
    final handleTop = trackTop + (1.0 - safeFocus) * trackRange;

    void updateFromLocalDy(double localDy) {
      final normalized = (1.0 - ((localDy - trackTop) / trackRange))
          .clamp(kCameraFocusDistanceMin, kCameraFocusDistanceMax)
          .toDouble();
      onChanged(normalized);
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (details) => updateFromLocalDy(details.localPosition.dy),
      onVerticalDragUpdate: (details) =>
          updateFromLocalDy(details.localPosition.dy),
      child: Container(
        width: 44,
        height: 106,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.42),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Align(
              alignment: Alignment.center,
              child: Container(
                width: 1.2,
                color: Colors.white.withValues(alpha: 0.44),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Text(
                '∞',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Text(
                'MACRO',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.82),
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                ),
              ),
            ),
            Positioned(
              top: handleTop,
              left: 7,
              right: 7,
              child: Container(
                height: 3,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ],
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

class _CameraSelectionSheet<T> extends StatelessWidget {
  final String title;
  final List<T> options;
  final T selected;
  final String Function(T value) labelFor;
  final String? Function(T value)? subtitleFor;

  const _CameraSelectionSheet({
    required this.title,
    required this.options,
    required this.selected,
    required this.labelFor,
    this.subtitleFor,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        decoration: BoxDecoration(
          color: const Color(0xFF141414),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              title.toUpperCase(),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.92),
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.9,
              ),
            ),
            const SizedBox(height: 12),
            for (final option in options)
              Builder(
                builder: (context) {
                  final subtitle = subtitleFor?.call(option);
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 2,
                    ),
                    title: Text(
                      labelFor(option),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: subtitle == null
                        ? null
                        : Text(
                            subtitle,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 12,
                            ),
                          ),
                    trailing: option == selected
                        ? const Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 18,
                          )
                        : null,
                    onTap: () => Navigator.of(context).pop(option),
                  );
                },
              ),
            const SizedBox(height: 10),
          ],
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
