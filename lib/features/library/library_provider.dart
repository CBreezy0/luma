import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../camera/camera_models.dart';
import 'library_models.dart';
import 'library_repository.dart';
import 'thumbnail_service.dart';

const int kLumaLibraryPageSize = 60;

final lumaLibraryRepositoryProvider = Provider<LumaLibraryRepository>((ref) {
  return LumaLibraryRepository();
});

final lumaThumbnailServiceProvider = Provider<LibraryThumbnailService>((ref) {
  final repository = ref.watch(lumaLibraryRepositoryProvider);
  final service = LibraryThumbnailService(repository: repository);
  ref.onDispose(() {
    unawaited(service.dispose());
  });
  return service;
});

final lumaLibraryProvider =
    StateNotifierProvider<LumaLibraryController, LumaLibraryState>((ref) {
      final repository = ref.watch(lumaLibraryRepositoryProvider);
      final thumbnailService = ref.watch(lumaThumbnailServiceProvider);
      final controller = LumaLibraryController(repository, thumbnailService);
      ref.onDispose(controller.dispose);
      return controller;
    });

class LumaLibraryState {
  final bool isLoading;
  final bool isLoadingMore;
  final String? errorMessage;
  final List<LumaPhoto> photos;
  final LumaPhotoSort sort;
  final LumaSmartAlbum album;
  final int pageSize;
  final int minimumRating;
  final String searchQuery;
  final int totalCount;

  const LumaLibraryState({
    required this.isLoading,
    required this.isLoadingMore,
    required this.errorMessage,
    required this.photos,
    required this.sort,
    required this.album,
    required this.pageSize,
    required this.minimumRating,
    required this.searchQuery,
    required this.totalCount,
  });

  factory LumaLibraryState.initial() {
    return const LumaLibraryState(
      isLoading: true,
      isLoadingMore: false,
      errorMessage: null,
      photos: <LumaPhoto>[],
      sort: LumaPhotoSort.newest,
      album: LumaSmartAlbum.all,
      pageSize: kLumaLibraryPageSize,
      minimumRating: 0,
      searchQuery: '',
      totalCount: 0,
    );
  }

  LumaLibraryState copyWith({
    bool? isLoading,
    bool? isLoadingMore,
    Object? errorMessage = _unset,
    List<LumaPhoto>? photos,
    LumaPhotoSort? sort,
    LumaSmartAlbum? album,
    int? pageSize,
    int? minimumRating,
    String? searchQuery,
    int? totalCount,
  }) {
    return LumaLibraryState(
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
      photos: photos ?? this.photos,
      sort: sort ?? this.sort,
      album: album ?? this.album,
      pageSize: pageSize ?? this.pageSize,
      minimumRating: minimumRating ?? this.minimumRating,
      searchQuery: searchQuery ?? this.searchQuery,
      totalCount: totalCount ?? this.totalCount,
    );
  }

  List<LumaPhoto> get filteredPhotos => photos;

  List<LumaPhoto> get visiblePhotos => photos;

  bool get hasMore => photos.length < totalCount;

  Map<String, int> get pairedCaptureCounts {
    final counts = <String, int>{};
    for (final photo in photos) {
      counts.update(
        photo.captureIdentifier,
        (value) => value + 1,
        ifAbsent: () => 1,
      );
    }
    return counts;
  }
}

const Object _unset = Object();

class LumaLibraryController extends StateNotifier<LumaLibraryState> {
  final LumaLibraryRepository _repository;
  final LibraryThumbnailService _thumbnailService;
  StreamSubscription<String>? _thumbnailUpdatesSubscription;
  bool _disposed = false;
  bool _didScheduleThumbnailRecovery = false;
  Timer? _thumbnailRecoveryDebounce;

  LumaLibraryController(this._repository, this._thumbnailService)
    : super(LumaLibraryState.initial()) {
    _thumbnailUpdatesSubscription = _thumbnailService.updates.listen((photoId) {
      unawaited(_refreshPhotoInState(photoId));
    });
    unawaited(initialize());
  }

  Future<void> initialize() async {
    if (_disposed) return;
    await _reload(reset: true);
  }

  Future<void> refresh() async {
    if (_disposed) return;
    await _reload(reset: true);
  }

