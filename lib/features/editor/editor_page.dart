// lib/features/editor/editor_page.dart
//
// Luma EditorPage (fast build, iOS, photo_manager 3.x, image 4.x)
//
// Performance plan:
// - UI stays smooth: all decode + edit + JPG encode runs in an isolate.
// - Slider drag triggers LOW-res render (fast).
// - Slider release triggers HIGH-res render (crisp).
// - Requests are coalesced: if you drag fast, older renders are discarded.
// - Small throttle so we do not queue a render every single touch event.
//
// Features:
// - Working tools (Light, Color, Effects, Detail, Optics)
// - Auto
// - Undo/Redo (values)
// - Double tap slider to reset
// - Save exports baked image to Photos
// - In-memory presets
//
// Notes:
// - This is a stable base. Crop/Masking/ToneCurve/HSL-per-channel will add extra CPU.
//   We should add those after this version stays smooth.

import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/foundation.dart'; // compute()
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image/image.dart' as img;
import 'package:photo_manager/photo_manager.dart';

class EditorPage extends StatefulWidget {
  final String assetId;

  const EditorPage({
    super.key,
    required this.assetId,
  });

  @override
  State<EditorPage> createState() => _EditorPageState();
}

enum _PreviewQuality { low, high }

class _EditorPageState extends State<EditorPage> {
  // ------------------------------------------------------------
  // Image state
  // ------------------------------------------------------------
  Uint8List? _originalBytes; // never changes
  Uint8List? _previewBytes; // edited preview jpg
  double _imageAspect = 4 / 5;
  bool _loading = true;

  // ------------------------------------------------------------
  // Render scheduling
  // ------------------------------------------------------------
  bool _buildingPreview = false;
  Timer? _throttle; // keeps drag updates from spamming compute()
  _PreviewQuality? _pendingQuality;
  int _renderToken = 0; // increments per request, discard stale results

  // ------------------------------------------------------------
  // UI state
  // ------------------------------------------------------------
  int _tabIndex = 0; // 0 Edit, 1 Presets
  int _groupIndex = 0;
  int _toolIndex = 0;

  // toolId -> value
  final Map<String, double> _values = {};

  // presets (in-memory for now)
  final List<_Preset> _presets = [];

  // ------------------------------------------------------------
  // Undo/Redo (tool values + selection)
  // ------------------------------------------------------------
  final List<_HistoryState> _undoStack = [];
  final List<_HistoryState> _redoStack = [];

  bool get _canUndo => _undoStack.isNotEmpty;
  bool get _canRedo => _redoStack.isNotEmpty;

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

