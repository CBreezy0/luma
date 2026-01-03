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

  final List<AssetEntity> _assets = [];
  int _page = 0;
  bool _isFetchingMore = false;
  bool _hasMore = true;

  static const int _pageSize = 80;

  @override
  void initState() {
    super.initState();
    _init();
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

      final paths = await PhotoManager.getAssetPathList(
        type: RequestType.image,
        hasAll: true,
        onlyAll: true,
      );

      if (paths.isEmpty) {
        _hasMore = false;
        return;
      }

      final album = paths.first;
      final pageAssets = await album.getAssetListPaged(
        page: _page,
        size: _pageSize,
      );

      _assets.addAll(pageAssets);
      _page += 1;

      if (pageAssets.length < _pageSize) {
        _hasMore = false;
      }
    } finally {
      if (mounted) {
        setState(() => _isFetchingMore = false);
      }
    }
  }

  void _openEditor(AssetEntity asset) {
    final id = asset.id;
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => EditorPage(assetId: id)));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_denied) {
      return Scaffold(
        appBar: AppBar(title: const Text('Gallery')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Photo access is off.\nTurn it on in Settings to pick photos.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => PhotoManager.openSetting(),
                  child: const Text('Open Settings'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Gallery')),
      body: NotificationListener<ScrollNotification>(
        onNotification: (n) {
          if (n.metrics.pixels >= n.metrics.maxScrollExtent - 600) {
            _loadMore();
          }
          return false;
        },
        child: GridView.builder(
          padding: const EdgeInsets.all(2),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 2,
            mainAxisSpacing: 2,
          ),
          itemCount: _assets.length,
          itemBuilder: (context, i) {
            final asset = _assets[i];
            return GestureDetector(
              onTap: () => _openEditor(asset),
              child: FutureBuilder<Uint8List?>(
                future: asset.thumbnailDataWithSize(
                  const ThumbnailSize(400, 400),
                ),
                builder: (context, snapshot) {
                  final bytes = snapshot.data;
                  if (bytes == null) {
                    return Container(color: const Color(0xFFE6E6E6));
                  }
                  return Image.memory(
                    bytes,
                    fit: BoxFit.cover,
                    gaplessPlayback: true,
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
