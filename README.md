![Lenovo Backlight Controller](https://github.com/r00bertos1/lenovo-backlight-controller/releases/download/v0.1.0/header.webp)

# lenovo-backlight-controller

Auto keyboard backlight controller for Lenovo laptops on Windows — turns on when you type, off when you don't, only at night.

## Install

```powershell
iwr -useb https://raw.githubusercontent.com/r00bertos1/lenovo-backlight-controller/main/install.ps1 | iex
```

No admin rights needed. The installer:
1. Installs AutoHotkey v2 via winget if missing.
2. Downloads this repo to `%LOCALAPPDATA%\lenovo-backlight-controller\`.
3. Registers a Task Scheduler entry to auto-start at login.
4. Starts the controller immediately.

Re-running the one-liner upgrades to the latest from `main`.

## How it works

- **Keyboard idle detection**: uses the built-in Windows `A_TimeIdleKeyboard` counter via AutoHotkey. Polls every 1 second. No keyboard hook installed.
- **Night gate**: reads Windows Night Light state directly from the registry. You configure the sunset/sunrise schedule in `Settings → System → Display → Night Light`. The controller respects whatever schedule (or fixed hours) you set there.
- **Driver layer**: talks to Lenovo's `IBMPmDrv` (ThinkPad) or `EnergyDrv` (ThinkBook/IdeaPad) directly via `DeviceIoControl`. No third-party tray app or service.

State machine:
1. Backlight starts off.
2. After 15+ seconds of keyboard idle, any keypress → check Night Light. If on, set backlight to High.
3. After 15 seconds of keyboard idle while on, set backlight to Off.
4. Mouse activity does not count as input.

## Supported devices

Out of the box:

| Name | Driver |
|---|---|
| ThinkPad T16 Gen 2 | IBMPmDrv |
| ThinkPad (legacy IBMPmDrv) | IBMPmDrv |
| ThinkBook / IdeaPad (EnergyDrv v1) | EnergyDrv |
| ThinkBook / IdeaPad (EnergyDrv v2) | EnergyDrv |

If your device isn't recognized, run `tools\detect-device.ahk` from the install dir — it cycles the backlight, records the response pattern, and adds a new entry to `devices.json` automatically. Then please open a PR (see CONTRIBUTING.md) so others benefit.

## Configuration

Edit the constants at the top of `controller.ahk`:
- `IdleMs := 15000` — idle timeout in milliseconds.
- `ActiveLevel := "high"` — active level: `"high"` or `"low"`.

Restart the controller (Task Scheduler entry or re-run the installer) after editing.

> Note: re-running the `iwr | iex` installer overwrites `%LOCALAPPDATA%\lenovo-backlight-controller\` with a fresh copy of `main`, so your edits revert. Keep a backup of your customized `controller.ahk` (or work from a fork) if you change the defaults.

## Troubleshooting

**Backlight doesn't turn on at all.**
- Check Night Light is enabled in Windows Settings.
- Wait 15 seconds without touching the keyboard, then press a key. The controller only re-checks Night Light on idle→active transitions.
- Verify the controller is running: `Get-Process AutoHotkey64`. If missing, log in again (Task Scheduler trigger) or run `controller.ahk` manually.

**"No supported Lenovo backlight device detected"** at startup.
- Your device isn't in `devices.json`. Run `tools\detect-device.ahk`. It will add your device and prompt you to open a PR.

**Night Light reading is wrong (controller never activates / always activates).**
- Microsoft can change the registry blob layout in Windows updates. Inspect:
  ```powershell
  $p = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\CloudStore\Store\DefaultAccount\Current\default$windows.data.bluelightreduction.bluelightreductionstate\windows.data.bluelightreduction.bluelightreductionstate'
  (Get-ItemProperty -Path $p -Name Data).Data -join ' '
  ```
  Toggle Night Light off/on between runs and diff. Find the byte that consistently flips between two distinct values. Update `NL_ON_OFFSET` and `NL_ON_BYTE` in `lib\nightlight.ahk` if your build differs from offset 23 / value `0x10` (verified on Windows 11 build 26200).

## Uninstall

```powershell
iwr -useb https://raw.githubusercontent.com/r00bertos1/lenovo-backlight-controller/main/uninstall.ps1 | iex
```

This removes the install dir and Task Scheduler entry. AutoHotkey runtime is left alone (it may be shared with other tools — remove via `winget uninstall AutoHotkey.AutoHotkey` if you want it gone too).

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for how to add device support or improve the code.

## Roadmap

Ideas under consideration. Open a discussion before starting larger changes — happy to refine the design together.

- **Configurable activation strategy** ([#1](https://github.com/r00bertos1/lenovo-backlight-controller/issues/1)).
  Beyond the current Night Light gate: always-on, fixed-hours schedule (e.g. `18:00-08:00`), or sync with Windows dark mode. Sketch: an `activation` config key selecting `nightlight` (default), `always`, `schedule:HH:MM-HH:MM`, or `darkmode`.

- **Tray GUI for runtime configuration** ([#2](https://github.com/r00bertos1/lenovo-backlight-controller/issues/2)).
  Right-click tray menu for idle timeout, activation strategy, and active level — instead of editing `controller.ahk`. Persist settings to a small JSON file outside the auto-overwritten install dir so customizations survive `iwr | iex` upgrades.

- **Pause on low battery / battery saver** ([#3](https://github.com/r00bertos1/lenovo-backlight-controller/issues/3)).
  Read `GetSystemPowerStatus` and skip activation when battery is below a threshold (default 20%) or Windows battery saver is active. Backlight costs measurable mW on most ThinkPads.

- **Power-draw measurement and tuning** ([#4](https://github.com/r00bertos1/lenovo-backlight-controller/issues/4)).
  Quantify CPU and battery impact of the 1-second `SetTimer` loop on T16 G2 and 1-2 older ThinkPads. Lower polling rate, switch to event-based wakeup (`SetWaitableTimer`, idle-state notification), or drop the AHK timer entirely if the data justifies it.

## Credits

- Initial reverse-engineering of `DriversConfig.json` device patterns: [SaltwaterC/KeyboardBacklightForLenovo](https://github.com/SaltwaterC/KeyboardBacklightForLenovo).
- IBMPmDrv IOCTL research: ThinkPad community over many years.

## License

MIT — see [LICENSE](LICENSE).