  // ------------------------------------------------------------
  // Tool system
  // ------------------------------------------------------------
  late final List<_ToolGroup> _groups = [
    _ToolGroup(
      label: 'Light',
      tools: const [
        _ToolItem(id: 'auto', label: 'Auto', kind: ToolKind.action),
        _ToolItem(id: 'exposure', label: 'Exposure', min: -1, max: 1, defaultValue: 0),
        _ToolItem(id: 'contrast', label: 'Contrast', min: -1, max: 1, defaultValue: 0),
        _ToolItem(id: 'highlights', label: 'Highlights', min: -1, max: 1, defaultValue: 0),
        _ToolItem(id: 'shadows', label: 'Shadows', min: -1, max: 1, defaultValue: 0),
        _ToolItem(id: 'whites', label: 'Whites', min: -1, max: 1, defaultValue: 0),
        _ToolItem(id: 'blacks', label: 'Blacks', min: -1, max: 1, defaultValue: 0),
      ],
    ),
    _ToolGroup(
      label: 'Color',
      tools: const [
        _ToolItem(id: 'tint', label: 'Tint', min: -1, max: 1, defaultValue: 0),
        _ToolItem(id: 'color_balance', label: 'Balance', min: -1, max: 1, defaultValue: 0),
        _ToolItem(id: 'vibrance', label: 'Vibrance', min: -1, max: 1, defaultValue: 0),
        _ToolItem(id: 'saturation', label: 'Saturation', min: -1, max: 1, defaultValue: 0),
      ],
    ),
    _ToolGroup(
      label: 'Effects',
      tools: const [
        _ToolItem(id: 'texture', label: 'Texture', min: -1, max: 1, defaultValue: 0),
        _ToolItem(id: 'clarity', label: 'Clarity', min: -1, max: 1, defaultValue: 0),
        _ToolItem(id: 'dehaze', label: 'Dehaze', min: -1, max: 1, defaultValue: 0),
        _ToolItem(id: 'grain', label: 'Grain', min: 0, max: 1, defaultValue: 0),
        _ToolItem(id: 'vignette', label: 'Vignette', min: 0, max: 1, defaultValue: 0),
      ],
    ),
    _ToolGroup(
      label: 'Detail',
      tools: const [
        _ToolItem(id: 'sharpen', label: 'Sharpen', min: 0, max: 1, defaultValue: 0),
        _ToolItem(id: 'noise', label: 'Noise Red.', min: 0, max: 1, defaultValue: 0),
        _ToolItem(id: 'color_noise', label: 'Color NR', min: 0, max: 1, defaultValue: 0),
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

  void _primeDefaults() {
    for (final g in _groups) {
      for (final t in g.tools) {
        _values.putIfAbsent(t.id, () => t.defaultValue);
      }
    }
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
    _pushUndoCheckpoint();
    setState(() => _values[_activeTool.id] = _activeTool.defaultValue);
    _schedulePreviewRebuild(_PreviewQuality.high, immediate: true);
  }

  // ------------------------------------------------------------
  // Init / dispose
  // ------------------------------------------------------------
  @override
  void initState() {
    super.initState();
    _primeDefaults();
    _loadImage();
  }

  @override
  void dispose() {
    _throttle?.cancel();
    super.dispose();
  }

  // ------------------------------------------------------------
  // Load image from Photos
  // ------------------------------------------------------------
  Future<void> _loadImage() async {
    final asset = await AssetEntity.fromId(widget.assetId);
    if (asset == null) {
      if (!mounted) return;
      setState(() => _loading = false);
      return;
    }

    final data = await asset.originBytes;
    if (!mounted) return;

    final decoded = data == null ? null : img.decodeImage(data);
    final aspect = (decoded == null || decoded.height == 0)
        ? (4 / 5)
        : (decoded.width / decoded.height);

    setState(() {
      _originalBytes = data;
      _imageAspect = aspect;
      _loading = false;
    });

    _pushUndoCheckpoint();
    _schedulePreviewRebuild(_PreviewQuality.high, immediate: true);
  }

  // ------------------------------------------------------------
  // Preview scheduling (throttle + coalesce + isolate)
  // ------------------------------------------------------------
  void _schedulePreviewRebuild(_PreviewQuality quality, {bool immediate = false}) {
    // If a high quality render is requested, always prioritize it after the drag finishes.
    // During drag we throttle low quality renders.
    if (quality == _PreviewQuality.low && !immediate) {
      if (_throttle?.isActive ?? false) return; // skip, keep UI smooth
      _throttle = Timer(const Duration(milliseconds: 35), () {}); // ~28 fps render cap
    }

    if (_buildingPreview) {
      _pendingQuality = quality;
      return;
    }

    final delayMs = immediate ? 0 : (quality == _PreviewQuality.low ? 0 : 60);

    Future.delayed(Duration(milliseconds: delayMs), () async {
      await _rebuildPreview(quality);
    });
  }

  Future<void> _rebuildPreview(_PreviewQuality quality) async {
    final src = _originalBytes;
    if (src == null) return;

    setState(() => _buildingPreview = true);

    // Tokenize requests so stale isolate results are ignored.
    final int token = ++_renderToken;

    final maxSide = (quality == _PreviewQuality.low) ? 520 : 1700;
    final job = _RenderJob(
      originalBytes: src,
      values: Map<String, double>.from(_values),
      maxSide: maxSide,
      jpgQuality: (quality == _PreviewQuality.low) ? 82 : 92,
    );

    // Heavy work goes off the UI thread.
    final Uint8List? jpg = await compute(_renderInIsolate, job);

    if (!mounted) return;

    // If a newer request happened, discard this result.
    if (token != _renderToken) {
      if (mounted) setState(() => _buildingPreview = false);
      return;
    }

    setState(() {
      if (jpg != null) _previewBytes = jpg;
      _buildingPreview = false;
    });

    if (_pendingQuality != null) {
      final next = _pendingQuality!;
      _pendingQuality = null;
      _schedulePreviewRebuild(next, immediate: true);
    }
  }

  // ------------------------------------------------------------
  // Auto (updates values, then re-render)
  // ------------------------------------------------------------
  void _applyAuto() async {
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
    final contrast = (((targetStd - std) * 1.6)).clamp(-0.5, 0.5);

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

  // ------------------------------------------------------------
  // Export final baked image to Photos (high res)
  // ------------------------------------------------------------
  Future<void> _exportToPhotos() async {
    final src = _originalBytes;
    if (src == null) return;

    final perm = await PhotoManager.requestPermissionExtend();
    if (!perm.isAuth && !perm.hasAccess) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Need Photos permission to save')),
      );
      return;
    }

    // Bake at full resolution in isolate to keep UI responsive.
    final job = _RenderJob(
      originalBytes: src,
      values: Map<String, double>.from(_values),
      maxSide: 999999, // do not downscale
      jpgQuality: 95,
      disableDownscale: true,
    );

    final baked = await compute(_renderInIsolate, job);
    if (baked == null) return;

    await PhotoManager.editor.saveImage(
      baked,
      filename: 'Luma_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved to Photos')));
  }

