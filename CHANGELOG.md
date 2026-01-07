# Changelog

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
