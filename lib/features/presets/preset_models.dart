// lib/features/presets/preset_models.dart
//
// Shared models for presets and their metadata.

enum LumaPhotoType {
  portrait,
  landscape,
  street,
  night,
  indoor,
  food,
  product,
  blackAndWhite,
  softFilm,
  vibrant,
  general,
}

class LumaPreset {
  final String id; // stable id (snake_case)
  final String name;
  final String description;
  final Map<String, double> values; // editor slider keys -> value
  final Set<LumaPhotoType> bestFor;
  final LumaPresetIcon icon;

  const LumaPreset({
    required this.id,
    required this.name,
    required this.description,
    required this.values,
    required this.bestFor,
    required this.icon,
  });
}

class LumaPresetPack {
  final String id;
  final String name;
  final String description;
  final List<String> presetIds;

  const LumaPresetPack({
    required this.id,
    required this.name,
    required this.description,
    required this.presetIds,
  });
}

class LumaPresetIcon {
  // system: a base glyph + 2-tone palette + optional accent
  // you can render this as a small rounded-square tile.
  final PresetGlyph glyph;
  final PresetPalette palette;
  final bool hasGrainHint; // optional tiny grain dots overlay
  final bool hasVignetteRing; // optional ring overlay

  const LumaPresetIcon({
    required this.glyph,
    required this.palette,
    this.hasGrainHint = false,
    this.hasVignetteRing = false,
  });
}

enum PresetGlyph {
  sun,
  moon,
  mountain,
  face,
  city,
  spark,
  leaf,
  drop,
  film,
  mono,
}

class PresetPalette {
  // Keep these as abstract palette ids so your UI can map them to colors
  // in light/dark mode without breaking icons.
  final PresetPaletteId id;
  const PresetPalette(this.id);
}

enum PresetPaletteId { neutral, warm, cool, vibrant, pastel, moody, mono }

class PresetCategory {
  final String id;
  final String name;
  final String description;

  const PresetCategory({
    required this.id,
    required this.name,
    required this.description,
  });
}
