# Luma

Luma is an iOS-first camera + photo workflow app built with Flutter and native Swift camera/rendering code.

It is designed around a professional shooting flow:
- Shoot in-app (JPG/RAW)
- Stay in camera after capture
- Build a session/library
- Open images in a non-destructive editor

## Current App Capabilities

### Camera (Native iOS pipeline)
- AVFoundation capture session with custom preview surface
- Film look system with `Original` (no look) + styled looks
- Look strength slider
- Exposure bias slider
- Live luminance histogram
- Tap-to-focus + long-press AE/AF lock
- Pinch-to-zoom
- RAW/JPG capture toggle (when supported)
- HEIC/JPEG output selection handled in native capture settings
- Thumbnail handoff back to Flutter UI

### Luma Library + Gallery
- Internal library storage under app documents:
  - `LumaLibrary/Originals`
  - `LumaLibrary/Edited`
  - `LumaLibrary/RAW`
  - `LumaLibrary/JPG`
  - `LumaLibrary/Thumbnails`
- Gallery shows only:
  - Photos captured in Luma
  - Photos explicitly imported by user
- No auto camera-roll preload
- Fast square thumbnail grid with lazy/infinite loading
- Multi-select actions:
  - Favorite / Unfavorite
  - Rate
  - Color label
  - Batch edit instruction append
  - Export
  - Delete
- Smart album filters:
  - All, Favorites, RAW, Edited, Imported, Recently Edited, Portrait, Landscape

### Viewer + Editing Workflow
- Full-screen viewer with swipe navigation
- Pinch + double-tap zoom
- Metadata overlay
- Histogram overlay (Luminance / RGB)
- Version actions:
  - Duplicate active version
  - Revert to original
- Side-by-side compare mode
- Editor route integration for selected photo

### Non-Destructive Model
- Originals are copied and retained
- Metadata + edit state is stored in Isar (with one-time migration from legacy `library_index.json` when present)
- Version system stores edit instructions instead of mutating originals

## Architecture Overview

- Flutter UI/state:
  - `lib/features/camera/*`
  - `lib/features/library/*`
  - `lib/features/editor/*`
  - Riverpod state notifiers for camera and library state
- Native iOS camera plugin:
  - `ios/Runner/LumaCameraPlugin.swift`
  - `ios/Runner/CameraViewController.swift`
  - `ios/Runner/LumaFilmSimulation.swift`
  - `ios/Runner/LumaLUTLoader.swift`
- Native editor renderer bridge:
  - `ios/Runner/NativeRenderer.swift`
  - `lib/features/editor/native/native_renderer.dart`

## Manual Import Behavior

Import is explicit only:
- Camera screen: `Import Photo` button (single/multi fallback)
- Gallery screen: `Import Photo` floating action button (multi-select)

No background fetch of all albums/assets is performed for gallery display.

## Tooling and CI

### GitHub Actions
Workflow file:
- `.github/workflows/flutter_ci.yml`

Runs:
1. `flutter pub get`
2. `dart format --set-exit-if-changed .`
3. `flutter analyze`
4. `flutter test`
5. `flutter build ios --simulator --no-codesign`

### Xcode Cloud Post-Clone Script
- `ci_scripts/ci_post_clone.sh` delegates to `ios/ci_scripts/ci_post_clone.sh`
- The iOS script installs Flutter (if needed), precaches iOS artifacts, runs `flutter pub get`, generates Flutter iOS config files, and runs `pod install --repo-update`.

## Local Development

### Requirements
- Flutter stable (Dart SDK compatible with `pubspec.yaml`)
- Xcode + CocoaPods for iOS builds

### Common Commands
```bash
flutter pub get
dart format .
flutter analyze
flutter test
flutter run
```

### iOS Build
```bash
flutter build ios --simulator --no-codesign
```

## Project Structure (Key Files)

- App entry:
  - `lib/main.dart`
- Camera:
  - `lib/features/camera/camera_page.dart`
  - `lib/features/camera/camera_provider.dart`
  - `ios/Runner/CameraViewController.swift`
- Gallery/Library:
  - `lib/features/camera/luma_gallery_page.dart`
  - `lib/features/library/library_models.dart`
  - `lib/features/library/photo_record.dart`
  - `lib/features/library/library_repository.dart`
  - `lib/features/library/library_provider.dart`
  - `lib/features/library/library_viewer_page.dart`
- Editor:
  - `lib/features/editor/editor_page.dart`
  - `lib/features/editor/native/native_renderer.dart`
  - `ios/Runner/NativeRenderer.swift`

## Recent Optimizations Applied

- Batched gallery multi-select updates to avoid repeated disk writes/refreshes per photo:
  - Favorites, ratings, and color labels now update in a single repository transaction per action.
- Camera-side import now supports multi-photo selection (with single-photo fallback).
- Orientation preference path in native camera now prioritizes interface orientation for more stable upright preview behavior.
