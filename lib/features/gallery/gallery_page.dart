import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

import '../editor/editor_page.dart';

class GalleryPage extends StatefulWidget {
  const GalleryPage({super.key});

  @override
  State<GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> {
  bool _loading = true;
  bool _denied = false;
  Timer? _initDelay;

  final List<AssetEntity> _assets = [];
  final Map<String, Uint8List> _thumbCache = {};
  final Map<String, Future<Uint8List?>> _thumbFutures = {};
  int _page = 0;
  bool _isFetchingMore = false;
  bool _hasMore = true;
  AssetPathEntity? _album;

  static const int _pageSize = 80;
  static const ThumbnailSize _thumbSize = ThumbnailSize(360, 360);
  static const int _thumbCacheLimit = 240;
  static const Color _canvas = Color(0xFFF6F3EF);
  static const Color _tile = Color(0xFFEDE7E1);
  static const Color _darkCanvas = Color(0xFF151515);
  static const Color _darkTile = Color(0xFF2A2A2A);
  static const Color _editorCanvas = Color(0xFF151515);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _initDelay?.cancel();
      _initDelay = Timer(const Duration(milliseconds: 300), () {
        if (!mounted) return;
        _init();
      });
    });
  }

  Future<void> _init() async {
    final perm = await PhotoManager.requestPermissionExtend();
    if (!mounted) return;

    if (!perm.isAuth) {
      setState(() {
        _loading = false;
        _denied = true;
      });
      return;
    }

    await _loadMore(reset: true);
    if (!mounted) return;

    setState(() => _loading = false);
  }

  @override
  void dispose() {
    _initDelay?.cancel();
    super.dispose();
  }

  Future<void> _loadMore({bool reset = false}) async {
    if (_isFetchingMore) return;
    if (!_hasMore && !reset) return;

    setState(() => _isFetchingMore = true);

    try {
      if (reset) {
        _assets.clear();
        _page = 0;
        _hasMore = true;
      }

      if (_album == null) {
        final paths = await PhotoManager.getAssetPathList(
          type: RequestType.image,
          hasAll: true,
          onlyAll: true,
        );

        if (paths.isEmpty) {
          _hasMore = false;
          return;
        }
        _album = paths.first;
      }

      final pageAssets = await _album!.getAssetListPaged(
        page: _page,
        size: _pageSize,
      );

      _assets.addAll(pageAssets);
      _page += 1;

      if (pageAssets.length < _pageSize) {
        _hasMore = false;
      }

      _primeThumbnails(pageAssets.take(36).toList());
    } finally {
      if (mounted) {
        setState(() => _isFetchingMore = false);
      }
    }
  }

  void _openEditor(AssetEntity asset) {
    final id = asset.id;
    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 320),
        reverseTransitionDuration: const Duration(milliseconds: 240),
        pageBuilder: (context, animation, secondaryAnimation) =>
            EditorPage(assetId: id),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final backgroundFade = CurvedAnimation(
            parent: animation,
            curve: const Interval(0.0, 0.45, curve: Curves.easeOut),
          );
          final contentFade = CurvedAnimation(
            parent: animation,
            curve: const Interval(0.25, 1.0, curve: Curves.easeOut),
          );

          return Stack(
            children: [
              FadeTransition(
                opacity: backgroundFade,
                child: const ColoredBox(color: _editorCanvas),
              ),
              FadeTransition(opacity: contentFade, child: child),
            ],
          );
        },
      ),
    );
  }

  Future<Uint8List?> _getThumb(AssetEntity asset) {
    final key = asset.id;
    final cached = _thumbCache[key];
    if (cached != null) return Future.value(cached);

    final existing = _thumbFutures[key];
    if (existing != null) return existing;

    final future = asset
        .thumbnailDataWithSize(_thumbSize, format: ThumbnailFormat.jpeg)
        .then((bytes) {
          if (bytes != null) {
            _thumbCache[key] = bytes;
            if (_thumbCache.length > _thumbCacheLimit) {
              _thumbCache.remove(_thumbCache.keys.first);
            }
          }
          return bytes;
        })
        .whenComplete(() {
          _thumbFutures.remove(key);
        });

    _thumbFutures[key] = future;
    return future;
  }

  void _primeThumbnails(List<AssetEntity> assets) {
    for (final asset in assets) {
      _getThumb(asset);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final canvas = isDark ? _darkCanvas : _canvas;
    final tile = isDark ? _darkTile : _tile;
    final titleColor = isDark ? const Color(0xFFEFEAE4) : Colors.black;

    if (_loading) {
      return Scaffold(backgroundColor: canvas, body: _GallerySkeleton(tile));
    }

    if (_denied) {
      return Scaffold(
        backgroundColor: canvas,
        appBar: AppBar(
          title: Text(
            'Gallery',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
              color: titleColor,
            ),
          ),
          backgroundColor: canvas,
          elevation: 0,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Photo access is off.\nTurn it on in Settings to pick photos.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF8B857C)),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => PhotoManager.openSetting(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark
                        ? const Color(0xFFEFEAE4)
                        : const Color(0xFF151411),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Open Settings'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: canvas,
      appBar: AppBar(
        title: Text(
          'Gallery',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.4,
            color: titleColor,
          ),
        ),
        backgroundColor: canvas,
        elevation: 0,
      ),
      body: NotificationListener<ScrollNotification>(
        onNotification: (n) {
          if (n.metrics.pixels >= n.metrics.maxScrollExtent - 600) {
            _loadMore();
          }
          return false;
        },
        child: GridView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          cacheExtent: 800,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: _assets.length,
          itemBuilder: (context, i) {
            final asset = _assets[i];
            return GestureDetector(
              onTap: () => _openEditor(asset),
              child: FutureBuilder<Uint8List?>(
                future: _getThumb(asset),
                builder: (context, snapshot) {
                  final bytes = snapshot.data;
                  if (bytes == null) {
                    return Container(
                      decoration: BoxDecoration(
                        color: tile,
                        borderRadius: BorderRadius.circular(14),
                      ),
                    );
                  }
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.memory(
                      bytes,
                      fit: BoxFit.cover,
                      gaplessPlayback: true,
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

class _GallerySkeleton extends StatelessWidget {
  final Color tile;
  const _GallerySkeleton(this.tile);

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      itemCount: 30,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemBuilder: (context, i) {
        return Container(
          decoration: BoxDecoration(
            color: tile,
            borderRadius: BorderRadius.circular(14),
          ),
        );
      },
    );
  }
}
