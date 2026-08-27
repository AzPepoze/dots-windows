# ============================================================================
#  scripts\load-config.ps1 - Dotfile & Terminal Configuration Sync
# ============================================================================
. "$PSScriptRoot\..\libs\tui\tui.ps1"
$ErrorActionPreference = "Continue"

Write-TuiHeader "Load Configurations"
Write-TuiDim "  Syncing settings, PowerShell profiles, wallpaper, and startup tasks."
Write-Host ""

# ==============================================================================
# 1. Windows Terminal Settings Sync
# ==============================================================================
Write-TuiSection "Windows Terminal"

$packagesDir = "$env:LOCALAPPDATA\Packages"
$wtPackages = Get-ChildItem -Path $packagesDir -Directory -Filter "Microsoft.WindowsTerminal_*" -ErrorAction SilentlyContinue

$sourceSettings = "$PSScriptRoot\..\dots\user\AppData\Local\Packages\Microsoft.WindowsTerminal\LocalState\settings.json"

if (-not (Test-Path $sourceSettings)) {
    Write-TuiWarn "Source settings.json not found at '$sourceSettings'"
} elseif (-not $wtPackages -or $wtPackages.Count -eq 0) {
    Write-TuiWarn "Windows Terminal package folder not found in LocalAppData."
    Write-TuiDim "  If installed via winget, please launch Windows Terminal once to create its package folder."
} else {
    foreach ($pkg in $wtPackages) {
        $targetDir = Join-Path $pkg.FullName "LocalState"
        if (-not (Test-Path $targetDir)) {
            New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
        }
        $dest = Join-Path $targetDir "settings.json"
        Copy-Item -Path $sourceSettings -Destination $dest -Force
        Write-TuiOk "Applied settings.json to $($pkg.Name)"
    }
}

# ==============================================================================
# 2. PowerShell Profile Sync
# ==============================================================================
Write-TuiSection "PowerShell Profile"

$profileSource = "$PSScriptRoot\..\dots\user\Documents\WindowsPowerShell"
$profileDest = "$env:USERPROFILE\Documents\WindowsPowerShell"

if (-not (Test-Path $profileSource)) {
    Write-TuiWarn "Profile source directory not found at '$profileSource'"
} else {
    if (-not (Test-Path $profileDest)) {
        New-Item -ItemType Directory -Path $profileDest -Force | Out-Null
    }
    Get-ChildItem -Path $profileSource -File | ForEach-Object {
        Copy-Item -Path $_.FullName -Destination $profileDest -Force
        Write-TuiOk "Copied $($_.Name) to Documents\WindowsPowerShell\"
    }
}

# ==============================================================================
# 3. Apply Desktop Wallpaper
# ==============================================================================
Write-TuiSection "Wallpaper"
& "$PSScriptRoot\set-wallpaper.ps1"

# ==============================================================================
# 4. Restart Startup Tasks
# ==============================================================================
Write-TuiSection "Startup Tasks"
& "$PSScriptRoot\startup.ps1" -Mode Run

Write-Host ""
Write-TuiOk "All configurations loaded and applied successfully!"

