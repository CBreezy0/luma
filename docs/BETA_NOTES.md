# Beta Notes

## Supported Devices
- iPhone only
- A physical device is required for camera validation
- ProRAW and 48MP workflows require supported hardware

## Current Focus Areas
- cold launch reliability in iOS Release / TestFlight-style builds
- camera preview stability after launch, resume, and look switching
- capture/save consistency across processed, RAW, and ProRAW formats
- library metadata correctness, thumbnail recovery, and editor handoff

## Known Limitations
- The iOS simulator cannot validate live camera capture paths.
- Hardware-dependent formats and resolutions vary by device and active session format.
- Signed distribution still requires Apple certificates, provisioning assets, and App Store Connect credentials outside normal repo validation.
