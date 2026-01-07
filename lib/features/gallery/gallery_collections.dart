import 'package:photo_manager/photo_manager.dart';

import 'gallery_models.dart';

class GalleryCollections {
  final GalleryCollection? recents;
  final List<GalleryCollection> albums;
  final GalleryCollection? screenshots;

  const GalleryCollections({
    required this.recents,
    required this.albums,
    required this.screenshots,
  });
}

class GalleryCollectionsRepository {
  Future<GalleryCollections> loadCollections() async {
    final recentsList = await PhotoManager.getAssetPathList(
      type: RequestType.image,
      hasAll: true,
      onlyAll: true,
    );

    final albums = await PhotoManager.getAssetPathList(
      type: RequestType.image,
      hasAll: false,
      onlyAll: false,
    );

    final recents = recentsList.isNotEmpty
        ? await _wrapCollection(recentsList.first)
        : null;

    GalleryCollection? screenshots;
    final wrappedAlbums = <GalleryCollection>[];
    for (final album in albums) {
      final wrapped = await _wrapCollection(album);
      final lower = wrapped.name.toLowerCase();
      if (lower.contains('video')) {
        continue;
      }
      wrappedAlbums.add(wrapped);
      if (screenshots == null &&
          (lower.contains('screenshot') || lower.contains('screen shot'))) {
        screenshots = GalleryCollection(
          id: wrapped.id,
          name: wrapped.name,
          path: wrapped.path,
          count: wrapped.count,
          isScreenshots: true,
        );
      }
    }

    return GalleryCollections(
      recents: recents,
      albums: wrappedAlbums,
      screenshots: screenshots,
    );
  }

  Future<GalleryCollection> _wrapCollection(AssetPathEntity path) async {
    final count = await path.assetCountAsync;
    return GalleryCollection(
      id: path.id,
      name: path.name,
      path: path,
      count: count,
    );
  }
}
