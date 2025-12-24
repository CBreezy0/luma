// lib/features/presets/preset_registry.dart
//
// Luma Preset Registry
// - Matches the editor slider keys exactly (see EditorPage tool ids).
// - Includes a lightweight “photo type” ranking system.
// - Includes a preset icon system (stable, deterministic).
//
// Supported keys (must match EditorPage ids):
// exposure, contrast, highlights, shadows, whites, blacks
// tint, color_balance, vibrance, saturation
// texture, clarity, dehaze, grain, vignette
// sharpen, noise, color_noise
// lens_correction, chromatic_aberration
//
// Notes:
// - All values are normalized to the same ranges EditorPage expects.
//   * centered sliders: -1..1
//   * effect/detail sliders: 0..1
//   * toggles: 0 or 1

import 'dart:math' as math;

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

enum PresetGlyph { sun, moon, mountain, face, city, spark, leaf, drop, film, mono }

class PresetPalette {
  // Keep these as abstract palette ids so your UI can map them to colors
  // in light/dark mode without breaking icons.
  final PresetPaletteId id;
  const PresetPalette(this.id);
}

enum PresetPaletteId {
  neutral,
  warm,
  cool,
  vibrant,
  pastel,
  moody,
  mono,
}

// -----------------------------------------------------------------------------
// Public API
// -----------------------------------------------------------------------------

