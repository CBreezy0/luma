# Luma v2 Beta

Release tag: `v2.0.0-beta`
App version: `2.0.0`
Current repo build number: `4`

## Summary

Luma v2 Beta is the current baseline for the rebuilt iOS camera, film simulation, library, and editor stack. This repo state includes the release-startup fix that resolved the iOS/TestFlight splash-screen hang and keeps the camera, gallery, and editing flows aligned with the live preview pipeline.

## New Features

- Custom AVFoundation camera implementation for preview, focus, zoom, exposure, and capture controls.
- Real-time Core Image film simulation pipeline with the `original`, `slate`, `ember`, `bloom`, `drift`, `vale`, and `mono` looks.
- Multi-frame processed capture path with frame alignment and bracket-aware merge support.
- Apple ProRAW capture support with 48MP targeting on supported devices.
- Expanded capture-format support for HEIC, JPEG, RAW, RAW+HEIC, RAW+JPEG, and ProRAW.
- Internal Luma gallery/library backed by Isar metadata and managed thumbnail generation.
- Native renderer bridge for editor previews, exports, and share flows.

## Stability and Performance

- Shared `CIContext` reuse across preview, still capture, and editor rendering.
- LUT descriptor caching to reduce repeated setup overhead.
- Per-render `CIFilter` construction to avoid cross-thread filter mutation.
- Improved preview throttling and histogram scheduling under sustained camera load.
- Synchronous look-state application so a newly selected film profile stays aligned with capture results.
- Camera provider timeout handling to keep startup and resume flows from hanging indefinitely.
- Cleaner GitHub CI and workflow naming with manual-only distribution automation.

## Bug Fixes

- Fixed the release-only iOS startup hang where the app stayed on the native splash screen before the first Flutter frame.
- Root cause: `Isar.initializeIsarCore(download: false)` was called before `runApp()`, and release dead-code stripping removed the IsarCore FFI symbols that call expected.
- Kept app launch free of database work before the first Flutter frame and retained IsarCore symbols in iOS release linker settings.
- Fixed a capture-state race where newly selected film profiles or look strength could lag behind the live preview during capture.
- Removed stale repository placeholders and local-only files that did not belong in source control.
- Simplified GitHub workflow behavior so routine pushes do not trigger any distribution path.

## Beta Testing Focus

Please focus testing on the following areas:

- Cold-launch the app repeatedly in Debug and Release and confirm the splash transitions into the camera shell every time.
- Start and stop the camera repeatedly and confirm the live preview appears reliably.
- Switch film profiles quickly while framing a scene and confirm the saved photo matches the previewed look.
- Capture in HEIC, JPEG, RAW, RAW+HEIC, RAW+JPEG, and ProRAW on supported devices.
- On supported hardware, test ProRAW resolution selection and confirm 48MP capture behavior.
- Exercise tap-to-focus, AE/AF lock, manual focus, zoom presets, and exposure-bias updates.
- Review library metadata, favorites, ratings, and thumbnail recovery behavior.
- Open editor previews, adjust parameters aggressively, and export full-resolution files.

## Notes for Beta Testers

This beta introduces the new custom camera engine, real-time film simulations, major image-processing improvements, and the iOS release-startup fix. Please report:

- preview freezes or black frames
- look switching mismatches between preview and saved photo
- RAW / ProRAW failures
- incorrect gallery metadata or missing thumbnails
- editor/export failures or unusually slow processing
