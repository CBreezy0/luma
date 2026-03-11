## Summary
- What changed?
- Why was it needed?

## Validation
- [ ] `dart format --set-exit-if-changed lib test`
- [ ] `flutter analyze`
- [ ] `flutter test`
- [ ] `flutter build ios --release --no-codesign` (required for native iOS / startup / camera / signing-path changes)

## Notes
- Device / iOS version tested:
- Affected areas: camera / library / editor / startup / docs / workflows
- Docs updated if behavior or setup changed
- No secrets, signing assets, or local-only files were committed
- No App Store Connect / TestFlight / distribution automation was triggered unintentionally
