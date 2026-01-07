import 'package:photo_manager/photo_manager.dart';

import '../samples/sample_images.dart';
import 'gallery_collections.dart';
import 'gallery_models.dart';

class GalleryPager {
  GalleryPager({
    required this.filter,
    required this.sort,
    required this.collections,
    required this.favorites,
    required this.samples,
    this.pageSize = 120,
  });

  final GalleryFilter filter;
  final GallerySort sort;
  final GalleryCollections collections;
  final Set<String> favorites;
  final List<SampleImage> samples;
  final int pageSize;

  int _page = 0;
  bool _hasMore = true;
  bool _sampleFavoritesConsumed = false;
  int _samplePage = 0;

  bool get hasMore => _hasMore;

  Future<List<GalleryItem>> loadNext() async {
    if (!_hasMore) return const [];

    switch (filter.type) {
      case GalleryFilterType.samples:
        return _loadSamplePage();
      case GalleryFilterType.recents:
      case GalleryFilterType.album:
      case GalleryFilterType.screenshots:
        return _loadDirectPage();
      case GalleryFilterType.favorites:
        return _loadFilteredPage(_isFavorite);
      case GalleryFilterType.raw:
        return _loadFilteredPage(_isRaw);
    }
  }

  Future<List<GalleryItem>> _loadSamplePage() async {
    final start = _samplePage * pageSize;
    if (start >= samples.length) {
      _hasMore = false;
      return const [];
    }
    final end = (start + pageSize).clamp(0, samples.length);
    _samplePage += 1;
    if (end >= samples.length) _hasMore = false;
    return [
      for (final sample in samples.sublist(start, end))
        GalleryItem.sample(sample),
    ];
  }

  Future<List<GalleryItem>> _loadDirectPage() async {
    final path = _sourcePath();
    if (path == null) {
      _hasMore = false;
      return const [];
    }
    final sorted = _sortedPath(path);
    final assets = await sorted.getAssetListPaged(
      page: _page,
      size: pageSize,
    );
    _page += 1;
    if (assets.length < pageSize) _hasMore = false;
    return [
      for (final asset in assets)
        if (asset.type == AssetType.image) GalleryItem.asset(asset),
    ];
  }

  Future<List<GalleryItem>> _loadFilteredPage(
    Future<bool> Function(AssetEntity asset) predicate,
  ) async {
    final path = _sourcePath();
    if (path == null) {
      _hasMore = false;
      return const [];
    }

    final items = <GalleryItem>[];
    if (filter.type == GalleryFilterType.favorites &&
        !_sampleFavoritesConsumed) {
      final sampleFavorites = samples
          .where((s) => favorites.contains(s.id))
          .map(GalleryItem.sample)
          .toList();
      if (sampleFavorites.isNotEmpty) {
        items.addAll(
          sampleFavorites.take(pageSize),
        );
      }
      _sampleFavoritesConsumed = true;
      if (items.length >= pageSize) {
        return items;
      }
    }

    final sorted = _sortedPath(path);
    while (items.length < pageSize && _hasMore) {
      final assets = await sorted.getAssetListPaged(
        page: _page,
        size: pageSize,
      );
      _page += 1;
      if (assets.isEmpty) {
        _hasMore = false;
        break;
      }
      for (final asset in assets) {
        if (asset.type != AssetType.image) {
          continue;
        }
        if (await predicate(asset)) {
          items.add(GalleryItem.asset(asset));
          if (items.length >= pageSize) break;
        }
      }
      if (assets.length < pageSize) {
        _hasMore = false;
      }
    }

    return items;
  }

  Future<bool> _isFavorite(AssetEntity asset) async {
    return favorites.contains(asset.id);
  }

  Future<bool> _isRaw(AssetEntity asset) async {
    if (asset.type != AssetType.image) return false;
    final title = asset.title?.toLowerCase() ?? '';
    final mime = asset.mimeType?.toLowerCase() ?? '';
    if (_isRawName(title) || _isRawMime(mime)) return true;
    try {
      final asyncTitle = (await asset.titleAsync).toLowerCase();
      if (_isRawName(asyncTitle)) return true;
      final subtypeTitle = (await asset.titleAsyncWithSubtype).toLowerCase();
      if (_isRawName(subtypeTitle)) return true;
    } catch (_) {
      // ignore lookup failures
    }
    return false;
  }

  bool _isRawName(String name) {
    return name.endsWith('.dng') ||
        name.endsWith('.nef') ||
        name.endsWith('.cr2') ||
        name.endsWith('.arw') ||
        name.endsWith('.rw2') ||
        name.endsWith('.orf');
  }

  bool _isRawMime(String mime) {
    return mime.contains('raw') || mime.contains('dng');
  }

  AssetPathEntity? _sourcePath() {
    switch (filter.type) {
      case GalleryFilterType.recents:
      case GalleryFilterType.raw:
      case GalleryFilterType.favorites:
        return collections.recents?.path;
      case GalleryFilterType.screenshots:
        return collections.screenshots?.path;
      case GalleryFilterType.album:
        if (filter.albumId == null) return collections.recents?.path;
        for (final album in collections.albums) {
          if (album.id == filter.albumId) return album.path;
        }
        return collections.recents?.path;
      case GalleryFilterType.samples:
        return null;
    }
  }

  AssetPathEntity _sortedPath(AssetPathEntity path) {
    final order = switch (sort) {
      GallerySort.newest => const OrderOption(
          type: OrderOptionType.createDate,
          asc: false,
        ),
      GallerySort.oldest => const OrderOption(
          type: OrderOptionType.createDate,
          asc: true,
        ),
      GallerySort.recentlyEdited => const OrderOption(
          type: OrderOptionType.updateDate,
          asc: false,
        ),
    };
    final option = FilterOptionGroup(orders: [order]);
    return path.copyWith(filterOption: option);
  }
}
