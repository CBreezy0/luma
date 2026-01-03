# Luma

Luma is a minimalist iOS photo editor built with Flutter. It pairs a native
Core Image renderer with a lightweight Flutter UI for fast previews and full
resolution exports.

## Features
- Photo gallery grid with infinite scroll (Photos permission required)
- Editor with Light, Color, Effects, Detail, and Optics tool groups
- Built-in presets plus custom preset saving
- Undo/redo editing history
- Native Core Image preview + full-res export to Photos

## Tech Stack
- Flutter + go_router
- photo_manager for Photo Library access
- MethodChannel bridge to native iOS renderer (Core Image)

## Project Structure
- `lib/features/gallery`: photo grid + permission flow
- `lib/features/editor`: editor UI + tool logic
- `lib/features/presets`: built-in preset registry
- `ios/Runner/NativeRenderer.swift`: Core Image pipeline + export

## Requirements
- macOS
- Xcode
- Flutter SDK
- iOS device or Simulator

## Install
```bash
flutter pub get
```

## Run
### Simulator
```bash
flutter run
```

### Device (Xcode)
1) Open `ios/Runner.xcworkspace`
2) Select the `Runner` target and your Apple Team in Signing & Capabilities
3) Pick your device from the toolbar and press Run

## Permissions
Photo access strings live in `ios/Runner/Info.plist`:
- `NSPhotoLibraryUsageDescription`
- `NSPhotoLibraryAddUsageDescription`
- `NSCameraUsageDescription`
