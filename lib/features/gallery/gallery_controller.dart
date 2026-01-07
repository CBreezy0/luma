import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_manager/photo_manager.dart';

import '../favorites/favorites_provider.dart';
import '../samples/sample_images.dart';
import 'gallery_collections.dart';
import 'gallery_models.dart';
import 'gallery_pager.dart';

enum GalleryPermissionState { unknown, denied, authorized }

@immutable
class GalleryState {
  final GalleryPermissionState permission;
  final GalleryFilter filter;
  final GallerySort sort;
  final List<GalleryItem> items;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final GalleryCollections collections;

  const GalleryState({
    required this.permission,
    required this.filter,
    required this.sort,
    required this.items,
    required this.isLoading,
    required this.isLoadingMore,
    required this.hasMore,
    required this.collections,
  });

  factory GalleryState.initial() {
    return const GalleryState(
      permission: GalleryPermissionState.unknown,
      filter: GalleryFilter.recents(),
      sort: GallerySort.newest,
      items: [],
      isLoading: false,
      isLoadingMore: false,
      hasMore: true,
      collections: GalleryCollections(
        recents: null,
        albums: [],
        screenshots: null,
      ),
    );
  }

  GalleryState copyWith({
    GalleryPermissionState? permission,
    GalleryFilter? filter,
    GallerySort? sort,
    List<GalleryItem>? items,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    GalleryCollections? collections,
  }) {
    return GalleryState(
      permission: permission ?? this.permission,
      filter: filter ?? this.filter,
      sort: sort ?? this.sort,
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      collections: collections ?? this.collections,
    );
  }
}

final galleryControllerProvider =
    StateNotifierProvider<GalleryController, GalleryState>((ref) {
  final controller = GalleryController(
    collectionsRepository: GalleryCollectionsRepository(),
  );
  ref.listen<Set<String>>(favoritesProvider, (_, next) {
    controller.updateFavorites(next);
  });
  controller.init();
  return controller;
});

class GalleryController extends StateNotifier<GalleryState> {
  GalleryController({required this.collectionsRepository})
      : super(GalleryState.initial());

  final GalleryCollectionsRepository collectionsRepository;
  final List<SampleImage> _samples = SampleImages.items;

  GalleryPager? _pager;
  int _loadToken = 0;
  bool _initialized = false;
  Set<String> _favorites = {};

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    state = state.copyWith(isLoading: true);

    final perm = await PhotoManager.requestPermissionExtend();
    if (!perm.isAuth && !perm.hasAccess) {
      state = state.copyWith(
        permission: GalleryPermissionState.denied,
        isLoading: false,
        items: const [],
        hasMore: false,
      );
      return;
    }

    final collections = await collectionsRepository.loadCollections();
    state = state.copyWith(
      permission: GalleryPermissionState.authorized,
      collections: collections,
    );
    await _resetAndLoad();
  }

  void updateFavorites(Set<String> favorites) {
    _favorites = favorites;
    if (state.filter.type == GalleryFilterType.favorites) {
      unawaited(_resetAndLoad());
    }
  }

  Future<void> setFilter(GalleryFilter filter) async {
    if (filter.type == state.filter.type &&
        filter.albumId == state.filter.albumId) {
      return;
    }
    state = state.copyWith(filter: filter);
    await _resetAndLoad();
  }

  Future<void> setSort(GallerySort sort) async {
    if (sort == state.sort) return;
    state = state.copyWith(sort: sort);
    await _resetAndLoad();
  }

  Future<void> refresh() async {
    await _resetAndLoad();
  }

  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;
    await _loadPage(reset: false);
  }

  Future<void> showSamples() async {
    await setFilter(const GalleryFilter.samples());
  }

  Future<void> _resetAndLoad() async {
    await _loadPage(reset: true);
  }

  Future<void> _loadPage({required bool reset}) async {
    final token = ++_loadToken;
    if (reset) {
      state = state.copyWith(
        items: const [],
        hasMore: true,
        isLoading: true,
        isLoadingMore: false,
      );
      _pager = GalleryPager(
        filter: state.filter,
        sort: state.sort,
        collections: state.collections,
        favorites: _favorites,
        samples: _samples,
        pageSize: 120,
      );
    } else {
      state = state.copyWith(isLoadingMore: true);
    }

    final pager = _pager;
    if (pager == null) return;
    final items = await pager.loadNext();
    if (token != _loadToken) return;

    final updated =
        reset ? items : [...state.items, ...items];

    state = state.copyWith(
      items: updated,
      hasMore: pager.hasMore,
      isLoading: false,
      isLoadingMore: false,
    );
  }
}
