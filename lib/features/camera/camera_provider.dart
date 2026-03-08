import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'camera_controller.dart';
import 'camera_models.dart';
import 'look_registry.dart';

final cameraBridgeProvider = Provider<CameraBridge>((ref) {
  return const MethodChannelCameraBridge();
});

final cameraUiControllerProvider =
    StateNotifierProvider.autoDispose<CameraUiController, CameraUiState>((ref) {
      final bridge = ref.watch(cameraBridgeProvider);
      final controller = CameraUiController(
        bridge: bridge,
        simulations: kLumaFilmSimulations,
      );
      ref.onDispose(controller.dispose);
      return controller;
    });

final capturedPhotosProvider =
    StateProvider.autoDispose<List<CameraCaptureResult>>((ref) {
      return const <CameraCaptureResult>[];
    });

class CameraUiController extends StateNotifier<CameraUiState> {
  final CameraBridge _bridge;
  final List<LumaFilmSimulation> _simulations;
  StreamSubscription<List<double>>? _histogramSubscription;
  double? _pendingLookStrength;
  bool _isApplyingLookStrength = false;
  double? _pendingExposureBias;
  bool _isApplyingExposureBias = false;
  bool _initialized = false;
  bool _isDisposed = false;
  bool _cameraShutdownRequested = false;
  bool _isCameraRunning = false;

  CameraUiController({
    required CameraBridge bridge,
    required List<LumaFilmSimulation> simulations,
  }) : _bridge = bridge,
       _simulations = simulations,
       super(CameraUiState.initial(selectedSimulationId: simulations.first.id));

  Future<void> initializeCamera() async {
    if (_initialized || _isDisposed) return;
    state = state.copyWith(isInitializing: true, errorMessage: null);
    try {
      final init = await _bridge.initializeCamera();
      if (_isDisposed || !mounted) return;
      _initialized = true;
      state = state.copyWith(
        isInitializing: false,
        isReady: init.isReady,
        supportsUltraWide: init.supportsUltraWide,
        supportsRawCapture: init.supportsRawCapture,
        lensMode: init.activeLensMode,
        isAeAfLocked: init.isAeAfLocked,
        lookStrength: init.lookStrength,
        exposureBias: init.exposureBias,
        captureFormat: init.captureFormat,
        errorMessage: null,
      );
      await _bridge.setSimulation(
        simulationId: state.selectedSimulationId,
        intensity: _activeIntensity,
      );
      await _bridge.setLookStrength(state.lookStrength);
      await _bridge.setFlashMode(state.flashMode);
    } catch (error) {
      if (_isDisposed || !mounted) return;
      state = state.copyWith(
        isInitializing: false,
        isReady: false,
        errorMessage: 'Camera unavailable: $error',
      );
    }
  }

  Future<void> startCamera() async {
    if (_isDisposed || !_initialized || state.isInitializing) return;
    try {
      await _bridge.startCamera();
      if (_isDisposed || !mounted) return;
      _isCameraRunning = true;
      _bindHistogramStream();
      state = state.copyWith(
        isInitializing: false,
        isReady: true,
        isAeAfLocked: false,
        errorMessage: null,
      );
    } catch (error) {
      _isCameraRunning = false;
      if (_isDisposed || !mounted) return;
      state = state.copyWith(
        isInitializing: false,
        isReady: false,
        errorMessage: 'Could not start camera: $error',
      );
    }
  }

  Future<void> stopCamera() async {
    if (_isDisposed) return;
    _isCameraRunning = false;
    await _cancelHistogramSubscription();
    try {
      await _bridge.stopCamera();
    } catch (_) {
      // Keep teardown resilient.
    }
  }

  Future<void> setSimulation(String simulationId) async {
    if (_isDisposed) return;
    if (!_simulations.any((s) => s.id == simulationId)) return;
    state = state.copyWith(
      selectedSimulationId: simulationId,
      errorMessage: null,
    );
    try {
      await _bridge.setSimulation(
        simulationId: simulationId,
        intensity: _activeIntensity,
      );
    } catch (error) {
      if (_isDisposed || !mounted) return;
      state = state.copyWith(errorMessage: 'Could not set look: $error');
    }
  }

