---
name: Device support request
about: Your Lenovo laptop isn't detected
labels: device-support
---

**Hardware**
- Lenovo model:
- Windows build:

**`tools\detect-device.ahk` output**

Run `tools\detect-device.ahk` from the install dir (`%LOCALAPPDATA%\lenovo-backlight-controller\`) and paste the JSON entry it generates here:

```json

```

If the tool reports "No Lenovo backlight driver found", check Device Manager → System devices for entries containing `IBMPmDrv` or `EnergyDrv` and let us know which (if any) is present.

**Tested**
- [ ] Backlight physically cycles off → low → high during detection.
- [ ] Re-running `install.ps1` after adding the JSON entry makes the controller pick it up.
