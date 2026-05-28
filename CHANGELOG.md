# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.1] - 2026-05-28

### Fixed
- `tools/detect-device.ahk`: replace removed `wmic` with `Get-CimInstance`
  (forward-compat with Windows 11 25H2 / build 26200+).
- README troubleshooting and `docs/ARCHITECTURE.md`: correct Night Light
  registry path, variable names (`NL_ON_OFFSET` / `NL_ON_BYTE`), and byte
  offset to match the implementation verified on build 26200.
- CHANGELOG date for 0.1.0 corrected to 2026-05-28.

### Added
- README header image (hosted on the v0.1.0 release asset).
- `## Roadmap` section in README linking to issues #1-#4.
- `SECURITY.md` with threat model and private advisory link.
- GitHub issue templates (`bug_report`, `device_request`) and PR template.
- `tools/validate-devices.py` + GitHub Actions workflow validating
  `devices.json` on every PR.
- Note in README that `iwr | iex` upgrades overwrite local config edits.

## [0.1.0] - 2026-05-28

### Added
- Initial release.
- Standalone AHK v2 controller with edge-detection state machine.
- Native `IBMPmDrv` / `EnergyDrv` driver layer via `DeviceIoControl`.
- Windows Night Light registry reader.
- One-liner installer / uninstaller (`iwr | iex`).
- Interactive device detection tool (`tools/detect-device.ahk`).
- Day-1 device support: ThinkPad T16 Gen 2, legacy ThinkPad (IBMPmDrv),
  ThinkBook/IdeaPad (EnergyDrv v1 & v2).
