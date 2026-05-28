; lib/driver.ahk - Lenovo backlight driver wrappers (IBMPmDrv / EnergyDrv).
; Uses documented Win32 API: CreateFileW + DeviceIoControl + CloseHandle.

#Requires AutoHotkey v2.0

GENERIC_READ_WRITE := 0xC0000000
OPEN_EXISTING      := 3
INVALID_HANDLE     := -1

; Open a device handle. Returns handle (int) or -1 on failure.
OpenDevice(principal) {
    return DllCall("kernel32\CreateFileW",
                   "Str", principal,
                   "UInt", 0xC0000000,    ; GENERIC_READ | GENERIC_WRITE
                   "UInt", 0,             ; no sharing
                   "Ptr", 0,              ; no security
                   "UInt", 3,             ; OPEN_EXISTING
                   "UInt", 0,             ; no flags
                   "Ptr", 0,              ; no template
                   "Ptr")
}

; Close a device handle.
CloseDevice(handle) {
    DllCall("kernel32\CloseHandle", "Ptr", handle)
}

; Send a GET IOCTL. Returns 32-bit response or -1 on failure.
; inValue is optional 4-byte input (used by EnergyDrv 'getIn').
IoctlGet(handle, ioctl, inValue := 0) {
    inBuf := Buffer(4, 0)
    if (inValue != 0)
        NumPut("UInt", inValue, inBuf, 0)
    outBuf := Buffer(4, 0)
    bytesReturned := 0
    inLen := (inValue != 0) ? 4 : 0
    ok := DllCall("kernel32\DeviceIoControl",
                  "Ptr", handle,
                  "UInt", ioctl,
                  "Ptr", inBuf, "UInt", inLen,
                  "Ptr", outBuf, "UInt", 4,
                  "UInt*", &bytesReturned,
                  "Ptr", 0)
    if (!ok)
        return -1
    return NumGet(outBuf, 0, "UInt")
}

; Send a SET IOCTL. Returns true on success, false on failure.
IoctlSet(handle, ioctl, value) {
    inBuf := Buffer(4, 0)
    NumPut("UInt", value, inBuf, 0)
    outBuf := Buffer(4, 0)
    bytesReturned := 0
    ok := DllCall("kernel32\DeviceIoControl",
                  "Ptr", handle,
                  "UInt", ioctl,
                  "Ptr", inBuf, "UInt", 4,
                  "Ptr", outBuf, "UInt", 4,
                  "UInt*", &bytesReturned,
                  "Ptr", 0)
    return ok ? true : false
}

; Parse a hex string like "0x00222680" into an integer.
ParseHex(s) {
    return Integer(s)
}

; Iterate DEVICES global, try each entry's principal + getIoctl.
; Returns the first matching device Map, or empty Map on no match.
DetectDevice(devices) {
    for d in devices {
        h := OpenDevice(d["principal"])
        if (h = -1)
            continue
        getIn := d.Has("getIn") ? ParseHex(d["getIn"]) : 0
        resp := IoctlGet(h, ParseHex(d["getIoctl"]), getIn)
        CloseDevice(h)
        if (resp = -1)
            continue
        respHex := Format("0x{:08X}", resp)
        if (respHex = StrUpper(d["getOff"]) ||
            respHex = StrUpper(d["getLow"]) ||
            respHex = StrUpper(d["getHigh"]))
            return d
    }
    return Map()
}