  // ------------------------------------------------------------
  // Presets
  // ------------------------------------------------------------
  Future<void> _saveAsPresetFlow() async {
    final controller = TextEditingController();

    final name = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Save as preset'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Preset name'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(null), child: const Text('Cancel')),
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
    setState(() => _presets.add(_Preset(name: name, values: Map<String, double>.from(_values))));

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Saved preset: $name')));
  }

  // ------------------------------------------------------------
  // Preview frame math: show image inside a fixed 4:5 frame
  // but preserve real aspect inside it.
  // ------------------------------------------------------------
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

  // ------------------------------------------------------------
  // Build UI
  // ------------------------------------------------------------
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
            // Top bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                      child: Text('Cancel', style: TextStyle(fontSize: 15, color: Color(0xFF777777))),
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      IconButton(
                        onPressed: _canUndo ? _undo : null,
                        icon: const Icon(Icons.undo),
                        color: Colors.black,
                        disabledColor: const Color(0xFFCCCCCC),
                      ),
                      IconButton(
                        onPressed: _canRedo ? _redo : null,
                        icon: const Icon(Icons.redo),
                        color: Colors.black,
                        disabledColor: const Color(0xFFCCCCCC),
                      ),
                      const SizedBox(width: 6),
                      const Text('Edit', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: _exportToPhotos,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                      child: Text('Save', style: TextStyle(fontSize: 15, color: Colors.black)),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Preview
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: AspectRatio(
                aspectRatio: 4 / 5,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final frameSize = Size(constraints.maxWidth, constraints.maxHeight);
                    final displayBox = _computeDisplayBox(frameSize, _imageAspect);

                    final bytesToShow = _previewBytes ?? _originalBytes!;

                    return ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Stack(
                        children: [
                          Positioned.fromRect(
                            rect: displayBox,
                            child: ClipRect(
                              child: Image.memory(bytesToShow, fit: BoxFit.cover),
                            ),
                          ),
                          Positioned.fill(
                            child: IgnorePointer(
                              child: CustomPaint(painter: _FrameMaskPainter(displayBox)),
                            ),
                          ),
                          if (_buildingPreview)
                            Positioned(
                              right: 10,
                              top: 10,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.70),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Text('Updating', style: TextStyle(color: Colors.white, fontSize: 12)),
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
              child: Column(
                children: [
                  // Edit / Presets
                  Container(
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
                                  fontWeight: _tabIndex == 0 ? FontWeight.w700 : FontWeight.w500,
                                  color: _tabIndex == 0 ? Colors.black : const Color(0xFF777777),
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
                                  fontWeight: _tabIndex == 1 ? FontWeight.w700 : FontWeight.w500,
                                  color: _tabIndex == 1 ? Colors.black : const Color(0xFF777777),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  Expanded(
                    child: _tabIndex == 0 ? _buildEditTab(tool, toolValue) : _buildPresetsTab(),
                  ),
                ],
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
        // Group selector
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
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemCount: _groups.length,
          ),
        ),

        const SizedBox(height: 10),

        // Tool selector
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
                    _pushUndoCheckpoint();
                    setState(() {
                      final cur = _v(t.id);
                      _values[t.id] = (cur >= 0.5) ? 0.0 : 1.0;
                    });
                    _schedulePreviewRebuild(_PreviewQuality.high, immediate: true);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  alignment: Alignment.center,
                  child: Text(
                    t.label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected ? Colors.black : const Color(0xFF777777),
                    ),
                  ),
                ),
              );
            },
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemCount: _activeGroup.tools.length,
          ),
        ),

        const SizedBox(height: 12),

        // Tool header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Text(tool.label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              const Spacer(),
              if (tool.kind == ToolKind.slider)
                Text('${_displayNumber(tool)}', style: const TextStyle(fontSize: 13, color: Color(0xFF777777)))
              else if (tool.kind == ToolKind.toggle)
                Text(_v(tool.id) >= 0.5 ? 'On' : 'Off', style: const TextStyle(fontSize: 13, color: Color(0xFF777777)))
              else
                const SizedBox.shrink(),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // Tool control
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _buildToolControl(tool, toolValue),
        ),

        const SizedBox(height: 10),

        // Preset save
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              TextButton(onPressed: _saveAsPresetFlow, child: const Text('Save as preset')),
              const Spacer(),
              Text('Presets: ${_presets.length}', style: const TextStyle(fontSize: 12, color: Color(0xFF777777))),
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
            _pushUndoCheckpoint();
            setState(() => _values[tool.id] = isOn ? 0.0 : 1.0);
            _schedulePreviewRebuild(_PreviewQuality.high, immediate: true);
          },
          child: Container(
            decoration: BoxDecoration(
              color: isOn ? Colors.black : const Color(0xFFEDEDED),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Text(
              isOn ? 'On' : 'Off',
              style: TextStyle(color: isOn ? Colors.white : Colors.black, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      );
    }

    // Slider tool
    return GestureDetector(
      onDoubleTap: _resetActiveTool,
      child: SliderTheme(
        data: SliderTheme.of(context).copyWith(
          activeTrackColor: Colors.black,
          inactiveTrackColor: const Color(0xFFDDDDDD),
          thumbColor: Colors.black,
          overlayColor: Colors.black.withOpacity(0.08),
        ),
        child: Slider(
          value: toolValue,
          min: tool.min,
          max: tool.max,
          onChangeStart: (_) => _pushUndoCheckpoint(),
          onChanged: (v) {
            setState(() => _values[tool.id] = v);
            _schedulePreviewRebuild(_PreviewQuality.low);
          },
          onChangeEnd: (_) => _schedulePreviewRebuild(_PreviewQuality.high, immediate: true),
        ),
      ),
    );
  }

  Widget _buildPresetsTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
      children: [
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
              onApply: () {
                _pushUndoCheckpoint();
                setState(() {
                  _values
                    ..clear()
                    ..addAll(p.values);
                });
                _schedulePreviewRebuild(_PreviewQuality.high, immediate: true);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Applied: ${p.name}')));
              },
            ),
          ),
      ],
    );
  }
}

