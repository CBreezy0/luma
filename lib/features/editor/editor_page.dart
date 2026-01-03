// lib/features/editor/editor_page.dart
//
// Luma Editor Page (Native Preview + Native Export)

import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image/image.dart' as img;
import 'package:photo_manager/photo_manager.dart';

import '../presets/preset_registry.dart' show LumaPreset, PresetRegistry;
import 'native/native_renderer.dart';

class EditorPage extends StatefulWidget {
  final String assetId;

  const EditorPage({super.key, required this.assetId});

  @override
  State<EditorPage> createState() => _EditorPageState();
}

enum _PreviewQuality { low, high }

class _EditorPageState extends State<EditorPage> {
  static const Color _accent = Color(0xFFB25B73);

  Uint8List? _originalBytes;
  Uint8List? _previewBytes;
  double _imageAspect = 4 / 5;
  bool _loading = true;

  bool _buildingPreview = false;
  bool _buildingHQ = false;
  _PreviewQuality? _pendingQuality;
  int _renderToken = 0;

  Timer? _dragDebounce;

  int _tabIndex = 0; // 0 Edit, 1 Presets
  int _groupIndex = 0;
  int _toolIndex = 0;

  String? _activePresetName;

  final Map<String, double> _values = {};
  final Map<String, double> _defaultValues = {};

  final List<_Preset> _presets = [];
  final List<_HistoryState> _undoStack = [];
  final List<_HistoryState> _redoStack = [];

  final Map<String, Uint8List> _presetPreviewCache = {};
  final Map<String, Future<Uint8List>> _presetPreviewFutures = {};

  bool get _canUndo => _undoStack.isNotEmpty;
  bool get _canRedo => _redoStack.isNotEmpty;

  late final List<_ToolGroup> _groups = [
    _ToolGroup(
      label: 'Light',
      tools: const [
        _ToolItem(id: 'auto', label: 'Auto', kind: ToolKind.action),
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
          label: 'Balance',
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
  ];

  _ToolGroup get _activeGroup => _groups[_groupIndex];
  _ToolItem get _activeTool => _activeGroup.tools[_toolIndex];

  @override
  void initState() {
    super.initState();
    _primeDefaults();
    _loadImage();
  }

  @override
  void dispose() {
    _dragDebounce?.cancel();
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
      activePresetName: _activePresetName,
    );
  }

  void _restoreState(_HistoryState s) {
    setState(() {
      _values
        ..clear()
        ..addAll(s.values);
      _tabIndex = s.tabIndex;
      _groupIndex = s.groupIndex;
      _toolIndex = s.toolIndex;
      _imageAspect = s.imageAspect;
      _activePresetName = s.activePresetName;
    });
    _schedulePreviewRebuild(_PreviewQuality.high, immediate: true);
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
      _imageAspect = aspect;
      _loading = false;
    });

