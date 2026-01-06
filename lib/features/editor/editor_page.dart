// lib/features/editor/editor_page.dart
//
// Luma Editor Page (Native Preview + Native Export)

import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:photo_manager/photo_manager.dart';

import '../presets/preset_registry.dart'
    show LumaPreset, LumaPresetPack, PresetRegistry;
import 'native/native_renderer.dart';

class EditorPage extends StatefulWidget {
  final String assetId;

  const EditorPage({super.key, required this.assetId});

  @override
  State<EditorPage> createState() => _EditorPageState();
}

enum _PreviewQuality { low, high }

enum PresetStage { categories, list, active }

class _EditorPageState extends State<EditorPage> {
  static const String _presetIntensityToolId = '__preset_intensity__';
  static const String _savedCategoryId = 'saved';
  static const Color _accent = Color(0xFFB08A6E);
  static const Color _ink = Color(0xFFF5F0EA);
  static const Color _muted = Color(0xFFB0A69A);
  static const Color _panel = Color(0xFF1C1C1C);
  static const Color _panelHighlight = Color(0xFF262626);
  static const Color _canvas = Color(0xFF151515);
  static const double _defaultPresetIntensity = 0.7;

  Uint8List? _originalBytes;
  Uint8List? _previewBytes;
  ImageProvider? _frontPreview;
  ImageProvider? _backPreview;
  Uint8List? _backPreviewBytes;
  ImageStream? _backPreviewStream;
  ImageStreamListener? _backPreviewListener;
  bool _showBackPreview = false;
  int _previewFrameToken = 0;
  static const Duration _previewFadeDuration = Duration(milliseconds: 100);
  static const double _dragPreviewScale = 0.6;
  double _imageAspect = 4 / 5;
  bool _loading = true;

  bool _buildingPreview = false;
  bool _buildingHQ = false;
  _PreviewQuality? _pendingQuality;
  int _renderToken = 0;
  int _previewRequestId = 0;
  int _latestPresentedRequestId = 0;
  bool _dragRenderInFlight = false;
  String? _dragToolId;
  String? _pendingDragToolId;
  double? _pendingDragValue;
  int _pendingDragOverwriteCount = 0;
  int _dragRenderSeq = 0;

  Timer? _dragDebounce;
  Timer? _previewDelay;

  int _tabIndex = 1; // 0 Edit, 1 Presets
  int _groupIndex = 0;
  int _toolIndex = 0;
  int? _preCropToolIndex;

  String? _activePresetName;
  bool _isCropMode = false;
  bool _isDragging = false;
  double? _cropAspect;
  int _rotateQuarterTurns = 0;
  Offset _cropCenter = const Offset(0.5, 0.5);
  double _cropScale = 1.0;
  _CropGestureState? _cropGestureState;
  static const double _minCropScale = 0.25;
  bool _isFreeformCrop = false;
  Rect _freeformCropRect = const Rect.fromLTWH(0.1, 0.1, 0.8, 0.8);
  _CropSnapshot? _cropSnapshot;

  final Map<String, double> _values = {};
  final Map<String, double> _defaultValues = {};
  Map<String, double>? _activePresetValues;
  String? _activePresetId;
  double _presetIntensityRaw = _defaultPresetIntensity;
  PresetStage _presetStage = PresetStage.categories;
  String? _selectedCategoryId;
  _PresetSnapshot? _presetSnapshot;

  final List<_Preset> _presets = [];
  final List<_HistoryState> _undoStack = [];
  final List<_HistoryState> _redoStack = [];

  final Map<String, Uint8List> _presetPreviewCache = {};
  final Map<String, Future<Uint8List>> _presetPreviewFutures = {};
  final Map<String, Uint8List> _previewCache = {};
  final Map<String, Future<PreviewResult>> _previewFutures = {};
  static const int _previewCacheLimit = 12;
  final GlobalKey _adjustmentPillKey = GlobalKey();
  final _Throttler _previewThrottler = _Throttler(
    interval: Duration(milliseconds: 33),
  );
  final _Throttler _dragPreviewThrottler = _Throttler(
    interval: Duration(milliseconds: 180),
  );

  bool get _canUndo => _undoStack.isNotEmpty;
  bool get _canRedo => _redoStack.isNotEmpty;

  late final List<_ToolGroup> _groups = [
    _ToolGroup(
      label: 'Light',
      tools: const [
        _ToolItem(id: 'auto', label: 'Balance', kind: ToolKind.action),
        _ToolItem(
          id: 'exposure',
          label: 'Exposure',
          min: -1,
          max: 1,
          defaultValue: 0,
        ),
        _ToolItem(
          id: 'contrast',
          label: 'Contrast',
          min: -1,
          max: 1,
          defaultValue: 0,
        ),
        _ToolItem(
          id: 'highlights',
          label: 'Highlights',
          min: -1,
          max: 1,
          defaultValue: 0,
        ),
        _ToolItem(
          id: 'shadows',
          label: 'Shadows',
          min: -1,
          max: 1,
          defaultValue: 0,
        ),
        _ToolItem(
          id: 'whites',
          label: 'Whites',
          min: -1,
          max: 1,
          defaultValue: 0,
        ),
        _ToolItem(
          id: 'blacks',
          label: 'Blacks',
          min: -1,
          max: 1,
          defaultValue: 0,
        ),
      ],
    ),
    _ToolGroup(
      label: 'Color',
      tools: const [
        _ToolItem(id: 'tint', label: 'Tint', min: -1, max: 1, defaultValue: 0),
        _ToolItem(
          id: 'color_balance',
          label: 'Warmth',
          min: -1,
          max: 1,
          defaultValue: 0,
        ),
        _ToolItem(
          id: 'vibrance',
          label: 'Vibrance',
          min: -1,
          max: 1,
          defaultValue: 0,
        ),
        _ToolItem(
          id: 'saturation',
          label: 'Saturation',
          min: -1,
          max: 1,
          defaultValue: 0,
        ),
      ],
    ),
    _ToolGroup(
      label: 'Effects',
      tools: const [
        _ToolItem(
          id: 'texture',
          label: 'Texture',
          min: -1,
          max: 1,
          defaultValue: 0,
        ),
        _ToolItem(
          id: 'clarity',
          label: 'Clarity',
          min: -1,
          max: 1,
          defaultValue: 0,
        ),
        _ToolItem(
          id: 'dehaze',
          label: 'Dehaze',
          min: -1,
          max: 1,
          defaultValue: 0,
        ),
        _ToolItem(id: 'grain', label: 'Grain', min: 0, max: 1, defaultValue: 0),
        _ToolItem(
          id: 'vignette',
          label: 'Vignette',
          min: 0,
          max: 1,
          defaultValue: 0,
        ),
      ],
    ),
    _ToolGroup(
      label: 'Detail',
      tools: const [
        _ToolItem(
          id: 'sharpen',
          label: 'Sharpen',
          min: 0,
          max: 1,
          defaultValue: 0,
        ),
        _ToolItem(
          id: 'noise',
          label: 'Noise Red.',
          min: 0,
          max: 1,
          defaultValue: 0,
        ),
        _ToolItem(
          id: 'color_noise',
          label: 'Color NR',
          min: 0,
          max: 1,
          defaultValue: 0,
        ),
      ],
    ),
    _ToolGroup(
      label: 'Optics',
      tools: const [
        _ToolItem(
          id: 'lens_correction',
          label: 'Lens Corr',
          kind: ToolKind.toggle,
          min: 0,
          max: 1,
          defaultValue: 0,
        ),
        _ToolItem(
          id: 'chromatic_aberration',
          label: 'Remove CA',
          kind: ToolKind.toggle,
          min: 0,
          max: 1,
          defaultValue: 0,
        ),
      ],
    ),
    _ToolGroup(
      label: 'Crop',
      tools: const [
        _ToolItem(id: 'rotate_90', label: 'Rotate 90', kind: ToolKind.action),
        _ToolItem(
          id: 'straighten',
          label: 'Straighten',
          min: -1,
          max: 1,
          defaultValue: 0,
        ),
      ],
    ),
  ];

  static const List<String> _quickAdjustmentIds = [
    'auto',
    'exposure',
    'highlights',
    'shadows',
    'color_balance',
  ];

  late final Map<String, _ToolItem> _toolsById = {
    for (final group in _groups)
      for (final tool in group.tools) tool.id: tool,
  };

  late final List<_ToolItem> _allAdjustmentTools = [
    for (final group in _groups) ...group.tools,
  ];
  late final List<String> _allAdjustmentIds = [
    for (final tool in _allAdjustmentTools) tool.id,
  ];

  List<_ToolItem> get _quickAdjustments => [
    for (final id in _quickAdjustmentIds)
      if (_toolsById.containsKey(id)) _toolsById[id]!,
  ];

  int get _activeAdjustmentIndex =>
      _clampIndex(_toolIndex, _allAdjustmentIds.length);
  String get _activeAdjustmentId => _allAdjustmentIds[_activeAdjustmentIndex];
  _ToolItem get _activeTool => _toolsById[_activeAdjustmentId]!;
  int _clampIndex(int value, int length) {
    if (length <= 0) return 0;
    if (value < 0) return 0;
    if (value >= length) return length - 1;
    return value;
  }

  double get _straightenDegrees => _v('straighten') * 8.0;

  @override
  void initState() {
    super.initState();
    _primeDefaults();
    _loadImage();
  }

  @override
  void dispose() {
    _dragDebounce?.cancel();
    _previewDelay?.cancel();
    _previewThrottler.dispose();
    _dragPreviewThrottler.dispose();
    _clearBackPreviewListener();
    super.dispose();
  }

  void _primeDefaults() {
    _defaultValues.clear();
    for (final g in _groups) {
      for (final t in g.tools) {
        _values.putIfAbsent(t.id, () => t.defaultValue);
        _defaultValues.putIfAbsent(t.id, () => t.defaultValue);
      }
    }
  }

  void _pushUndoCheckpoint() {
    _undoStack.add(_captureState());
    _redoStack.clear();
  }

