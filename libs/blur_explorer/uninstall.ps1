# ============================================================================
#  libs\blur_explorer\uninstall.ps1 - Unregister ExplorerBlurMica DLL
# ============================================================================
. "$PSScriptRoot\..\tui\tui.ps1"
$ErrorActionPreference = "Continue"

Write-TuiHeader "ExplorerBlurMica -- Uninstall"

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-TuiWarn "Administrator privileges required to unregister ExplorerBlurMica."
    Write-TuiInfo "Requesting UAC elevation..."
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit 0
}

$dllPath = "$PSScriptRoot\ExplorerBlurMica.dll"
if (Test-Path $dllPath) {
    Write-TuiInfo "Unregistering DLL via regsvr32 /u..."
    Start-Process regsvr32.exe -ArgumentList "/u /s `"$dllPath`"" -Wait
    Write-TuiOk "ExplorerBlurMica DLL unregistered"
}

$appDataDir = "$env:APPDATA\ExplorerBlurMica"
if (Test-Path $appDataDir) {
    Remove-Item -Path $appDataDir -Recurse -Force -ErrorAction SilentlyContinue
    Write-TuiOk "Removed configuration directory at $appDataDir"
}

Write-TuiOk "ExplorerBlurMica uninstalled successfully!"
Wait-TuiPause