  Future<void> setFocusPoint({
    required double x,
    required double y,
    bool lock = false,
  }) async {
    if (_isDisposed ||
        state.isInitializing ||
        !_initialized ||
        !state.isReady ||
        state.isCapturing) {
      return;
    }
    final normalizedX = x.clamp(0.0, 1.0).toDouble();
    final normalizedY = y.clamp(0.0, 1.0).toDouble();
    final previousLock = state.isAeAfLocked;
    state = state.copyWith(isAeAfLocked: lock, errorMessage: null);
    try {
      await _bridge.setFocusPoint(x: normalizedX, y: normalizedY, lock: lock);
    } catch (error) {
      if (_isDisposed || !mounted) return;
      state = state.copyWith(
        isAeAfLocked: previousLock,
        errorMessage: 'Could not set focus: $error',
      );
    }
  }

  Future<void> cycleFlashMode() async {
    if (_isDisposed) return;
    final next = switch (state.flashMode) {
      CameraFlashMode.auto => CameraFlashMode.off,
      CameraFlashMode.off => CameraFlashMode.on,
      CameraFlashMode.on => CameraFlashMode.auto,
    };
    state = state.copyWith(flashMode: next, errorMessage: null);
    try {
      await _bridge.setFlashMode(next);
    } catch (error) {
      if (_isDisposed || !mounted) return;
      state = state.copyWith(errorMessage: 'Could not set flash: $error');
    }
  }

  Future<void> toggleLensMode() async {
    if (_isDisposed) return;
    if (!state.supportsUltraWide) return;
    final desired = state.lensMode == CameraLensMode.wide
        ? CameraLensMode.ultraWide
        : CameraLensMode.wide;
    try {
      final active = await _bridge.setLensMode(desired);
      if (_isDisposed || !mounted) return;
      state = state.copyWith(
        lensMode: active,
        isAeAfLocked: false,
        errorMessage: null,
      );
    } catch (error) {
      if (_isDisposed || !mounted) return;
      state = state.copyWith(errorMessage: 'Could not switch lens: $error');
    }
  }

  Future<void> setCaptureFormat(CameraCaptureFormat format) async {
    if (_isDisposed ||
        state.isInitializing ||
        !_initialized ||
        !state.isReady) {
      return;
    }
    final previous = state.captureFormat;
    state = state.copyWith(captureFormat: format, errorMessage: null);
    try {
      final applied = await _bridge.setCaptureFormat(format);
      if (_isDisposed || !mounted) return;
      state = state.copyWith(captureFormat: applied, errorMessage: null);
    } catch (error) {
      if (_isDisposed || !mounted) return;
      state = state.copyWith(
        captureFormat: previous,
        errorMessage: 'Could not set format: $error',
      );
    }
  }

  Future<void> setExposureBias(double bias) async {
    if (_isDisposed ||
        state.isInitializing ||
        !_initialized ||
        !state.isReady) {
      return;
    }
    final clamped = bias.clamp(kCameraExposureBiasMin, kCameraExposureBiasMax);
    final target = (clamped as num).toDouble();
    state = state.copyWith(exposureBias: target, errorMessage: null);
    _pendingExposureBias = target;
    if (_isApplyingExposureBias) return;

    _isApplyingExposureBias = true;
    try {
      while (!_isDisposed && mounted && _pendingExposureBias != null) {
        final requestBias = _pendingExposureBias!;
        _pendingExposureBias = null;
        try {
          final applied = await _bridge.setExposureBias(requestBias);
          if (_isDisposed || !mounted) return;
          state = state.copyWith(
            exposureBias: applied
                .clamp(kCameraExposureBiasMin, kCameraExposureBiasMax)
                .toDouble(),
            errorMessage: null,
          );
        } catch (error) {
          if (_isDisposed || !mounted) return;
          state = state.copyWith(
            errorMessage: 'Could not set exposure: $error',
          );
          break;
        }
      }
    } finally {
      _isApplyingExposureBias = false;
    }
  }

