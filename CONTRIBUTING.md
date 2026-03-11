# Contributing to Luma

Thanks for taking the time to contribute to Luma.

Luma is an intentionally public repository created and maintained by Chris Bryant. The project combines Flutter UI with native Swift imaging code, so even small changes can affect camera behavior, gallery persistence, or editor rendering. Please keep contributions focused, well-tested, and free of secrets or signing assets.

## Project Scope

- `lib/features/` contains the Flutter feature modules for camera, library, editor, export, and supporting flows.
- `ios/Runner/` contains the native iOS camera, preview, render, and plugin bridge implementation.
- `.github/workflows/` contains CI and the manually guarded distribution workflow.

## Local Setup

```sh
flutter pub get
cd ios && pod install && cd ..
```

For camera validation, use a physical iPhone. The simulator cannot exercise the live camera path.

## Development Guidelines

- Keep changes scoped to the problem you are solving.
- Match the surrounding code style and existing project structure.
- Update docs when behavior, workflows, or setup steps change.
- Prefer repo-safe validation steps over distribution actions during normal development.
- Never commit secrets, signing material, local environment files, or generated release artifacts.

## Validation

Run the relevant safe checks before opening a pull request:

```sh
dart format --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build ios --release --no-codesign
```

Use the iOS build step when changing native camera, plugin, signing, or release-path behavior.

## Pull Requests

- Describe the problem and the fix clearly.
- Call out any camera, gallery, editor, or startup flows affected.
- Include device / iOS version notes when behavior depends on hardware.
- Confirm that no distribution, App Store Connect, or TestFlight automation was triggered as part of normal validation.

By contributing, you agree that your contributions will be licensed under the MIT License in `LICENSE`.