class PresetRegistry {
  static const List<LumaPreset> all = [
    // GENERAL / SAFE (works on most photos)
    LumaPreset(
      id: 'clean_pop',
      name: 'Clean Pop',
      description: 'Crisp, balanced, everyday go-to.',
      bestFor: {LumaPhotoType.general, LumaPhotoType.street, LumaPhotoType.product},
      icon: LumaPresetIcon(glyph: PresetGlyph.sun, palette: PresetPalette(PresetPaletteId.neutral)),
      values: {
        'exposure': 0.06,
        'contrast': 0.14,
        'highlights': -0.10,
        'shadows': 0.10,
        'whites': 0.08,
        'blacks': -0.08,
        'vibrance': 0.14,
        'saturation': 0.06,
        'texture': 0.10,
        'clarity': 0.08,
        'dehaze': 0.06,
        'sharpen': 0.12,
        'noise': 0.06,
        'color_noise': 0.06,
        'grain': 0.10,
        'vignette': 0.10,
        'lens_correction': 1.0,
        'chromatic_aberration': 1.0,
      },
    ),

    LumaPreset(
      id: 'true_tone',
      name: 'True Tone',
      description: 'Natural color, softer contrast, clean skin tones.',
      bestFor: {LumaPhotoType.portrait, LumaPhotoType.indoor, LumaPhotoType.general},
      icon: LumaPresetIcon(glyph: PresetGlyph.face, palette: PresetPalette(PresetPaletteId.neutral)),
      values: {
        'exposure': 0.05,
        'contrast': 0.06,
        'highlights': -0.12,
        'shadows': 0.14,
        'whites': 0.04,
        'blacks': -0.04,
        'tint': 0.04,
        'color_balance': 0.03, // slight warm
        'vibrance': 0.10,
        'saturation': 0.02,
        'texture': 0.04,
        'clarity': 0.02,
        'dehaze': 0.00,
        'sharpen': 0.10,
        'noise': 0.08,
        'color_noise': 0.10,
        'grain': 0.06,
        'vignette': 0.08,
        'lens_correction': 1.0,
        'chromatic_aberration': 1.0,
      },
    ),

    // VIBRANT / SOCIAL
    LumaPreset(
      id: 'summer_punch',
      name: 'Summer Punch',
      description: 'Bright, colorful, high-energy.',
      bestFor: {LumaPhotoType.vibrant, LumaPhotoType.landscape, LumaPhotoType.food},
      icon: LumaPresetIcon(glyph: PresetGlyph.spark, palette: PresetPalette(PresetPaletteId.vibrant)),
      values: {
        'exposure': 0.10,
        'contrast': 0.18,
        'highlights': -0.08,
        'shadows': 0.08,
        'whites': 0.10,
        'blacks': -0.10,
        'color_balance': 0.05,
        'vibrance': 0.26,
        'saturation': 0.14,
        'texture': 0.10,
        'clarity': 0.10,
        'dehaze': 0.10,
        'sharpen': 0.14,
        'grain': 0.06,
        'vignette': 0.06,
        'lens_correction': 1.0,
        'chromatic_aberration': 1.0,
      },
    ),

    // MOODY / CINEMATIC
    LumaPreset(
      id: 'moody_cinema',
      name: 'Moody Cinema',
      description: 'Deep blacks, controlled highlights, cinematic punch.',
      bestFor: {LumaPhotoType.street, LumaPhotoType.landscape, LumaPhotoType.general},
      icon: LumaPresetIcon(glyph: PresetGlyph.film, palette: PresetPalette(PresetPaletteId.moody), hasVignetteRing: true),
      values: {
        'exposure': -0.02,
        'contrast': 0.22,
        'highlights': -0.18,
        'shadows': 0.10,
        'whites': 0.04,
        'blacks': -0.16,
        'color_balance': -0.03, // slightly cooler
        'vibrance': 0.10,
        'saturation': -0.02,
        'texture': 0.14,
        'clarity': 0.16,
        'dehaze': 0.14,
        'sharpen': 0.14,
        'noise': 0.06,
        'color_noise': 0.06,
        'grain': 0.18,
        'vignette': 0.22,
        'lens_correction': 1.0,
        'chromatic_aberration': 1.0,
      },
    ),

    // NIGHT / LOW LIGHT
    LumaPreset(
      id: 'night_clean',
      name: 'Night Clean',
      description: 'Cleaner low light with controlled noise + crispness.',
      bestFor: {LumaPhotoType.night, LumaPhotoType.indoor, LumaPhotoType.street},
      icon: LumaPresetIcon(glyph: PresetGlyph.moon, palette: PresetPalette(PresetPaletteId.cool)),
      values: {
        'exposure': 0.08,
        'contrast': 0.10,
        'highlights': -0.20,
        'shadows': 0.18,
        'whites': 0.02,
        'blacks': -0.08,
        'color_balance': -0.04,
        'vibrance': 0.10,
        'saturation': 0.02,
        'clarity': 0.08,
        'dehaze': 0.10,
        'sharpen': 0.10,
        'noise': 0.26,
        'color_noise': 0.28,
        'grain': 0.06,
        'vignette': 0.10,
        'lens_correction': 1.0,
        'chromatic_aberration': 1.0,
      },
    ),

    // LANDSCAPE
    LumaPreset(
      id: 'landscape_crisp',
      name: 'Landscape Crisp',
      description: 'More depth, detail, and haze control.',
      bestFor: {LumaPhotoType.landscape, LumaPhotoType.street, LumaPhotoType.general},
      icon: LumaPresetIcon(glyph: PresetGlyph.mountain, palette: PresetPalette(PresetPaletteId.cool)),
      values: {
        'exposure': 0.04,
        'contrast': 0.16,
        'highlights': -0.14,
        'shadows': 0.08,
        'whites': 0.08,
        'blacks': -0.10,
        'vibrance': 0.18,
        'saturation': 0.08,
        'texture': 0.16,
        'clarity': 0.16,
        'dehaze': 0.18,
        'sharpen': 0.18,
        'noise': 0.06,
        'color_noise': 0.06,
        'grain': 0.08,
        'vignette': 0.10,
        'lens_correction': 1.0,
        'chromatic_aberration': 1.0,
      },
    ),

    // FOOD
    LumaPreset(
      id: 'food_fresh',
      name: 'Food Fresh',
      description: 'Bright, warm, clean, tasty color.',
      bestFor: {LumaPhotoType.food, LumaPhotoType.indoor, LumaPhotoType.vibrant},
      icon: LumaPresetIcon(glyph: PresetGlyph.leaf, palette: PresetPalette(PresetPaletteId.warm)),
      values: {
        'exposure': 0.10,
        'contrast': 0.10,
        'highlights': -0.10,
        'shadows': 0.10,
        'whites': 0.08,
        'blacks': -0.06,
        'color_balance': 0.08,
        'tint': 0.02,
        'vibrance': 0.22,
        'saturation': 0.10,
        'texture': 0.10,
        'clarity': 0.06,
        'dehaze': 0.02,
        'sharpen': 0.12,
        'noise': 0.08,
        'color_noise': 0.08,
        'grain': 0.05,
        'vignette': 0.05,
        'lens_correction': 1.0,
        'chromatic_aberration': 1.0,
      },
    ),

    // PRODUCT / ECOM
    LumaPreset(
      id: 'product_clean',
      name: 'Product Clean',
      description: 'Neutral + sharp. Great for listings and design shots.',
      bestFor: {LumaPhotoType.product, LumaPhotoType.general},
      icon: LumaPresetIcon(glyph: PresetGlyph.drop, palette: PresetPalette(PresetPaletteId.neutral)),
      values: {
        'exposure': 0.08,
        'contrast': 0.10,
        'highlights': -0.06,
        'shadows': 0.06,
        'whites': 0.10,
        'blacks': -0.06,
        'vibrance': 0.06,
        'saturation': 0.00,
        'texture': 0.14,
        'clarity': 0.10,
        'dehaze': 0.04,
        'sharpen': 0.22,
        'noise': 0.06,
        'color_noise': 0.06,
        'grain': 0.00,
        'vignette': 0.00,
        'lens_correction': 1.0,
        'chromatic_aberration': 1.0,
      },
    ),

    // BLACK & WHITE STYLE (approx using saturation pull)
    LumaPreset(
      id: 'mono_contrast',
      name: 'Mono Contrast',
      description: 'Punchy black & white look (via desat + contrast).',
      bestFor: {LumaPhotoType.blackAndWhite, LumaPhotoType.street, LumaPhotoType.portrait},
      icon: LumaPresetIcon(glyph: PresetGlyph.mono, palette: PresetPalette(PresetPaletteId.mono), hasGrainHint: true),
      values: {
        'exposure': 0.02,
        'contrast': 0.22,
        'highlights': -0.12,
        'shadows': 0.10,
        'whites': 0.06,
        'blacks': -0.14,
        'vibrance': -0.30,
        'saturation': -0.60, // hard desat
        'texture': 0.10,
        'clarity': 0.14,
        'dehaze': 0.10,
        'sharpen': 0.14,
        'noise': 0.08,
        'color_noise': 0.10,
        'grain': 0.22,
        'vignette': 0.18,
        'lens_correction': 1.0,
        'chromatic_aberration': 1.0,
      },
    ),

    // SOFT FILM (gentle, lifted shadows + grain)
    LumaPreset(
      id: 'soft_film',
      name: 'Soft Film',
      description: 'Soft contrast, lifted shadows, subtle film grain.',
      bestFor: {LumaPhotoType.softFilm, LumaPhotoType.portrait, LumaPhotoType.general},
      icon: LumaPresetIcon(glyph: PresetGlyph.film, palette: PresetPalette(PresetPaletteId.pastel), hasGrainHint: true),
      values: {
        'exposure': 0.06,
        'contrast': -0.06,
        'highlights': -0.10,
        'shadows': 0.18,
        'whites': -0.02,
        'blacks': 0.06,
        'color_balance': 0.05,
        'tint': 0.02,
        'vibrance': 0.10,
        'saturation': -0.02,
        'texture': -0.06,
        'clarity': -0.06,
        'dehaze': -0.04,
        'sharpen': 0.06,
        'noise': 0.10,
        'color_noise': 0.12,
        'grain': 0.26,
        'vignette': 0.14,
        'lens_correction': 1.0,
        'chromatic_aberration': 1.0,
      },
    ),
  ];

