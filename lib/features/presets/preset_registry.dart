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

// -----------------------------------------------------------------------------
// Public API
// -----------------------------------------------------------------------------

class PresetRegistry {
  static const List<LumaPresetPack> packs = [
    LumaPresetPack(
      id: 'sunday_studio',
      name: 'Sunday Studio',
      description: 'Soft light, clean skin, quiet color.',
      presetIds: [
        'clean_natural',
        'portrait_skin_clean',
        'portrait_soft_matte',
        'bright_airy',
        'golden_hour_glow',
      ],
    ),
    LumaPresetPack(
      id: 'film',
      name: 'Film',
      description: 'Quiet analog, modern scans, fine texture.',
      presetIds: [
        'neutral_scan',
        'clean_roll',
        'warm_scan',
        'silver_soft',
        'film_warm',
      ],
    ),
    LumaPresetPack(
      id: 'roadside',
      name: 'Roadside',
      description: 'Warm drives, hard edges, city nights.',
      presetIds: [
        'film_warm',
        'street_contrast',
        'sunset_pop',
        'moody_cool',
        'cinematic_teal',
      ],
    ),
    LumaPresetPack(
      id: 'field_notes',
      name: 'Field Notes',
      description: 'Earth tones, depth, and texture.',
      presetIds: [
        'landscape_pop',
        'landscape_deep',
        'urban_grit',
        'vintage_fade',
        'film_cool',
      ],
    ),
    LumaPresetPack(
      id: 'nightroom',
      name: 'Nightroom',
      description: 'Low light, grain, and heavy contrast.',
      presetIds: [
        'soft_film',
        'moody_warm',
        'cinematic_dark',
        'black_white_classic',
        'black_white_grit',
      ],
    ),
  ];

