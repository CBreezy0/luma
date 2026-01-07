import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'favorites_repository.dart';

final favoritesRepositoryProvider = Provider<FavoritesRepository>((ref) {
  return FavoritesRepository();
});

final favoritesProvider =
    StateNotifierProvider<FavoritesController, Set<String>>((ref) {
  final repo = ref.watch(favoritesRepositoryProvider);
  final controller = FavoritesController(repo);
  controller.load();
  return controller;
});

class FavoritesController extends StateNotifier<Set<String>> {
  FavoritesController(this._repo) : super(const {});

  final FavoritesRepository _repo;

  Future<void> load() async {
    state = await _repo.loadFavorites();
  }

  Future<void> toggleFavorite(String id) async {
    final next = Set<String>.from(state);
    if (next.contains(id)) {
      next.remove(id);
    } else {
      next.add(id);
    }
    state = next;
    await _repo.saveFavorites(next);
  }
}
