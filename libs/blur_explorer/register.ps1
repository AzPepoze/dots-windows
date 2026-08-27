# ============================================================================
#  libs\blur_explorer\register.ps1 - Register ExplorerBlurMica DLL
# ============================================================================
. "$PSScriptRoot\..\tui\tui.ps1"
$ErrorActionPreference = "Continue"

Write-TuiHeader "ExplorerBlurMica -- Registration"

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-TuiWarn "Administrator privileges required to register ExplorerBlurMica."
    Write-TuiInfo "Requesting UAC elevation..."
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit 0
}

$appDataDir = "$env:APPDATA\ExplorerBlurMica"
if (-not (Test-Path $appDataDir)) {
    New-Item -ItemType Directory -Path $appDataDir -Force | Out-Null
}

$configFile = "$PSScriptRoot\config.ini"
if (Test-Path $configFile) {
    Copy-Item -Path $configFile -Destination "$appDataDir\config.ini" -Force
    Write-TuiOk "Configuration copied to $appDataDir\config.ini"
}

$dllPath = "$PSScriptRoot\ExplorerBlurMica.dll"
if (-not (Test-Path $dllPath)) {
    Write-TuiErr "DLL not found at '$dllPath'"
    Wait-TuiPause
    exit 1
}

Write-TuiInfo "Registering DLL via regsvr32..."
Start-Process regsvr32.exe -ArgumentList "/s `"$dllPath`"" -Wait

if ($LASTEXITCODE -eq 0) {
    Write-TuiOk "ExplorerBlurMica registered successfully!"
    Write-TuiDim "  Restart File Explorer or log out to apply changes."
} else {
    Write-TuiErr "Registration failed with exit code $LASTEXITCODE"
}

Wait-TuiPause

