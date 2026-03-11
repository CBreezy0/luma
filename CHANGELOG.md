# Changelog

## v2.0.0-beta
- Rebuilt the native AVFoundation camera and preview pipeline around the custom iOS camera stack.
- Added the Core Image film simulation system with real-time look switching and shared render behavior between preview and still capture.
- Expanded capture support for HEIC, JPEG, RAW, RAW+HEIC, RAW+JPEG, and Apple ProRAW with 48MP targeting on supported hardware.
- Added the internal Luma library with Isar-backed metadata, thumbnail generation/recovery, favorites, ratings, and richer gallery viewing.
- Added the native editor/export bridge for full-resolution rendering and sharing.
- Fixed the release-only iOS startup splash hang by moving Isar work off the pre-`runApp()` path and retaining IsarCore symbols in release builds.
- Cleaned repo automation by removing duplicate CI, making distribution workflows manual-only, and refreshing repo documentation.
- Added MIT licensing, CODEOWNERS, contribution guidance, and stronger ignore rules for secrets, signing assets, and local build artifacts.

## v1.0.1 (Beta)
- Editor: compact adjustment picker with Quick list and “All tools” panel.
- Presets: category → list → active flow with intensity slider, cancel/done actions, and expanded preset catalog.
- Gallery: Recents/Albums/Screenshots/RAW/Favorites filters with sorting and pagination.
- Favorites: in-app hearts (tap/long-press) with local persistence and a Favorites filter.
- Samples: “Try Sample Photos” flow when Photos access is unavailable.
- Preview: iOS rendering moved off the main thread with requestId ordering to ignore stale frames.
- Preview: preset intensity uses image-space blend for final frames with double-buffered swaps to avoid flicker.
- Interaction: drag renders are throttled/gated to keep sliders responsive.
- CI/Build: Flutter action with lockfile enforcement, analyze + expanded tests; version bumped to 1.0.1+2.
- Docs: README refreshed with screenshots, beta status, build, and feedback info.

## 0.1.0 (First Beta)
- Premium editor stage background (dark, consistent)
- Signature preset packs with curated names + descriptions
- Film pack includes "Neutral Scan" anchor preset
- Presets tab updated with larger tiles + saved presets section
- Splash screen held for 2 seconds and matched to iOS LaunchScreen