// ============================================================
// Isolate render job + function
// ============================================================

class _RenderJob {
  final Uint8List originalBytes;
  final Map<String, double> values;
  final int maxSide;
  final int jpgQuality;
  final bool disableDownscale;

  const _RenderJob({
    required this.originalBytes,
    required this.values,
    required this.maxSide,
    required this.jpgQuality,
    this.disableDownscale = false,
  });
}

Uint8List? _renderInIsolate(_RenderJob job) {
  final decoded = img.decodeImage(job.originalBytes);
  if (decoded == null) return null;

  img.Image base = decoded;

  if (!job.disableDownscale) {
    final w = base.width;
    final h = base.height;
    final maxDim = math.max(w, h);
    if (maxDim > job.maxSide) {
      final scale = job.maxSide / maxDim;
      base = img.copyResize(
        base,
        width: (w * scale).round(),
        height: (h * scale).round(),
        interpolation: img.Interpolation.cubic,
      );
    }
  }

  img.Image out = img.Image.from(base);

  double v(String id) => job.values[id] ?? 0.0;

  // --------------------------
  // Light
  // --------------------------
  final exposure = v('exposure');
  final contrast = v('contrast');
  final highlights = v('highlights');
  final shadows = v('shadows');
  final whites = v('whites');
  final blacks = v('blacks');

  final expMul = math.pow(2.0, exposure * 0.9).toDouble();
  final c = 1.0 + (contrast * 0.9);

  for (int y = 0; y < out.height; y++) {
    for (int x = 0; x < out.width; x++) {
      final p = out.getPixel(x, y);

      double r = p.r / 255.0;
      double g = p.g / 255.0;
      double b = p.b / 255.0;

      // exposure
      r = (r * expMul).clamp(0.0, 1.0);
      g = (g * expMul).clamp(0.0, 1.0);
      b = (b * expMul).clamp(0.0, 1.0);

      // contrast
      r = (((r - 0.5) * c) + 0.5).clamp(0.0, 1.0);
      g = (((g - 0.5) * c) + 0.5).clamp(0.0, 1.0);
      b = (((b - 0.5) * c) + 0.5).clamp(0.0, 1.0);

      final lum = (0.2126 * r + 0.7152 * g + 0.0722 * b).clamp(0.0, 1.0);

      // shadows
      final shadowMask = (1.0 - lum).clamp(0.0, 1.0);
      final shadowGain = shadows * 0.35 * shadowMask;
      r = (r + shadowGain).clamp(0.0, 1.0);
      g = (g + shadowGain).clamp(0.0, 1.0);
      b = (b + shadowGain).clamp(0.0, 1.0);

      // highlights
      final hiMask = lum.clamp(0.0, 1.0);
      final hiGain = highlights * 0.35 * hiMask;
      r = (r - hiGain).clamp(0.0, 1.0);
      g = (g - hiGain).clamp(0.0, 1.0);
      b = (b - hiGain).clamp(0.0, 1.0);

      // whites
      if (whites != 0) {
        final wAmt = whites * 0.18;
        r = (r + wAmt * r).clamp(0.0, 1.0);
        g = (g + wAmt * g).clamp(0.0, 1.0);
        b = (b + wAmt * b).clamp(0.0, 1.0);
      }

      // blacks
      if (blacks != 0) {
        final bAmt = blacks * 0.18;
        r = (r - bAmt * (1.0 - r)).clamp(0.0, 1.0);
        g = (g - bAmt * (1.0 - g)).clamp(0.0, 1.0);
        b = (b - bAmt * (1.0 - b)).clamp(0.0, 1.0);
      }

      out.setPixelRgba(
        x,
        y,
        (r * 255).round(),
        (g * 255).round(),
        (b * 255).round(),
        p.a.toInt(),
      );
    }
  }

  // --------------------------
  // Color
  // --------------------------
  final tint = v('tint');
  final balance = v('color_balance');
  final vibrance = v('vibrance');
  final saturation = v('saturation');

  final warm = balance * 0.10;
  final tintAmt = tint * 0.10;

  for (int y = 0; y < out.height; y++) {
    for (int x = 0; x < out.width; x++) {
      final p = out.getPixel(x, y);

      double r = p.r / 255.0;
      double g = p.g / 255.0;
      double b = p.b / 255.0;

      // warm/cool
      r = (r + warm).clamp(0.0, 1.0);
      b = (b - warm).clamp(0.0, 1.0);

      // tint
      r = (r + tintAmt).clamp(0.0, 1.0);
      b = (b + tintAmt).clamp(0.0, 1.0);
      g = (g - tintAmt).clamp(0.0, 1.0);

      final lum = (0.2126 * r + 0.7152 * g + 0.0722 * b).clamp(0.0, 1.0);

      // saturation
      final satFactor = 1.0 + (saturation * 0.85);
      r = (lum + (r - lum) * satFactor).clamp(0.0, 1.0);
      g = (lum + (g - lum) * satFactor).clamp(0.0, 1.0);
      b = (lum + (b - lum) * satFactor).clamp(0.0, 1.0);

      // vibrance
      final maxc = math.max(r, math.max(g, b));
      final minc = math.min(r, math.min(g, b));
      final sat = (maxc - minc).clamp(0.0, 1.0);
      final vibBoost = (1.0 - sat) * vibrance * 0.55;
      final vibFactor = 1.0 + vibBoost;

      r = (lum + (r - lum) * vibFactor).clamp(0.0, 1.0);
      g = (lum + (g - lum) * vibFactor).clamp(0.0, 1.0);
      b = (lum + (b - lum) * vibFactor).clamp(0.0, 1.0);

      out.setPixelRgba(
        x,
        y,
        (r * 255).round(),
        (g * 255).round(),
        (b * 255).round(),
        p.a.toInt(),
      );
    }
  }

  // --------------------------
  // Effects
  // --------------------------
  final texture = v('texture');
  final clarity = v('clarity');
  final dehaze = v('dehaze');

  img.Image blend(img.Image baseImg, img.Image overlay, double alpha) {
    final a = alpha.clamp(0.0, 1.0);
    for (int y = 0; y < baseImg.height; y++) {
      for (int x = 0; x < baseImg.width; x++) {
        final p = baseImg.getPixel(x, y);
        final q = overlay.getPixel(x, y);

        final rr = (p.r.toDouble() * (1 - a) + q.r.toDouble() * a).round();
        final gg = (p.g.toDouble() * (1 - a) + q.g.toDouble() * a).round();
        final bb = (p.b.toDouble() * (1 - a) + q.b.toDouble() * a).round();

        baseImg.setPixelRgba(x, y, rr, gg, bb, p.a.toInt());
      }
    }
    return baseImg;
  }

  img.Image unsharp(img.Image im, double amount, int radius) {
    final blurred = img.gaussianBlur(img.Image.from(im), radius: radius);
    final amt = amount.clamp(0.0, 2.0);

    for (int y = 0; y < im.height; y++) {
      for (int x = 0; x < im.width; x++) {
        final p = im.getPixel(x, y);
        final b = blurred.getPixel(x, y);

        int r = p.r.toInt();
        int g = p.g.toInt();
        int bb = p.b.toInt();

        r = (r + (r - b.r.toInt()) * amt).round().clamp(0, 255);
        g = (g + (g - b.g.toInt()) * amt).round().clamp(0, 255);
        bb = (bb + (bb - b.b.toInt()) * amt).round().clamp(0, 255);

        im.setPixelRgba(x, y, r, g, bb, p.a.toInt());
      }
    }
    return im;
  }

  if (texture != 0) {
    out = unsharp(out, texture.abs() * 1.0, 1);
    if (texture < 0) {
      final blurred = img.gaussianBlur(img.Image.from(out), radius: 1);
      out = blend(out, blurred, texture.abs() * 0.35);
    }
  }

  if (clarity != 0) {
    out = unsharp(out, clarity.abs() * 1.2, 2);
    if (clarity < 0) {
      final blurred = img.gaussianBlur(img.Image.from(out), radius: 2);
      out = blend(out, blurred, clarity.abs() * 0.30);
    }
  }

  if (dehaze != 0) {
    final amt = dehaze.clamp(-1.0, 1.0);
    final cc = 1.0 + amt * 0.35;
    final blackPull = amt * 0.06;

    for (int y = 0; y < out.height; y++) {
      for (int x = 0; x < out.width; x++) {
        final p = out.getPixel(x, y);

        double r = p.r / 255.0;
        double g = p.g / 255.0;
        double b = p.b / 255.0;

        r = (((r - 0.5) * cc) + 0.5).clamp(0.0, 1.0);
        g = (((g - 0.5) * cc) + 0.5).clamp(0.0, 1.0);
        b = (((b - 0.5) * cc) + 0.5).clamp(0.0, 1.0);

        r = (r - blackPull * (1.0 - r)).clamp(0.0, 1.0);
        g = (g - blackPull * (1.0 - g)).clamp(0.0, 1.0);
        b = (b - blackPull * (1.0 - b)).clamp(0.0, 1.0);

        out.setPixelRgba(
          x,
          y,
          (r * 255).round(),
          (g * 255).round(),
          (b * 255).round(),
          p.a.toInt(),
        );
      }
    }
  }

  // --------------------------
  // Detail
  // --------------------------
  final sharpen = v('sharpen');
  final noise = v('noise');
  final colorNoise = v('color_noise');

  if (noise > 0) {
    final radius = (1 + (noise * 2.5)).round().clamp(1, 4);
    final blurred = img.gaussianBlur(img.Image.from(out), radius: radius);
    out = blend(out, blurred, (noise * 0.55).clamp(0.0, 0.70));
  }

  if (colorNoise > 0) {
    final radius = (1 + (colorNoise * 2.5)).round().clamp(1, 4);

    final cb = img.Image(width: out.width, height: out.height);
    final cr = img.Image(width: out.width, height: out.height);

    for (int y = 0; y < out.height; y++) {
      for (int x = 0; x < out.width; x++) {
        final p = out.getPixel(x, y);
        final r = p.r.toDouble();
        final g = p.g.toDouble();
        final b = p.b.toDouble();

        final cbv = (128 - 0.168736 * r - 0.331264 * g + 0.5 * b).clamp(0.0, 255.0);
        final crv = (128 + 0.5 * r - 0.418688 * g - 0.081312 * b).clamp(0.0, 255.0);

        cb.setPixelRgba(x, y, cbv.round(), cbv.round(), cbv.round(), 255);
        cr.setPixelRgba(x, y, crv.round(), crv.round(), crv.round(), 255);
      }
    }

    final cbB = img.gaussianBlur(cb, radius: radius);
    final crB = img.gaussianBlur(cr, radius: radius);

    for (int y = 0; y < out.height; y++) {
      for (int x = 0; x < out.width; x++) {
        final p = out.getPixel(x, y);
        final r = p.r.toDouble();
        final g = p.g.toDouble();
        final b = p.b.toDouble();

        final yv = (0.299 * r + 0.587 * g + 0.114 * b).clamp(0.0, 255.0);

        final cbv = cbB.getPixel(x, y).r.toDouble();
        final crv = crB.getPixel(x, y).r.toDouble();

        final rr = (yv + 1.402 * (crv - 128)).clamp(0.0, 255.0);
        final gg = (yv - 0.344136 * (cbv - 128) - 0.714136 * (crv - 128)).clamp(0.0, 255.0);
        final bb = (yv + 1.772 * (cbv - 128)).clamp(0.0, 255.0);

        out.setPixelRgba(x, y, rr.round(), gg.round(), bb.round(), p.a.toInt());
      }
    }
  }

  if (sharpen > 0) {
    out = unsharp(out, (sharpen * 1.4).clamp(0.0, 1.6), 1);
  }

  // --------------------------
  // Optics
  // --------------------------
  final lens = (v('lens_correction') >= 0.5);
  final ca = (v('chromatic_aberration') >= 0.5);

  if (lens) {
    // barrel correction (simple)
    final s = 0.08;
    final w = out.width;
    final h = out.height;
    final cx = (w - 1) / 2.0;
    final cy = (h - 1) / 2.0;
    final maxR = math.sqrt(cx * cx + cy * cy);
    final srcCopy = img.Image.from(out);

    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        final dx = (x - cx);
        final dy = (y - cy);
        final r = math.sqrt(dx * dx + dy * dy) / maxR;
        final k = 1.0 - s * (r * r);

        final sx = (cx + dx * k);
        final sy = (cy + dy * k);

        final ix = sx.round().clamp(0, w - 1);
        final iy = sy.round().clamp(0, h - 1);

        final p = srcCopy.getPixel(ix, iy);
        out.setPixelRgba(x, y, p.r.toInt(), p.g.toInt(), p.b.toInt(), p.a.toInt());
      }
    }
  }

  if (ca) {
    // reduce chromatic aberration by sampling R/B with small opposite shifts
    final shiftPx = 1;
    final w = out.width;
    final h = out.height;
    final cx = (w - 1) / 2.0;
    final cy = (h - 1) / 2.0;
    final srcCopy = img.Image.from(out);

    int sampleChannel(int x, int y, int dx, int dy, int channel) {
      final sx = (x + dx).clamp(0, w - 1);
      final sy = (y + dy).clamp(0, h - 1);
      final p = srcCopy.getPixel(sx, sy);
      if (channel == 0) return p.r.toInt();
      if (channel == 1) return p.g.toInt();
      return p.b.toInt();
    }

    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        final dx = x - cx;
        final dy = y - cy;
        final dist = math.sqrt(dx * dx + dy * dy);
        final nx = dist == 0 ? 0.0 : dx / dist;
        final ny = dist == 0 ? 0.0 : dy / dist;

        final ix = (-nx * shiftPx).round();
        final iy = (-ny * shiftPx).round();

        final p = srcCopy.getPixel(x, y);
        final r = sampleChannel(x, y, ix, iy, 0);
        final g = p.g.toInt();
        final b = sampleChannel(x, y, -ix, -iy, 2);

        out.setPixelRgba(x, y, r, g, b, p.a.toInt());
      }
    }
  }

  // --------------------------
  // Grain + Vignette last
  // --------------------------
  final grain = v('grain').clamp(0.0, 1.0);
  if (grain > 0) {
    final rng = math.Random(1337);
    final amt = 18.0 * grain;
    for (int y = 0; y < out.height; y++) {
      for (int x = 0; x < out.width; x++) {
        final p = out.getPixel(x, y);
        final n = (rng.nextDouble() * 2 - 1) * amt;

        final rr = (p.r.toDouble() + n).round().clamp(0, 255);
        final gg = (p.g.toDouble() + n).round().clamp(0, 255);
        final bb = (p.b.toDouble() + n).round().clamp(0, 255);

        out.setPixelRgba(x, y, rr, gg, bb, p.a.toInt());
      }
    }
  }

  final vignette = v('vignette').clamp(0.0, 1.0);
  if (vignette > 0) {
    final cx = out.width / 2;
    final cy = out.height / 2;
    final maxD = math.sqrt(cx * cx + cy * cy);

    for (int y = 0; y < out.height; y++) {
      for (int x = 0; x < out.width; x++) {
        final p = out.getPixel(x, y);
        final dx = x - cx;
        final dy = y - cy;
        final d = math.sqrt(dx * dx + dy * dy) / maxD;

        final vv = (1.0 - (d * d) * (0.85 * vignette)).clamp(0.0, 1.0);

        final rr = (p.r.toDouble() * vv).round().clamp(0, 255);
        final gg = (p.g.toDouble() * vv).round().clamp(0, 255);
        final bb = (p.b.toDouble() * vv).round().clamp(0, 255);

        out.setPixelRgba(x, y, rr, gg, bb, p.a.toInt());
      }
    }
  }

  return Uint8List.fromList(img.encodeJpg(out, quality: job.jpgQuality));
}

