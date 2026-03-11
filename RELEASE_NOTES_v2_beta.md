# Luma v2 Beta

Release tag: `v2.0.0-beta`
App version: `2.0.0`
Build number: `3`

## New Features

- New custom AVFoundation camera implementation for capture, preview, focus, zoom, and exposure controls.
- Real-time Core Image film simulation pipeline with six branded looks plus the original profile.
- Multi-frame processed capture pipeline with frame alignment and bracket-based merge support.
- Apple ProRAW capture support with 48MP targeting on supported devices.
- Expanded capture format support for HEIC, JPEG, RAW, RAW+HEIC, RAW+JPEG, and ProRAW.
- Luma internal gallery system backed by Isar metadata and managed thumbnail generation.
- Native editor rendering bridge for preview rendering and full-resolution export.

## Performance Improvements

- Shared `CIContext` reuse across preview, still capture, and editor rendering.
- Cached LUT cube descriptors to reduce repeated setup overhead.
- Adaptive preview processing mode to protect frame rate under load.
- Safer per-render `CIFilter` construction to avoid cross-thread filter mutation.
- Improved camera startup resilience with explicit timeout handling in the Flutter provider.
- Updated CI workflows to use a consistent Flutter SDK version and clearer workflow names.

## Bug Fixes

- Fixed a capture-state race where a newly selected film profile or look strength could lag behind the live preview during capture.
- Removed stale workspace/config artifacts from the tracked repository state.
- Cleaned release metadata so Xcode now resolves version `2.0.0` and build `3` from Flutter build settings.
- Corrected release build settings so Debug resolves to Apple Development while Profile and Release resolve to Apple Distribution in Xcode build settings.

## Beta Testing Instructions

Please focus testing on the following areas:

- Start the camera repeatedly and confirm the live preview appears reliably.
- Switch film profiles quickly while framing a scene and confirm the saved photo matches the previewed look.
- Capture in HEIC, JPEG, RAW, RAW+HEIC, RAW+JPEG, and ProRAW on supported devices.
- On supported hardware, test ProRAW resolution selection and confirm 48MP capture behavior.
- Exercise tap-to-focus, AE/AF lock, manual focus, zoom presets, and exposure bias updates.
- Capture high-contrast scenes to stress the multi-frame processed capture path.
- Review gallery metadata, favorites, ratings, and thumbnail recovery behavior.
- Open editor previews, adjust parameters aggressively, and export full-resolution files.

## Notes for TestFlight Testers

This beta introduces the new custom camera engine, real-time film simulations, and major image-processing improvements. Please report:

- preview freezes or black frames
- look switching mismatches between preview and saved photo
- RAW / ProRAW failures
- incorrect metadata in the gallery viewer
- export failures or unusually slow processing
