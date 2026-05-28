#Requires AutoHotkey v2.0
#SingleInstance Force

; ============================================================
; controller.ahk
; Auto keyboard backlight controller for Lenovo laptops.
;
; - turn on at first keypress after >= IdleMs of inactivity
; - turn off after IdleMs of keyboard inactivity
; - only act when Windows Night Light is active
; ============================================================

#Include lib/driver.ahk
#Include lib/nightlight.ahk
#Include devices.ahk

; --- Configuration ---------------------------------------------------------
IdleMs       := 15000
ActiveLevel  := "high"   ; "high" or "low"

; --- Device detection ------------------------------------------------------
device := DetectDevice(DEVICES)
if (device.Count = 0) {
    MsgBox "No supported Lenovo backlight device detected.`n`nRun tools\detect-device.ahk to add your device, then rerun the installer."
    ExitApp 1
}

handle := OpenDevice(device["principal"])
if (handle = -1) {
    MsgBox "Failed to open device " . device["principal"] . ".`n`nThe driver may not be loaded or another process holds an exclusive handle."
    ExitApp 1
}

setIoctl    := ParseHex(device["setIoctl"])
setOffValue := ParseHex(device["setOff"])
setOnValue  := ParseHex(device["set" . (ActiveLevel = "high" ? "High" : "Low")])

; --- State -----------------------------------------------------------------
global currentLevel := "off"
global wasIdle      := true   ; first keypress = idle->active edge

; --- Main loop -------------------------------------------------------------
; AHK v2 scoping note: functions must explicitly declare every global
; they read or write (the language is strict about this in v2).
Tick(*) {
    global currentLevel, wasIdle
    global IdleMs, ActiveLevel, handle, setIoctl, setOffValue, setOnValue
    idle := A_TimeIdleKeyboard
    nowIdle := (idle >= IdleMs)

    if (currentLevel = "off") {
        if (!nowIdle && wasIdle && IsNight()) {
            IoctlSet(handle, setIoctl, setOnValue)
            currentLevel := ActiveLevel
        }
    } else {
        if (nowIdle) {
            IoctlSet(handle, setIoctl, setOffValue)
            currentLevel := "off"
        }
    }

    wasIdle := nowIdle
}

SetTimer(Tick, 1000)

; Close the device handle on exit. Use a named function (not an arrow lambda)
; so the `global handle` declaration is unambiguous.
CleanupOnExit(*) {
    global handle
    CloseDevice(handle)
}
OnExit(CleanupOnExit)
