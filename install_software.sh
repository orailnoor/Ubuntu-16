
---

**auto-start.ps1**
```powershell
<# 
Creates/updates a Scheduled Task that, at user logon:
  1) (optional) runs ADB port-forward:  tcp:5901 -> tcp:5901
  2) launches your VNC viewer to connect to localhost:5901

Edit the paths below as needed, then run:
  - Right-click PowerShell ➜ "Run as administrator"
  - Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
  - .\auto-start.ps1
#>

param(
  [string]$TaskName = "Android16 GNOME Auto Connect",
  [string]$VncViewerPath = "C:\Program Files\RealVNC\VNC Viewer\vncviewer.exe",
  [string]$VncTarget = "localhost:5901",
  [switch]$UseAdb = $true,
  [string]$AdbPath = "C:\Android\platform-tools\adb.exe"
)

# Build action list
$actions = @()

if ($UseAdb -and (Test-Path $AdbPath)) {
  $actions += New-ScheduledTaskAction -Execute $AdbPath -Argument "forward tcp:5901 tcp:5901"
}

if (Test-Path $VncViewerPath) {
  $actions += New-ScheduledTaskAction -Execute $VncViewerPath -Argument $VncTarget
} else {
  Write-Warning "VNC Viewer not found at $VncViewerPath. Edit the script to point to your viewer."
}

if ($actions.Count -eq 0) {
  Write-Error "No valid actions found. Adjust paths and re-run."
  exit 1
}

# Trigger at logon for current user
$principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -RunLevel LeastPrivilege
$trigger   = New-ScheduledTaskTrigger -AtLogOn

# Register or update
try {
  if (Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue) {
    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
  }
  $task = New-ScheduledTask -Action $actions -Trigger $trigger -Principal $principal
  Register-ScheduledTask -TaskName $TaskName -InputObject $task | Out-Null
  Write-Host "Scheduled Task '$TaskName' created."
} catch {
  Write-Error $_.Exception.Message
  exit 1
}