  static LumaPreset byId(String id) => all.firstWhere((p) => p.id == id);

  /// Returns presets ordered for a photo given simple metadata.
  /// You can feed:
  /// - aspect ratio (w/h)
  /// - isLowLight (from exposure time / ISO if you add EXIF later)
  /// - isPortraitGuess (if aspect is tall + face detection later)
  static List<LumaPreset> rankedFor({
    required double aspect, // width / height
    bool isLowLight = false,
    bool isIndoorGuess = false,
    bool isPortraitGuess = false,
  }) {
    final scores = <String, double>{};

    for (final p in all) {
      double s = 0;

      // base bias: general-friendly presets show higher
      if (p.bestFor.contains(LumaPhotoType.general)) s += 1.0;

      // portrait hints
      if (isPortraitGuess) {
        if (p.bestFor.contains(LumaPhotoType.portrait)) s += 3.0;
        if (p.id == 'true_tone') s += 1.0;
      }

      // aspect hints
      final isWide = aspect > 1.25;
      final isTall = aspect < 0.85;
      if (isWide && p.bestFor.contains(LumaPhotoType.landscape)) s += 2.0;
      if (isTall && p.bestFor.contains(LumaPhotoType.portrait)) s += 1.5;

      // low light
      if (isLowLight && p.bestFor.contains(LumaPhotoType.night)) s += 3.0;

      // indoor guess
      if (isIndoorGuess && p.bestFor.contains(LumaPhotoType.indoor)) s += 2.0;

      // style clusters
      if (p.bestFor.contains(LumaPhotoType.vibrant)) s += 0.5;
      if (p.bestFor.contains(LumaPhotoType.softFilm)) s += 0.5;
      if (p.bestFor.contains(LumaPhotoType.blackAndWhite)) s += 0.2;

      // slight variety: stable pseudo-random based on id
      s += _stableJitter(p.id) * 0.08;

      scores[p.id] = s;
    }

    final list = [...all];
    list.sort((a, b) => (scores[b.id] ?? 0).compareTo(scores[a.id] ?? 0));
    return list;
  }
}

double _stableJitter(String s) {
  // deterministic 0..1 based on string
  int h = 2166136261;
  for (final c in s.codeUnits) {
    h ^= c;
    h = (h * 16777619) & 0x7fffffff;
  }
  return (h % 1000) / 1000.0;
}