# Contributing to lenovo-backlight-controller

Thanks for considering a contribution. The most common contribution is **adding support for a new Lenovo device**. It takes 5 minutes and one file change.

## Adding device support

1. Make sure the controller is installed (`iwr | iex` one-liner from README).
2. Open a terminal in the install dir:
   ```powershell
   cd $env:LOCALAPPDATA\lenovo-backlight-controller
   ```
3. Run the detection tool:
   ```powershell
   & 'C:\Users\<you>\AppData\Local\Programs\AutoHotkey\v2\AutoHotkey64.exe' tools\detect-device.ahk
   ```
4. Follow the prompts. The tool will:
   - Detect whether your device uses IBMPmDrv (ThinkPad family) or EnergyDrv (ThinkBook/IdeaPad family).
   - Cycle the backlight off → low → high and record the firmware's GET response for each level.
   - Show you a JSON entry ready to add to `devices.json`.
   - Optionally append it to your local `devices.json` so the controller picks it up immediately.
5. Open a pull request adding that same entry to the canonical `devices.json` in this repo:
   ```bash
   # In your fork of the repo:
   # Edit devices.json, paste your entry into the "devices" array.
   git add devices.json
   git commit -m "Add support for <your model>"
   git push
   # Then open a PR on GitHub.
   ```

That's it. No code changes needed for new devices — the data lives in `devices.json` and the controller iterates through all entries to find a match.

## devices.json schema

Each entry is a flat object:

```json
{
  "name": "ThinkPad X1 Carbon Gen 11",
  "principal": "\\\\.\\IBMPmDrv",
  "getIoctl": "0x00222680",
  "getIn":    "0x00000032",
  "getOff":   "0x00050200",
  "getLow":   "0x00050201",
  "getHigh":  "0x00050202",
  "setIoctl": "0x00222684",
  "setOff":   "0x00000000",
  "setLow":   "0x00000001",
  "setHigh":  "0x00000002",
  "credits":  "detected by your-username on 2026-05-25"
}
```

Field reference:
- `name` — human-readable identifier.
- `principal` — driver path, backslashes escaped per JSON (`\\\\.\\IBMPmDrv` → literal `\\.\IBMPmDrv`).
- `getIoctl` — IOCTL for reading current level.
- `getIn` — OPTIONAL: input value for GET (EnergyDrv only).
- `getOff` / `getLow` / `getHigh` — expected GET response for each level.
- `setIoctl` — IOCTL for setting level.
- `setOff` / `setLow` / `setHigh` — SET payload to write for each level.
- `credits` — attribution.

All hex values are strings. The controller parses them at startup.

## Code changes

For larger contributions (bug fixes, new features), follow these conventions:

- **AHK code**: AutoHotkey v2.0 only. No global mutable state outside `controller.ahk`'s explicit `global` declarations. Library files (`lib/*.ahk`) export pure functions only.
- **PowerShell**: target PS 5.0+ (Windows 10/11 stock). No external modules. Use `$ErrorActionPreference = 'Stop'` in scripts. Validate JSON via `ConvertFrom-Json`.
- **Commit messages**: short imperative first line ("Add X" / "Fix Y" / "Refactor Z"), wrap at 72 chars. Detailed body if needed.

### Local development

After cloning, set up a dev install pointed at your working copy:

```powershell
# Clone, then from the repo dir:
$dev = "$env:LOCALAPPDATA\lenovo-backlight-controller-dev"
New-Item -ItemType SymbolicLink -Path $dev -Target $pwd
# Now edit files in the repo, run controller from the dev dir.
```

Or just run files directly:

```powershell
& 'C:\Users\<you>\AppData\Local\Programs\AutoHotkey\v2\AutoHotkey64.exe' controller.ahk
```

(You'll need to regenerate `devices.ahk` after editing `devices.json` — re-run `install.ps1` or copy its generation block manually.)

## Testing

There's no automated test framework — the controller is small and AHK testing tools are limited. Manual smoke tests per change:

1. `Set-Content` a sample `devices.json` with a known-good entry.
2. Run `install.ps1` against a clean state.
3. Run the 4 smoke test scenarios from the README "How it works" section.
4. Run `uninstall.ps1`, verify clean removal.

## Questions

Open an issue. Bug reports welcome, especially with registry-dump-style data that helps diagnose Night Light parsing issues on different Windows builds.
