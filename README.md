# Luma

Luma is a modern iOS photo camera and editor built with Flutter for product UI and native Swift for capture and rendering. The project combines a custom AVFoundation camera stack, an internal photo library, and a non-destructive editor in a single app workflow.

## Project Overview

Luma is designed around a photographer-first flow:

1. Capture photos in a custom in-app camera.
2. Keep originals and processed files inside the Luma library.
3. Review work in a fast gallery and viewer.
4. Apply non-destructive edits through a native rendering bridge.

The app is Flutter-driven at the feature layer, while performance-sensitive imaging work stays in native Swift.

## Luma v2

Luma v2 highlights the current beta direction:

- computational photography pipeline
- HDR multi-frame capture
- RAW workflows
- film simulation improvements
- tone-mapped preview pipeline
- Isar powered gallery
- background thumbnail generation

## Camera System

The camera system is implemented with AVFoundation and exposed to Flutter through a native plugin.

Current camera features include:

- Native AVFoundation capture session with a custom preview surface.
- Processed capture formats for HEIC and JPEG.
- RAW workflows, including single-frame RAW capture and Apple ProRAW support when available.
- Multi-frame HDR capture with bracketed stills and luminance-weighted merging.
- Frame alignment for HDR merge on still capture.
- Film simulation pipeline with LUT-backed looks and adjustable look strength.
- Processed preview pipeline with light tone mapping and film rendering.
- Live histogram stream derived from preview frames.
- Exposure bias controls, tap-to-focus, AE/AF lock, and manual focus support when hardware allows.
- Pinch zoom plus quick zoom levels such as `0.5x`, `1x`, `3x`, and `5x`.
- Processed still enhancements such as ISO-aware noise reduction and subtle sharpening.

Key native camera files:

- `ios/Runner/LumaCameraPlugin.swift`
- `ios/Runner/CameraViewController.swift`
- `ios/Runner/LumaPreviewProcessor.swift`
- `ios/Runner/LumaFilmSimulation.swift`
- `ios/Runner/LumaLUTLoader.swift`
- `ios/Runner/LumaFrameAligner.swift`

## Library System

Luma maintains its own internal library rather than mirroring the entire system photo roll.

The library system provides:

- An internal `LumaLibrary` storage layout for originals, edited outputs, RAW companions, JPEG/HEIC files, and thumbnails.
- Metadata persistence using Isar-backed records.
- Thumbnail generation and recovery for fast gallery browsing.
- Explicit imports into the Luma library instead of automatic camera-roll ingestion.
- Gallery filters, selection actions, and viewer metadata surfaces.

Primary library files live under:

- `lib/features/library/`
- `lib/features/camera/luma_gallery_page.dart`

## Editor Pipeline

The editor uses a non-destructive model. Originals are preserved, while edit instructions and versions are stored as metadata and replayed through a native renderer.

Current editor pipeline includes:

- Non-destructive edit versions.
- A preset-based adjustment system.
- Native preview rendering and full-resolution export through a Flutter method channel.
- Export and sharing flows built on top of the native renderer and iOS share/photos APIs.

Key files:

- `lib/features/editor/`
- `lib/features/export/`
- `ios/Runner/NativeRenderer.swift`

## Architecture

Luma uses a layered Flutter + Swift architecture.

Flutter is responsible for:

- Camera UI and state management.
- Gallery, library, and viewer flows.
- Editor controls, presets, and adjustment state.
- Method-channel and event-channel integration.

Native Swift is responsible for:

- AVFoundation capture and preview processing.
- HDR frame collection, alignment, and merge.
- Film simulation and still-image rendering.
- Export rendering and iOS-native sharing/photos save flows.

The main bridge points are:

- `luma/camera`
- `luma/camera_histogram`
- `luma/camera_zoom`
- `luma/native_renderer`
- `luma/native_share`

## Development Setup

### Requirements

- Flutter SDK
- Xcode
- CocoaPods

### Bootstrap

```bash
flutter pub get
cd ios && pod install && cd ..
flutter run
```

### Verification

```bash
dart format .
flutter analyze
flutter test
```

### iOS Simulator Build

```bash
xcodebuild -workspace ios/Runner.xcworkspace \
  -scheme Runner \
  -sdk iphonesimulator \
  -configuration Debug \
  CODE_SIGNING_ALLOWED=NO build
```

## CI/CD

Luma uses both GitHub Actions and Xcode Cloud.

### GitHub Actions

GitHub Actions covers Flutter and iOS validation, including:

- dependency setup
- formatting checks
- `flutter analyze`
- `flutter test`
- iOS simulator builds

### Xcode Cloud

Xcode Cloud support is configured through the repository CI scripts under:

- `ci_scripts/`
- `ios/ci_scripts/`

Those scripts prepare Flutter, generate iOS Flutter config, and install CocoaPods before cloud builds.
