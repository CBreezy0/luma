import 'package:shared_preferences/shared_preferences.dart';

class FavoritesRepository {
  static const String _key = 'favorite_ids';

  Future<Set<String>> loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList(_key) ?? const <String>[];
    return Set<String>.from(stored);
  }

  Future<void> saveFavorites(Set<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, ids.toList());
  }
}
