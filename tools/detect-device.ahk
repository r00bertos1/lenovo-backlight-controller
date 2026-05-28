; tools/detect-device.ahk
; Interactive Lenovo backlight device detection.
; - Tries IBMPmDrv, then EnergyDrv.
; - Cycles SET off/low/high, records GET response for each.
; - Generates a devices.json entry and optionally appends to the local file.

#Requires AutoHotkey v2.0
#Include ..\lib\driver.ahk

; Family defaults (standard IBMPmDrv / EnergyDrv IOCTL constants).
FAMILIES := [
    Map(
        "principal", "\\.\IBMPmDrv",
        "label", "ThinkPad (IBMPmDrv)",
        "getIoctl", 0x00222680,
        "setIoctl", 0x00222684,
        "setOff",   0x00000000,
        "setLow",   0x00000001,
        "setHigh",  0x00000002,
        "getIn",    0
    ),
    Map(
        "principal", "\\.\EnergyDrv",
        "label", "ThinkBook/IdeaPad (EnergyDrv)",
        "getIoctl", 0x83102144,
        "setIoctl", 0x83102144,
        "setOff",   0x00000033,
        "setLow",   0x00010033,
        "setHigh",  0x00020033,
        "getIn",    0x00000032
    )
]

result := MsgBox("Lenovo backlight device detector.`n`nMake sure no other backlight controller is running.`nClick OK to start.", "detect-device", 1)
if (result = "Cancel")
    ExitApp 0

; Try each family.
matched := Map()
for f in FAMILIES {
    h := OpenDevice(f["principal"])
    if (h = -1)
        continue
    matched := f
    matched["handle"] := h
    break
}

if (matched.Count = 0) {
    MsgBox "No Lenovo backlight driver found.`n`nTried: \\.\IBMPmDrv and \\.\EnergyDrv. This tool requires a Lenovo laptop with one of those drivers."
    ExitApp 1
}

MsgBox "Found driver: " . matched["label"] . "`n`nNow cycling SET off/low/high and reading GET each time. Watch the keyboard.`n`nClick OK to start cycle."

; Backup current GET state (best-effort restore).
originalGet := IoctlGet(matched["handle"], matched["getIoctl"], matched["getIn"])

; Cycle off / low / high, record GET response.
patterns := Map()
for level in ["Off", "Low", "High"] {
    IoctlSet(matched["handle"], matched["setIoctl"], matched["set" . level])
    Sleep 500
    resp := IoctlGet(matched["handle"], matched["getIoctl"], matched["getIn"])
    patterns["get" . level] := Format("0x{:08X}", resp)
}

; Restore (best-effort: write 'off' since we don't know what originalGet meant).
IoctlSet(matched["handle"], matched["setIoctl"], matched["setOff"])
CloseDevice(matched["handle"])

; Build JSON entry.
; WMIC was removed by default starting with Windows 11 25H2 (build 26200),
; so go through PowerShell + CIM for a future-proof readout.
modelName := ""
try {
    modelName := Trim(RunCommand('powershell -NoProfile -Command "(Get-CimInstance Win32_ComputerSystem).Model"'))
}
if (modelName = "")
    modelName := matched["label"] . " (unknown model)"

entry := "    {`n"
entry .= "      `"name`": `"" . modelName . "`",`n"
entry .= "      `"principal`": `"" . StrReplace(matched["principal"], "\", "\\") . "`",`n"
entry .= "      `"getIoctl`": `"" . Format("0x{:08X}", matched["getIoctl"]) . "`",`n"
if (matched["getIn"] != 0)
    entry .= "      `"getIn`": `"" . Format("0x{:08X}", matched["getIn"]) . "`",`n"
entry .= "      `"getOff`": `"" . patterns["getOff"] . "`",`n"
entry .= "      `"getLow`": `"" . patterns["getLow"] . "`",`n"
entry .= "      `"getHigh`": `"" . patterns["getHigh"] . "`",`n"
entry .= "      `"setIoctl`": `"" . Format("0x{:08X}", matched["setIoctl"]) . "`",`n"
entry .= "      `"setOff`": `"" . Format("0x{:08X}", matched["setOff"]) . "`",`n"
entry .= "      `"setLow`": `"" . Format("0x{:08X}", matched["setLow"]) . "`",`n"
entry .= "      `"setHigh`": `"" . Format("0x{:08X}", matched["setHigh"]) . "`",`n"
entry .= "      `"credits`": `"detected by " . A_UserName . " on " . FormatTime(, "yyyy-MM-dd") . "`"`n"
entry .= "    }"

; Show entry, ask to auto-add.
ans := MsgBox("Detected device entry:`n`n" . entry . "`n`nAdd to local devices.json and use it now?", "detect-device", 4)
if (ans = "Yes") {
    AppendToDevicesJson(entry)
    MsgBox "Added to devices.json.`n`nRe-run install.ps1 (or manually regenerate devices.ahk) for the controller to pick it up."
}

MsgBox "Done!`n`nPlease share this entry by opening a PR:`nhttps://github.com/r00bertos1/lenovo-backlight-controller/pulls`n`nSee CONTRIBUTING.md for instructions."
ExitApp 0

; --- Helpers ---------------------------------------------------------------
RunCommand(cmd) {
    tmp := A_Temp . "\detect-device-" . A_TickCount . ".txt"
    RunWait('cmd.exe /c "' . cmd . ' > "' . tmp . '" 2>&1"', , "Hide")
    out := FileRead(tmp)
    FileDelete(tmp)
    return out
}

AppendToDevicesJson(entryText) {
    path := A_ScriptDir . "\..\devices.json"
    contents := FileRead(path)
    ; Find the closing ] of the devices array and inject our entry before it.
    ; Naive but works for our shape: find the last "]" before the file-end "}".
    pos := InStr(contents, "]", false, , -1)
    if (pos = 0)
        throw Error("devices.json: cannot find closing array bracket")
    head := SubStr(contents, 1, pos - 1)
    tail := SubStr(contents, pos)
    ; Trim trailing whitespace from head, then add comma + newline + entry.
    head := RTrim(head, " `t`r`n")
    newContents := head . ",`n" . entryText . "`n  " . tail
    FileMove(path, path . ".bak", 1)
    FileAppend(newContents, path)
}
