# Architecture deep-dive

This document explains how the controller talks to the hardware and reads OS state. Useful for contributors who want to debug device-specific issues or port to new hardware families.

## Driver layer (`lib/driver.ahk`)

Lenovo laptops ship with one of two kernel drivers for keyboard backlight control:

- **IBMPmDrv** — used by ThinkPad models. Exposed as `\\.\IBMPmDrv`.
- **EnergyDrv** — used by ThinkBook and IdeaPad models. Exposed as `\\.\EnergyDrv`.

Both are accessed via standard Win32 file I/O + `DeviceIoControl`:

1. `CreateFileW("\\.\IBMPmDrv", GENERIC_READ|GENERIC_WRITE, 0, NULL, OPEN_EXISTING, 0, NULL)` returns a kernel handle.
2. `DeviceIoControl(handle, IOCTL_CODE, inBuf, inLen, outBuf, outLen, &returned, NULL)` sends a single 32-bit request and reads a 32-bit response.
3. `CloseHandle(handle)` releases it.

### GET response format

The GET IOCTL returns a 32-bit value that encodes the current backlight level somewhere in its bits. The encoding differs per firmware family and even per ThinkPad generation.

Example responses on ThinkPad T16 Gen 2 (IBMPmDrv):
- Backlight OFF: `0x00250200`
- Backlight LOW: `0x00250201`
- Backlight HIGH: `0x00250202`

The level is the lowest byte (`00`/`01`/`02`). The upper 24 bits (`0x002502`) appear to encode firmware version / capability flags. Older ThinkPads (e.g. X1 Carbon Gen 6) report `0x000502XX` — same lowest byte, different upper bits.

ThinkBook/IdeaPad (EnergyDrv) uses a completely different encoding (`0x00000001`/`0x00000003`/`0x00000005` for off/low/high in v1 firmware). EnergyDrv also requires an input value (`getIn = 0x32`) which acts as a "subcommand" — without it, the IOCTL returns nothing.

### SET payload format

The SET IOCTL writes a 32-bit value. Encoding:

- **IBMPmDrv**: `0x00` = off, `0x01` = low, `0x02` = high. Same across all known firmware versions.
- **EnergyDrv**: `0x00000033` = off, `0x00010033` = low, `0x00020033` = high. The `0x33` suffix is the "set backlight" subcommand, the upper 16 bits encode the level.

These are documented in `devices.json` per entry — the controller just iterates and matches without knowing the family semantics.

### Device detection

`DetectDevice(devices)` iterates through `DEVICES` (loaded from `devices.json` via `devices.ahk`). For each entry:

1. Try `OpenDevice(entry.principal)`. If the driver isn't installed, this fails — skip to the next entry.
2. Call `IoctlGet(handle, entry.getIoctl, entry.getIn)`. Get a 32-bit response.
3. Compare response (formatted as `0xXXXXXXXX`) against `entry.getOff`/`entry.getLow`/`entry.getHigh`.
4. If any match, return that entry as the detected device.

This means entries are tried in `devices.json` order. T16 Gen 2 is listed first because that's the maintainer's hardware; for production use, ordering doesn't matter (mismatched entries fail the GET match and the loop continues).

## Night Light layer (`lib/nightlight.ahk`)

Windows stores the active state of Night Light in the registry:

- Key: `HKCU\Software\Microsoft\Windows\CurrentVersion\CloudStore\Store\Cache\DefaultAccount\$$windows.data.bluelightreduction.bluelightreductionstate\Current`
- Value: `Data` (REG_BINARY, ~43 bytes)

The blob has a header, a timestamp, and a state flag. **The exact layout is undocumented** and can change between Windows builds. As of Windows 11 24H2 (build 10.0.26100), the state flag is at byte 18 (zero-indexed):

- `0x10` (16) — Night Light is currently OFF (scheduled but not active, or disabled entirely).
- `0x12` or `0x13` — Night Light is currently ON. Bit `0x02` is the "active" flag.

The controller reads the blob via `RegRead`, extracts byte 18, masks with `0x02`. If the registry key is missing or shorter than expected, it returns `false` — safe default (don't activate backlight without confidence).

If Microsoft changes the layout in a future Windows update, `NL_FLAG_OFFSET` in `lib/nightlight.ahk` needs updating. The README documents how to diagnose via a registry dump.

## State machine (`controller.ahk`)

The control loop runs every 1 second (1000 ms `SetTimer`):

```
state: currentLevel ∈ {"off", "high"}        (init: "off")
state: wasIdle      ∈ {true, false}           (init: true)

each tick:
    idle    = A_TimeIdleKeyboard
    nowIdle = (idle >= IdleMs)

    if currentLevel == "off":
        if (!nowIdle && wasIdle && IsNight()):
            SetLevel(ActiveLevel)
            currentLevel = "high"
    else: # currentLevel == "high"
        if nowIdle:
            SetLevel("off")
            currentLevel = "off"

    wasIdle = nowIdle
```

Key design choices:

- **Edge-triggered Night Light check**: `IsNight()` is called only on idle→active transitions (`!nowIdle && wasIdle`), not every tick. This means at most one registry read per "typing session" — typically 1-2 per minute of active use, never during idle or sustained typing.
- **`A_TimeIdleKeyboard`**: built-in AHK v2 readout that excludes mouse movement. The controller responds only to keyboard input by design.
- **Idempotent `SetLevel`**: the `currentLevel` guard means the controller doesn't spam IOCTLs. Each transition writes once.
- **No retry/backoff on IOCTL failure**: if `IoctlSet` fails (driver unloaded, etc.), the next tick's state check will retry. Failure is rare and self-healing.

### Hardware hotkey desync (`Fn+Space`)

Pressing `Fn+Space` (Lenovo's hardware backlight toggle) sends a command directly to the EC/firmware, bypassing the controller. The controller's `currentLevel` is now out of sync with reality. This is **accepted behavior**:

- If user pressed `Fn+Space` while the controller thought level was "off", but it's now physically "on": next idle timeout (15s without typing) → controller writes SET=off → backlight physically goes off. Synced.
- If user pressed `Fn+Space` while the controller thought "high", but it's now physically "off": next typing → controller writes SET=high → backlight physically on. Synced.

Worst case: brief desync, never longer than one idle/active cycle. Polling the GET register every tick would eliminate this, but at the cost of an IOCTL per second forever. Trade-off rejected.
