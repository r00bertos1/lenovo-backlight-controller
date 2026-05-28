# uninstall.ps1
# Removes the lenovo-backlight-controller installation.
# - Stops and unregisters the scheduled task.
# - Kills running controller.ahk AHK processes.
# - Deletes %LOCALAPPDATA%\lenovo-backlight-controller\.
# - Does NOT remove AutoHotkey runtime (may be shared).

$TaskName  = 'LenovoBacklightController'
$InstallDir = Join-Path $env:LOCALAPPDATA 'lenovo-backlight-controller'

Write-Host 'Uninstalling lenovo-backlight-controller...'

# Stop and unregister task.
$task = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
if ($task) {
    Stop-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
    Write-Host "  Unregistered task: $TaskName"
} else {
    Write-Host "  Task not found (already removed): $TaskName"
}

# Kill running controller processes. Process.Path is the AHK runtime; the
# script path lives in CommandLine, which requires CIM/WMI.
$procs = @(Get-CimInstance Win32_Process -Filter "Name = 'AutoHotkey64.exe'" |
    Where-Object { $_.CommandLine -like "*$InstallDir*" })
if ($procs.Count -gt 0) {
    foreach ($p in $procs) {
        Stop-Process -Id $p.ProcessId -Force -ErrorAction SilentlyContinue
    }
    Write-Host "  Killed $($procs.Count) controller process(es)."
}

# Remove install dir.
if (Test-Path $InstallDir) {
    Remove-Item -Recurse -Force $InstallDir
    Write-Host "  Removed: $InstallDir"
} else {
    Write-Host "  Install dir not found (already removed): $InstallDir"
}

Write-Host ''
Write-Host 'Uninstalled. AutoHotkey runtime not removed (may be shared with other tools).'
Write-Host 'To remove AutoHotkey: winget uninstall AutoHotkey.AutoHotkey'
