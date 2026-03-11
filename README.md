# Luma

Luma is an iOS-first camera, library, and editing app built with Flutter for product UI and native Swift for capture, preview rendering, and high-resolution image processing. The repository focuses on a custom AVFoundation camera stack, a Core Image film simulation pipeline, an internal Isar-backed library, and a non-destructive editor/export flow.

Created and maintained by **Chris Bryant**, Luma is intentionally developed in public and kept safe for open collaboration through documented ownership, manual-only distribution workflows, and conservative secret-handling rules.

## Current Status

Luma is currently tracked as **Luma v2 Beta**.

- custom AVFoundation camera implementation with native preview rendering
- real-time Core Image film simulation pipeline with seven built-in looks
- shared `CIContext` reuse across preview, still capture, and editor rendering
- multi-frame processed capture, RAW workflows, and Apple ProRAW / 48MP support on supported hardware
- internal library with Isar metadata, thumbnail generation, favorites, ratings, and capture metadata
- native editor rendering bridge for preview, export, and iOS share flows

## Luma v2 Beta Highlights

Luma v2 Beta is the current repository baseline for the rebuilt imaging stack.

- rebuilt camera flow around `ios/Runner/CameraViewController.swift`
- shared film simulation and render pipeline in `ios/Runner/LumaFilmSimulation.swift`
- preview reliability improvements, histogram throttling, and look-switch synchronization fixes
- startup hardening for release/TestFlight cold launches on iOS
- refreshed GitHub workflows so CI stays active while distribution remains manual-only and opt-in

## Startup Reliability Fix

The most important recent release fix is the iOS release/TestFlight splash-screen hang. The root cause was an eager `Isar.initializeIsarCore(download: false)` call before `runApp()`. In release builds, dead-code stripping removed IsarCore FFI symbols that `DynamicLibrary.process()` expected, so the app failed before Flutter rendered its first frame.

The fix keeps launch free of database work before `runApp()` and retains IsarCore symbols in the iOS release linker settings. That keeps cold launch behavior aligned across Debug, Release, and TestFlight while preserving the gallery's Isar-backed metadata layer.

## Feature Overview

### Camera

- custom native camera preview and controls driven from Flutter via method/event channels
- focus, AE/AF lock, zoom presets, exposure bias, flash mode, and format selection
- HEIC, JPEG, RAW, RAW+HEIC, RAW+JPEG, and Apple ProRAW capture support
- 48MP ProRAW targeting on supported devices
- multi-frame processed capture path with bracket alignment support

### Film Simulation

Built-in looks are defined natively and surfaced in Flutter with stable IDs:

- `original`
- `slate`
- `ember`
- `bloom`
- `drift`
- `vale`
- `mono`

Preview rendering and still rendering share the same look definitions so saved output stays aligned with the live camera look. The render path uses shared `CIContext` reuse and per-render `CIFilter` construction to avoid mutable filter reuse across queues.

### Library / Gallery

Luma maintains an internal library instead of mirroring the entire system photo roll.

- metadata is stored with Isar in `lib/features/library/`
- originals, processed outputs, RAW companions, and thumbnails live under the app library root
- thumbnail generation and recovery run in the background
- gallery filters support recents, favorites, RAW, edited, imported, ratings, and search workflows
- the viewer surfaces capture metadata and routes directly into the editor/export path

### Editor and Export

The editor is non-destructive and replays settings through the native renderer.

- preview rendering uses the native Core Image pipeline
- edits preserve original assets while recording adjustment metadata
- crop, rotation, straighten, preset blending, and parameter-based adjustments are supported
- export and share flows are bridged through native iOS code for full-resolution output

## Architecture Summary

### Flutter modules

- `lib/features/camera/` — camera UI, Riverpod state, method-channel bridge, look picker, histogram, capture UI, and gallery entry points
- `lib/features/library/` — Isar-backed metadata, library repository/controller, thumbnail services, and viewer flows
- `lib/features/editor/` — non-destructive editing UI and native-renderer integration
- `lib/features/export/` — export and share helpers on top of the renderer pipeline
- `test/` — Dart-side unit and widget coverage for camera, library, and editor behavior

### Native iOS modules

- `ios/Runner/AppDelegate.swift` — app bootstrap, plugin registration, and native Flutter channels
- `ios/Runner/LumaCameraPlugin.swift` — Flutter bridge for the native camera surface and controls
- `ios/Runner/CameraViewController.swift` — session lifecycle, device control, preview, capture orchestration, RAW / ProRAW, and metadata packaging
- `ios/Runner/LumaPreviewProcessor.swift` — live preview processing path
- `ios/Runner/LumaFilmSimulation.swift` — film profiles plus the shared film render pipeline for preview and stills
- `ios/Runner/LumaLUTLoader.swift` — LUT generation and caching
- `ios/Runner/LumaFrameAligner.swift` — frame alignment for processed multi-frame capture
- `ios/Runner/NativeRenderer.swift` — editor preview rendering and full-resolution export
- `ios/Runner/LumaCIContext.swift` — shared Core Image context and color-space configuration

## Local Development

### Prerequisites

- Flutter stable `3.41.x`
- Xcode with iOS SDKs and command-line tools installed
- CocoaPods available on the machine
- a physical iPhone for camera validation; the simulator cannot exercise camera hardware paths

### Setup

```sh
flutter pub get
cd ios && pod install && cd ..
```

### Run locally

```sh
flutter run -d <ios-device-id>
```

For local Xcode debugging, open `ios/Runner.xcworkspace`, select a physical iPhone, and choose either **Debug** or **Release** run configuration depending on the path you want to validate.

## Repo-Safe Validation

These commands are safe for local and CI validation and do not upload or distribute builds:

```sh
dart format --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build ios --release --no-codesign
```

## GitHub Automation

The repository keeps GitHub automation intentionally conservative.

- Linux CI checks formatting, static analysis, and tests on every push / pull request to `main`
- macOS validation performs `pod install` and an unsigned iOS release build
- TestFlight upload automation is **manual-only**, requires explicit confirmation, and is guarded in both GitHub Actions and Fastlane
- normal pushes and tags do **not** upload anything to App Store Connect

## Ownership and License

- Project ownership is defined in `.github/CODEOWNERS` and the Git history remains attributable to Chris Bryant.
- Contribution expectations and safe development rules live in `CONTRIBUTING.md`.
- Luma is available under the MIT License in `LICENSE`.

## Known Limitations

- Luma is currently iPhone-only
- the iOS simulator cannot validate live camera behavior
- Apple ProRAW and 48MP capture depend on supported hardware and current session format availability
- signed App Store / TestFlight delivery still requires Apple certificates, provisioning assets, and App Store Connect credentials on the build machine

## Release History

- `v2.0.0-beta` — rebuilt camera, film simulation, library, and editor pipeline with the iOS startup hang fix
- `v1.0.1` — editor, gallery, and preview interaction refinements
- `0.1.0` — first beta milestone

Detailed beta notes live in `RELEASE_NOTES_v2_beta.md`, with additional tester guidance in `docs/BETA_CHECKLIST.md` and `docs/BETA_NOTES.md`.

If you want to contribute, start with `CONTRIBUTING.md`, use the bug-report template for reproducible issues, and keep all changes free of signing assets, private credentials, and release artifacts.
