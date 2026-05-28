# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.0] - 2026-05-25

### Added
- Initial release.
- Standalone AHK v2 controller with edge-detection state machine.
- Native `IBMPmDrv` / `EnergyDrv` driver layer via `DeviceIoControl`.
- Windows Night Light registry reader.
- One-liner installer / uninstaller (`iwr | iex`).
- Interactive device detection tool (`tools/detect-device.ahk`).
- Day-1 device support: ThinkPad T16 Gen 2, legacy ThinkPad (IBMPmDrv),
  ThinkBook/IdeaPad (EnergyDrv v1 & v2).