  Future<void> _reload({required bool reset}) async {
    if (_disposed) return;
    if (!reset && (!state.hasMore || state.isLoadingMore || state.isLoading)) {
      return;
    }

    final offset = reset ? 0 : state.photos.length;
    if (reset) {
      state = state.copyWith(
        isLoading: true,
        isLoadingMore: false,
        errorMessage: null,
      );
    } else {
      state = state.copyWith(isLoadingMore: true, errorMessage: null);
    }

    try {
      await _repository.initialize();
      final result = await _repository.queryPhotosPage(
        sort: state.sort,
        album: state.album,
        minimumRating: state.minimumRating,
        searchQuery: state.searchQuery,
        offset: offset,
        limit: state.pageSize,
      );
      if (_disposed || !mounted) return;
      final nextPhotos = reset
          ? result.photos
          : List<LumaPhoto>.unmodifiable([...state.photos, ...result.photos]);

      state = state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        errorMessage: null,
        photos: List<LumaPhoto>.unmodifiable(nextPhotos),
        totalCount: result.totalCount,
      );
      await _thumbnailService.enqueueForPhotos(nextPhotos);
      if (!_didScheduleThumbnailRecovery) {
        _didScheduleThumbnailRecovery = true;
        _thumbnailRecoveryDebounce?.cancel();
        _thumbnailRecoveryDebounce = Timer(
          const Duration(milliseconds: 250),
          () {
            unawaited(_thumbnailService.enqueueMissingThumbnails(limit: 2000));
          },
        );
      }
    } catch (error) {
      if (_disposed || !mounted) return;
      state = state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        errorMessage: 'Could not load library: $error',
      );
    }
  }

  void loadMore() {
    if (_disposed) return;
    unawaited(_reload(reset: false));
  }

  void setSort(LumaPhotoSort sort) {
    if (_disposed) return;
    state = state.copyWith(sort: sort);
    unawaited(_reload(reset: true));
  }

  void setAlbum(LumaSmartAlbum album) {
    if (_disposed) return;
    state = state.copyWith(album: album);
    unawaited(_reload(reset: true));
  }

  void setMinimumRating(int rating) {
    if (_disposed) return;
    state = state.copyWith(minimumRating: rating.clamp(0, 5));
    unawaited(_reload(reset: true));
  }

  void setSearchQuery(String query) {
    if (_disposed) return;
    state = state.copyWith(searchQuery: query);
    unawaited(_reload(reset: true));
  }

  Future<void> saveCapturedPhoto(CameraCaptureResult capture) async {
    if (_disposed) return;
    try {
      final photo = await _repository.addCapturedPhoto(capture);
      await _thumbnailService.enqueueForPhotos([photo]);
      await refresh();
    } catch (error) {
      if (_disposed || !mounted) return;
      state = state.copyWith(errorMessage: 'Save capture failed: $error');
    }
  }

  Future<void> importPhotoPaths(List<String> paths) async {
    if (_disposed || paths.isEmpty) return;
    try {
      final imported = await _repository.importPhotoPaths(paths);
      await _thumbnailService.enqueueForPhotos(imported);
      await refresh();
    } catch (error) {
      if (_disposed || !mounted) return;
      state = state.copyWith(errorMessage: 'Import failed: $error');
    }
  }

  Future<void> toggleFavorite(String photoId) async {
    if (_disposed) return;
    final current = state.photos;
    final index = current.indexWhere((photo) => photo.photoId == photoId);
    if (index < 0) return;
    await setFavorites({photoId}, !current[index].isFavorite);
  }

  Future<void> setFavorite(String photoId, bool isFavorite) async {
    await setFavorites({photoId}, isFavorite);
  }

  Future<void> setFavorites(Set<String> photoIds, bool isFavorite) async {
    if (_disposed || photoIds.isEmpty) return;
    try {
      await _repository.updatePhotos(photoIds, (photo) {
        return photo.copyWith(isFavorite: isFavorite);
      });
      await refresh();
    } catch (error) {
      if (_disposed || !mounted) return;
      state = state.copyWith(errorMessage: 'Favorite update failed: $error');
    }
  }

  Future<void> setRating(String photoId, int rating) async {
    await setRatings({photoId}, rating);
  }

  Future<void> setRatings(Set<String> photoIds, int rating) async {
    if (_disposed || photoIds.isEmpty) return;
    final safeRating = rating.clamp(0, 5);
    try {
      await _repository.updatePhotos(photoIds, (photo) {
        return photo.copyWith(rating: safeRating);
      });
      await refresh();
    } catch (error) {
      if (_disposed || !mounted) return;
      state = state.copyWith(errorMessage: 'Rating update failed: $error');
    }
  }

  Future<void> setColorLabel(String photoId, LumaColorLabel label) async {
    await setColorLabels({photoId}, label);
  }

  Future<void> setColorLabels(
    Set<String> photoIds,
    LumaColorLabel label,
  ) async {
    if (_disposed || photoIds.isEmpty) return;
    try {
      await _repository.updatePhotos(photoIds, (photo) {
        return photo.copyWith(colorLabel: label);
      });
      await refresh();
    } catch (error) {
      if (_disposed || !mounted) return;
      state = state.copyWith(errorMessage: 'Label update failed: $error');
    }
  }

  Future<void> deletePhotos(Set<String> photoIds) async {
    if (_disposed || photoIds.isEmpty) return;
    await _repository.removePhotos(photoIds);
    await refresh();
  }

  Future<void> addEditInstructions(
    Set<String> photoIds,
    List<LumaEditInstruction> instructions,
  ) async {
    if (_disposed || photoIds.isEmpty || instructions.isEmpty) return;
    await _repository.applyBatchEdits(photoIds, instructions);
    await refresh();
  }

  Future<void> duplicateActiveVersion(String photoId) async {
    if (_disposed) return;
    await _repository.duplicateActiveVersion(photoId);
    await refresh();
  }

  Future<void> revertToOriginal(String photoId) async {
    if (_disposed) return;
    await _repository.revertToOriginalVersion(photoId);
    await refresh();
  }

  Future<String?> exportPhoto(String photoId) async {
    if (_disposed) return null;
    try {
      return await _repository.exportPhoto(photoId);
    } catch (error) {
      if (_disposed || !mounted) return null;
      state = state.copyWith(errorMessage: 'Export failed: $error');
      return null;
    }
  }

  Future<void> ensureThumbnail(String photoId) async {
    if (_disposed || photoId.isEmpty) return;
    await _thumbnailService.enqueueForPhotoId(photoId);
  }

  Future<void> _refreshPhotoInState(String photoId) async {
    if (_disposed || !mounted) return;
    final index = state.photos.indexWhere((photo) => photo.photoId == photoId);
    if (index < 0) return;
    final updated = await _repository.photoById(photoId);
    if (_disposed || !mounted || updated == null) return;
    final next = List<LumaPhoto>.from(state.photos);
    next[index] = updated;
    state = state.copyWith(photos: List<LumaPhoto>.unmodifiable(next));
  }

  @override
  void dispose() {
    _disposed = true;
    _thumbnailRecoveryDebounce?.cancel();
    _thumbnailUpdatesSubscription?.cancel();
    unawaited(_repository.close());
    super.dispose();
  }
}