  _HistoryState _captureState() {
    return _HistoryState(
      values: Map<String, double>.from(_values),
      tabIndex: _tabIndex,
      groupIndex: _groupIndex,
      toolIndex: _toolIndex,
      imageAspect: _imageAspect,
      cropAspect: _cropAspect,
      rotateQuarterTurns: _rotateQuarterTurns,
      cropCenter: _cropCenter,
      cropScale: _cropScale,
      isFreeformCrop: _isFreeformCrop,
      freeformCropRect: _freeformCropRect,
      activePresetName: _activePresetName,
      activePresetValues:
          _activePresetValues == null
              ? null
              : Map<String, double>.from(_activePresetValues!),
      activePresetId: _activePresetId,
      presetIntensityRaw: _presetIntensityRaw,
    );
  }

  void _restoreState(_HistoryState s) {
    setState(() {
      final safeToolIndex = _clampIndex(s.toolIndex, _allAdjustmentIds.length);
      _values
        ..clear()
        ..addAll(s.values);
      _tabIndex = s.tabIndex;
      _groupIndex = 0;
      _toolIndex = safeToolIndex;
      _isCropMode = false;
      _imageAspect = s.imageAspect;
      _cropAspect = s.cropAspect;
      _rotateQuarterTurns = s.rotateQuarterTurns;
      _cropCenter = s.cropCenter;
      _cropScale = s.cropScale;
      _isFreeformCrop = s.isFreeformCrop;
      _freeformCropRect = s.freeformCropRect;
      _activePresetName = s.activePresetName;
      _activePresetValues =
          s.activePresetValues == null
              ? null
              : Map<String, double>.from(s.activePresetValues!);
      _activePresetId = s.activePresetId;
      _presetIntensityRaw = s.presetIntensityRaw;
    });
    _schedulePreviewRebuild(_PreviewQuality.high, immediate: true);
  }

  _PresetSnapshot _capturePresetSnapshot() {
    return _PresetSnapshot(
      state: _captureState(),
      stage: _presetStage,
      selectedCategoryId: _selectedCategoryId,
      activePresetId: _activePresetId,
    );
  }

  void _restorePresetSnapshot(_PresetSnapshot snapshot) {
    _restoreState(snapshot.state);
    setState(() {
      _presetStage = snapshot.stage;
      _selectedCategoryId = snapshot.selectedCategoryId;
      _activePresetId = snapshot.activePresetId;
    });
  }

  void _selectPresetCategory(String id) {
    setState(() {
      _selectedCategoryId = id;
      _presetStage = PresetStage.list;
    });
  }

  void _selectRegistryPreset(LumaPreset preset) {
    _presetSnapshot = _capturePresetSnapshot();
    _applyRegistryPreset(preset);
  }

  void _selectSavedPreset(_Preset preset) {
    _presetSnapshot = _capturePresetSnapshot();
    _applySavedPreset(preset);
  }

  void _cancelPresetSelection() {
    final snapshot = _presetSnapshot;
    _presetSnapshot = null;
    if (snapshot == null) {
      setState(() {
        _presetStage = PresetStage.list;
      });
      return;
    }
    _restorePresetSnapshot(snapshot);
  }

  void _finishPresetSelection() {
    setState(() {
      _presetStage = PresetStage.list;
    });
    _presetSnapshot = null;
  }

  void _undo() {
    if (!_canUndo) return;
    final current = _captureState();
    final prev = _undoStack.removeLast();
    _redoStack.add(current);
    _restoreState(prev);
  }

  void _redo() {
    if (!_canRedo) return;
    final current = _captureState();
    final next = _redoStack.removeLast();
    _undoStack.add(current);
    _restoreState(next);
  }

