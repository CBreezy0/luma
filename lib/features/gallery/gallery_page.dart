import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_manager/photo_manager.dart';

import '../editor/editor_page.dart';
import '../favorites/favorites_provider.dart';
import 'gallery_controller.dart';
import 'gallery_models.dart';

class GalleryPage extends ConsumerStatefulWidget {
  const GalleryPage({super.key});

  @override
  ConsumerState<GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends ConsumerState<GalleryPage> {
  final ScrollController _scrollController = ScrollController();
  final Map<String, Uint8List> _thumbCache = {};
  final Map<String, Future<Uint8List?>> _thumbFutures = {};

  static const int _thumbCacheLimit = 240;
  static const ThumbnailSize _thumbSize = ThumbnailSize(360, 360);
  static const Color _canvas = Color(0xFFF6F3EF);
  static const Color _tile = Color(0xFFEDE7E1);
  static const Color _darkCanvas = Color(0xFF151515);
  static const Color _darkTile = Color(0xFF2A2A2A);
  static const Color _editorCanvas = Color(0xFF151515);

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 600) {
      ref.read(galleryControllerProvider.notifier).loadMore();
    }
  }

  void _openEditor(String id) {
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

  void _toggleFavorite(String id) {
    ref.read(favoritesProvider.notifier).toggleFavorite(id);
  }

  void _openAlbumsSheet(GalleryState state) {
    final albums = state.collections.albums;
    if (albums.isEmpty) return;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1D1D1D) : Colors.white,
            borderRadius: BorderRadius.circular(18),
          ),
          child: SafeArea(
            top: false,
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: albums.length + 1,
              separatorBuilder: (_, _) {
                final dividerColor = isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.black.withValues(alpha: 0.06);
                return Divider(height: 1, color: dividerColor);
              },
              itemBuilder: (context, i) {
                if (i == 0) {
                  return ListTile(
                    title: const Text('Recents'),
                    onTap: () {
                      Navigator.of(context).pop();
                      ref
                          .read(galleryControllerProvider.notifier)
                          .setFilter(const GalleryFilter.recents());
                    },
                  );
                }
                final album = albums[i - 1];
                return ListTile(
                  title: Text(album.name),
                  trailing: Text(
                    '${album.count}',
                    style: TextStyle(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.6)
                          : Colors.black.withValues(alpha: 0.6),
                      fontSize: 12,
                    ),
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    ref.read(galleryControllerProvider.notifier).setFilter(
                          GalleryFilter.album(
                            id: album.id,
                            name: album.name,
                          ),
                        );
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(galleryControllerProvider);
    final favorites = ref.watch(favoritesProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final canvas = isDark ? _darkCanvas : _canvas;
    final tile = isDark ? _darkTile : _tile;
    final titleColor = isDark ? const Color(0xFFEFEAE4) : Colors.black;

    final showPermissionEmpty =
        state.permission == GalleryPermissionState.denied &&
        state.filter.type != GalleryFilterType.samples;

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
        actions: [
          PopupMenuButton<GallerySort>(
            initialValue: state.sort,
            onSelected: (value) {
              ref.read(galleryControllerProvider.notifier).setSort(value);
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: GallerySort.newest,
                child: Text('Newest'),
              ),
              PopupMenuItem(
                value: GallerySort.oldest,
                child: Text('Oldest'),
              ),
              PopupMenuItem(
                value: GallerySort.recentlyEdited,
                child: Text('Recently edited'),
              ),
            ],
            icon: Icon(Icons.swap_vert, color: titleColor),
          ),
        ],
      ),
      body: Column(
        children: [
          _FilterBar(
            state: state,
            onSelect: (filter) {
              ref.read(galleryControllerProvider.notifier).setFilter(filter);
            },
            onAlbumsTap: () => _openAlbumsSheet(state),
          ),
          Expanded(
            child: Builder(
              builder: (context) {
                if (state.isLoading && state.items.isEmpty) {
                  return _GallerySkeleton(tile);
                }

                if (showPermissionEmpty) {
                  return _PermissionEmptyState(
                    onOpenSettings: () => PhotoManager.openSetting(),
                    onTrySamples: () =>
                        ref.read(galleryControllerProvider.notifier).showSamples(),
                  );
                }

                if (state.filter.type == GalleryFilterType.favorites &&
                    favorites.isEmpty) {
                  return const _EmptyState(
                    title: 'No favorites yet',
                    subtitle: 'Tap the heart on any photo to save it here.',
                  );
                }

                if (state.items.isEmpty) {
                  return _EmptyState(
                    title: 'No photos found',
                    subtitle: 'Try another filter or sample photos.',
                    action: TextButton(
                      onPressed: () => ref
                          .read(galleryControllerProvider.notifier)
                          .showSamples(),
                      child: const Text('Try Sample Photos'),
                    ),
                  );
                }

                return NotificationListener<ScrollNotification>(
                  onNotification: (n) {
                    if (n.metrics.pixels >=
                        n.metrics.maxScrollExtent - 600) {
                      ref.read(galleryControllerProvider.notifier).loadMore();
                    }
                    return false;
                  },
                  child: GridView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    cacheExtent: 900,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount:
                        state.items.length + (state.isLoadingMore ? 1 : 0),
                    itemBuilder: (context, i) {
                      if (i >= state.items.length) {
                        return const Center(
                          child: SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        );
                      }
                      final item = state.items[i];
                      final isFavorite = favorites.contains(item.id);
                      return GestureDetector(
                        onTap: () => _openEditor(item.id),
                        onLongPress: () => _toggleFavorite(item.id),
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: _GalleryThumb(
                                  item: item,
                                  tile: tile,
                                  getThumb: _getThumb,
                                ),
                              ),
                            ),
                            Positioned(
                              top: 6,
                              right: 6,
                              child: GestureDetector(
                                onTap: () => _toggleFavorite(item.id),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.45),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    isFavorite
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                    size: 16,
                                    color: isFavorite
                                        ? const Color(0xFFE87A7A)
                                        : Colors.white.withValues(alpha: 0.85),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _GalleryThumb extends StatelessWidget {
  final GalleryItem item;
  final Color tile;
  final Future<Uint8List?> Function(AssetEntity asset) getThumb;

  const _GalleryThumb({
    required this.item,
    required this.tile,
    required this.getThumb,
  });

  @override
  Widget build(BuildContext context) {
    if (item.type == GalleryItemType.sample) {
      final sample = item.sample;
      if (sample == null) return const SizedBox.shrink();
      return Image.asset(sample.assetPath, fit: BoxFit.cover);
    }

    final asset = item.asset;
    if (asset == null) {
      return Container(color: tile);
    }

    return FutureBuilder<Uint8List?>(
      future: getThumb(asset),
      builder: (context, snapshot) {
        final bytes = snapshot.data;
        if (bytes == null) {
          return Container(color: tile);
        }
        return Image.memory(bytes, fit: BoxFit.cover, gaplessPlayback: true);
      },
    );
  }
}

class _FilterBar extends StatelessWidget {
  final GalleryState state;
  final ValueChanged<GalleryFilter> onSelect;
  final VoidCallback onAlbumsTap;

  const _FilterBar({
    required this.state,
    required this.onSelect,
    required this.onAlbumsTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor =
        isDark ? const Color(0xFFEFEAE4) : const Color(0xFF151515);
    final inactiveColor = isDark
        ? Colors.white.withValues(alpha: 0.5)
        : Colors.black.withValues(alpha: 0.5);

    final chips = <Widget>[
      _FilterChipButton(
        label: 'Recents',
        selected: state.filter.type == GalleryFilterType.recents,
        activeColor: activeColor,
        inactiveColor: inactiveColor,
        onTap: () => onSelect(const GalleryFilter.recents()),
      ),
      _FilterChipButton(
        label: 'Favorites',
        selected: state.filter.type == GalleryFilterType.favorites,
        activeColor: activeColor,
        inactiveColor: inactiveColor,
        onTap: () => onSelect(const GalleryFilter.favorites()),
      ),
    ];

    if (state.collections.screenshots != null) {
      chips.add(
        _FilterChipButton(
          label: 'Screenshots',
          selected: state.filter.type == GalleryFilterType.screenshots,
          activeColor: activeColor,
          inactiveColor: inactiveColor,
          onTap: () => onSelect(const GalleryFilter.screenshots()),
        ),
      );
    }

    chips.add(
      _FilterChipButton(
        label: 'RAW',
        selected: state.filter.type == GalleryFilterType.raw,
        activeColor: activeColor,
        inactiveColor: inactiveColor,
        onTap: () => onSelect(const GalleryFilter.raw()),
      ),
    );

    chips.add(
      _FilterChipButton(
        label: state.filter.type == GalleryFilterType.album
            ? (state.filter.albumName ?? 'Album')
            : 'Albums',
        selected: state.filter.type == GalleryFilterType.album,
        activeColor: activeColor,
        inactiveColor: inactiveColor,
        onTap: onAlbumsTap,
      ),
    );

    if (state.filter.type == GalleryFilterType.samples) {
      chips.add(
        _FilterChipButton(
          label: 'Samples',
          selected: true,
          activeColor: activeColor,
          inactiveColor: inactiveColor,
          onTap: () => onSelect(const GalleryFilter.samples()),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final chip in chips) ...[
              chip,
              const SizedBox(width: 8),
            ],
          ],
        ),
      ),
    );
  }
}

class _FilterChipButton extends StatelessWidget {
  final String label;
  final bool selected;
  final Color activeColor;
  final Color inactiveColor;
  final VoidCallback onTap;

  const _FilterChipButton({
    required this.label,
    required this.selected,
    required this.activeColor,
    required this.inactiveColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? activeColor.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected
                ? activeColor.withValues(alpha: 0.5)
                : inactiveColor.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
            color: selected ? activeColor : inactiveColor,
          ),
        ),
      ),
    );
  }
}

class _PermissionEmptyState extends StatelessWidget {
  final VoidCallback onOpenSettings;
  final VoidCallback onTrySamples;

  const _PermissionEmptyState({
    required this.onOpenSettings,
    required this.onTrySamples,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Photo access is off.\nTurn it on to view your library.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF8B857C)),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: onOpenSettings,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEFEAE4),
                foregroundColor: const Color(0xFF151411),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Allow Photos Access'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: onTrySamples,
              child: const Text('Try Sample Photos'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? action;

  const _EmptyState({
    required this.title,
    required this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subtitleColor = isDark
        ? Colors.white.withValues(alpha: 0.6)
        : Colors.black.withValues(alpha: 0.6);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(color: subtitleColor),
            ),
            if (action != null) ...[
              const SizedBox(height: 12),
              action!,
            ],
          ],
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
