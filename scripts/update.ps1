# ============================================================================
#  update.ps1 - Git Pull & Dotfile Configuration Reload
# ============================================================================
. "$PSScriptRoot\..\libs\tui\tui.ps1"
$ErrorActionPreference = "Continue"

Write-TuiHeader "Update Dots"

Write-Host "${script:C_SKY}$($script:S_INFO)${script:C_RESET} ${script:C_WHITE}Fetching and pulling latest changes...${script:C_RESET}"
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

