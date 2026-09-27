# ============================================================================
#  scripts\sync-time.ps1 - Dual-Boot Clock Fix & Automatic Time Sync
#
#  Windows and Linux disagree about the hardware clock (RTC):
#    - Linux stores UTC in the RTC
#    - Windows stores local time in the RTC
#  So every time you boot back from Linux, Windows shows the wrong time.
#
#  This script:
#    1. Tells Windows the RTC is UTC (RealTimeIsUniversal = 1)
#    2. Ensures the Windows Time service is running and set to Automatic
#    3. Points it at a reliable NTP server (time.windows.com)
#    4. Resyncs the clock immediately
#    5. Registers a logon task so the clock resyncs every time Windows starts
#
#  Usage:
#    .\sync-time.ps1              # apply fix + resync + register logon task
#    .\sync-time.ps1 -Mode Sync   # just resync the clock now
#    .\sync-time.ps1 -Mode Remove # remove the logon auto-sync task
# ============================================================================
param(
    [ValidateSet("Setup", "Sync", "Remove")]
    [string]$Mode = "Setup"
)

. "$PSScriptRoot\..\libs\tui\tui.ps1"
$ErrorActionPreference = "Continue"

$taskName = "SyncSystemTime"

# ----------------------------------------------------------------------------
# Resync helpers
# ----------------------------------------------------------------------------
function Invoke-ClockResync {
    Write-TuiInfo "Ensuring Windows Time service is running..."
    Set-Service -Name w32time -StartupType Automatic -ErrorAction SilentlyContinue
    Start-Service -Name w32time -ErrorAction SilentlyContinue

    Write-TuiInfo "Forcing an immediate time resync..."
    $out = & w32tm.exe /resync /force 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-TuiOk "System clock resynchronized successfully"
    } else {
        Write-TuiWarn "Time resync failed (are you online?)"
        if ($out) { $out | ForEach-Object { Write-TuiDim "  $_" } }
    }
}

function Register-TimeSyncTask {
    $taskScript = (Resolve-Path "$PSScriptRoot\sync-time.ps1").Path
    $taskCmd = "powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$taskScript`" -Mode Sync"

    Write-Host "${script:C_DIM}  Task Name: ${script:C_WHITE}$taskName${script:C_RESET}"
    Write-Host "${script:C_DIM}  Command:   ${script:C_DIM}$taskCmd${script:C_RESET}"
    Write-Host ""

    schtasks.exe /Delete /TN "$taskName" /F 2>$null | Out-Null
    schtasks.exe /Create /SC ONLOGON /RL HIGHEST /TN "$taskName" /TR "$taskCmd" /F 2>$null | Out-Null

    if ($LASTEXITCODE -eq 0) {
        Write-TuiOk "Logon task '$taskName' created successfully"
        Write-TuiDim "  The clock will resync every time Windows starts."
    } else {
        Write-TuiErr "Failed to create scheduled task '$taskName'"
    }
}

function Unregister-TimeSyncTask {
    schtasks.exe /Query /TN "$taskName" 2>$null | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Write-TuiWarn "Time sync task '$taskName' is not registered (already disabled)."
        return
    }

    schtasks.exe /Delete /TN "$taskName" /F 2>$null | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-TuiOk "Time sync task '$taskName' removed successfully"
        Write-TuiDim "  The clock will no longer auto-resync at logon."
    } else {
        Write-TuiErr "Failed to remove scheduled task '$taskName'"
    }
}

# ==========================================================================
# All modes write to the registry / use w32tm and need administrator rights
# ==========================================================================
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-TuiWarn "Administrator privileges required to synchronize the system clock."
    Write-TuiInfo "Requesting UAC elevation..."
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`" -Mode $Mode" -Verb RunAs
    return
}

$normalized = $Mode.ToLower()

if ($normalized -eq "remove") {
    Write-TuiHeader "System Time -- Disable Auto Sync"
    Write-TuiDim "  Removes the logon task that resyncs the clock on startup."
    Write-Host ""
    Unregister-TimeSyncTask
    exit 0
}

if ($normalized -eq "sync") {
    Write-TuiHeader "System Time -- Syncing"
    Invoke-ClockResync
    exit 0
}

# ==========================================================================
# SETUP: fix RTC interpretation + configure NTP + resync + register logon task
# ==========================================================================
Write-TuiHeader "System Time -- Dual-Boot Fix"
Write-TuiDim "  Configures Windows to store UTC in the hardware clock and resyncs at logon."
Write-Host ""

Write-TuiSection "Hardware Clock (RTC)"
$tzPath = "HKLM:\SYSTEM\CurrentControlSet\Control\TimeZoneInformation"
$existing = (Get-ItemProperty -Path $tzPath -Name "RealTimeIsUniversal" -ErrorAction SilentlyContinue).RealTimeIsUniversal
if ($existing -eq 1) {
    Write-TuiOk "RTC already treated as UTC (RealTimeIsUniversal = 1)"
} else {
    New-ItemProperty -Path $tzPath -Name "RealTimeIsUniversal" -Value 1 -PropertyType DWord -Force -ErrorAction SilentlyContinue | Out-Null
    if ((Get-ItemProperty -Path $tzPath -Name "RealTimeIsUniversal" -ErrorAction SilentlyContinue).RealTimeIsUniversal -eq 1) {
        Write-TuiOk "Windows now treats the hardware clock as UTC (matches Linux)"
    } else {
        Write-TuiErr "Failed to set RealTimeIsUniversal"
    }
}

Write-TuiSection "NTP Configuration"
Write-TuiInfo "Pointing Windows Time at time.windows.com..."
& w32tm.exe /config /manualpeerlist:"time.windows.com,0x8" /syncfromflags:manual /reliable:yes /update 2>&1 | Out-Null
if ($LASTEXITCODE -eq 0) {
    Write-TuiOk "NTP configuration applied"
} else {
    Write-TuiWarn "NTP configuration returned a non-zero status"
}
Restart-Service -Name w32time -ErrorAction SilentlyContinue

Write-TuiSection "Immediate Resync"
Invoke-ClockResync

Write-TuiSection "Automatic Sync at Logon"
Register-TimeSyncTask