  Future<void> _loadImage() async {
    final asset = await AssetEntity.fromId(widget.assetId);
    if (asset == null) {
      if (!mounted) return;
      setState(() => _loading = false);
      return;
    }

    final aspect = asset.height == 0 ? (4 / 5) : (asset.width / asset.height);

    final data = await asset.thumbnailDataWithSize(
      const ThumbnailSize(1400, 1400),
      format: ThumbnailFormat.jpeg,
      quality: 90,
    );

    if (!mounted) return;

    setState(() {
      _originalBytes = data;
      _previewBytes = data;
      _frontPreview = data == null ? null : MemoryImage(data);
      _imageAspect = aspect;
      _loading = false;
    });

    _pushUndoCheckpoint();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _schedulePreviewRebuild(_PreviewQuality.high, immediate: true);
    });
  }

  void _debugDragLog(String Function() messageBuilder) {
    assert(() {
      debugPrint(messageBuilder());
      return true;
    }());
  }

  void _clearPendingDragRequest() {
    _pendingDragToolId = null;
    _pendingDragValue = null;
    _pendingDragOverwriteCount = 0;
  }

  void _requestDragPreviewRender(String toolId, double value) {
    if (toolId == _presetIntensityToolId) {
      _presetIntensityRaw = value.clamp(0.0, 1.0);
    } else {
      _values[toolId] = value;
    }

    if (_dragRenderInFlight) {
      _pendingDragToolId = toolId;
      _pendingDragValue = value;
      _pendingDragOverwriteCount++;
      _debugDragLog(
        () =>
            '[drag] pending overwrite=$_pendingDragOverwriteCount inFlight=true',
      );
      return;
    }

    _dragRenderInFlight = true;
    final requestId = ++_dragRenderSeq;
    final overwrites = _pendingDragOverwriteCount;
    _pendingDragOverwriteCount = 0;
    _debugDragLog(
      () => '[drag] start #$requestId inFlight=true overwrites=$overwrites',
    );
    unawaited(_runDragRender(requestId));
  }

  Future<void> _runDragRender(int requestId) async {
    try {
      await _rebuildPreview(_PreviewQuality.low);
    } finally {
      _dragRenderInFlight = false;
    }
    _debugDragLog(
      () =>
          '[drag] end #$requestId inFlight=false pending=$_pendingDragOverwriteCount',
    );
    if (!_isDragging) {
      _clearPendingDragRequest();
      return;
    }
    final nextTool = _pendingDragToolId;
    final nextValue = _pendingDragValue;
    if (nextTool == null || nextValue == null) return;
    _clearPendingDragRequest();
    _requestDragPreviewRender(nextTool, nextValue);
  }

  void _clearBackPreviewListener() {
    if (_backPreviewStream != null && _backPreviewListener != null) {
      _backPreviewStream!.removeListener(_backPreviewListener!);
    }
    _backPreviewStream = null;
    _backPreviewListener = null;
  }

  void _presentPreviewBytes(
    Uint8List bytes, {
    required bool allowFade,
    required int requestId,
  }) {
    if (_isDragging) {
      _presentPreviewBytesDuringDrag(bytes, requestId: requestId);
      return;
    }
    if (requestId < _latestPresentedRequestId) return;
    _latestPresentedRequestId = requestId;
    _clearBackPreviewListener();
    final token = ++_previewFrameToken;
    final provider = MemoryImage(bytes);
    final config = createLocalImageConfiguration(context);
    final stream = provider.resolve(config);
    ImageStreamListener? listener;
    listener = ImageStreamListener(
      (_, _) {
        stream.removeListener(listener!);
        _backPreviewStream = null;
        _backPreviewListener = null;
        if (!mounted) return;
        if (token != _previewFrameToken) return;
        if (!allowFade || _frontPreview == null) {
          setState(() {
            _frontPreview = provider;
            _previewBytes = bytes;
            _backPreview = null;
            _backPreviewBytes = null;
            _showBackPreview = false;
            _buildingPreview = false;
            _buildingHQ = false;
          });
          return;
        }
        setState(() {
          _backPreview = provider;
          _backPreviewBytes = bytes;
          _showBackPreview = true;
          _buildingPreview = false;
          _buildingHQ = false;
        });
      },
      onError: (_, _) {
        stream.removeListener(listener!);
        _backPreviewStream = null;
        _backPreviewListener = null;
        if (!mounted) return;
        setState(() {
          _buildingPreview = false;
          _buildingHQ = false;
        });
      },
    );
    _backPreviewStream = stream;
    _backPreviewListener = listener;
    stream.addListener(listener);
  }

  void _presentPreviewBytesDuringDrag(
    Uint8List bytes, {
    required int requestId,
  }) {
    if (bytes.isEmpty) return;
    if (requestId < _latestPresentedRequestId) return;
    _latestPresentedRequestId = requestId;
    _clearBackPreviewListener();
    setState(() {
      _frontPreview = MemoryImage(bytes);
      _previewBytes = bytes;
      _backPreview = null;
      _backPreviewBytes = null;
      _showBackPreview = false;
      _buildingPreview = false;
      _buildingHQ = false;
    });
  }

  double get _effectivePresetIntensity {
    return _presetIntensityRaw.clamp(0.0, 1.0);
  }

  Map<String, double> _effectiveValues() {
    final base = Map<String, double>.from(_values);
    final presetValues = _activePresetValues;
    if (presetValues == null) return base;
    final intensity = _effectivePresetIntensity;
    if (intensity <= 0.0) return base;
    for (final entry in presetValues.entries) {
      final id = entry.key;
      final presetValue = entry.value;
      final defaultValue = _defaultValues[id] ?? 0.0;
      final baseValue = base[id] ?? defaultValue;
      base[id] = baseValue + (presetValue - defaultValue) * intensity;
    }
    return base;
  }

  void _promoteBackPreview() {
    if (_backPreview == null || _backPreviewBytes == null) return;
    setState(() {
      _frontPreview = _backPreview;
      _previewBytes = _backPreviewBytes;
      _backPreview = null;
      _backPreviewBytes = null;
      _showBackPreview = false;
    });
  }

  void _schedulePreviewRebuild(
    _PreviewQuality quality, {
    bool immediate = false,
  }) {
    if (_buildingPreview) {
      _pendingQuality = quality;
      return;
    }

    if (immediate) {
      unawaited(_rebuildPreview(quality));
      return;
    }

    final delayMs = (quality == _PreviewQuality.low) ? 0 : 40;

    // Cancel any queued delayed rebuild so we don't leave pending timers around.
    _previewDelay?.cancel();

    if (delayMs == 0) {
      unawaited(_rebuildPreview(quality));
      return;
    }

    _previewDelay = Timer(Duration(milliseconds: delayMs), () {
      if (!mounted) return;
      unawaited(_rebuildPreview(quality));
    });
  }

  Future<void> _rebuildPreview(_PreviewQuality quality) async {
    if (_originalBytes == null) return;

    final int token = ++_renderToken;
    final isDragLow = quality == _PreviewQuality.low && _isDragging;
    final isIntensityDrag =
        isDragLow && _dragToolId == _presetIntensityToolId;
    if (!isDragLow) {
      setState(() {
        _buildingPreview = true;
        if (quality == _PreviewQuality.high) _buildingHQ = true;
      });
    }

    var maxSide = (quality == _PreviewQuality.low) ? 700 : 1600;
    var q = (quality == _PreviewQuality.low) ? 0.70 : 0.82;
    if (_isDragging && quality == _PreviewQuality.low && !isIntensityDrag) {
      maxSide = math.max(1, (maxSide * _dragPreviewScale).round());
    }
    if (isIntensityDrag) {
      maxSide = 1600;
      q = 0.82;
    }

    final presetValues = _activePresetValues;
    final presetIntensity =
        (presetValues == null) ? null : _presetIntensityRaw.clamp(0.0, 1.0);
    final Map<String, double> valuesForRender;
    Map<String, double>? presetValuesForRender = presetValues;
    String? presetBlendMode;

    if (isDragLow && presetValues != null && !isIntensityDrag) {
      valuesForRender = _effectiveValues();
      presetValuesForRender = null;
      presetBlendMode = null;
    } else {
      valuesForRender = Map<String, double>.from(_values);
      presetBlendMode = presetValues == null ? null : 'image';
    }
    final useCropRect =
        !_isCropMode &&
        _normalizedCropRect() != const Rect.fromLTWH(0, 0, 1, 1);
    final cacheKey = _previewKey(
      valuesForRender,
      maxSide,
      q,
      useCropRect: useCropRect,
      presetValues: presetValuesForRender,
      presetIntensity: presetIntensity,
      presetBlendMode: presetBlendMode,
    );
    final useCache = !isIntensityDrag;
    final cached = useCache ? _previewCache[cacheKey] : null;
    if (cached != null) {
      if (mounted) {
        final allowFade = !_isDragging;
        _presentPreviewBytes(
          cached,
          allowFade: allowFade,
          requestId: ++_previewRequestId,
        );
      }
      return;
    }

    final existing = useCache ? _previewFutures[cacheKey] : null;
    if (existing != null) {
      try {
        final result = await existing;
        if (!mounted) return;
        if (token != _renderToken) return;
        final allowFade = !_isDragging;
        _presentPreviewBytes(
          result.bytes,
          allowFade: allowFade,
          requestId: result.requestId,
        );
      } catch (_) {
        if (!mounted || isDragLow) return;
        setState(() {
          _buildingPreview = false;
          _buildingHQ = false;
        });
      }
      return;
    }

    try {
      final requestId = ++_previewRequestId;
      final previewTier =
          isIntensityDrag
              ? 'final'
              : (_isDragging && quality == _PreviewQuality.low)
                  ? 'drag'
                  : 'final';
      final future = NativeRenderer.renderPreview(
        assetId: widget.assetId,
        values: Map<String, double>.from(valuesForRender),
        maxSide: maxSide,
        quality: q,
        previewTier: previewTier,
        requestId: requestId,
        presetValues:
            presetValuesForRender == null
                ? null
                : Map<String, double>.from(presetValuesForRender),
        presetIntensity: presetIntensity,
        presetBlendMode: presetBlendMode,
        rotationTurns: _rotateQuarterTurns,
        straightenDegrees: _straightenDegrees,
        cropRect: useCropRect ? _normalizedCropRect() : null,
      );
      if (useCache) {
        _previewFutures[cacheKey] = future;
      }
      final result = await future;
      final jpg = result.bytes;
      if (useCache) {
        _previewCache[cacheKey] = jpg;
        if (_previewCache.length > _previewCacheLimit) {
          _previewCache.remove(_previewCache.keys.first);
        }
        _previewFutures.remove(cacheKey);
      }

      if (!mounted) return;

      if (token != _renderToken) {
        if (!isDragLow) {
          setState(() {
            _buildingPreview = false;
            _buildingHQ = false;
          });
        }
        return;
      }

      final allowFade = !_isDragging;
      _presentPreviewBytes(
        jpg,
        allowFade: allowFade,
        requestId: result.requestId,
      );
    } catch (_) {
      if (useCache) {
        _previewFutures.remove(cacheKey);
      }
      if (!mounted || isDragLow) return;
      setState(() {
        _buildingPreview = false;
        _buildingHQ = false;
      });
    }

    if (_pendingQuality != null) {
      final next = _pendingQuality!;
      _pendingQuality = null;
      _schedulePreviewRebuild(next, immediate: true);
    }
  }

  String _presetSignature(Map<String, double> values) {
    final keys = values.keys.toList()..sort();
    final b = StringBuffer();
    for (final k in keys) {
      final v = values[k] ?? 0.0;
      b.write(k);
      b.write('=');
      b.write((v * 1000).round());
      b.write(';');
    }
    return b.toString();
  }

  String _previewKey(
    Map<String, double> values,
    int maxSide,
    double quality, {
    required bool useCropRect,
    Map<String, double>? presetValues,
    double? presetIntensity,
    String? presetBlendMode,
  }) {
    final rect = _normalizedCropRect();
    final b = StringBuffer();
    b.write(widget.assetId);
    b.write('|');
    b.write(_presetSignature(values));
    if (presetValues != null) {
      b.write('|p=');
      b.write(_presetSignature(presetValues));
    }
    if (presetIntensity != null) {
      b.write('|pi=');
      b.write((presetIntensity * 1000).round());
    }
    if (presetBlendMode != null) {
      b.write('|pb=');
      b.write(presetBlendMode);
    }
    b.write('|r=');
    b.write(_rotateQuarterTurns);
    b.write('|s=');
    b.write((_straightenDegrees * 10).round());
    b.write('|crop=');
    b.write(useCropRect ? '1' : '0');
    if (useCropRect) {
      b.write('|c=');
      b.write((rect.left * 1000).round());
      b.write(',');
      b.write((rect.top * 1000).round());
      b.write(',');
      b.write((rect.width * 1000).round());
      b.write(',');
      b.write((rect.height * 1000).round());
    }
    b.write('|ms=');
    b.write(maxSide);
    b.write('|q=');
    b.write((quality * 100).round());
    return b.toString();
  }

  String _presetCacheKey(String presetName, Map<String, double> presetValues) {
    return '${widget.assetId}|$presetName|${_presetSignature(presetValues)}';
  }

  Future<Uint8List> _getPresetPreviewBytes(
    String presetName,
    Map<String, double> presetValues,
  ) {
    final key = _presetCacheKey(presetName, presetValues);

    final cached = _presetPreviewCache[key];
    if (cached != null) return Future.value(cached);

    final existing = _presetPreviewFutures[key];
    if (existing != null) return existing;

    final merged = Map<String, double>.from(_defaultValues)
      ..addAll(presetValues);

    final useCropRect =
        !_isCropMode &&
        _normalizedCropRect() != const Rect.fromLTWH(0, 0, 1, 1);
    final fut =
        NativeRenderer.renderPreview(
              assetId: widget.assetId,
              values: merged,
              maxSide: 520,
              quality: 0.74,
              previewTier: 'final',
              requestId: ++_previewRequestId,
              rotationTurns: _rotateQuarterTurns,
              straightenDegrees: _straightenDegrees,
              cropRect: useCropRect ? _normalizedCropRect() : null,
            )
            .then((result) {
              _presetPreviewCache[key] = result.bytes;
              return result.bytes;
            })
            .whenComplete(() {
              _presetPreviewFutures.remove(key);
            });

    _presetPreviewFutures[key] = fut;
    return fut;
  }

  double _v(String id) => _values[id] ?? 0.0;

  int _displayNumber(_ToolItem t) {
    if (t.id == 'straighten') return _straightenDegrees.round();
    final v = _v(t.id);
    final centered = (t.min < 0 && t.max > 0);
    if (centered) return (v.clamp(-1.0, 1.0) * 100).round();
    return (v.clamp(0.0, 1.0) * 100).round();
  }

  void _resetActiveTool() {
    if (_activeTool.kind != ToolKind.slider) return;
    HapticFeedback.selectionClick();
    _pushUndoCheckpoint();
    setState(() {
      _values[_activeTool.id] = _activeTool.defaultValue;
    });
    _schedulePreviewRebuild(_PreviewQuality.high, immediate: true);
  }

  void _rotate90() {
    HapticFeedback.selectionClick();
    _pushUndoCheckpoint();
    setState(() {
      _rotateQuarterTurns = (_rotateQuarterTurns + 1) % 4;
    });
    _schedulePreviewRebuild(_PreviewQuality.high, immediate: true);
  }

  void _setCropOption(_CropAspectOption option) {
    HapticFeedback.selectionClick();
    _pushUndoCheckpoint();
    final currentRect = _normalizedCropRect();
    setState(() {
      if (option.isFreeform) {
        _isFreeformCrop = true;
        _cropAspect = null;
        _freeformCropRect = currentRect;
      } else {
        _isFreeformCrop = false;
        _cropAspect = option.aspect;
        _applyCropRect(currentRect);
      }
    });
    _schedulePreviewRebuild(_PreviewQuality.high, immediate: true);
  }

  double get _currentCropAspect => _cropAspect ?? _imageAspect;
  double get _croppedAspect {
    final rect = _normalizedCropRect();
    if (rect.height <= 0) return _imageAspect;
    return (rect.width / rect.height) * _imageAspect;
  }

  Rect _baseCropRect() {
    if (_isFreeformCrop) {
      return const Rect.fromLTWH(0, 0, 1, 1);
    }
    final aspect = _currentCropAspect;
    final imageAspect = _imageAspect;

    double baseW;
    double baseH;

    if (imageAspect > aspect) {
      baseH = 1.0;
      baseW = aspect / imageAspect;
    } else {
      baseW = 1.0;
      baseH = imageAspect / aspect;
    }

    final left = 0.5 - baseW / 2;
    final top = 0.5 - baseH / 2;
    return Rect.fromLTWH(left, top, baseW, baseH);
  }

  Rect _normalizedCropRect() {
    if (_isFreeformCrop) {
      return _freeformCropRect;
    }
    final base = _baseCropRect();
    final scale = _cropScale.clamp(_minCropScale, 1.0);
    final w = base.width * scale;
    final h = base.height * scale;

    final center = _clampCropCenter(_cropCenter, scale);
    final left = (center.dx - w / 2).clamp(0.0, 1.0 - w);
    final top = (center.dy - h / 2).clamp(0.0, 1.0 - h);
    return Rect.fromLTWH(left, top, w, h);
  }

  Offset _clampCropCenter(Offset center, double scale) {
    final base = _baseCropRect();
    final w = base.width * scale.clamp(_minCropScale, 1.0);
    final h = base.height * scale.clamp(_minCropScale, 1.0);

    final minX = w / 2;
    final maxX = 1.0 - w / 2;
    final minY = h / 2;
    final maxY = 1.0 - h / 2;

    return Offset(center.dx.clamp(minX, maxX), center.dy.clamp(minY, maxY));
  }

  void _applyCropRect(Rect rect) {
    final base = _baseCropRect();
    final scale = (rect.width / base.width).clamp(_minCropScale, 1.0);
    final center = Offset(
      rect.center.dx.clamp(0.0, 1.0),
      rect.center.dy.clamp(0.0, 1.0),
    );

    _cropScale = scale;
    _cropCenter = _clampCropCenter(center, scale);
  }

  Rect _displayRectForNormalized(Rect normalized, Size displaySize) {
    return Rect.fromLTWH(
      normalized.left * displaySize.width,
      normalized.top * displaySize.height,
      normalized.width * displaySize.width,
      normalized.height * displaySize.height,
    );
  }

  _CropHandle? _hitTestHandle(Offset point, Rect cropRect) {
    const handleRadius = 18.0;
    final handles = {
      _CropHandle.topLeft: cropRect.topLeft,
      _CropHandle.topRight: cropRect.topRight,
      _CropHandle.bottomLeft: cropRect.bottomLeft,
      _CropHandle.bottomRight: cropRect.bottomRight,
      _CropHandle.top: cropRect.topCenter,
      _CropHandle.bottom: cropRect.bottomCenter,
      _CropHandle.left: cropRect.centerLeft,
      _CropHandle.right: cropRect.centerRight,
    };

    for (final entry in handles.entries) {
      if ((entry.value - point).distance <= handleRadius) {
        return entry.key;
      }
    }
    return null;
  }

  Rect _resizeCropRect(Rect start, _CropHandle handle, Offset deltaNorm) {
    if (_isFreeformCrop) {
      return _resizeFreeformRect(start, handle, deltaNorm);
    }
    final aspect = _currentCropAspect;
    final base = _baseCropRect();
    final minW = base.width * _minCropScale;
    final minH = base.height * _minCropScale;
    Rect rect;

    switch (handle) {
      case _CropHandle.left:
        final anchor = start.centerRight;
        var width = (anchor.dx - (start.left + deltaNorm.dx)).clamp(minW, 1.0);
        final height = (width / aspect).clamp(minH, 1.0);
        rect = Rect.fromCenter(
          center: Offset(anchor.dx - width / 2, anchor.dy),
          width: width,
          height: height,
        );
        break;
      case _CropHandle.right:
        final anchor = start.centerLeft;
        var width = ((start.right + deltaNorm.dx) - anchor.dx).clamp(minW, 1.0);
        final height = (width / aspect).clamp(minH, 1.0);
        rect = Rect.fromCenter(
          center: Offset(anchor.dx + width / 2, anchor.dy),
          width: width,
          height: height,
        );
        break;
      case _CropHandle.top:
        final anchor = start.bottomCenter;
        var height = (anchor.dy - (start.top + deltaNorm.dy)).clamp(minH, 1.0);
        final width = (height * aspect).clamp(minW, 1.0);
        rect = Rect.fromCenter(
          center: Offset(anchor.dx, anchor.dy - height / 2),
          width: width,
          height: height,
        );
        break;
      case _CropHandle.bottom:
        final anchor = start.topCenter;
        var height = ((start.bottom + deltaNorm.dy) - anchor.dy).clamp(
          minH,
          1.0,
        );
        final width = (height * aspect).clamp(minW, 1.0);
        rect = Rect.fromCenter(
          center: Offset(anchor.dx, anchor.dy + height / 2),
          width: width,
          height: height,
        );
        break;
      case _CropHandle.topLeft:
        final anchor = start.bottomRight;
        var width = (anchor.dx - (start.left + deltaNorm.dx)).clamp(minW, 1.0);
        var height = (width / aspect).clamp(minH, 1.0);
        rect = Rect.fromLTRB(
          anchor.dx - width,
          anchor.dy - height,
          anchor.dx,
          anchor.dy,
        );
        break;
      case _CropHandle.topRight:
        final anchor = start.bottomLeft;
        var width = ((start.right + deltaNorm.dx) - anchor.dx).clamp(minW, 1.0);
        var height = (width / aspect).clamp(minH, 1.0);
        rect = Rect.fromLTRB(
          anchor.dx,
          anchor.dy - height,
          anchor.dx + width,
          anchor.dy,
        );
        break;
      case _CropHandle.bottomLeft:
        final anchor = start.topRight;
        var width = (anchor.dx - (start.left + deltaNorm.dx)).clamp(minW, 1.0);
        var height = (width / aspect).clamp(minH, 1.0);
        rect = Rect.fromLTRB(
          anchor.dx - width,
          anchor.dy,
          anchor.dx,
          anchor.dy + height,
        );
        break;
      case _CropHandle.bottomRight:
        final anchor = start.topLeft;
        var width = ((start.right + deltaNorm.dx) - anchor.dx).clamp(minW, 1.0);
        var height = (width / aspect).clamp(minH, 1.0);
        rect = Rect.fromLTRB(
          anchor.dx,
          anchor.dy,
          anchor.dx + width,
          anchor.dy + height,
        );
        break;
    }

    rect = Rect.fromLTRB(
      rect.left.clamp(0.0, 1.0),
      rect.top.clamp(0.0, 1.0),
      rect.right.clamp(0.0, 1.0),
      rect.bottom.clamp(0.0, 1.0),
    );

    final shiftX = rect.left < 0
        ? -rect.left
        : rect.right > 1.0
        ? 1.0 - rect.right
        : 0.0;
    final shiftY = rect.top < 0
        ? -rect.top
        : rect.bottom > 1.0
        ? 1.0 - rect.bottom
        : 0.0;

    return rect.shift(Offset(shiftX, shiftY));
  }

  Rect _resizeFreeformRect(Rect start, _CropHandle handle, Offset deltaNorm) {
    var left = start.left;
    var right = start.right;
    var top = start.top;
    var bottom = start.bottom;

    switch (handle) {
      case _CropHandle.left:
        left += deltaNorm.dx;
        break;
      case _CropHandle.right:
        right += deltaNorm.dx;
        break;
      case _CropHandle.top:
        top += deltaNorm.dy;
        break;
      case _CropHandle.bottom:
        bottom += deltaNorm.dy;
        break;
      case _CropHandle.topLeft:
        left += deltaNorm.dx;
        top += deltaNorm.dy;
        break;
      case _CropHandle.topRight:
        right += deltaNorm.dx;
        top += deltaNorm.dy;
        break;
      case _CropHandle.bottomLeft:
        left += deltaNorm.dx;
        bottom += deltaNorm.dy;
        break;
      case _CropHandle.bottomRight:
        right += deltaNorm.dx;
        bottom += deltaNorm.dy;
        break;
    }

    final minSize = 0.08;
    var rect = Rect.fromLTRB(left, top, right, bottom);
    if (rect.width < minSize) {
      final centerX = rect.center.dx;
      rect = Rect.fromLTRB(
        centerX - minSize / 2,
        rect.top,
        centerX + minSize / 2,
        rect.bottom,
      );
    }
    if (rect.height < minSize) {
      final centerY = rect.center.dy;
      rect = Rect.fromLTRB(
        rect.left,
        centerY - minSize / 2,
        rect.right,
        centerY + minSize / 2,
      );
    }

    rect = Rect.fromLTRB(
      rect.left.clamp(0.0, 1.0),
      rect.top.clamp(0.0, 1.0),
      rect.right.clamp(0.0, 1.0),
      rect.bottom.clamp(0.0, 1.0),
    );

    return rect;
  }

  void _onCropGestureStart(ScaleStartDetails details, Rect displayBox) {
    _pushUndoCheckpoint();
    final normalized = _normalizedCropRect();
    final cropRect = _displayRectForNormalized(normalized, displayBox.size);
    final handle = _hitTestHandle(details.localFocalPoint, cropRect);
    final mode = (handle != null)
        ? _CropDragMode.handle
        : _CropDragMode.moveScale;

    _cropGestureState = _CropGestureState(
      center: _cropCenter,
      scale: _cropScale,
      focalPoint: details.localFocalPoint,
      displaySize: displayBox.size,
      mode: mode,
      handle: handle,
      startRect: normalized,
    );
  }

  void _onCropGestureUpdate(ScaleUpdateDetails details) {
    final state = _cropGestureState;
    if (state == null) return;

    final delta = details.localFocalPoint - state.focalPoint;
    final dx = delta.dx / state.displaySize.width;
    final dy = delta.dy / state.displaySize.height;

    if (state.mode == _CropDragMode.handle && state.handle != null) {
      final nextRect = _resizeCropRect(
        state.startRect,
        state.handle!,
        Offset(dx, dy),
      );
      setState(() {
        if (_isFreeformCrop) {
          _freeformCropRect = nextRect;
        } else {
          _applyCropRect(nextRect);
        }
      });
    } else if (_isFreeformCrop) {
      final scaled = _scaleRectAroundCenter(
        state.startRect,
        details.scale.clamp(0.7, 1.3),
      );
      final moved = scaled.shift(Offset(dx, dy));
      setState(() {
        _freeformCropRect = _clampRectToBounds(moved);
      });
    } else {
      final nextScale = (state.scale * details.scale).clamp(_minCropScale, 1.0);
      final nextCenter = _clampCropCenter(
        Offset(state.center.dx + dx, state.center.dy + dy),
        nextScale,
      );

      setState(() {
        _cropScale = nextScale;
        _cropCenter = nextCenter;
      });
    }

    _dragDebounce?.cancel();
  }

  void _onCropGestureEnd() {
    _cropGestureState = null;
    _dragDebounce?.cancel();
    _schedulePreviewRebuild(_PreviewQuality.high, immediate: true);
  }

  Rect _scaleRectAroundCenter(Rect rect, double scale) {
    final center = rect.center;
    final w = (rect.width * scale).clamp(0.08, 1.0);
    final h = (rect.height * scale).clamp(0.08, 1.0);
    return Rect.fromCenter(center: center, width: w, height: h);
  }

  Rect _clampRectToBounds(Rect rect) {
    final left = rect.left.clamp(0.0, 1.0 - rect.width);
    final top = rect.top.clamp(0.0, 1.0 - rect.height);
    return Rect.fromLTWH(left, top, rect.width, rect.height);
  }

  void _applyRegistryPreset(LumaPreset preset) {
    HapticFeedback.selectionClick();
    _pushUndoCheckpoint();
    setState(() {
      _activePresetId = preset.id;
      _activePresetName = preset.name;
      _activePresetValues = Map<String, double>.from(preset.values);
      _presetIntensityRaw = _defaultPresetIntensity;
      _tabIndex = 1;
      _presetStage = PresetStage.active;
    });
    _schedulePreviewRebuild(_PreviewQuality.high, immediate: true);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Applied: ${preset.name}')));
  }

  void _applySavedPreset(_Preset preset) {
    HapticFeedback.selectionClick();
    _pushUndoCheckpoint();
    setState(() {
      _activePresetId = 'saved:${preset.name}';
      _activePresetName = preset.name;
      _activePresetValues = Map<String, double>.from(preset.values);
      _presetIntensityRaw = _defaultPresetIntensity;
      _tabIndex = 1;
      _presetStage = PresetStage.active;
    });
    _schedulePreviewRebuild(_PreviewQuality.high, immediate: true);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Applied: ${preset.name}')));
  }

  void _applyAuto() async {
    HapticFeedback.selectionClick();

    final src = _originalBytes;
    if (src == null) return;

    final decoded = img.decodeImage(src);
    if (decoded == null) return;

    final small = _resizeForPreview(decoded, maxSide: 520);

    double sum = 0;
    double sumSq = 0;
    int n = 0;

    for (int y = 0; y < small.height; y += 2) {
      for (int x = 0; x < small.width; x += 2) {
        final p = small.getPixel(x, y);
        final r = p.r.toDouble();
        final g = p.g.toDouble();
        final b = p.b.toDouble();
        final lum = (0.2126 * r + 0.7152 * g + 0.0722 * b) / 255.0;
        sum += lum;
        sumSq += lum * lum;
        n++;
      }
    }

    final mean = (n == 0) ? 0.5 : (sum / n);
    final varr = (n == 0) ? 0.05 : (sumSq / n - mean * mean);
    final std = math.sqrt(varr.clamp(0.0001, 1.0));

    final targetMean = 0.52;
    final targetStd = 0.22;

    final exposure = ((targetMean - mean) * 1.2).clamp(-0.6, 0.6);
    final contrast = ((targetStd - std) * 1.6).clamp(-0.5, 0.5);

    _pushUndoCheckpoint();
    setState(() {
      _values['exposure'] = exposure;
      _values['contrast'] = contrast;
      _values['vibrance'] = 0.12;
      _values['highlights'] = -0.10;
      _values['shadows'] = 0.12;
    });

    _schedulePreviewRebuild(_PreviewQuality.high, immediate: true);
  }

  img.Image _resizeForPreview(img.Image input, {required int maxSide}) {
    final w = input.width;
    final h = input.height;
    final maxDim = math.max(w, h);
    if (maxDim <= maxSide) return input;

    final scale = maxSide / maxDim;
    final nw = (w * scale).round();
    final nh = (h * scale).round();

    return img.copyResize(
      input,
      width: nw,
      height: nh,
      interpolation: img.Interpolation.cubic,
    );
  }

  Future<void> _exportToPhotos() async {
    final perm = await PhotoManager.requestPermissionExtend();
    if (!perm.isAuth && !perm.hasAccess) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Need Photos permission to save')),
      );
      return;
    }

    try {
      final effectiveValues = _effectiveValues();
      await NativeRenderer.exportFullRes(
        assetId: widget.assetId,
        values: Map<String, double>.from(effectiveValues),
        quality: 0.92,
        cropAspect: _cropAspect,
        rotationTurns: _rotateQuarterTurns,
        straightenDegrees: _straightenDegrees,
        cropRect: _normalizedCropRect(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Saved to Photos')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Save failed: $e')));
    }
  }

  Future<void> _saveAsPresetFlow() async {
    final controller = TextEditingController();

    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save as preset'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Preset name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final v = controller.text.trim();
              if (v.isEmpty) return;
              Navigator.of(context).pop(v);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (name == null) return;

    _pushUndoCheckpoint();
    setState(() {
      _presets.add(
        _Preset(name: name, values: Map<String, double>.from(_values)),
      );
      _activePresetName = name;
    });

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Saved preset: $name')));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: _canvas,
        body: SafeArea(
          child: Center(child: CircularProgressIndicator(color: _accent)),
        ),
      );
    }

    if (_originalBytes == null) {
      return const Scaffold(
        backgroundColor: _canvas,
        body: SafeArea(
          child: Center(
            child: Text(
              'Could not load image',
              style: TextStyle(color: _muted),
            ),
          ),
        ),
      );
    }

    final tool = _activeTool;
    final toolValue = _v(tool.id);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: _canvas,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: _canvas,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 10,
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.of(context).maybePop(),
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 8,
                            ),
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: _muted,
                              ),
                            ),
                          ),
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            IconButton(
                              onPressed: _canUndo ? _undo : null,
                              icon: const Icon(Icons.undo),
                              color: _ink,
                              disabledColor: _muted,
                            ),
                            IconButton(
                              onPressed: _canRedo ? _redo : null,
                              icon: const Icon(Icons.redo),
                              color: _ink,
                              disabledColor: _muted,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Edit',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.2,
                                color: _ink,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: _exportToPhotos,
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 8,
                            ),
                            child: Text(
                              'Save',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.2,
                                color: _ink,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Divider(height: 10, color: _ink.withAlpha(24)),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.52,
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final previewAspect = _isCropMode
                            ? _imageAspect
                            : _croppedAspect;
                        final maxWidth = constraints.maxWidth;
                        final maxHeight = constraints.maxHeight.isFinite
                            ? constraints.maxHeight
                            : maxWidth / previewAspect;
                        final width = math.min(
                          maxWidth,
                          maxHeight * previewAspect,
                        );
                        final height = width / previewAspect;
                        final displayBox = Offset.zero & Size(width, height);
                        final frontProvider =
                            _frontPreview ??
                            (_originalBytes != null
                                ? MemoryImage(_originalBytes!)
                                : null);
                        final backProvider = _backPreview;

                        return Container(
                          width: width,
                          height: height,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x0A000000),
                                blurRadius: 16,
                                offset: Offset(0, 6),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Stack(
                              children: [
                                Positioned.fromRect(
                                  rect: displayBox,
                                  child: ClipRect(
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        if (frontProvider != null)
                                          Image(
                                            image: frontProvider,
                                            fit: BoxFit.cover,
                                            gaplessPlayback: true,
                                          ),
                                        if (backProvider != null)
                                          AnimatedOpacity(
                                            opacity: _showBackPreview
                                                ? 1.0
                                                : 0.0,
                                            duration: _previewFadeDuration,
                                            curve: Curves.easeOut,
                                            onEnd: () {
                                              if (_showBackPreview &&
                                                  _backPreview != null) {
                                                _promoteBackPreview();
                                              }
                                            },
                                            child: Image(
                                              image: backProvider,
                                              fit: BoxFit.cover,
                                              gaplessPlayback: true,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                                if (_isCropMode)
                                  Positioned.fromRect(
                                    rect: displayBox,
                                    child: GestureDetector(
                                      behavior: HitTestBehavior.opaque,
                                      onScaleStart: (d) =>
                                          _onCropGestureStart(d, displayBox),
                                      onScaleUpdate: _onCropGestureUpdate,
                                      onScaleEnd: (_) => _onCropGestureEnd(),
                                      child: SizedBox.expand(
                                        child: CustomPaint(
                                          painter: _CropOverlayPainter(
                                            _normalizedCropRect(),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                if (_buildingHQ)
                                  Positioned(
                                    right: 10,
                                    top: 10,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _panelHighlight.withAlpha(
                                          (0.9 * 255).round(),
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Text(
                                        'Updating',
                                        style: TextStyle(
                                          color: _ink,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                    child: Container(
                      decoration: BoxDecoration(
                        color: _panel.withAlpha((0.96 * 255).round()),
                        border: Border(
                          top: BorderSide(color: _ink.withAlpha(20)),
                        ),
                      ),
                      child: Column(
                        children: [
                          const SizedBox(height: 10),
                          _buildEditPresetsToggle(),
                          const SizedBox(height: 12),
                          Expanded(
                            child: _tabIndex == 0
                                ? _buildEditTab(tool, toolValue)
                                : _buildPresetsTab(),
                          ),
                        ],
                      ),
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

  Widget _buildEditPresetsToggle() {
    return Center(
      child: Container(
        width: 240,
        height: 34,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: _panel,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _ink.withAlpha(18)),
        ),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _tabIndex = 0),
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _tabIndex == 0
                        ? _panelHighlight
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: _tabIndex == 0
                        ? Border.all(color: _accent.withAlpha(120))
                        : null,
                  ),
                  child: Text(
                    'Edit',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: _tabIndex == 0
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: _tabIndex == 0 ? _ink : _muted,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _tabIndex = 1),
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _tabIndex == 1
                        ? _panelHighlight
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: _tabIndex == 1
                        ? Border.all(color: _accent.withAlpha(120))
                        : null,
                  ),
                  child: Text(
                    'Presets',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: _tabIndex == 1
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: _tabIndex == 1 ? _ink : _muted,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditTab(_ToolItem tool, double toolValue) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 18),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(child: _buildAdjustmentPickerPill()),
              const SizedBox(width: 10),
              _buildCropEntryButton(),
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (_isCropMode) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _CropAspectSelector(
              current: _cropAspect,
              isFreeform: _isFreeformCrop,
              onSelect: _setCropOption,
              activeColor: _panelHighlight,
              inactiveColor: _panel,
              activeTextColor: _ink,
              inactiveTextColor: _muted,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                TextButton(
                  onPressed: _cancelCropMode,
                  style: TextButton.styleFrom(foregroundColor: _muted),
                  child: const Text('Cancel'),
                ),
                const Spacer(),
                TextButton(
                  onPressed: _exitCropMode,
                  style: TextButton.styleFrom(foregroundColor: _muted),
                  child: const Text('Done'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                OutlinedButton(
                  onPressed: _rotate90,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _ink,
                    backgroundColor: _panel,
                    side: BorderSide(color: _ink.withAlpha(22)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Rotate 90'),
                ),
                const Spacer(),
                Text(
                  'Drag to crop',
                  style: TextStyle(fontSize: 11, color: _muted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  _toolsById['straighten']?.label ?? 'Straighten',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                    color: _ink,
                  ),
                ),
                const Spacer(),
                Text(
                  '${_displayNumber(_toolsById['straighten']!)}',
                  style: TextStyle(fontSize: 12, color: _muted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildToolControl(
              _toolsById['straighten']!,
              _v('straighten'),
            ),
          ),
          const SizedBox(height: 10),
        ] else if (!_isCropMode) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  tool.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                    color: _ink,
                  ),
                ),
                const Spacer(),
                if (tool.kind == ToolKind.slider)
                  Text(
                    '${_displayNumber(tool)}',
                    style: TextStyle(fontSize: 12, color: _muted),
                  )
                else if (tool.kind == ToolKind.toggle)
                  Text(
                    _v(tool.id) >= 0.5 ? 'On' : 'Off',
                    style: TextStyle(fontSize: 12, color: _muted),
                  )
                else
                  const SizedBox.shrink(),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildToolControl(tool, toolValue),
          ),
          const SizedBox(height: 10),
        ],
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              TextButton(
                onPressed: _saveAsPresetFlow,
                style: TextButton.styleFrom(foregroundColor: _accent),
                child: const Text('Save', style: TextStyle(letterSpacing: 0.3)),
              ),
              const Spacer(),
              Text(
                'Saved: ${_presets.length}',
                style: TextStyle(fontSize: 11, color: _muted),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAdjustmentPickerPill() {
    return GestureDetector(
      onTap: _showAdjustmentPicker,
      child: Container(
        key: _adjustmentPillKey,
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: _panelHighlight.withAlpha((0.6 * 255).round()),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Text(
              _isCropMode ? 'Crop' : _activeTool.label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
                color: _ink.withAlpha((0.85 * 255).round()),
              ),
            ),
            const Spacer(),
            Icon(Icons.expand_more, size: 18, color: _muted),
          ],
        ),
      ),
    );
  }

  Widget _buildCropEntryButton() {
    return GestureDetector(
      onTap: _enterCropMode,
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: _panel,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _ink.withAlpha(20)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.crop, size: 16, color: _muted),
            const SizedBox(width: 6),
            Text(
              'Crop',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
                color: _ink.withAlpha((0.8 * 255).round()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _enterCropMode() {
    if (_isCropMode) return;
    final cropIndex = _allAdjustmentIds.indexOf('straighten');
    if (cropIndex < 0) return;
    setState(() {
      _cropSnapshot ??= _CropSnapshot(
        cropAspect: _cropAspect,
        isFreeform: _isFreeformCrop,
        cropCenter: _cropCenter,
        cropScale: _cropScale,
        freeformCropRect: _freeformCropRect,
        rotateQuarterTurns: _rotateQuarterTurns,
      );
      _preCropToolIndex = _toolIndex;
      _toolIndex = cropIndex;
      _isCropMode = true;
    });
  }

  void _exitCropMode() {
    if (!_isCropMode) return;
    setState(() {
      _isCropMode = false;
      if (_preCropToolIndex != null) {
        _toolIndex = _preCropToolIndex!;
      }
      _preCropToolIndex = null;
      _cropSnapshot = null;
    });
    _schedulePreviewRebuild(_PreviewQuality.high, immediate: true);
  }

  void _cancelCropMode() {
    if (!_isCropMode) return;
    final snapshot = _cropSnapshot;
    setState(() {
      if (snapshot != null) {
        _cropAspect = snapshot.cropAspect;
        _isFreeformCrop = snapshot.isFreeform;
        _cropCenter = snapshot.cropCenter;
        _cropScale = snapshot.cropScale;
        _freeformCropRect = snapshot.freeformCropRect;
        _rotateQuarterTurns = snapshot.rotateQuarterTurns;
      }
      _isCropMode = false;
      if (_preCropToolIndex != null) {
        _toolIndex = _preCropToolIndex!;
      }
      _preCropToolIndex = null;
      _cropSnapshot = null;
    });
    _schedulePreviewRebuild(_PreviewQuality.high, immediate: true);
  }

  void _setActiveToolId(String id) {
    final nextIndex = _allAdjustmentIds.indexOf(id);
    if (nextIndex < 0) return;
    setState(() {
      _toolIndex = nextIndex;
      _isCropMode = false;
      _preCropToolIndex = null;
    });
  }

  Future<void> _showAdjustmentPicker() {
    final baseColor = const Color(0xFF0B0B0B);
    final surfaceOpacity = 0.82;
    final selectedOpacity = 0.08;
    final blurSigma = 12.0;
    final primaryText = Colors.white.withValues(alpha: 0.9);
    final secondaryText = Colors.white.withValues(alpha: 0.6);
    final sectionText = Colors.white.withValues(alpha: 0.45);

    final box =
        _adjustmentPillKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return Future.value();
    final pillTopLeft = box.localToGlobal(Offset.zero);
    final pillRect = pillTopLeft & box.size;
    final media = MediaQuery.of(context);
    final screen = media.size;
    const sidePadding = 12.0;
    const gap = 10.0;
    const rowHeight = 48.0;
    const rowGap = 4.0;
    const headerHeight = 22.0;
    final quickCount = _quickAdjustments.length;
    final quickHeight =
        quickCount * rowHeight + (math.max(quickCount - 1, 0) * rowGap);
    final menuHeight = 10 + headerHeight + 8 + quickHeight + 4 + rowHeight + 10;
    final width = box.size.width.clamp(260.0, 320.0);
    final left = (pillRect.center.dx - width / 2).clamp(
      sidePadding,
      screen.width - sidePadding - width,
    );

    final availableAbove = pillRect.top - gap - media.padding.top;
    final availableBelow =
        screen.height - pillRect.bottom - gap - media.padding.bottom;
    final openAbove =
        availableAbove >= menuHeight || availableAbove > availableBelow;
    final top = openAbove
        ? (pillRect.top - gap - menuHeight).clamp(
            media.padding.top + sidePadding,
            screen.height - media.padding.bottom - menuHeight,
          )
        : (pillRect.bottom + gap).clamp(
            media.padding.top + sidePadding,
            screen.height - media.padding.bottom - menuHeight,
          );

    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 120),
      pageBuilder: (context, _, _) {
        return Stack(
          children: [
            Positioned(
              left: left,
              top: top,
              width: width,
              child: Material(
                color: Colors.transparent,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(
                      sigmaX: blurSigma,
                      sigmaY: blurSigma,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: baseColor.withValues(alpha: surfaceOpacity),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.25),
                            blurRadius: 28,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 2, 16, 8),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Quick',
                                style: TextStyle(
                                  fontSize: 11,
                                  letterSpacing: 0.6,
                                  color: sectionText,
                                ),
                              ),
                            ),
                          ),
                          for (final tool in _quickAdjustments) ...[
                            _buildAdjustmentRow(
                              tool,
                              highlightColor: baseColor.withValues(
                                alpha: selectedOpacity,
                              ),
                              primaryText: primaryText,
                              secondaryText: secondaryText,
                            ),
                            const SizedBox(height: rowGap),
                          ],
                          const SizedBox(height: 4),
                          _buildAllToolsRow(
                            highlightColor: baseColor.withValues(
                              alpha: selectedOpacity,
                            ),
                            primaryText: primaryText,
                            secondaryText: secondaryText,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
      transitionBuilder: (context, animation, _, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOut,
        );
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.98, end: 1.0).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  Widget _buildAdjustmentRow(
    _ToolItem tool, {
    required Color highlightColor,
    required Color primaryText,
    required Color secondaryText,
  }) {
    final isSelected = tool.id == _activeAdjustmentId;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        _setActiveToolId(tool.id);
        Navigator.of(context).pop();
      },
      child: Container(
        height: 48,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? highlightColor : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Text(
              tool.label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                letterSpacing: 0.2,
                color: primaryText,
              ),
            ),
            const Spacer(),
            if (tool.kind == ToolKind.slider)
              Text(
                '${_displayNumber(tool)}',
                style: TextStyle(fontSize: 12, color: secondaryText),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAllToolsRow({
    required Color highlightColor,
    required Color primaryText,
    required Color secondaryText,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        Navigator.of(context).pop();
        Future.microtask(_showAllToolsPicker);
      },
      child: Container(
        height: 48,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Text(
              'All tools',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
                color: primaryText,
              ),
            ),
            const Spacer(),
            Text(
              '${_allAdjustmentTools.length}',
              style: TextStyle(fontSize: 12, color: secondaryText),
            ),
            const SizedBox(width: 6),
            Icon(Icons.chevron_right, size: 18, color: secondaryText),
          ],
        ),
      ),
    );
  }

  Future<void> _showAllToolsPicker() {
    final primaryText = Colors.white.withValues(alpha: 0.9);
    final secondaryText = Colors.white.withValues(alpha: 0.6);
    final sectionText = Colors.white.withValues(alpha: 0.45);
    final highlightColor = Colors.white.withValues(alpha: 0.08);

    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (context) {
          return Scaffold(
            backgroundColor: _canvas,
            body: SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                    child: Row(
                      children: [
                        Text(
                          'All tools',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                            color: primaryText,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: Icon(Icons.close, color: secondaryText),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                      children: [
                        for (final group in _groups)
                          if (group.label != 'Crop') ...[
                            Padding(
                              padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
                              child: Text(
                                group.label,
                                style: TextStyle(
                                  fontSize: 11,
                                  letterSpacing: 0.6,
                                  color: sectionText,
                                ),
                              ),
                            ),
                            for (final tool in group.tools) ...[
                              _buildAdjustmentRow(
                                tool,
                                highlightColor: highlightColor,
                                primaryText: primaryText,
                                secondaryText: secondaryText,
                              ),
                              const SizedBox(height: 4),
                            ],
                          ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _applySliderValue(String id, double value, _PreviewQuality quality) {
    _values[id] = value;
    _schedulePreviewRebuild(quality, immediate: true);
  }

  void _applyPresetIntensity(double value, _PreviewQuality quality) {
    setState(() {
      _presetIntensityRaw = value.clamp(0.0, 1.0);
    });
    _schedulePreviewRebuild(quality, immediate: true);
  }

  Widget _buildToolControl(_ToolItem tool, double toolValue) {
    if (tool.kind == ToolKind.action) {
      final (label, action) = switch (tool.id) {
        'auto' => ('Balance', _applyAuto),
        'rotate_90' => ('Rotate 90', _rotate90),
        _ => ('Run', _applyAuto),
      };
      return SizedBox(
        height: 44,
        child: OutlinedButton(
          onPressed: action,
          style: OutlinedButton.styleFrom(
            backgroundColor: _panel,
            foregroundColor: _ink,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            side: BorderSide(color: _ink.withAlpha(24)),
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
            ),
          ),
        ),
      );
    }

    if (tool.kind == ToolKind.toggle) {
      final isOn = _v(tool.id) >= 0.5;
      return SizedBox(
        height: 44,
        child: GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            _pushUndoCheckpoint();
            setState(() {
              _values[tool.id] = isOn ? 0.0 : 1.0;
            });
            _schedulePreviewRebuild(_PreviewQuality.high, immediate: true);
          },
          child: Container(
            decoration: BoxDecoration(
              color: isOn ? _panelHighlight : _panel,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _ink.withAlpha(22)),
            ),
            alignment: Alignment.center,
            child: Text(
              isOn ? 'On' : 'Off',
              style: TextStyle(
                color: isOn ? _ink : _muted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      );
    }

    return GestureDetector(
      onDoubleTap: _resetActiveTool,
      child: SliderTheme(
        data: SliderTheme.of(context).copyWith(
          activeTrackColor: _accent,
          inactiveTrackColor: _panelHighlight,
          thumbColor: _accent,
          overlayColor: _accent.withAlpha((0.10 * 255).round()),
        ),
        child: _LiveSlider(
          value: toolValue,
          min: tool.min,
          max: tool.max,
          onChangeStart: () {
            _isDragging = true;
            _dragToolId = tool.id;
            _dragPreviewThrottler.cancel();
            _clearPendingDragRequest();
            _pushUndoCheckpoint();
          },
          onChanged: (v) {
            _dragPreviewThrottler.schedule(() {
              if (!mounted) return;
              _requestDragPreviewRender(tool.id, v);
            });
          },
          onChangeEnd: (v) {
            _isDragging = false;
            _dragToolId = null;
            _dragPreviewThrottler.cancel();
            _clearPendingDragRequest();
            _applySliderValue(tool.id, v, _PreviewQuality.high);
          },
        ),
      ),
    );
  }

  Widget _buildPresetIntensityControl() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Intensity',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
            color: _muted,
          ),
        ),
        const SizedBox(height: 6),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: _accent,
            inactiveTrackColor: _panelHighlight,
            thumbColor: _accent,
            overlayColor: _accent.withAlpha((0.10 * 255).round()),
          ),
          child: _LiveSlider(
            value: _presetIntensityRaw,
            min: 0,
            max: 1,
            onChangeStart: () {
              _isDragging = true;
              _dragToolId = _presetIntensityToolId;
              _dragPreviewThrottler.cancel();
              _clearPendingDragRequest();
              _pushUndoCheckpoint();
            },
            onChanged: (v) {
              _dragPreviewThrottler.schedule(() {
                if (!mounted) return;
                _requestDragPreviewRender(_presetIntensityToolId, v);
              });
            },
            onChangeEnd: (v) {
              _isDragging = false;
              _dragToolId = null;
              _dragPreviewThrottler.cancel();
              _clearPendingDragRequest();
              _applyPresetIntensity(v, _PreviewQuality.high);
            },
          ),
        ),
      ],
    );
  }

  LumaPresetPack? _findPresetPack(String id) {
    for (final pack in PresetRegistry.packs) {
      if (pack.id == id) return pack;
    }
    return null;
  }

  Widget _buildPresetCategoryTile({
    required String title,
    required String subtitle,
    required int count,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _panel,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _panelHighlight),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                        color: _ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 12, color: _muted),
                    ),
                  ],
                ),
              ),
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPresetCategoriesView() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        Text(
          'Categories',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
            color: _muted,
          ),
        ),
        const SizedBox(height: 10),
        for (final pack in PresetRegistry.packs) ...[
          _buildPresetCategoryTile(
            title: pack.name,
            subtitle: pack.description,
            count: pack.presetIds.length,
            onTap: () => _selectPresetCategory(pack.id),
          ),
          const SizedBox(height: 10),
        ],
        if (_presets.isNotEmpty) ...[
          _buildPresetCategoryTile(
            title: 'Saved',
            subtitle: 'Your custom presets.',
            count: _presets.length,
            onTap: () => _selectPresetCategory(_savedCategoryId),
          ),
        ],
      ],
    );
  }

  Widget _buildPresetListView() {
    final selectedId = _selectedCategoryId;
    if (selectedId == null) return _buildPresetCategoriesView();

    final isSaved = selectedId == _savedCategoryId;
    final pack = isSaved ? null : _findPresetPack(selectedId);
    if (!isSaved && pack == null) return _buildPresetCategoriesView();

    final title = isSaved ? 'Saved' : pack!.name;
    final subtitle = isSaved ? 'Your custom presets.' : pack!.description;
    final fallbackBytes = _previewBytes ?? _originalBytes!;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Row(
          children: [
            IconButton(
              onPressed: () {
                setState(() => _presetStage = PresetStage.categories);
              },
              icon: Icon(Icons.arrow_back, color: _muted),
              splashRadius: 18,
            ),
            const SizedBox(width: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
                color: _ink,
              ),
            ),
          ],
        ),
        if (subtitle.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 48, right: 8, bottom: 8),
            child: Text(subtitle, style: TextStyle(fontSize: 12, color: _muted)),
          ),
        const SizedBox(height: 8),
        if (isSaved) ...[
          if (_presets.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 20),
              child: Text(
                'No presets yet.\nSave one from the Edit tab.',
                textAlign: TextAlign.center,
                style: TextStyle(color: _muted),
              ),
            )
          else
            ..._presets.map((p) {
              final selected = _activePresetId == 'saved:${p.name}';
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _PresetCard(
                  preset: p,
                  selected: selected,
                  ink: _ink,
                  muted: _muted,
                  panel: _panel,
                  panelHighlight: _panelHighlight,
                  accent: _accent,
                  onApply: () => _selectSavedPreset(p),
                ),
              );
            }),
        ] else ...[
          SizedBox(
            height: 170,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: pack!.presetIds.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, i) {
                final p = PresetRegistry.byId(pack.presetIds[i]);
                return _RegistryPresetTile(
                  preset: p,
                  selected: _activePresetId == p.id,
                  accent: _accent,
                  ink: _ink,
                  muted: _muted,
                  panel: _panel,
                  panelHighlight: _panelHighlight,
                  fallbackBytes: fallbackBytes,
                  previewFuture: _getPresetPreviewBytes(p.name, p.values),
                  onApply: () => _selectRegistryPreset(p),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPresetActiveView() {
    final name = _activePresetName ?? 'Preset';

    return LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox(
          height: constraints.maxHeight,
          child: Column(
            children: [
              const Spacer(),
              Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                decoration: BoxDecoration(
                  color: _panel,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _panelHighlight),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                        color: _ink,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildPresetIntensityControl(),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _cancelPresetSelection,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _muted,
                              side: BorderSide(color: _panelHighlight),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: _finishPresetSelection,
                            style: FilledButton.styleFrom(
                              backgroundColor: _accent,
                              foregroundColor: _canvas,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Done'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPresetsTab() {
    final stage =
        (_presetStage == PresetStage.active && _activePresetValues == null)
            ? PresetStage.categories
            : _presetStage;

    switch (stage) {
      case PresetStage.categories:
        return _buildPresetCategoriesView();
      case PresetStage.list:
        return _buildPresetListView();
      case PresetStage.active:
        return _buildPresetActiveView();
    }
  }
}

class _RegistryPresetTile extends StatelessWidget {
  final LumaPreset preset;
  final VoidCallback onApply;
  final bool selected;
  final Future<Uint8List> previewFuture;
  final Uint8List fallbackBytes;
  final Color accent;
  final Color ink;
  final Color muted;
  final Color panel;
  final Color panelHighlight;

  const _RegistryPresetTile({
    required this.preset,
    required this.onApply,
    required this.selected,
    required this.previewFuture,
    required this.fallbackBytes,
    required this.accent,
    required this.ink,
    required this.muted,
    required this.panel,
    required this.panelHighlight,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onApply,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          width: 180,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: selected ? panelHighlight : panel,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? accent : panelHighlight.withAlpha(200),
              width: selected ? 1.5 : 1,
            ),
            boxShadow: const [
              BoxShadow(
                blurRadius: 16,
                offset: Offset(0, 8),
                color: Color(0x24000000),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  height: 90,
                  width: double.infinity,
                  child: FutureBuilder<Uint8List>(
                    future: previewFuture,
                    builder: (context, snap) {
                      final bytes = snap.data ?? fallbackBytes;
                      return Image.memory(bytes, fit: BoxFit.cover);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                preset.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                  color: ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Preset {
  final String name;
  final Map<String, double> values;
  const _Preset({required this.name, required this.values});
}

class _PresetCard extends StatelessWidget {
  final _Preset preset;
  final VoidCallback onApply;
  final bool selected;
  final Color ink;
  final Color muted;
  final Color panel;
  final Color panelHighlight;
  final Color accent;

  const _PresetCard({
    required this.preset,
    required this.onApply,
    required this.selected,
    required this.ink,
    required this.muted,
    required this.panel,
    required this.panelHighlight,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onApply,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: selected ? panelHighlight : panel,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? accent : const Color(0x00000000),
              width: selected ? 1.1 : 0,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  preset.name,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                    color: ink,
                  ),
                ),
              ),
              Icon(Icons.check, size: 18, color: muted),
            ],
          ),
        ),
      ),
    );
  }
}

enum ToolKind { slider, toggle, action }

class _ToolGroup {
  final String label;
  final List<_ToolItem> tools;
  _ToolGroup({required this.label, required this.tools});
}

class _ToolItem {
  final String id;
  final String label;
  final double min;
  final double max;
  final double defaultValue;
  final ToolKind kind;

  const _ToolItem({
    required this.id,
    required this.label,
    this.min = -1,
    this.max = 1,
    this.defaultValue = 0,
    this.kind = ToolKind.slider,
  });
}

class _LiveSlider extends StatefulWidget {
  const _LiveSlider({
    required this.value,
    required this.min,
    required this.max,
    required this.onChangeStart,
    required this.onChanged,
    required this.onChangeEnd,
  });

  final double value;
  final double min;
  final double max;
  final VoidCallback onChangeStart;
  final ValueChanged<double> onChanged;
  final ValueChanged<double> onChangeEnd;

  @override
  State<_LiveSlider> createState() => _LiveSliderState();
}

class _LiveSliderState extends State<_LiveSlider> {
  late double _dragValue;
  bool _dragging = false;

  @override
  void initState() {
    super.initState();
    _dragValue = widget.value;
  }

  @override
  void didUpdateWidget(covariant _LiveSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_dragging) {
      _dragValue = widget.value;
    }
  }

  @override
  Widget build(BuildContext context) {
    final value = _dragValue.clamp(widget.min, widget.max);
    return Slider(
      value: value,
      min: widget.min,
      max: widget.max,
      onChangeStart: (_) {
        setState(() => _dragging = true);
        widget.onChangeStart();
      },
      onChanged: (v) {
        setState(() => _dragValue = v);
        widget.onChanged(v);
      },
      onChangeEnd: (v) {
        setState(() {
          _dragValue = v;
          _dragging = false;
        });
        widget.onChangeEnd(v);
      },
    );
  }
}

class _Throttler {
  _Throttler({required this.interval});

  final Duration interval;
  Timer? _timer;
  VoidCallback? _pending;

  void schedule(VoidCallback fn) {
    _pending = fn;
    if (_timer?.isActive ?? false) return;
    _timer = Timer(interval, _run);
  }

  void _run() {
    final pending = _pending;
    _pending = null;
    _timer = null;
    if (pending != null) {
      pending();
    }
  }

  void flush() {
    _timer?.cancel();
    _timer = null;
    final pending = _pending;
    _pending = null;
    if (pending != null) {
      pending();
    }
  }

  void cancel() {
    _timer?.cancel();
    _timer = null;
    _pending = null;
  }

  void dispose() {
    cancel();
  }
}

class _PresetSnapshot {
  final _HistoryState state;
  final PresetStage stage;
  final String? selectedCategoryId;
  final String? activePresetId;

  const _PresetSnapshot({
    required this.state,
    required this.stage,
    required this.selectedCategoryId,
    required this.activePresetId,
  });
}

class _HistoryState {
  final Map<String, double> values;
  final int tabIndex;
  final int groupIndex;
  final int toolIndex;
  final double imageAspect;
  final double? cropAspect;
  final int rotateQuarterTurns;
  final Offset cropCenter;
  final double cropScale;
  final bool isFreeformCrop;
  final Rect freeformCropRect;
  final String? activePresetName;
  final Map<String, double>? activePresetValues;
  final String? activePresetId;
  final double presetIntensityRaw;

  const _HistoryState({
    required this.values,
    required this.tabIndex,
    required this.groupIndex,
    required this.toolIndex,
    required this.imageAspect,
    required this.cropAspect,
    required this.rotateQuarterTurns,
    required this.cropCenter,
    required this.cropScale,
    required this.isFreeformCrop,
    required this.freeformCropRect,
    required this.activePresetName,
    required this.activePresetValues,
    required this.activePresetId,
    required this.presetIntensityRaw,
  });
}

class _CropSnapshot {
  final double? cropAspect;
  final bool isFreeform;
  final Offset cropCenter;
  final double cropScale;
  final Rect freeformCropRect;
  final int rotateQuarterTurns;

  const _CropSnapshot({
    required this.cropAspect,
    required this.isFreeform,
    required this.cropCenter,
    required this.cropScale,
    required this.freeformCropRect,
    required this.rotateQuarterTurns,
  });
}

class _CropAspectOption {
  final String label;
  final double? aspect;
  final bool isFreeform;

  const _CropAspectOption(this.label, this.aspect, {this.isFreeform = false});
}

class _CropAspectSelector extends StatelessWidget {
  final double? current;
  final bool isFreeform;
  final ValueChanged<_CropAspectOption> onSelect;
  final Color activeColor;
  final Color inactiveColor;
  final Color activeTextColor;
  final Color inactiveTextColor;

  const _CropAspectSelector({
    required this.current,
    required this.isFreeform,
    required this.onSelect,
    required this.activeColor,
    required this.inactiveColor,
    required this.activeTextColor,
    required this.inactiveTextColor,
  });

  @override
  Widget build(BuildContext context) {
    const options = [
      _CropAspectOption('Freeform', null, isFreeform: true),
      _CropAspectOption('Original', null),
      _CropAspectOption('Instagram Square', 1),
      _CropAspectOption('Instagram Feed', 4 / 5),
      _CropAspectOption('Reels/TikTok', 9 / 16),
      _CropAspectOption('YouTube', 16 / 9),
    ];

    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: options.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final opt = options[index];
          final selected = opt.isFreeform
              ? isFreeform
              : (current == null && opt.aspect == null && !isFreeform) ||
                    (current != null &&
                        opt.aspect != null &&
                        (current! - opt.aspect!).abs() < 0.0001);

          return GestureDetector(
            onTap: () => onSelect(opt),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? activeColor : inactiveColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                opt.label,
                style: TextStyle(
                  color: selected ? activeTextColor : inactiveTextColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CropOverlayPainter extends CustomPainter {
  final Rect normalizedRect;
  _CropOverlayPainter(this.normalizedRect);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(
      normalizedRect.left * size.width,
      normalizedRect.top * size.height,
      normalizedRect.width * size.width,
      normalizedRect.height * size.height,
    );

    final shade = Paint()
      ..color = Colors.black.withAlpha((0.35 * 255).round())
      ..style = PaintingStyle.fill;

    canvas.saveLayer(Offset.zero & size, Paint());
    canvas.drawRect(Offset.zero & size, shade);
    final clearPaint = Paint()
      ..blendMode = BlendMode.clear
      ..style = PaintingStyle.fill;
    canvas.drawRect(rect, clearPaint);
    canvas.restore();

    final border = Paint()
      ..color = Colors.white
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawRect(rect, border);

    final gridPaint = Paint()
      ..color = Colors.white.withAlpha((0.45 * 255).round())
      ..strokeWidth = 1.0;

    final thirdW = rect.width / 3;
    final thirdH = rect.height / 3;

    canvas.drawLine(
      Offset(rect.left + thirdW, rect.top),
      Offset(rect.left + thirdW, rect.bottom),
      gridPaint,
    );
    canvas.drawLine(
      Offset(rect.left + thirdW * 2, rect.top),
      Offset(rect.left + thirdW * 2, rect.bottom),
      gridPaint,
    );
    canvas.drawLine(
      Offset(rect.left, rect.top + thirdH),
      Offset(rect.right, rect.top + thirdH),
      gridPaint,
    );
    canvas.drawLine(
      Offset(rect.left, rect.top + thirdH * 2),
      Offset(rect.right, rect.top + thirdH * 2),
      gridPaint,
    );

    final handlePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    const handleRadius = 4.0;
    final handlePoints = [
      rect.topLeft,
      rect.topCenter,
      rect.topRight,
      rect.centerRight,
      rect.bottomRight,
      rect.bottomCenter,
      rect.bottomLeft,
      rect.centerLeft,
    ];
    for (final p in handlePoints) {
      canvas.drawCircle(p, handleRadius, handlePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _CropOverlayPainter oldDelegate) {
    return oldDelegate.normalizedRect != normalizedRect;
  }
}

class _CropGestureState {
  final Offset center;
  final double scale;
  final Offset focalPoint;
  final Size displaySize;
  final _CropDragMode mode;
  final _CropHandle? handle;
  final Rect startRect;

  _CropGestureState({
    required this.center,
    required this.scale,
    required this.focalPoint,
    required this.displaySize,
    required this.mode,
    required this.handle,
    required this.startRect,
  });
}

enum _CropDragMode { moveScale, handle }

enum _CropHandle {
  topLeft,
  top,
  topRight,
  right,
  bottomRight,
  bottom,
  bottomLeft,
  left,
}