    _pushUndoCheckpoint();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _schedulePreviewRebuild(_PreviewQuality.high, immediate: true);
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
    Future.delayed(Duration(milliseconds: delayMs), () {
      if (!mounted) return;
      unawaited(_rebuildPreview(quality));
    });
  }

  Future<void> _rebuildPreview(_PreviewQuality quality) async {
    if (_originalBytes == null) return;

    final int token = ++_renderToken;

    setState(() {
      _buildingPreview = true;
      if (quality == _PreviewQuality.high) _buildingHQ = true;
    });

    final maxSide = (quality == _PreviewQuality.low) ? 700 : 1600;
    final q = (quality == _PreviewQuality.low) ? 0.70 : 0.82;

    try {
      final jpg = await NativeRenderer.renderPreview(
        assetId: widget.assetId,
        values: Map<String, double>.from(_values),
        maxSide: maxSide,
        quality: q,
      );

      if (!mounted) return;

      if (token != _renderToken) {
        setState(() {
          _buildingPreview = false;
          _buildingHQ = false;
        });
        return;
      }

      setState(() {
        _previewBytes = jpg;
        _buildingPreview = false;
        _buildingHQ = false;
      });
    } catch (_) {
      if (!mounted) return;
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

    final fut =
        NativeRenderer.renderPreview(
              assetId: widget.assetId,
              values: merged,
              maxSide: 520,
              quality: 0.74,
            )
            .then((bytes) {
              _presetPreviewCache[key] = bytes;
              return bytes;
            })
            .whenComplete(() {
              _presetPreviewFutures.remove(key);
            });

    _presetPreviewFutures[key] = fut;
    return fut;
  }

  double _v(String id) => _values[id] ?? 0.0;

  int _displayNumber(_ToolItem t) {
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
      _activePresetName = null;
    });
    _schedulePreviewRebuild(_PreviewQuality.high, immediate: true);
  }

  void _applyRegistryPreset(LumaPreset preset) {
    HapticFeedback.selectionClick();
    _pushUndoCheckpoint();
    setState(() {
      for (final e in preset.values.entries) {
        _values[e.key] = e.value;
      }
      _activePresetName = preset.name;
      _tabIndex = 0;
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
      _activePresetName = null;
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
      await NativeRenderer.exportFullRes(
        assetId: widget.assetId,
        values: Map<String, double>.from(_values),
        quality: 0.92,
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

  Rect _computeDisplayBox(Size frame, double aspect) {
    final frameAspect = frame.width / frame.height;
    double w;
    double h;

    if (frameAspect > aspect) {
      h = frame.height;
      w = h * aspect;
    } else {
      w = frame.width;
      h = w / aspect;
    }

    final left = (frame.width - w) / 2;
    final top = (frame.height - h) / 2;
    return Rect.fromLTWH(left, top, w, h);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: SafeArea(child: Center(child: CircularProgressIndicator())),
      );
    }

    if (_originalBytes == null) {
      return const Scaffold(
        body: SafeArea(child: Center(child: Text('Could not load image'))),
      );
    }

    final tool = _activeTool;
    final toolValue = _v(tool.id);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              child: Column(
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => context.pop(),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 8,
                          ),
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              fontSize: 15,
                              color: Color(0xFF777777),
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
                            color: Colors.black,
                            disabledColor: Color(0xFFCCCCCC),
                          ),
                          IconButton(
                            onPressed: _canRedo ? _redo : null,
                            icon: const Icon(Icons.redo),
                            color: Colors.black,
                            disabledColor: Color(0xFFCCCCCC),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'Edit',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: _exportToPhotos,
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 8,
                          ),
                          child: Text(
                            'Save',
                            style: TextStyle(fontSize: 15, color: Colors.black),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 10, color: Color(0x11000000)),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: AspectRatio(
                aspectRatio: 4 / 5,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final frameSize = Size(
                      constraints.maxWidth,
                      constraints.maxHeight,
                    );
                    final displayBox = _computeDisplayBox(
                      frameSize,
                      _imageAspect,
                    );

                    final bytesToShow = _previewBytes ?? _originalBytes!;

                    return ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Stack(
                        children: [
                          Positioned.fromRect(
                            rect: displayBox,
                            child: ClipRect(
                              child: Image.memory(
                                bytesToShow,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Positioned.fill(
                            child: IgnorePointer(
                              child: CustomPaint(
                                painter: _FrameMaskPainter(displayBox),
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
                                  color: Colors.black.withAlpha(
                                    (0.72 * 255).round(),
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Text(
                                  'Updating',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
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
                      color: Colors.white.withAlpha((0.72 * 255).round()),
                      border: const Border(
                        top: BorderSide(color: Color(0x1A000000)),
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
    );
  }

  Widget _buildEditPresetsToggle() {
    return Center(
      child: Container(
        width: 240,
        height: 34,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: const Color(0xFFEDEDED),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _tabIndex = 0),
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _tabIndex == 0 ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Edit',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: _tabIndex == 0
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: _tabIndex == 0
                          ? Colors.black
                          : const Color(0xFF777777),
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
                    color: _tabIndex == 1 ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Presets',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: _tabIndex == 1
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: _tabIndex == 1
                          ? Colors.black
                          : const Color(0xFF777777),
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
        SizedBox(
          height: 24,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemBuilder: (context, i) {
              final selected = i == _groupIndex;
              return GestureDetector(
                onTap: () => setState(() {
                  _groupIndex = i;
                  _toolIndex = 0;
                }),
                child: Text(
                  _groups[i].label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected ? Colors.black : const Color(0xFF777777),
                  ),
                ),
              );
            },
            separatorBuilder: (_, _) => const SizedBox(width: 16),
            itemCount: _groups.length,
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 34,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemBuilder: (context, i) {
              final selected = i == _toolIndex;
              final t = _activeGroup.tools[i];

              return GestureDetector(
                onTap: () {
                  setState(() => _toolIndex = i);

                  if (t.kind == ToolKind.action) {
                    if (t.id == 'auto') _applyAuto();
                    return;
                  }

                  if (t.kind == ToolKind.toggle) {
                    HapticFeedback.selectionClick();
                    _pushUndoCheckpoint();
                    setState(() {
                      final cur = _v(t.id);
                      _values[t.id] = (cur >= 0.5) ? 0.0 : 1.0;
                      _activePresetName = null;
                    });
                    _schedulePreviewRebuild(
                      _PreviewQuality.high,
                      immediate: true,
                    );
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        t.label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: selected
                              ? Colors.black
                              : const Color(0xFF9A9A9A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        curve: Curves.easeOut,
                        height: 2,
                        width: selected ? 18 : 0,
                        decoration: BoxDecoration(
                          color: _accent,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
            separatorBuilder: (_, _) => const SizedBox(width: 14),
            itemCount: _activeGroup.tools.length,
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Text(
                tool.label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (tool.kind == ToolKind.slider)
                Text(
                  '${_displayNumber(tool)}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF777777),
                  ),
                )
              else if (tool.kind == ToolKind.toggle)
                Text(
                  _v(tool.id) >= 0.5 ? 'On' : 'Off',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF777777),
                  ),
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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              TextButton(
                onPressed: _saveAsPresetFlow,
                style: TextButton.styleFrom(foregroundColor: _accent),
                child: const Text('Save as preset'),
              ),
              const Spacer(),
              Text(
                'Presets: ${_presets.length}',
                style: const TextStyle(fontSize: 12, color: Color(0xFF777777)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildToolControl(_ToolItem tool, double toolValue) {
    if (tool.kind == ToolKind.action) {
      return SizedBox(
        height: 44,
        child: ElevatedButton(
          onPressed: _applyAuto,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text('Run Auto'),
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
              _activePresetName = null;
            });
            _schedulePreviewRebuild(_PreviewQuality.high, immediate: true);
          },
          child: Container(
            decoration: BoxDecoration(
              color: isOn ? Colors.black : const Color(0xFFEDEDED),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(
              isOn ? 'On' : 'Off',
              style: TextStyle(
                color: isOn ? Colors.white : Colors.black,
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
          inactiveTrackColor: const Color(0xFFDDDDDD),
          thumbColor: _accent,
          overlayColor: _accent.withAlpha((0.10 * 255).round()),
        ),
        child: Slider(
          value: toolValue,
          min: tool.min,
          max: tool.max,
          onChangeStart: (_) {
            _pushUndoCheckpoint();
            _dragDebounce?.cancel();
          },
          onChanged: (v) {
            setState(() {
              _values[tool.id] = v;
              _activePresetName = null;
            });

            _dragDebounce?.cancel();
            _dragDebounce = Timer(const Duration(milliseconds: 70), () {
              if (!mounted) return;
              _schedulePreviewRebuild(_PreviewQuality.low, immediate: true);
            });
          },
          onChangeEnd: (_) {
            _dragDebounce?.cancel();
            _schedulePreviewRebuild(_PreviewQuality.high, immediate: true);
          },
        ),
      ),
    );
  }

  Widget _buildPresetsTab() {
    final builtIns = PresetRegistry.rankedFor(
      aspect: _imageAspect,
      isLowLight: false,
      isIndoorGuess: false,
      isPortraitGuess: false,
    );

    final fallbackBytes = _previewBytes ?? _originalBytes!;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
      children: [
        const Text(
          'Built-in presets',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 118,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: builtIns.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, i) {
              final p = builtIns[i];
              return _RegistryPresetTile(
                preset: p,
                selected: _activePresetName == p.name,
                accent: _accent,
                fallbackBytes: fallbackBytes,
                previewFuture: _getPresetPreviewBytes(p.name, p.values),
                onApply: () => _applyRegistryPreset(p),
              );
            },
          ),
        ),
        const SizedBox(height: 18),
        const Divider(height: 1),
        const SizedBox(height: 14),
        Row(
          children: [
            const Text(
              'Your presets',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
            const Spacer(),
            Text(
              'Saved: ${_presets.length}',
              style: const TextStyle(fontSize: 12, color: Color(0xFF777777)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (_presets.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 20),
            child: Text(
              'No presets yet.\nSave one from the Edit tab.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF777777)),
            ),
          )
        else
          ..._presets.map(
            (p) => _PresetCard(
              preset: p,
              selected: _activePresetName == p.name,
              onApply: () {
                HapticFeedback.selectionClick();
                _pushUndoCheckpoint();
                setState(() {
                  _values
                    ..clear()
                    ..addAll(p.values);
                  _activePresetName = p.name;
                  _tabIndex = 0;
                });
                _schedulePreviewRebuild(_PreviewQuality.high, immediate: true);
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Applied: ${p.name}')));
              },
            ),
          ),
      ],
    );
  }
}

class _RegistryPresetTile extends StatelessWidget {
  final LumaPreset preset;
  final VoidCallback onApply;
  final bool selected;
  final Future<Uint8List> previewFuture;
  final Uint8List fallbackBytes;
  final Color accent;

  const _RegistryPresetTile({
    required this.preset,
    required this.onApply,
    required this.selected,
    required this.previewFuture,
    required this.fallbackBytes,
    required this.accent,
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
          width: 150,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFF4F0F1) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? accent : const Color(0xFFE6E6E6),
              width: selected ? 1.5 : 1,
            ),
            boxShadow: const [
              BoxShadow(
                blurRadius: 14,
                offset: Offset(0, 6),
                color: Color(0x14000000),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  height: 56,
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
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
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

  const _PresetCard({
    required this.preset,
    required this.onApply,
    required this.selected,
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
            color: selected ? const Color(0xFFEFEFEF) : const Color(0xFFF6F6F6),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? Colors.black : const Color(0x00000000),
              width: selected ? 1.2 : 0,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  preset.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Icon(Icons.check, size: 18, color: Color(0xFF777777)),
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

class _HistoryState {
  final Map<String, double> values;
  final int tabIndex;
  final int groupIndex;
  final int toolIndex;
  final double imageAspect;
  final String? activePresetName;

  const _HistoryState({
    required this.values,
    required this.tabIndex,
    required this.groupIndex,
    required this.toolIndex,
    required this.imageAspect,
    required this.activePresetName,
  });
}

class _FrameMaskPainter extends CustomPainter {
  final Rect displayBox;
  _FrameMaskPainter(this.displayBox);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;
    final full = Offset.zero & size;

    canvas.drawRect(
      Rect.fromLTRB(full.left, full.top, full.right, displayBox.top),
      paint,
    );
    canvas.drawRect(
      Rect.fromLTRB(full.left, displayBox.bottom, full.right, full.bottom),
      paint,
    );
    canvas.drawRect(
      Rect.fromLTRB(
        full.left,
        displayBox.top,
        displayBox.left,
        displayBox.bottom,
      ),
      paint,
    );
    canvas.drawRect(
      Rect.fromLTRB(
        displayBox.right,
        displayBox.top,
        full.right,
        displayBox.bottom,
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _FrameMaskPainter oldDelegate) =>
      oldDelegate.displayBox != displayBox;
}
