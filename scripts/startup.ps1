# ============================================================================
#  scripts\startup.ps1 - Startup Task Runner & Logon Scheduler
#
#  Usage:
#    .\startup.ps1 -Mode Run      # Launch all items in startup\
#    .\startup.ps1 -Mode Setup    # Register Windows Logon Scheduled Task
# ============================================================================
param(
    [ValidateSet("Run", "Setup", "run", "setup")]
    [string]$Mode = "Run"
)

. "$PSScriptRoot\..\libs\tui\tui.ps1"
$ErrorActionPreference = "Continue"

$startupDir = (Resolve-Path "$PSScriptRoot\..\startup").Path

if ($Mode -match '(?i)run') {
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

    Write-Host "${script:C_SKY}$($script:S_INFO)${script:C_RESET} Terminating existing AutoHotkey processes..."
    taskkill /F /IM AutoHotkey*.exe 2>$null | Out-Null
    Start-Sleep -Milliseconds 500

    $tasks = Get-ChildItem -Path $startupDir | Where-Object { $_.Extension -match '\.(ahk|lnk)$' }

    if (-not $tasks -or $tasks.Count -eq 0) {
        Write-TuiWarn "No .ahk or .lnk files found in '$startupDir'"
    } else {
        foreach ($t in $tasks) {
            Write-Host "${script:C_SKY}$($script:S_INFO)${script:C_RESET} ${script:C_WHITE}$($t.Name)${script:C_RESET} ${script:C_DIM}--> launching${script:C_RESET}"
            Start-Process -FilePath $t.FullName -WorkingDirectory $startupDir
            Start-Sleep -Milliseconds 250
        }
    }

    Write-TuiSeparator
    Write-TuiOk "All startup tasks launched"
} else {
    # ==========================================================================
    # SETUP MODE: Register Logon Scheduled Task
    # ==========================================================================
    Write-TuiHeader "Startup -- Task Setup"
    Write-TuiDim "  Configures a Windows Scheduled Task to run startup\ at logon."
    Write-Host ""

    $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if (-not $isAdmin) {
        Write-TuiWarn "Administrator privileges required to register logon task."
        Write-TuiInfo "Requesting UAC elevation..."
        Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`" -Mode Setup" -Verb RunAs
        return
    }

    $taskName = "RunStartupFolder"
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

