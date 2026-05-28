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
  $p = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\CloudStore\Store\Cache\DefaultAccount\$$windows.data.bluelightreduction.bluelightreductionstate\Current'
  (Get-ItemProperty -Path $p -Name Data).Data -join ' '
  ```
  Toggle Night Light off/on between runs and diff. The flag byte is the one that changes. Update `NL_FLAG_OFFSET` in `lib\nightlight.ahk` if it's no longer 18.

## Uninstall

```powershell
iwr -useb https://raw.githubusercontent.com/r00bertos1/lenovo-backlight-controller/main/uninstall.ps1 | iex
```

This removes the install dir and Task Scheduler entry. AutoHotkey runtime is left alone (it may be shared with other tools — remove via `winget uninstall AutoHotkey.AutoHotkey` if you want it gone too).

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for how to add device support or improve the code.

## Credits

- Initial reverse-engineering of `DriversConfig.json` device patterns: [SaltwaterC/KeyboardBacklightForLenovo](https://github.com/SaltwaterC/KeyboardBacklightForLenovo).
- IBMPmDrv IOCTL research: ThinkPad community over many years.

## License

MIT — see [LICENSE](LICENSE).
