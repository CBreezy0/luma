# Beta Checklist

## Core launch and camera flow
- [ ] Clean install works on a physical iPhone
- [ ] Cold launch reaches the camera shell without hanging on splash
- [ ] Camera preview starts reliably after launch and after background/resume
- [ ] Switching looks does not freeze preview or desync saved captures

## Capture and save flow
- [ ] HEIC / JPEG capture works
- [ ] RAW / RAW+processed capture works on supported hardware
- [ ] ProRAW and 48MP selection work on supported devices
- [ ] Captured photos save into the Luma library and can be reopened

## Library and editor flow
- [ ] Gallery/library loads quickly and shows metadata correctly
- [ ] Favorites, ratings, search, and filters behave as expected
- [ ] Editor opens selected photos reliably and export/share completes
- [ ] Missing thumbnails recover automatically when needed

## Repo validation
- [ ] `dart format --set-exit-if-changed lib test` passes
- [ ] `flutter analyze` passes
- [ ] `flutter test` passes
