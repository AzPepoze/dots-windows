# ============================================================================
#  scripts\update.ps1 - Git Pull & Dotfile Configuration Reload
# ============================================================================
. "$PSScriptRoot\..\libs\tui\tui.ps1"
$ErrorActionPreference = "Continue"

Write-TuiHeader "Update Dots"

Write-TuiInfo "Fetching and pulling latest changes..."
Write-TuiSeparator
git pull
Write-Host ""

if ($LASTEXITCODE -eq 0) {
    Write-TuiOk "Repository updated successfully"
} else {
    Write-TuiWarn "Git pull finished with status code $LASTEXITCODE"
}

Write-Host ""
Write-TuiInfo "Reloading dotfile configurations..."
& "$PSScriptRoot\load-config.ps1"

Write-Host ""
Write-TuiOk "Update completed successfully!"

