# Luma Studio 3.0.0 Beta

Version: `3.0.0`
Build: `1`

## Summary

Luma Studio 3.0.0 Beta is the next repository-prepared beta milestone for the Luma camera, library, and editor stack. This version keeps the iOS startup reliability fix in place while advancing the native camera pipeline, film simulation stability, gallery responsiveness, and capture/save reliability.

## Major Improvements

- New native camera pipeline improvements
- Film simulation engine stability updates
- Gallery performance improvements
- Fix for the release/TestFlight splash screen startup issue
- Improved capture and save flow
- General stability and performance improvements

## Validation Focus

Please focus testing on the following areas when this build is eventually distributed manually:

- Cold launch into the camera shell on iPhone hardware
- Capture preview stability while switching looks
- Save flow reliability for processed and RAW-capable capture formats
- Gallery loading speed, metadata correctness, and thumbnail recovery
- Editor handoff, preview rendering, and export behavior
