---
name: Bug report
about: Something doesn't behave the way the README describes
labels: bug
---

**Hardware**
- Lenovo model:
- Windows build (run `[System.Environment]::OSVersion.Version` in PowerShell):

**What's happening**
<short description of the actual behavior>

**What you expected**
<short description of the expected behavior>

**Diagnostic output**

Paste the output of the following block (run in a non-elevated PowerShell):

```powershell
# Is the controller running?
Get-CimInstance Win32_Process -Filter "Name = 'AutoHotkey64.exe'" |
    Select-Object ProcessId, CommandLine

# Is the scheduled task registered?
Get-ScheduledTask -TaskName LenovoBacklightController -ErrorAction SilentlyContinue |
    Format-List TaskName, State, Actions

# Is Night Light enabled (and what does its registry blob look like)?
$p = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\CloudStore\Store\DefaultAccount\Current\default$windows.data.bluelightreduction.bluelightreductionstate\windows.data.bluelightreduction.bluelightreductionstate'
(Get-ItemProperty -Path $p -Name Data -ErrorAction SilentlyContinue).Data -join ' '
```
