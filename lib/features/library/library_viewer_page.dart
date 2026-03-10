import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;

import '../export/export_sheet.dart';
import '../export/native_share_bridge.dart';
import '../editor/editor_navigation.dart';
import 'library_models.dart';
import 'library_provider.dart';

class LumaLibraryViewerPage extends ConsumerStatefulWidget {
  final List<String> orderedPhotoIds;
  final int initialIndex;

  const LumaLibraryViewerPage({
    super.key,
    required this.orderedPhotoIds,
    required this.initialIndex,
  });

  @override
  ConsumerState<LumaLibraryViewerPage> createState() =>
      _LumaLibraryViewerPageState();
}

class _LumaLibraryViewerPageState extends ConsumerState<LumaLibraryViewerPage> {
  late final PageController _pageController;
  final TransformationController _zoomController = TransformationController();
  int _currentIndex = 0;
  bool _showInfo = false;
  LumaHistogramMode _histogramMode = LumaHistogramMode.off;

  @override
  void initState() {
    super.initState();
    final safeInitial = widget.initialIndex.clamp(
      0,
      widget.orderedPhotoIds.isEmpty ? 0 : widget.orderedPhotoIds.length - 1,
    );
    _currentIndex = safeInitial;
    _pageController = PageController(initialPage: safeInitial);
  }

