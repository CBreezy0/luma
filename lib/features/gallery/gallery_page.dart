import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:photo_manager/photo_manager.dart';

class GalleryPage extends StatefulWidget {
  const GalleryPage({super.key});

  @override
  State<GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> {
  bool _loading = true;
  String? _error;
  List<AssetEntity> _assets = [];

  @override
  void initState() {
    super.initState();
    _initGallery();
  }

  Future<void> _initGallery() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final permission = await PhotoManager.requestPermissionExtend();
    if (!permission.isAuth) {
      setState(() {
        _loading = false;
        _error = 'Photo permission denied. Enable it in settings.';
      });
      return;
    }

    final albums = await PhotoManager.getAssetPathList(
      type: RequestType.image,
      onlyAll: true,
    );

    if (albums.isEmpty) {
      setState(() {
        _loading = false;
        _error = 'No photos found.';
      });
      return;
    }

    final recent = albums.first;
    final assets = await recent.getAssetListPaged(page: 0, size: 200);

    setState(() {
      _assets = assets;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _ErrorState(message: _error!, onRetry: _initGallery)
                : Column(
                    children: [
                      _TopBar(
                        onProTap: () {
                          // Paywall later
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Paywall coming soon')),
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: GridView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                          ),
                          itemCount: _assets.length,
                          itemBuilder: (context, index) {
                            final asset = _assets[index];
                            return _ThumbTile(
                              asset: asset,
                              onTap: () => context.push('/editor?assetId=${asset.id}'),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 8),
                      const _BottomNav(),
                    ],
                  ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final VoidCallback onProTap;
  const _TopBar({required this.onProTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'luma',
            style: TextStyle(fontSize: 16, color: Colors.black),
          ),
          GestureDetector(
            onTap: onProTap,
            child: const Text(
              'Pro',
              style: TextStyle(fontSize: 16, color: Color(0xFF777777)),
            ),
          ),
        ],
      ),
    );
  }
}

class _ThumbTile extends StatelessWidget {
  final AssetEntity asset;
  final VoidCallback onTap;
  const _ThumbTile({required this.asset, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Material(
        color: const Color(0xFFEAEAEA),
        child: InkWell(
          onTap: onTap,
          child: FutureBuilder<Uint8List?>(
            future: asset.thumbnailDataWithSize(const ThumbnailSize(256, 256)),
            builder: (context, snap) {
              final bytes = snap.data;
              if (bytes == null) {
                return const SizedBox.expand();
              }
              return Image.memory(bytes, fit: BoxFit.cover);
            },
          ),
        ),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFE5E5E5))),
        color: Colors.white,
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Gallery', style: TextStyle(fontSize: 14, color: Colors.black)),
          Text('Edit', style: TextStyle(fontSize: 14, color: Color(0xFF999999))),
          Text('Presets', style: TextStyle(fontSize: 14, color: Color(0xFF999999))),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => onRetry(),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
