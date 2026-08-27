# ============================================================================
#  scripts\run.ps1 - Master Setup Orchestrator for Dots-Windows
# ============================================================================
. "$PSScriptRoot\..\libs\tui\tui.ps1"
$ErrorActionPreference = "Continue"

Write-TuiHeader "Dots-Windows Setup"
Write-TuiDim "  This will run package installation, configuration loading, and startup task setup."
Write-Host ""

# Step 1: Package Installation
& "$PSScriptRoot\install.ps1"

# Step 2: Load Dotfile & Terminal Configurations
& "$PSScriptRoot\load-config.ps1"

# Step 3: Setup Scheduled Logon Task
& "$PSScriptRoot\startup.ps1" -Mode Setup

Write-Host ""
Write-TuiOk "Dots-Windows setup has completed successfully!"