  @override
  void dispose() {
    _zoomController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _toggleFavorite(LumaPhoto photo) async {
    await ref.read(lumaLibraryProvider.notifier).toggleFavorite(photo.photoId);
  }

  Future<void> _deleteCurrent(LumaPhoto photo) async {
    await ref.read(lumaLibraryProvider.notifier).deletePhotos({photo.photoId});
    if (!mounted) return;

    final visible = _visiblePhotos();
    if (visible.isEmpty) {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      return;
    }

    final maxIndex = visible.length - 1;
    if (_currentIndex > maxIndex) {
      setState(() {
        _currentIndex = maxIndex;
        _showInfo = false;
      });
      _pageController.jumpToPage(maxIndex);
    }
  }

  Future<void> _exportCurrent(LumaPhoto photo) async {
    final action = await showLumaExportSheet(context, itemCount: 1);
    if (!mounted || action == null) return;

    final path = await ref
        .read(lumaLibraryProvider.notifier)
        .exportPhoto(photo.photoId);
    if (!mounted) return;
    if (path == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Export failed')));
      return;
    }

    try {
      switch (action) {
        case LumaExportAction.share:
          await NativeShareBridge.shareFiles([path], subject: 'Luma Export');
          break;
        case LumaExportAction.saveToCameraRoll:
          await NativeShareBridge.saveFilesToPhotos([path]);
          if (!mounted) return;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Saved to Camera Roll')));
          break;
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Export failed: $error')));
    }
  }

  Future<void> _openEditor(LumaPhoto photo) async {
    await Navigator.of(context).push(
      buildEditorRoute(
        assetId: 'library:${photo.photoId}',
        sourceFilePath: photo.workingPath,
        capturedAtMs: photo.captureDateMs,
      ),
    );
  }

  Future<void> _showVersions(LumaPhoto photo) async {
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF141414),
      builder: (context) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              const ListTile(
                title: Text('Versions', style: TextStyle(color: Colors.white)),
              ),
              for (final version in photo.versions)
                ListTile(
                  title: Text(
                    version.name,
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    DateTime.fromMillisecondsSinceEpoch(
                      version.createdAtMs,
                    ).toString(),
                    style: const TextStyle(color: Colors.white60),
                  ),
                  trailing: version.versionId == photo.activeVersionId
                      ? const Icon(
                          Icons.check_circle,
                          color: Colors.greenAccent,
                        )
                      : null,
                ),
              ListTile(
                leading: const Icon(Icons.copy, color: Colors.white),
                title: const Text(
                  'Duplicate active version',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () async {
                  Navigator.of(context).pop();
                  await ref
                      .read(lumaLibraryProvider.notifier)
                      .duplicateActiveVersion(photo.photoId);
                },
              ),
              ListTile(
                leading: const Icon(Icons.restore, color: Colors.white),
                title: const Text(
                  'Revert to original',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () async {
                  Navigator.of(context).pop();
                  await ref
                      .read(lumaLibraryProvider.notifier)
                      .revertToOriginal(photo.photoId);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showComparePicker(LumaPhoto currentPhoto) async {
    final photos = _visiblePhotos();
    final others = photos
        .where((photo) => photo.photoId != currentPhoto.photoId)
        .toList(growable: false);
    if (others.isEmpty || !mounted) return;

    final selected = await showModalBottomSheet<LumaPhoto>(
      context: context,
      backgroundColor: const Color(0xFF141414),
      builder: (context) {
        return SafeArea(
          child: ListView.builder(
            itemCount: others.length,
            itemBuilder: (context, index) {
              final photo = others[index];
              return ListTile(
                title: Text(
                  photo.captureIdentifier,
                  style: const TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  DateTime.fromMillisecondsSinceEpoch(
                    photo.captureDateMs,
                  ).toString(),
                  style: const TextStyle(color: Colors.white60),
                ),
                onTap: () => Navigator.of(context).pop(photo),
              );
            },
          ),
        );
      },
    );

    if (!mounted || selected == null) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _LumaComparePage(a: currentPhoto, b: selected),
      ),
    );
  }

  List<LumaPhoto> _visiblePhotos() {
    final library = ref.read(lumaLibraryProvider);
    final byId = <String, LumaPhoto>{
      for (final photo in library.filteredPhotos) photo.photoId: photo,
    };
    return widget.orderedPhotoIds
        .map((id) => byId[id])
        .whereType<LumaPhoto>()
        .toList(growable: false);
  }

  void _toggleZoom() {
    final matrix = _zoomController.value;
    if (!matrix.isIdentity()) {
      _zoomController.value = Matrix4.identity();
      return;
    }
    _zoomController.value = Matrix4.identity()
      ..scaleByDouble(2.0, 2.0, 1.0, 1.0);
  }

  void _cycleHistogramMode() {
    setState(() {
      _histogramMode = switch (_histogramMode) {
        LumaHistogramMode.off => LumaHistogramMode.luminance,
        LumaHistogramMode.luminance => LumaHistogramMode.rgb,
        LumaHistogramMode.rgb => LumaHistogramMode.off,
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    final photos = _visiblePhotos();
    if (photos.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text(
            'Photo no longer available.',
            style: TextStyle(color: Colors.white70),
          ),
        ),
      );
    }

    final safeIndex = _currentIndex.clamp(0, photos.length - 1);
    final current = photos[safeIndex];

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          '${safeIndex + 1} / ${photos.length}',
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.layers_outlined),
            onPressed: () => _showVersions(current),
          ),
          IconButton(
            icon: const Icon(Icons.compare),
            onPressed: () => _showComparePicker(current),
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: _cycleHistogramMode,
          ),
          IconButton(
            icon: Icon(_showInfo ? Icons.info : Icons.info_outline),
            onPressed: () {
              setState(() {
                _showInfo = !_showInfo;
              });
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: photos.length,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
                _showInfo = false;
              });
              _zoomController.value = Matrix4.identity();
            },
            itemBuilder: (context, index) {
              final photo = photos[index];
              return GestureDetector(
                onDoubleTap: _toggleZoom,
                child: InteractiveViewer(
                  transformationController: _zoomController,
                  minScale: 1,
                  maxScale: 6,
                  child: Center(
                    child: Image.file(
                      File(photo.workingPath),
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.broken_image_outlined,
                          color: Colors.white54,
                          size: 52,
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),
          Positioned(
            left: 12,
            right: 12,
            bottom: 88,
            child: IgnorePointer(
              ignoring: !_showInfo,
              child: AnimatedSlide(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                offset: _showInfo ? Offset.zero : const Offset(0, 0.12),
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  opacity: _showInfo ? 1 : 0,
                  child: _MetadataPanel(photo: current),
                ),
              ),
            ),
          ),
          if (_histogramMode != LumaHistogramMode.off)
            Positioned(
              left: 12,
              top: 12,
              child: _HistogramOverlay(photo: current, mode: _histogramMode),
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: SizedBox(
          height: 72,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _ViewerAction(
                icon: Icons.tune,
                label: 'Edit',
                onTap: () => _openEditor(current),
              ),
              _ViewerAction(
                icon: current.isFavorite
                    ? Icons.favorite
                    : Icons.favorite_border,
                label: 'Favorite',
                onTap: () => _toggleFavorite(current),
              ),
              _ViewerAction(
                icon: Icons.ios_share_outlined,
                label: 'Export',
                onTap: () => _exportCurrent(current),
              ),
              _ViewerAction(
                icon: Icons.delete_outline,
                label: 'Delete',
                onTap: () => _deleteCurrent(current),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ViewerAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ViewerAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetadataPanel extends StatelessWidget {
  final LumaPhoto photo;

  const _MetadataPanel({required this.photo});

  @override
  Widget build(BuildContext context) {
    String valueOrDash(Object? value) {
      if (value == null) return '—';
      final text = value.toString().trim();
      return text.isEmpty ? '—' : text;
    }

    final rows = <String, String>{
      'ISO': valueOrDash(photo.iso?.toStringAsFixed(0)),
      'Shutter': valueOrDash(photo.shutterSpeed),
      'Aperture': valueOrDash(
        photo.aperture == null ? null : 'f/${photo.aperture}',
      ),
      'Lens': valueOrDash(photo.lens),
      'Resolution': photo.width != null && photo.height != null
          ? '${photo.width} x ${photo.height}'
          : '—',
      'Date': DateTime.fromMillisecondsSinceEpoch(
        photo.captureDateMs,
      ).toString(),
      'Location': valueOrDash(photo.location),
    };

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Wrap(
          spacing: 12,
          runSpacing: 6,
          children: rows.entries
              .map(
                (entry) => Text(
                  '${entry.key}: ${entry.value}',
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
              )
              .toList(growable: false),
        ),
      ),
    );
  }
}

class _HistogramOverlay extends StatefulWidget {
  final LumaPhoto photo;
  final LumaHistogramMode mode;

  const _HistogramOverlay({required this.photo, required this.mode});

  @override
  State<_HistogramOverlay> createState() => _HistogramOverlayState();
}

class _HistogramOverlayState extends State<_HistogramOverlay> {
  late Future<_HistogramData?> _histogramFuture;

  @override
  void initState() {
    super.initState();
    _histogramFuture = _computeHistogram(widget.photo, widget.mode);
  }

  @override
  void didUpdateWidget(covariant _HistogramOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.photo.photoId != widget.photo.photoId ||
        oldWidget.mode != widget.mode) {
      _histogramFuture = _computeHistogram(widget.photo, widget.mode);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_HistogramData?>(
      future: _histogramFuture,
      builder: (context, snapshot) {
        final data = snapshot.data;
        if (data == null) {
          return const SizedBox.shrink();
        }
        return Container(
          width: 170,
          height: 82,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
          ),
          child: CustomPaint(painter: _HistogramPainter(data)),
        );
      },
    );
  }

  Future<_HistogramData?> _computeHistogram(
    LumaPhoto photo,
    LumaHistogramMode mode,
  ) async {
    final sourcePath = photo.thumbnailPath ?? photo.workingPath;
    if (sourcePath.isEmpty) return null;
    final file = File(sourcePath);
    if (!await file.exists()) return null;

    final bytes = await file.readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return null;
    final resized = decoded.width > 320
        ? img.copyResize(decoded, width: 320)
        : decoded;

    const bins = 64;
    final lum = List<double>.filled(bins, 0);
    final r = List<double>.filled(bins, 0);
    final g = List<double>.filled(bins, 0);
    final b = List<double>.filled(bins, 0);

    final pixelCount = resized.width * resized.height;
    if (pixelCount == 0) return null;

    for (final pixel in resized) {
      final rv = pixel.r.toDouble();
      final gv = pixel.g.toDouble();
      final bv = pixel.b.toDouble();
      final lv = (0.2126 * rv) + (0.7152 * gv) + (0.0722 * bv);
      final rBin = (rv / 255.0 * (bins - 1)).round().clamp(0, bins - 1);
      final gBin = (gv / 255.0 * (bins - 1)).round().clamp(0, bins - 1);
      final bBin = (bv / 255.0 * (bins - 1)).round().clamp(0, bins - 1);
      final lBin = (lv / 255.0 * (bins - 1)).round().clamp(0, bins - 1);
      r[rBin] += 1;
      g[gBin] += 1;
      b[bBin] += 1;
      lum[lBin] += 1;
    }

    double normalize(List<double> values) {
      final maxValue = values.reduce((a, b) => a > b ? a : b);
      return maxValue <= 0 ? 1 : maxValue;
    }

    final lumScale = normalize(lum);
    final rgbScale = normalize([...r, ...g, ...b]);

    List<double> scaled(List<double> values, double scale) {
      return values.map((v) => v / scale).toList(growable: false);
    }

    return _HistogramData(
      mode: mode,
      luminance: scaled(lum, lumScale),
      red: scaled(r, rgbScale),
      green: scaled(g, rgbScale),
      blue: scaled(b, rgbScale),
    );
  }
}

class _HistogramData {
  final LumaHistogramMode mode;
  final List<double> luminance;
  final List<double> red;
  final List<double> green;
  final List<double> blue;

  const _HistogramData({
    required this.mode,
    required this.luminance,
    required this.red,
    required this.green,
    required this.blue,
  });
}

class _HistogramPainter extends CustomPainter {
  final _HistogramData data;

  _HistogramPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..strokeWidth = 1;
    canvas.drawRect(Offset.zero & size, grid..style = PaintingStyle.stroke);

    void drawSeries(List<double> values, Color color) {
      if (values.isEmpty) return;
      final path = Path();
      final stepX = size.width / (values.length - 1);
      for (var i = 0; i < values.length; i += 1) {
        final x = i * stepX;
        final y = size.height - (values[i].clamp(0, 1) * size.height);
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2;
      canvas.drawPath(path, paint);
    }

    if (data.mode == LumaHistogramMode.luminance) {
      drawSeries(data.luminance, Colors.white);
    } else {
      drawSeries(data.red, const Color(0xFFFF5252));
      drawSeries(data.green, const Color(0xFF66BB6A));
      drawSeries(data.blue, const Color(0xFF64B5F6));
    }
  }

  @override
  bool shouldRepaint(covariant _HistogramPainter oldDelegate) {
    return oldDelegate.data != data;
  }
}

class _LumaComparePage extends StatelessWidget {
  final LumaPhoto a;
  final LumaPhoto b;

  const _LumaComparePage({required this.a, required this.b});

  @override
  Widget build(BuildContext context) {
    Widget tile(LumaPhoto photo) {
      return Expanded(
        child: Container(
          color: Colors.black,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  photo.captureIdentifier,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Expanded(
                child: InteractiveViewer(
                  minScale: 1,
                  maxScale: 5,
                  child: Center(
                    child: Image.file(
                      File(photo.workingPath),
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.broken_image_outlined,
                          color: Colors.white54,
                          size: 46,
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Compare'),
      ),
      body: Row(
        children: [
          tile(a),
          Container(width: 1, color: Colors.white24),
          tile(b),
        ],
      ),
    );
  }
}
