# Luma

First Beta: v1.0.0

Luma — minimalist iOS photo editor

## Overview
Luma is a minimalist iOS photo editor built with Flutter and a native Core
Image renderer for fast previews and high‑quality exports.

## Features
- Curated signature preset packs
- Fast editor with Light, Color, Effects, Detail, Optics, and Crop
- Crop/rotate/straighten with grid overlay
- Undo/redo history
- Export to Photos

## Requirements
- Flutter 3.38.5 (pinned in CI)
- Xcode for iOS builds

## Run Locally
```bash
flutter pub get --enforce-lockfile
flutter run
```

## Build
```bash
flutter build ios --release
```

## Quality
```bash
flutter analyze
flutter test -r expanded
```

## Presets
Presets are defined in `lib/features/presets/preset_registry.dart`. To add one:
- Add a new `LumaPreset` entry to `PresetRegistry.all`.
- Include it in the appropriate `LumaPresetPack` in `PresetRegistry.packs`.
- Adjust its `values` map to match the desired look.

## Screenshots
![Splash](ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage.png)
![Branding](assets/branding/luma_mark_light.png)

## Changelog (v1.0.0)
- Premium editor stage background (dark, consistent)
- Signature preset packs with curated names + descriptions
- Film pack includes "Neutral Scan" anchor preset
- Presets tab updated with larger tiles + saved presets section
- Splash screen held for 2 seconds and matched to iOS LaunchScreen
