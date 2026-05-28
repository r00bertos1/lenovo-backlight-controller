; lib/nightlight.ahk - Read Windows Night Light state from registry.
; Best-effort: the blob layout is undocumented and can change in
; any Windows update. On any parse/read error, returns false
; (safe default: don't activate backlight without confidence).
;
; Verified empirically on Windows 11 Pro 10.0.26200 (2026-05).
;
; Layout discovery on this build:
;   - Key:   HKCU\...\CloudStore\Store\DefaultAccount\Current\
;            default$windows.data.bluelightreduction.bluelightreductionstate\
;            windows.data.bluelightreduction.bluelightreductionstate
;            (nested two-level: parent + same-named child)
;   - Value: "Data" (REG_BINARY)
;   - When ON,  blob is ~43 bytes and contains a "10 00" sub-section at
;     offset 23 (a second copy of the "43 42 01 00" header at offset 19
;     is immediately followed by "10 00"; that "10" is the marker).
;   - When OFF, blob is ~41 bytes and byte 23 holds an unrelated value
;     (commonly 0xD0).
;
; If a future Windows build moves the marker, see the README
; troubleshooting section for the registry dump procedure.

#Requires AutoHotkey v2.0

NL_ON_OFFSET := 23
NL_ON_BYTE   := 0x10

; Returns true if Windows Night Light is currently active (on).
; Returns false if Night Light is off, the key/blob can't be read,
; or the format is unrecognized.
IsNight() {
    static regPath := "HKCU\Software\Microsoft\Windows\CurrentVersion\CloudStore\Store\DefaultAccount\Current\default$windows.data.bluelightreduction.bluelightreductionstate\windows.data.bluelightreduction.bluelightreductionstate"

    try {
        ; AHK v2 RegRead on a REG_BINARY value returns the bytes as a
        ; hex string (2 hex chars per byte, uppercase).
        raw := RegRead(regPath, "Data")
    } catch {
        return false   ; key missing (never-enabled NL) or no permission
    }

    if (StrLen(raw) < (NL_ON_OFFSET + 1) * 2)
        return false   ; blob too short

    byteHex := SubStr(raw, NL_ON_OFFSET * 2 + 1, 2)
    byteVal := Integer("0x" . byteHex)

    return (byteVal = NL_ON_BYTE)
}