  static const List<LumaPreset> all = [
    LumaPreset(
      id: 'clean_natural',
      name: 'Sunday',
      description: 'Soft balance, natural color, calm light.',
      bestFor: {
        LumaPhotoType.general,
        LumaPhotoType.portrait,
        LumaPhotoType.indoor,
      },
      icon: LumaPresetIcon(
        glyph: PresetGlyph.sun,
        palette: PresetPalette(PresetPaletteId.neutral),
      ),
      values: {
        'exposure': 0.04,
        'contrast': 0.04,
        'highlights': -0.08,
        'shadows': 0.08,
        'whites': 0.02,
        'blacks': -0.02,
        'vibrance': 0.06,
        'saturation': 0.02,
        'texture': 0.04,
        'clarity': 0.02,
        'dehaze': 0.02,
        'sharpen': 0.08,
        'noise': 0.06,
        'color_noise': 0.06,
        'grain': 0.02,
        'vignette': 0.04,
        'lens_correction': 1.0,
        'chromatic_aberration': 1.0,
      },
    ),

    LumaPreset(
      id: 'soft_film',
      name: 'Warm Static',
      description: 'Muted contrast, soft glow, subtle grain.',
      bestFor: {
        LumaPhotoType.softFilm,
        LumaPhotoType.portrait,
        LumaPhotoType.general,
      },
      icon: LumaPresetIcon(
        glyph: PresetGlyph.film,
        palette: PresetPalette(PresetPaletteId.pastel),
        hasGrainHint: true,
      ),
      values: {
        'exposure': 0.06,
        'contrast': -0.08,
        'highlights': -0.12,
        'shadows': 0.14,
        'whites': -0.04,
        'blacks': 0.06,
        'color_balance': 0.04,
        'tint': 0.02,
        'vibrance': 0.04,
        'saturation': -0.04,
        'texture': -0.08,
        'clarity': -0.08,
        'dehaze': -0.04,
        'sharpen': 0.06,
        'noise': 0.10,
        'color_noise': 0.12,
        'grain': 0.22,
        'vignette': 0.12,
        'lens_correction': 1.0,
        'chromatic_aberration': 1.0,
      },
    ),

    LumaPreset(
      id: 'neutral_scan',
      name: 'Neutral Scan',
      description: 'Straight scan, gentle contrast, clean grain.',
      bestFor: {
        LumaPhotoType.general,
        LumaPhotoType.portrait,
        LumaPhotoType.product,
      },
      icon: LumaPresetIcon(
        glyph: PresetGlyph.film,
        palette: PresetPalette(PresetPaletteId.neutral),
        hasGrainHint: true,
      ),
      values: {
        'exposure': 0.01,
        'contrast': 0.02,
        'highlights': -0.02,
        'shadows': 0.02,
        'whites': 0.00,
        'blacks': 0.03,
        'color_balance': 0.00,
        'tint': 0.00,
        'vibrance': 0.00,
        'saturation': 0.00,
        'texture': 0.00,
        'clarity': 0.00,
        'dehaze': 0.00,
        'sharpen': 0.06,
        'noise': 0.06,
        'color_noise': 0.06,
        'grain': 0.10,
        'vignette': 0.02,
        'lens_correction': 1.0,
        'chromatic_aberration': 1.0,
      },
    ),

    LumaPreset(
      id: 'clean_roll',
      name: 'Clean Roll',
      description: 'Neutral color, gentle contrast, fine grain.',
      bestFor: {
        LumaPhotoType.general,
        LumaPhotoType.portrait,
        LumaPhotoType.indoor,
      },
      icon: LumaPresetIcon(
        glyph: PresetGlyph.film,
        palette: PresetPalette(PresetPaletteId.neutral),
        hasGrainHint: true,
      ),
      values: {
        'exposure': 0.02,
        'contrast': 0.04,
        'highlights': -0.06,
        'shadows': 0.06,
        'whites': 0.02,
        'blacks': -0.02,
        'color_balance': 0.00,
        'tint': 0.00,
        'vibrance': 0.02,
        'saturation': -0.02,
        'texture': 0.02,
        'clarity': 0.01,
        'dehaze': 0.00,
        'sharpen': 0.08,
        'noise': 0.08,
        'color_noise': 0.08,
        'grain': 0.14,
        'vignette': 0.04,
        'lens_correction': 1.0,
        'chromatic_aberration': 1.0,
      },
    ),

    LumaPreset(
      id: 'warm_scan',
      name: 'Warm Scan',
      description: 'Slight warmth, lifted mids, soft highlights.',
      bestFor: {
        LumaPhotoType.portrait,
        LumaPhotoType.indoor,
        LumaPhotoType.general,
      },
      icon: LumaPresetIcon(
        glyph: PresetGlyph.film,
        palette: PresetPalette(PresetPaletteId.warm),
        hasGrainHint: true,
      ),
      values: {
        'exposure': 0.04,
        'contrast': -0.02,
        'highlights': -0.10,
        'shadows': 0.10,
        'whites': -0.02,
        'blacks': 0.02,
        'color_balance': 0.06,
        'tint': 0.01,
        'vibrance': 0.04,
        'saturation': -0.02,
        'texture': -0.02,
        'clarity': -0.02,
        'dehaze': -0.02,
        'sharpen': 0.08,
        'noise': 0.08,
        'color_noise': 0.10,
        'grain': 0.18,
        'vignette': 0.06,
        'lens_correction': 1.0,
        'chromatic_aberration': 1.0,
      },
    ),

    LumaPreset(
      id: 'silver_soft',
      name: 'Silver Soft',
      description: 'Cooler shadows, smooth tonal roll-off.',
      bestFor: {
        LumaPhotoType.general,
        LumaPhotoType.street,
        LumaPhotoType.indoor,
      },
      icon: LumaPresetIcon(
        glyph: PresetGlyph.moon,
        palette: PresetPalette(PresetPaletteId.cool),
        hasGrainHint: true,
      ),
      values: {
        'exposure': 0.02,
        'contrast': -0.04,
        'highlights': -0.12,
        'shadows': 0.12,
        'whites': -0.04,
        'blacks': 0.04,
        'color_balance': -0.06,
        'tint': -0.01,
        'vibrance': -0.02,
        'saturation': -0.04,
        'texture': 0.00,
        'clarity': -0.02,
        'dehaze': -0.02,
        'sharpen': 0.08,
        'noise': 0.08,
        'color_noise': 0.10,
        'grain': 0.18,
        'vignette': 0.08,
        'lens_correction': 1.0,
        'chromatic_aberration': 1.0,
      },
    ),

    LumaPreset(
      id: 'film_warm',
      name: 'Late Drive',
      description: 'Warmth up front, soft shadows, quiet blues.',
      bestFor: {
        LumaPhotoType.portrait,
        LumaPhotoType.indoor,
        LumaPhotoType.general,
      },
      icon: LumaPresetIcon(
        glyph: PresetGlyph.face,
        palette: PresetPalette(PresetPaletteId.warm),
      ),
      values: {
        'exposure': 0.04,
        'contrast': -0.02,
        'highlights': -0.12,
        'shadows': 0.10,
        'whites': -0.02,
        'blacks': 0.02,
        'color_balance': 0.08,
        'tint': 0.02,
        'vibrance': 0.06,
        'saturation': -0.04,
        'texture': 0.02,
        'clarity': 0.02,
        'dehaze': 0.00,
        'sharpen': 0.08,
        'noise': 0.08,
        'color_noise': 0.10,
        'grain': 0.16,
        'vignette': 0.10,
        'lens_correction': 1.0,
        'chromatic_aberration': 1.0,
      },
    ),

    LumaPreset(
      id: 'film_cool',
      name: 'Cold Air',
      description: 'Cool lift, quiet reds, soft blacks.',
      bestFor: {
        LumaPhotoType.street,
        LumaPhotoType.general,
        LumaPhotoType.indoor,
      },
      icon: LumaPresetIcon(
        glyph: PresetGlyph.moon,
        palette: PresetPalette(PresetPaletteId.cool),
      ),
      values: {
        'exposure': 0.02,
        'contrast': -0.04,
        'highlights': -0.10,
        'shadows': 0.12,
        'whites': -0.04,
        'blacks': 0.08,
        'color_balance': -0.08,
        'tint': -0.01,
        'vibrance': -0.02,
        'saturation': -0.06,
        'texture': 0.00,
        'clarity': 0.02,
        'dehaze': -0.02,
        'sharpen': 0.08,
        'noise': 0.08,
        'color_noise': 0.10,
        'grain': 0.16,
        'vignette': 0.12,
        'lens_correction': 1.0,
        'chromatic_aberration': 1.0,
      },
    ),

    LumaPreset(
      id: 'vintage_fade',
      name: 'Dusty Light',
      description: 'Lifted blacks, faded color, gentle contrast.',
      bestFor: {LumaPhotoType.softFilm, LumaPhotoType.general},
      icon: LumaPresetIcon(
        glyph: PresetGlyph.film,
        palette: PresetPalette(PresetPaletteId.moody),
        hasGrainHint: true,
      ),
      values: {
        'exposure': 0.04,
        'contrast': -0.14,
        'highlights': -0.08,
        'shadows': 0.18,
        'whites': -0.06,
        'blacks': 0.12,
        'color_balance': 0.02,
        'tint': 0.01,
        'vibrance': -0.08,
        'saturation': -0.12,
        'texture': -0.06,
        'clarity': -0.08,
        'dehaze': -0.02,
        'sharpen': 0.06,
        'noise': 0.10,
        'color_noise': 0.12,
        'grain': 0.24,
        'vignette': 0.18,
        'lens_correction': 1.0,
        'chromatic_aberration': 1.0,
      },
    ),

    LumaPreset(
      id: 'bright_airy',
      name: 'Open Air',
      description: 'Light lift, soft contrast, clean whites.',
      bestFor: {LumaPhotoType.general, LumaPhotoType.vibrant},
      icon: LumaPresetIcon(
        glyph: PresetGlyph.sun,
        palette: PresetPalette(PresetPaletteId.pastel),
      ),
      values: {
        'exposure': 0.14,
        'contrast': 0.02,
        'highlights': -0.08,
        'shadows': 0.12,
        'whites': 0.12,
        'blacks': -0.02,
        'vibrance': 0.08,
        'saturation': 0.02,
        'texture': 0.02,
        'clarity': -0.02,
        'dehaze': -0.02,
        'sharpen': 0.08,
        'noise': 0.06,
        'color_noise': 0.06,
        'grain': 0.04,
        'vignette': 0.04,
        'lens_correction': 1.0,
        'chromatic_aberration': 1.0,
      },
    ),

    LumaPreset(
      id: 'golden_hour_glow',
      name: 'Gold Hour',
      description: 'Warmth and glow, soft highlights.',
      bestFor: {LumaPhotoType.portrait, LumaPhotoType.vibrant},
      icon: LumaPresetIcon(
        glyph: PresetGlyph.sun,
        palette: PresetPalette(PresetPaletteId.warm),
      ),
      values: {
        'exposure': 0.06,
        'contrast': 0.06,
        'highlights': -0.14,
        'shadows': 0.10,
        'whites': 0.06,
        'blacks': -0.04,
        'color_balance': 0.12,
        'tint': 0.04,
        'vibrance': 0.16,
        'saturation': 0.10,
        'texture': 0.06,
        'clarity': 0.04,
        'dehaze': 0.02,
        'sharpen': 0.08,
        'noise': 0.06,
        'color_noise': 0.06,
        'grain': 0.08,
        'vignette': 0.08,
        'lens_correction': 1.0,
        'chromatic_aberration': 1.0,
      },
    ),

    LumaPreset(
      id: 'sunset_pop',
      name: 'Crimson Sky',
      description: 'Richer reds, deeper contrast, vivid sky.',
      bestFor: {LumaPhotoType.landscape, LumaPhotoType.vibrant},
      icon: LumaPresetIcon(
        glyph: PresetGlyph.spark,
        palette: PresetPalette(PresetPaletteId.vibrant),
      ),
      values: {
        'exposure': 0.02,
        'contrast': 0.20,
        'highlights': -0.10,
        'shadows': 0.06,
        'whites': 0.08,
        'blacks': -0.12,
        'color_balance': 0.06,
        'tint': 0.06,
        'vibrance': 0.24,
        'saturation': 0.14,
        'texture': 0.12,
        'clarity': 0.12,
        'dehaze': 0.12,
        'sharpen': 0.12,
        'noise': 0.06,
        'color_noise': 0.06,
        'grain': 0.08,
        'vignette': 0.12,
        'lens_correction': 1.0,
        'chromatic_aberration': 1.0,
      },
    ),

    LumaPreset(
      id: 'moody_warm',
      name: 'Amber Room',
      description: 'Low light, warm shadows, gentle highs.',
      bestFor: {LumaPhotoType.indoor, LumaPhotoType.general},
      icon: LumaPresetIcon(
        glyph: PresetGlyph.moon,
        palette: PresetPalette(PresetPaletteId.warm),
        hasVignetteRing: true,
      ),
      values: {
        'exposure': -0.08,
        'contrast': 0.16,
        'highlights': -0.18,
        'shadows': 0.10,
        'whites': -0.02,
        'blacks': -0.14,
        'color_balance': 0.08,
        'tint': 0.02,
        'vibrance': 0.06,
        'saturation': -0.02,
        'texture': 0.10,
        'clarity': 0.12,
        'dehaze': 0.12,
        'sharpen': 0.10,
        'noise': 0.06,
        'color_noise': 0.06,
        'grain': 0.16,
        'vignette': 0.18,
        'lens_correction': 1.0,
        'chromatic_aberration': 1.0,
      },
    ),

    LumaPreset(
      id: 'moody_cool',
      name: 'Blue Hour',
      description: 'Cool shadows, muted warmth, quiet mood.',
      bestFor: {LumaPhotoType.street, LumaPhotoType.general},
      icon: LumaPresetIcon(
        glyph: PresetGlyph.moon,
        palette: PresetPalette(PresetPaletteId.cool),
        hasVignetteRing: true,
      ),
      values: {
        'exposure': -0.10,
        'contrast': 0.16,
        'highlights': -0.18,
        'shadows': 0.08,
        'whites': -0.02,
        'blacks': -0.16,
        'color_balance': -0.08,
        'tint': -0.02,
        'vibrance': 0.04,
        'saturation': -0.04,
        'texture': 0.10,
        'clarity': 0.12,
        'dehaze': 0.12,
        'sharpen': 0.10,
        'noise': 0.06,
        'color_noise': 0.06,
        'grain': 0.16,
        'vignette': 0.18,
        'lens_correction': 1.0,
        'chromatic_aberration': 1.0,
      },
    ),

    LumaPreset(
      id: 'cinematic_teal',
      name: 'Teal Fade',
      description: 'Teal lows, warm highs, cinematic contrast.',
      bestFor: {LumaPhotoType.street, LumaPhotoType.landscape},
      icon: LumaPresetIcon(
        glyph: PresetGlyph.film,
        palette: PresetPalette(PresetPaletteId.moody),
        hasVignetteRing: true,
      ),
      values: {
        'exposure': -0.04,
        'contrast': 0.22,
        'highlights': -0.16,
        'shadows': 0.08,
        'whites': 0.02,
        'blacks': -0.18,
        'color_balance': -0.10,
        'tint': 0.05,
        'vibrance': 0.10,
        'saturation': -0.02,
        'texture': 0.12,
        'clarity': 0.14,
        'dehaze': 0.16,
        'sharpen': 0.12,
        'noise': 0.06,
        'color_noise': 0.06,
        'grain': 0.14,
        'vignette': 0.22,
        'lens_correction': 1.0,
        'chromatic_aberration': 1.0,
      },
    ),

    LumaPreset(
      id: 'cinematic_dark',
      name: 'Night Plot',
      description: 'Crushed blacks, high contrast, muted color.',
      bestFor: {LumaPhotoType.street, LumaPhotoType.general},
      icon: LumaPresetIcon(
        glyph: PresetGlyph.city,
        palette: PresetPalette(PresetPaletteId.moody),
        hasVignetteRing: true,
      ),
      values: {
        'exposure': -0.14,
        'contrast': 0.28,
        'highlights': -0.22,
        'shadows': 0.04,
        'whites': -0.04,
        'blacks': -0.28,
        'color_balance': -0.02,
        'tint': 0.01,
        'vibrance': -0.08,
        'saturation': -0.10,
        'texture': 0.16,
        'clarity': 0.18,
        'dehaze': 0.18,
        'sharpen': 0.14,
        'noise': 0.06,
        'color_noise': 0.06,
        'grain': 0.18,
        'vignette': 0.26,
        'lens_correction': 1.0,
        'chromatic_aberration': 1.0,
      },
    ),

    LumaPreset(
      id: 'urban_grit',
      name: 'Concrete',
      description: 'Hard detail, lower color, raw edge.',
      bestFor: {LumaPhotoType.street, LumaPhotoType.general},
      icon: LumaPresetIcon(
        glyph: PresetGlyph.city,
        palette: PresetPalette(PresetPaletteId.neutral),
      ),
      values: {
        'exposure': 0.00,
        'contrast': 0.18,
        'highlights': -0.12,
        'shadows': 0.06,
        'whites': 0.02,
        'blacks': -0.12,
        'color_balance': -0.02,
        'tint': 0.00,
        'vibrance': -0.10,
        'saturation': -0.18,
        'texture': 0.22,
        'clarity': 0.24,
        'dehaze': 0.16,
        'sharpen': 0.18,
        'noise': 0.06,
        'color_noise': 0.06,
        'grain': 0.12,
        'vignette': 0.10,
        'lens_correction': 1.0,
        'chromatic_aberration': 1.0,
      },
    ),

    LumaPreset(
      id: 'street_contrast',
      name: 'After Rain',
      description: 'Deep blacks, sharp edges, city punch.',
      bestFor: {LumaPhotoType.street, LumaPhotoType.general},
      icon: LumaPresetIcon(
        glyph: PresetGlyph.city,
        palette: PresetPalette(PresetPaletteId.moody),
      ),
      values: {
        'exposure': -0.02,
        'contrast': 0.24,
        'highlights': -0.10,
        'shadows': 0.04,
        'whites': 0.06,
        'blacks': -0.20,
        'vibrance': 0.04,
        'saturation': -0.02,
        'texture': 0.16,
        'clarity': 0.18,
        'dehaze': 0.12,
        'sharpen': 0.20,
        'noise': 0.06,
        'color_noise': 0.06,
        'grain': 0.12,
        'vignette': 0.14,
        'lens_correction': 1.0,
        'chromatic_aberration': 1.0,
      },
    ),

    LumaPreset(
      id: 'portrait_skin_clean',
      name: 'Porcelain',
      description: 'Clean skin, reduced reds, soft highlights.',
      bestFor: {LumaPhotoType.portrait, LumaPhotoType.indoor},
      icon: LumaPresetIcon(
        glyph: PresetGlyph.face,
        palette: PresetPalette(PresetPaletteId.neutral),
      ),
      values: {
        'exposure': 0.06,
        'contrast': 0.04,
        'highlights': -0.16,
        'shadows': 0.12,
        'whites': 0.04,
        'blacks': -0.04,
        'color_balance': 0.02,
        'tint': -0.02,
        'vibrance': 0.04,
        'saturation': -0.06,
        'texture': -0.08,
        'clarity': -0.06,
        'dehaze': -0.02,
        'sharpen': 0.08,
        'noise': 0.08,
        'color_noise': 0.10,
        'grain': 0.04,
        'vignette': 0.06,
        'lens_correction': 1.0,
        'chromatic_aberration': 1.0,
      },
    ),

    LumaPreset(
      id: 'portrait_soft_matte',
      name: 'Studio Soft',
      description: 'Matte blacks, warm tone, soft contrast.',
      bestFor: {LumaPhotoType.portrait, LumaPhotoType.softFilm},
      icon: LumaPresetIcon(
        glyph: PresetGlyph.face,
        palette: PresetPalette(PresetPaletteId.warm),
        hasGrainHint: true,
      ),
      values: {
        'exposure': 0.04,
        'contrast': -0.08,
        'highlights': -0.10,
        'shadows': 0.16,
        'whites': -0.02,
        'blacks': 0.10,
        'color_balance': 0.06,
        'tint': 0.02,
        'vibrance': 0.06,
        'saturation': -0.02,
        'texture': -0.06,
        'clarity': -0.06,
        'dehaze': -0.02,
        'sharpen': 0.06,
        'noise': 0.10,
        'color_noise': 0.12,
        'grain': 0.18,
        'vignette': 0.12,
        'lens_correction': 1.0,
        'chromatic_aberration': 1.0,
      },
    ),

    LumaPreset(
      id: 'landscape_pop',
      name: 'Greenfield',
      description: 'Boosted greens, clear detail, fresh light.',
      bestFor: {LumaPhotoType.landscape, LumaPhotoType.vibrant},
      icon: LumaPresetIcon(
        glyph: PresetGlyph.mountain,
        palette: PresetPalette(PresetPaletteId.vibrant),
      ),
      values: {
        'exposure': 0.04,
        'contrast': 0.16,
        'highlights': -0.12,
        'shadows': 0.06,
        'whites': 0.08,
        'blacks': -0.10,
        'color_balance': -0.04,
        'tint': 0.00,
        'vibrance': 0.22,
        'saturation': 0.10,
        'texture': 0.16,
        'clarity': 0.18,
        'dehaze': 0.18,
        'sharpen': 0.16,
        'noise': 0.06,
        'color_noise': 0.06,
        'grain': 0.08,
        'vignette': 0.10,
        'lens_correction': 1.0,
        'chromatic_aberration': 1.0,
      },
    ),

    LumaPreset(
      id: 'landscape_deep',
      name: 'Deep Ridge',
      description: 'Darker lift, rich color, bold contrast.',
      bestFor: {LumaPhotoType.landscape, LumaPhotoType.general},
      icon: LumaPresetIcon(
        glyph: PresetGlyph.mountain,
        palette: PresetPalette(PresetPaletteId.moody),
      ),
      values: {
        'exposure': -0.06,
        'contrast': 0.22,
        'highlights': -0.16,
        'shadows': 0.06,
        'whites': 0.02,
        'blacks': -0.18,
        'color_balance': -0.02,
        'tint': 0.00,
        'vibrance': 0.16,
        'saturation': 0.06,
        'texture': 0.16,
        'clarity': 0.18,
        'dehaze': 0.20,
        'sharpen': 0.18,
        'noise': 0.06,
        'color_noise': 0.06,
        'grain': 0.10,
        'vignette': 0.14,
        'lens_correction': 1.0,
        'chromatic_aberration': 1.0,
      },
    ),

    LumaPreset(
      id: 'black_white_classic',
      name: 'Linen Mono',
      description: 'Balanced contrast, clean highlight rolloff.',
      bestFor: {LumaPhotoType.blackAndWhite, LumaPhotoType.portrait},
      icon: LumaPresetIcon(
        glyph: PresetGlyph.mono,
        palette: PresetPalette(PresetPaletteId.mono),
      ),
      values: {
        'exposure': 0.02,
        'contrast': 0.16,
        'highlights': -0.08,
        'shadows': 0.08,
        'whites': 0.04,
        'blacks': -0.10,
        'vibrance': -0.30,
        'saturation': -0.60,
        'texture': 0.08,
        'clarity': 0.10,
        'dehaze': 0.08,
        'sharpen': 0.12,
        'noise': 0.08,
        'color_noise': 0.10,
        'grain': 0.10,
        'vignette': 0.10,
        'lens_correction': 1.0,
        'chromatic_aberration': 1.0,
      },
    ),

    LumaPreset(
      id: 'black_white_grit',
      name: 'Grain Noir',
      description: 'Heavy contrast, grain and texture.',
      bestFor: {LumaPhotoType.blackAndWhite, LumaPhotoType.street},
      icon: LumaPresetIcon(
        glyph: PresetGlyph.mono,
        palette: PresetPalette(PresetPaletteId.mono),
        hasGrainHint: true,
      ),
      values: {
        'exposure': 0.00,
        'contrast': 0.28,
        'highlights': -0.12,
        'shadows': 0.04,
        'whites': 0.02,
        'blacks': -0.22,
        'vibrance': -0.40,
        'saturation': -0.70,
        'texture': 0.18,
        'clarity': 0.22,
        'dehaze': 0.14,
        'sharpen': 0.16,
        'noise': 0.08,
        'color_noise': 0.10,
        'grain': 0.26,
        'vignette': 0.18,
        'lens_correction': 1.0,
        'chromatic_aberration': 1.0,
      },
    ),
  ];

  static LumaPreset byId(String id) => all.firstWhere((p) => p.id == id);

  static List<LumaPreset> presetsForPack(LumaPresetPack pack) {
    return pack.presetIds.map(byId).toList();
  }

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
        if (p.id == 'portrait_skin_clean') s += 1.0;
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