  Future<void> setLookStrength(double strength) async {
    if (_isDisposed ||
        state.isInitializing ||
        !_initialized ||
        !state.isReady) {
      return;
    }
    final clamped = strength.clamp(
      kCameraLookStrengthMin,
      kCameraLookStrengthMax,
    );
    final target = (clamped as num).toDouble();
    state = state.copyWith(lookStrength: target, errorMessage: null);
    _pendingLookStrength = target;
    if (_isApplyingLookStrength) return;

    _isApplyingLookStrength = true;
    try {
      while (!_isDisposed && mounted && _pendingLookStrength != null) {
        final requestStrength = _pendingLookStrength!;
        _pendingLookStrength = null;
        try {
          final applied = await _bridge.setLookStrength(requestStrength);
          if (_isDisposed || !mounted) return;
          state = state.copyWith(
            lookStrength: applied
                .clamp(kCameraLookStrengthMin, kCameraLookStrengthMax)
                .toDouble(),
            errorMessage: null,
          );
        } catch (error) {
          if (_isDisposed || !mounted) return;
          state = state.copyWith(errorMessage: 'Could not set look: $error');
          break;
        }
      }
    } finally {
      _isApplyingLookStrength = false;
    }
  }

  Future<CameraCaptureResult?> capturePhoto() async {
    if (_isDisposed ||
        state.isInitializing ||
        !state.isReady ||
        state.isCapturing) {
      return null;
    }
    state = state.copyWith(
      captureState: CameraCaptureState.capturing,
      lastCapture: null,
    );
    try {
      final result = await _bridge.capturePhoto();
      final thumb = await _bridge.latestThumbnail();
      if (_isDisposed || !mounted) return result;
      state = state.copyWith(
        isInitializing: false,
        captureState: CameraCaptureState.idle,
        lastCapture: result,
        latestThumbnail: thumb,
        errorMessage: null,
      );
      return result;
    } catch (error) {
      if (_isDisposed || !mounted) return null;
      state = state.copyWith(
        isInitializing: false,
        captureState: CameraCaptureState.idle,
        errorMessage: 'Capture failed: $error',
      );
      return null;
    }
  }

  Future<void> refreshLatestThumbnail() async {
    if (_isDisposed) return;
    try {
      final thumb = await _bridge.latestThumbnail();
      if (_isDisposed || !mounted) return;
      state = state.copyWith(latestThumbnail: thumb);
    } catch (_) {
      // Thumbnail is optional.
    }
  }

  Future<void> disposeCamera() async {
    if (_isDisposed) return;
    _isDisposed = true;
    _isCameraRunning = false;
    await _shutdownCamera();
  }

  Future<void> _shutdownCamera() async {
    if (_cameraShutdownRequested) return;
    _cameraShutdownRequested = true;
    await _cancelHistogramSubscription();
    try {
      await _bridge.stopCamera();
    } catch (_) {
      // Best effort shutdown.
    }
    try {
      await _bridge.disposeCamera();
    } catch (_) {
      // Best effort shutdown.
    }
  }

  Future<void> _cancelHistogramSubscription() async {
    final histogramSubscription = _histogramSubscription;
    _histogramSubscription = null;
    await histogramSubscription?.cancel();
  }

  double get _activeIntensity {
    final simulation = lumaSimulationById(state.selectedSimulationId);
    return simulation.intensity;
  }

  void _bindHistogramStream() {
    if (_isDisposed || !mounted || !_isCameraRunning) return;
    final previousSubscription = _histogramSubscription;
    _histogramSubscription = null;
    unawaited(previousSubscription?.cancel());
    _histogramSubscription = _bridge.histogramStream().listen(
      (bins) {
        if (_isDisposed || !mounted || !_isCameraRunning) return;
        final histogram = List<double>.unmodifiable(bins);
        if (listEquals(state.histogram, histogram)) return;
        state = state.copyWith(histogram: histogram);
      },
      onError: (_) {
        // Histogram is optional and should never break capture flow.
      },
    );
  }

  @override
  void dispose() {
    _isDisposed = true;
    _isCameraRunning = false;
    unawaited(_shutdownCamera());
    super.dispose();
  }
}
