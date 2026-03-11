# Luma

Luma is an iOS-first camera and photo workflow app built with Flutter for product UI and native Swift for capture, preview rendering, and high-resolution image processing. The app combines a custom AVFoundation camera, an internal library, and a non-destructive editor in one pipeline.

## Luma v2 Beta

Luma v2 Beta centers on a rebuilt camera and image-processing stack:

- custom AVFoundation camera implementation with native preview rendering
- Core Image film simulation pipeline with real-time look switching
- shared `CIContext` reuse across preview, capture, and editor rendering
- safer per-render `CIFilter` construction to avoid cross-thread filter reuse issues
- multi-frame processed capture and HDR-style bracket merging
- Apple ProRAW support and 48MP ProRAW target selection on supported hardware
- improved Luma gallery storage, metadata persistence, and thumbnail recovery
- native editor rendering bridge with full-resolution export and sharing flows

### iOS startup reliability

The iOS/TestFlight splash-screen hang was traced to an eager `Isar.initializeIsarCore(download: false)` call that ran before `runApp()`. In release builds, dead-code stripping removed most IsarCore FFI symbols, so that call threw before Flutter rendered its first frame and the native splash never advanced.

The fix keeps app launch free of database work before `runApp()` and updates the iOS release linker settings to force-load and retain the IsarCore archive symbols required by `DynamicLibrary.process()`. That keeps cold-start behavior consistent across Debug, Release, and TestFlight while preserving the gallery's Isar-backed metadata layer.

## Architecture

Luma is split between a Flutter feature layer and a native iOS imaging layer.

### Flutter feature modules

- `lib/features/camera/` drives camera UI, Riverpod state, method-channel integration, histogram display, and gallery entry points.
- `lib/features/library/` owns the internal Luma library, Isar-backed metadata, thumbnail generation, and viewer flows.
- `lib/features/editor/` provides the non-destructive editing experience and bridges to the native renderer.
- `lib/features/export/` handles export and share flows built on top of the native render pipeline.

### Native iOS modules

- `ios/Runner/LumaCameraPlugin.swift` exposes the native camera surface and controls to Flutter.
- `ios/Runner/CameraViewController.swift` owns AVFoundation session configuration, device controls, preview rendering, capture orchestration, RAW / ProRAW handling, metadata enrichment, and bracket capture.
- `ios/Runner/LumaPreviewProcessor.swift` runs the live preview path.
- `ios/Runner/LumaFilmSimulation.swift` contains look metadata plus the shared film render pipeline for preview and processed stills.
- `ios/Runner/LumaLUTLoader.swift` generates and caches LUT cube data.
- `ios/Runner/LumaFrameAligner.swift` supports multi-frame alignment for processed capture.
- `ios/Runner/NativeRenderer.swift` powers editor preview rendering and export.
- `ios/Runner/LumaCIContext.swift` centralizes the working color space and shared `CIContext`.

## Camera Pipeline Architecture

The camera pipeline is built around a native AVFoundation session with Flutter controlling state through method and event channels.

1. `CameraViewController` configures the capture session, video output, photo output, focus/exposure controls, zoom, and capture format availability.
2. Preview frames arrive through `AVCaptureVideoDataOutput` and are processed by `LumaPreviewProcessor`.
3. The preview processor applies a neutral base, film look transform, adaptive preview throttling, and optional histogram generation before updating the preview surface.
4. Still capture reuses the same look definitions through `LumaFilmRenderPipeline`, which keeps the preview and saved-image look behavior aligned.
5. Processed still capture can use multi-frame exposure bracketing and frame alignment before final rendering and metadata packaging.

### Preview reliability and performance

The current pipeline emphasizes responsiveness under sustained camera load:

- preview and still rendering share a reusable `CIContext`
- LUT descriptors are cached once and reused
- preview rendering adapts between standard and reduced modes based on observed frame cost
- histogram computation is throttled independently from preview rendering
- capture state now updates synchronously when switching looks or look strength, so saved results stay aligned with the live preview
- `CIFilter` instances in the film pipeline are created per render pass, avoiding thread-safety issues from reusing mutable filter instances across queues

## Film Simulation System

Film looks are defined in `ios/Runner/LumaFilmSimulation.swift` as normalized look profiles containing LUT selection, tone-curve data, color biases, grain, and still-polish parameters.

Supported built-in looks:

- `original`
- `slate`
- `ember`
- `bloom`
- `drift`
- `vale`
- `mono`

Each look can be blended with adjustable intensity and look strength. Preview rendering omits still-only polish such as grain and sharpening, while processed stills apply final sharpening and optional grain with ISO-aware scaling.

## Supported Capture Formats

Luma currently exposes the following capture modes through the native camera controller:

- HEIC
- JPEG
- RAW
- Apple ProRAW
- RAW + HEIC
- RAW + JPEG

Resolution handling is format-aware:

- processed HEIC / JPEG capture prefers 12MP and 24MP targets when available
- RAW and RAW+processed capture stay on the standard RAW path
- ProRAW targets the highest available sensor resolution and prefers 48MP on supported devices

## Gallery and Library System

Luma maintains its own internal library instead of mirroring the full system photo roll.

The library system provides:

- internal storage for originals, processed outputs, RAW companions, and thumbnails
- Isar-backed metadata records for capture details, ratings, favorites, and edits
- background thumbnail generation and thumbnail recovery
- gallery filters, sorting, and viewer metadata surfaces
- explicit save/import flows rather than implicit system-roll ingestion

Primary files for this layer live in `lib/features/library/` and `lib/features/camera/luma_gallery_page.dart`.

## RAW and Editor Workflows

The editor is non-destructive. Originals remain intact while edit settings are stored as metadata and replayed through `NativeRenderer`.

Current editor workflow highlights:

- full-resolution export through the native Core Image renderer
- crop, rotation, straighten, preset blending, and parameter-based adjustments
- native JPEG export and iOS sharing integration
- preservation of capture metadata inside the Luma library record
- RAW companion awareness in the library and capture pipeline

## Performance Improvements

Luma v2 Beta includes several production-readiness improvements:

- shared `CIContext` reuse instead of ad hoc context creation
- safer filter lifecycle management in the film render path
- improved preview throttling and histogram scheduling under load
- stronger state synchronization between look selection and capture execution
- removed pre-`runApp()` IsarCore initialization from the launch path so the first Flutter frame is never blocked by database setup
- iOS release builds now force-load and retain IsarCore symbols so TestFlight cold starts match local debug behavior
- camera provider startup timeouts to prevent hanging UI initialization
- cleaner CI workflow naming and consistent Flutter SDK pinning in GitHub Actions

## Development Validation

Recommended validation commands:

- `flutter analyze`
- `flutter test`
- `flutter build ios --release --no-codesign`
- `xcodebuild -workspace ios/Runner.xcworkspace -scheme Runner -configuration Release -showBuildSettings`

For signed App Store / TestFlight delivery, a valid Apple Distribution certificate and matching provisioning assets are still required on the build machine.
