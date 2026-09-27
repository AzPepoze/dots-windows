# ============================================================================
#  scripts\startup.ps1 - Startup Task Runner & Logon Scheduler
#
#  Usage:
#    .\startup.ps1 -Mode Run       # Launch all items in startup\
#    .\startup.ps1 -Mode Enable    # Register Windows Logon Scheduled Task
#    .\startup.ps1 -Mode Disable   # Remove the Logon Scheduled Task
#    .\startup.ps1 -Mode Status    # Print whether the Logon Task is registered
#    .\startup.ps1 -Mode Setup     # Alias for Enable (kept for compatibility)
# ============================================================================
param(
    [ValidateSet("Run", "Enable", "Disable", "Status", "Setup")]
    [string]$Mode = "Run"
)

. "$PSScriptRoot\..\libs\tui\tui.ps1"
$ErrorActionPreference = "Continue"

$startupDir = (Resolve-Path "$PSScriptRoot\..\startup").Path
$taskName   = "RunStartupFolder"

# ----------------------------------------------------------------------------
# Task helpers
# ----------------------------------------------------------------------------
function Test-StartupTask {
    schtasks.exe /Query /TN "$taskName" 2>$null | Out-Null
    return ($LASTEXITCODE -eq 0)
}

function Register-StartupTask {
    $taskScript = (Resolve-Path "$PSScriptRoot\startup.ps1").Path
    $taskCmd = "powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$taskScript`" -Mode Run"

    Write-Host "${script:C_DIM}  Task Name: ${script:C_WHITE}$taskName${script:C_RESET}"
    Write-Host "${script:C_DIM}  Command:   ${script:C_DIM}$taskCmd${script:C_RESET}"
    Write-Host ""

    schtasks.exe /Delete /TN "$taskName" /F 2>$null | Out-Null
    schtasks.exe /Create /SC ONLOGON /TN "$taskName" /TR "$taskCmd" /F 2>$null | Out-Null

    if ($LASTEXITCODE -eq 0) {
        Write-TuiOk "Logon task '$taskName' created successfully"
        Write-TuiDim "  It will automatically run your startup tasks whenever you log in."
    } else {
        Write-TuiErr "Failed to create scheduled task '$taskName'"
    }
}

function Unregister-StartupTask {
    if (-not (Test-StartupTask)) {
        Write-TuiWarn "Logon task '$taskName' is not registered (already disabled)."
        return
    }

    schtasks.exe /Delete /TN "$taskName" /F 2>$null | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-TuiOk "Logon task '$taskName' removed successfully"
        Write-TuiDim "  startup\ will no longer run automatically at logon."
    } else {
        Write-TuiErr "Failed to remove scheduled task '$taskName'"
    }
}

# ----------------------------------------------------------------------------
# Dispatch
# ----------------------------------------------------------------------------
$normalized = $Mode.ToLower()

if ($normalized -eq "status") {
    if (Test-StartupTask) { Write-TuiOk "Startup at logon is ENABLED" } else { Write-TuiWarn "Startup at logon is DISABLED" }
    exit 0
}

if ($normalized -eq "run") {
    # ==========================================================================
    # RUN MODE: Launch scripts and shortcuts in startup folder
    # ==========================================================================
    Write-TuiHeader "Startup -- Launching Tasks"
    Write-TuiDim "  Running all tasks in startup\ ..."
    Write-Host ""

    if (-not (Test-Path $startupDir)) {
        Write-TuiErr "Startup folder not found at '$startupDir'"
        exit 1
    }

    Write-TuiOk "Found startup folder"
    Write-TuiSeparator

    Write-TuiInfo "Terminating existing AutoHotkey processes..."
    taskkill /F /IM AutoHotkey*.exe 2>$null | Out-Null
    Start-Sleep -Milliseconds 500

    $tasks = Get-ChildItem -Path $startupDir | Where-Object { $_.Extension -match '\.(ahk|lnk)$' }

    if (-not $tasks -or $tasks.Count -eq 0) {
        Write-TuiWarn "No .ahk or .lnk files found in '$startupDir'"
    } else {
        foreach ($t in $tasks) {
            Write-TuiInfo "$($t.Name) --> launching"
            Start-Process -FilePath $t.FullName -WorkingDirectory $startupDir
            Start-Sleep -Milliseconds 250
        }
    }

    Write-TuiSeparator
    Write-TuiOk "All startup tasks launched"
    exit 0
}

# ==========================================================================
# ENABLE / DISABLE / SETUP: Manage the Logon Scheduled Task (needs admin)
# ==========================================================================
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-TuiWarn "Administrator privileges required to modify the logon task."
    Write-TuiInfo "Requesting UAC elevation..."
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`" -Mode $Mode" -Verb RunAs
    return
}

if ($normalized -eq "disable") {
    Write-TuiHeader "Startup -- Disable"
    Write-TuiDim "  Removes the Windows Scheduled Task that runs startup\ at logon."
    Write-Host ""
    Unregister-StartupTask
} else {
    Write-TuiHeader "Startup -- Enable"
    Write-TuiDim "  Configures a Windows Scheduled Task to run startup\ at logon."
    Write-Host ""
    Register-StartupTask
}
