# Security policy

## Reporting a vulnerability

If you find a security issue — for example, a way for the controller to be abused for privilege escalation, kernel driver misuse, or arbitrary code execution — please open a private security advisory:

https://github.com/r00bertos1/lenovo-backlight-controller/security/advisories/new

Please do not file public issues for security reports.

## Scope and threat model

This project talks to two kernel drivers (`IBMPmDrv`, `EnergyDrv`) that ship with Lenovo laptops. It uses `DeviceIoControl` only:

- Reads the current backlight level (4-byte response).
- Writes one of three backlight levels (`off` / `low` / `high`).
- No privilege escalation. No driver loading. No memory remapping.

The controller runs as the logged-in user (`Limited` run level, no elevation). It registers a per-user scheduled task triggered at log on. The installer writes to `%LOCALAPPDATA%` only — nothing in `Program Files`, `System32`, or `HKLM`.

`tools\detect-device.ahk` is the only piece that probes unknown IOCTLs and is run manually by the user.

`install.ps1` downloads a release zip from `github.com/r00bertos1/lenovo-backlight-controller` over HTTPS and extracts it. If you are concerned about supply-chain risk, clone the repo and run `install.ps1` from a local checkout instead of `iwr | iex`.
