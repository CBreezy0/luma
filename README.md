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

## TestFlight CI (GitHub Actions)
This repo can build and upload an iOS IPA to TestFlight using GitHub Actions +
Fastlane. Workflow: `.github/workflows/ios_testflight.yml`

### Required GitHub Secrets
Add these in **GitHub → Settings → Secrets and variables → Actions**.

#### Signing (manual)
- `IOS_P12_BASE64` – base64 of your iOS signing certificate `.p12`
- `IOS_P12_PASSWORD` – password used when exporting the `.p12`
- `IOS_PROFILE_BASE64` – base64 of your provisioning profile `.mobileprovision`
- `IOS_KEYCHAIN_PASSWORD` – any strong password (used only on the CI runner)

#### App identity
- `APP_IDENTIFIER` – bundle identifier (e.g. `com.yourcompany.luma`)
- `APPLE_TEAM_ID` – Apple Developer Team ID

#### App Store Connect API
- `ASC_KEY_ID` – API Key ID
- `ASC_ISSUER_ID` – Issuer ID
- `ASC_KEY_P8` – contents of the `.p8` key file (paste the full multiline text)

### Generate base64 values (macOS)
```bash
# Certificate (.p12)
base64 -i path/to/cert.p12 | pbcopy

# Provisioning profile (.mobileprovision)
base64 -i path/to/profile.mobileprovision | pbcopy
```

### Triggering a TestFlight build
Tag-based: push a version tag (e.g. `v1.0.2`) and the workflow will run
automatically.

```bash
git tag v1.0.2
git push origin v1.0.2
```

Manual: GitHub → Actions → iOS TestFlight → Run workflow

Builds will appear in App Store Connect → TestFlight after upload and
processing.

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