// ============================================================
// Models + Painter
// ============================================================

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

class _Preset {
  final String name;
  final Map<String, double> values;
  const _Preset({required this.name, required this.values});
}

class _PresetCard extends StatelessWidget {
  final _Preset preset;
  final VoidCallback onApply;

  const _PresetCard({
    super.key,
    required this.preset,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F6F6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              preset.name,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
          TextButton(onPressed: onApply, child: const Text('Apply')),
        ],
      ),
    );
  }
}

class _HistoryState {
  final Map<String, double> values;
  final int tabIndex;
  final int groupIndex;
  final int toolIndex;
  final double imageAspect;

  const _HistoryState({
    required this.values,
    required this.tabIndex,
    required this.groupIndex,
    required this.toolIndex,
    required this.imageAspect,
  });
}

class _FrameMaskPainter extends CustomPainter {
  final Rect displayBox;
  _FrameMaskPainter(this.displayBox);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;
    final full = Offset.zero & size;

    canvas.drawRect(Rect.fromLTRB(full.left, full.top, full.right, displayBox.top), paint);
    canvas.drawRect(Rect.fromLTRB(full.left, displayBox.bottom, full.right, full.bottom), paint);
    canvas.drawRect(Rect.fromLTRB(full.left, displayBox.top, displayBox.left, displayBox.bottom), paint);
    canvas.drawRect(Rect.fromLTRB(displayBox.right, displayBox.top, full.right, displayBox.bottom), paint);
  }

  @override
  bool shouldRepaint(covariant _FrameMaskPainter oldDelegate) => oldDelegate.displayBox != displayBox;
}