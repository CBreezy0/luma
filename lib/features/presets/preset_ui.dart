import 'preset_models.dart';
import 'preset_registry.dart';

class PresetCategoryGroup {
  final PresetCategory category;
  final List<LumaPreset> presets;

  const PresetCategoryGroup({
    required this.category,
    required this.presets,
  });
}

class PresetUi {
  static const List<PresetCategory> categories = [
    PresetCategory(
      id: 'portrait',
      name: 'Portrait',
      description: 'Soft skin, calm light.',
    ),
    PresetCategory(
      id: 'landscape',
      name: 'Landscape',
      description: 'Depth and color.',
    ),
    PresetCategory(
      id: 'night',
      name: 'Night',
      description: 'Low light and contrast.',
    ),
    PresetCategory(
      id: 'film',
      name: 'Film',
      description: 'Analog tones and grain.',
    ),
    PresetCategory(
      id: 'street',
      name: 'Street',
      description: 'Crisp edges and grit.',
    ),
    PresetCategory(
      id: 'indoor',
      name: 'Indoor',
      description: 'Warm interior light.',
    ),
    PresetCategory(
      id: 'bw',
      name: 'B&W',
      description: 'Monochrome contrast.',
    ),
    PresetCategory(
      id: 'vibrant',
      name: 'Vibrant',
      description: 'Color pop and punch.',
    ),
    PresetCategory(
      id: 'everyday',
      name: 'Everyday',
      description: 'Balanced, clean looks.',
    ),
  ];

  static final Map<String, PresetCategory> _categoryById = {
    for (final c in categories) c.id: c,
  };

  static final Map<String, int> _ranks = {
    for (var i = 0; i < PresetRegistry.all.length; i++)
      PresetRegistry.all[i].id: i,
  };

  static PresetCategory categoryFor(LumaPreset preset) {
    if (preset.bestFor.contains(LumaPhotoType.portrait)) {
      return _categoryById['portrait']!;
    }
    if (preset.bestFor.contains(LumaPhotoType.landscape)) {
      return _categoryById['landscape']!;
    }
    if (preset.bestFor.contains(LumaPhotoType.night)) {
      return _categoryById['night']!;
    }
    if (preset.bestFor.contains(LumaPhotoType.softFilm)) {
      return _categoryById['film']!;
    }
    if (preset.bestFor.contains(LumaPhotoType.blackAndWhite)) {
      return _categoryById['bw']!;
    }
    if (preset.bestFor.contains(LumaPhotoType.street)) {
      return _categoryById['street']!;
    }
    if (preset.bestFor.contains(LumaPhotoType.indoor)) {
      return _categoryById['indoor']!;
    }
    if (preset.bestFor.contains(LumaPhotoType.vibrant)) {
      return _categoryById['vibrant']!;
    }
    return _categoryById['everyday']!;
  }

  static List<PresetCategoryGroup> groupedPresets() {
    final grouped = <String, List<LumaPreset>>{};
    for (final preset in PresetRegistry.all) {
      final category = categoryFor(preset);
      grouped.putIfAbsent(category.id, () => []).add(preset);
    }

    for (final list in grouped.values) {
      list.sort((a, b) => _rankFor(a).compareTo(_rankFor(b)));
    }

    final result = <PresetCategoryGroup>[];
    for (final category in categories) {
      final presets = grouped[category.id];
      if (presets == null || presets.isEmpty) continue;
      result.add(PresetCategoryGroup(category: category, presets: presets));
    }
    return result;
  }

  static List<LumaPreset> presetsForCategory(String categoryId) {
    final presets = <LumaPreset>[];
    for (final preset in PresetRegistry.all) {
      final category = categoryFor(preset);
      if (category.id == categoryId) {
        presets.add(preset);
      }
    }
    presets.sort((a, b) => _rankFor(a).compareTo(_rankFor(b)));
    return presets;
  }

  static int _rankFor(LumaPreset preset) {
    return _ranks[preset.id] ?? 9999;
  }
}
