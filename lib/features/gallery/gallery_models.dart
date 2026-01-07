import 'package:flutter/foundation.dart';
import 'package:photo_manager/photo_manager.dart';

import '../samples/sample_images.dart';

enum GalleryFilterType { recents, favorites, screenshots, raw, album, samples }

enum GallerySort { newest, oldest, recentlyEdited }

@immutable
class GalleryFilter {
  final GalleryFilterType type;
  final String? albumId;
  final String? albumName;

  const GalleryFilter._(this.type, {this.albumId, this.albumName});

  const GalleryFilter.recents() : this._(GalleryFilterType.recents);

  const GalleryFilter.favorites() : this._(GalleryFilterType.favorites);

  const GalleryFilter.screenshots() : this._(GalleryFilterType.screenshots);

  const GalleryFilter.raw() : this._(GalleryFilterType.raw);

  const GalleryFilter.album({required String id, required String name})
      : this._(GalleryFilterType.album, albumId: id, albumName: name);

  const GalleryFilter.samples() : this._(GalleryFilterType.samples);
}

@immutable
class GalleryCollection {
  final String id;
  final String name;
  final AssetPathEntity path;
  final int count;
  final bool isScreenshots;

  const GalleryCollection({
    required this.id,
    required this.name,
    required this.path,
    required this.count,
    this.isScreenshots = false,
  });
}

enum GalleryItemType { asset, sample }

@immutable
class GalleryItem {
  final String id;
  final GalleryItemType type;
  final AssetEntity? asset;
  final SampleImage? sample;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  GalleryItem.asset(AssetEntity this.asset)
      : id = asset.id,
        type = GalleryItemType.asset,
        sample = null,
        createdAt = asset.createDateTime,
        updatedAt = asset.modifiedDateTime;

  GalleryItem.sample(SampleImage this.sample)
      : id = sample.id,
        type = GalleryItemType.sample,
        asset = null,
        createdAt = null,
        updatedAt = null;
}
