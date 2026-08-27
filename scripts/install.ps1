# ============================================================================
#  scripts\install.ps1 - Interactive Package & Tooling Installer
# ============================================================================
. "$PSScriptRoot\..\libs\tui\tui.ps1"
$ErrorActionPreference = "Continue"

Write-TuiHeader "Installation Setup"

# ==============================================================================
# Prerequisites Check
# ==============================================================================
Write-TuiSection "Prerequisites"

$hasScoop = [bool](Get-Command scoop -ErrorAction SilentlyContinue)
if (-not $hasScoop) {
    $scoopShim = "$env:USERPROFILE\scoop\shims\scoop.ps1"
    if (Test-Path $scoopShim) {
        $env:PATH = "$env:USERPROFILE\scoop\shims;$env:USERPROFILE\scoop\apps\scoop\current\bin;$env:PATH"
        $hasScoop = $true
    }
}

if (-not $hasScoop) {
    Write-TuiInfo "Scoop not found -- installing Scoop automatically..."
    try {
        Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force -ErrorAction SilentlyContinue
        Invoke-RestMethod -Uri https://get.scoop.sh | Invoke-Expression
        $env:PATH = "$env:USERPROFILE\scoop\shims;$env:USERPROFILE\scoop\apps\scoop\current\bin;$env:PATH"
        $hasScoop = [bool](Get-Command scoop -ErrorAction SilentlyContinue)
    } catch {
        Write-TuiWarn "Automatic Scoop installation encountered an issue: $_"
    }
}

if ($hasScoop) {
    Write-TuiOk "Scoop package manager ready"
} else {
    Write-TuiErr "Could not initialize Scoop package manager."
}

$hasWinget = [bool](Get-Command winget -ErrorAction SilentlyContinue)
if (-not $hasWinget) {
    Write-TuiErr "Winget is not installed or not in PATH."
    Write-TuiDim "  Install App Installer from Microsoft Store or github.com/microsoft/winget-cli"
    Wait-TuiPause
    exit 1
}
Write-TuiOk "Winget package manager found"

$hasCurl = [bool](Get-Command curl.exe -ErrorAction SilentlyContinue)
if ($hasCurl) {
    Write-TuiOk "curl download utility found"
} else {
    Write-TuiWarn "curl not found; downloads will fallback to PowerShell"
}

# ==============================================================================
# Ensure Scoop Buckets
# ==============================================================================
Write-TuiSection "Scoop Buckets"
$buckets = @("extras", "games", "nerd-fonts")
foreach ($b in $buckets) {
    Write-Host "${script:C_SKY}$($script:S_INFO)${script:C_RESET} ${script:C_WHITE}Bucket '$b'${script:C_RESET} ${script:C_DIM}-- checking...${script:C_RESET}"
    $bucketList = scoop bucket list 2>$null
    if ($bucketList -match "\b$b\b") {
        Write-TuiOk "Bucket '$b' is ready (skipped)"
    } else {
        Write-TuiInfo "Adding bucket '$b'..."
        scoop bucket add $b 2>&1 | Out-Null
        Write-TuiOk "Bucket '$b' added"
    }
}

# ==============================================================================
# Package Definitions (Categorized & Grouped)
# ==============================================================================
$items = [System.Collections.ArrayList]@(
    # --- Scoop Packages ---
    [PSCustomObject]@{ IsHeader = $true; Name = "Scoop Packages" }
    [PSCustomObject]@{ Id = "micaforeveryone"; Name = "Mica For Everyone"; Category = "Scoop"; Type = "scoop"; Selected = $true }

    # --- Direct curl Downloads ---
    [PSCustomObject]@{ IsHeader = $true; Name = "Direct Downloads (curl)" }
    [PSCustomObject]@{ Id = "vscode"; Name = "Visual Studio Code"; Category = "Direct curl"; Type = "vscode"; Selected = $true }
    [PSCustomObject]@{ Id = "steam"; Name = "Steam"; Category = "Direct curl"; Type = "steam"; Selected = $true }

    # --- Web & Cloud Apps ---
    [PSCustomObject]@{ IsHeader = $true; Name = "Web & Cloud Apps" }
    [PSCustomObject]@{ Id = "Zen-Team.Zen-Browser"; Name = "Zen Browser"; Category = "Winget"; Type = "winget"; Selected = $true }
    [PSCustomObject]@{ Id = "Google.GoogleDrive"; Name = "Google Drive"; Category = "Winget"; Type = "winget"; Selected = $true }
    [PSCustomObject]@{ Id = "SoftDeluxe.FreeDownloadManager"; Name = "Free Download Manager"; Category = "Winget"; Type = "winget"; Selected = $true }

    # --- Developer & Terminal Tools ---
    [PSCustomObject]@{ IsHeader = $true; Name = "Developer & Terminal Tools" }
    [PSCustomObject]@{ Id = "Oven-sh.Bun"; Name = "Bun JavaScript Runtime"; Category = "Winget"; Type = "winget"; Selected = $true }
    [PSCustomObject]@{ Id = "JanDeDobbeleer.OhMyPosh"; Name = "Oh My Posh"; Category = "Winget"; Type = "winget"; Selected = $true }
    [PSCustomObject]@{ Id = "AutoHotkey.AutoHotkey"; Name = "AutoHotkey v2"; Category = "Winget"; Type = "winget"; Selected = $true }
    [PSCustomObject]@{ Id = "Microsoft.PowerToys"; Name = "Microsoft PowerToys"; Category = "Winget"; Type = "winget"; Selected = $true }

    # --- System & Utility Apps ---
    [PSCustomObject]@{ IsHeader = $true; Name = "System & Utility Apps" }
    [PSCustomObject]@{ Id = "M2Team.NanaZip"; Name = "NanaZip (7-Zip Alternative)"; Category = "Winget"; Type = "winget"; Selected = $true }
    [PSCustomObject]@{ Id = "Nilesoft.Shell"; Name = "Nilesoft Shell (Context Menus)"; Category = "Winget"; Type = "winget"; Selected = $true }
    [PSCustomObject]@{ Id = "StartIsBack.StartAllBack"; Name = "StartAllBack"; Category = "Winget"; Type = "winget"; Selected = $true }
    [PSCustomObject]@{ Id = "AntibodySoftware.WizTree"; Name = "WizTree Disk Analyzer"; Category = "Winget"; Type = "winget"; Selected = $true }
    [PSCustomObject]@{ Id = "Tailscale.Tailscale"; Name = "Tailscale Mesh VPN"; Category = "Winget"; Type = "winget"; Selected = $true }
    [PSCustomObject]@{ Id = "Parsec.Parsec"; Name = "Parsec Remote Desktop"; Category = "Winget"; Type = "winget"; Selected = $true }
    [PSCustomObject]@{ Id = "Devolutions.UniGetUI"; Name = "UniGetUI Package Manager"; Category = "Winget"; Type = "winget"; Selected = $true }

    # --- System Integrations & Tweaks ---
    [PSCustomObject]@{ IsHeader = $true; Name = "System Integrations & Tweaks" }
    [PSCustomObject]@{ Id = "blur_explorer"; Name = "Blur Explorer (Requires Admin)"; Category = "Utility"; Type = "blur_explorer"; Selected = $true }
    [PSCustomObject]@{ Id = "vscode_menu"; Name = "VS Code Context Menu Integration"; Category = "Utility"; Type = "vscode_menu"; Selected = $true }
)

# ==============================================================================
# Interactive Checkbox Menu
# ==============================================================================
Clear-Host
$result = Invoke-TuiMultiSelect -Title "Select Packages to Install" -Items $items -Header "Installation Setup"

if ($null -eq $result) {
    Write-TuiSkip "Installation cancelled by user."
    exit 0
}

$selected = $result | Where-Object { $_.Selected -and -not $_.IsHeader }

if ($selected.Count -eq 0) {
    Write-TuiWarn "No packages were selected to install."
    exit 0
}

# ==============================================================================
# Installation Execution
# ==============================================================================
Write-TuiSection "Installing Selected Packages ($($selected.Count) items)"

foreach ($pkg in $selected) {
    switch ($pkg.Type) {
        "scoop" {
            Write-Host ""
            Write-Host "${script:C_SKY}$($script:S_INFO)${script:C_RESET} ${script:C_WHITE}[Scoop] $($pkg.Name)${script:C_RESET} ${script:C_DIM}-- checking status...${script:C_RESET}"
            $installed = scoop list 2>$null | Select-String -Pattern "^$([regex]::Escape($pkg.Id))\b" -SimpleMatch
            if ($installed) {
                Write-TuiOk "[Scoop] $($pkg.Name) is already installed (skipped)"
            } else {
                Write-TuiInfo "Installing $($pkg.Name) via Scoop..."
                scoop install $pkg.Id
                if ($LASTEXITCODE -eq 0) {
                    Write-TuiOk "[Scoop] $($pkg.Name) installed successfully"
                } else {
                    Write-TuiErr "[Scoop] Failed to install $($pkg.Name)"
                }
            }
        }
        "vscode" {
            Write-Host ""
            Write-Host "${script:C_SKY}$($script:S_INFO)${script:C_RESET} ${script:C_WHITE}[VS Code] Visual Studio Code${script:C_RESET} ${script:C_DIM}-- checking install path...${script:C_RESET}"
            $codePaths = @(
                "$env:LOCALAPPDATA\Programs\Microsoft VS Code\Code.exe",
                "$env:ProgramFiles\Microsoft VS Code\Code.exe",
                "${env:ProgramFiles(x86)}\Microsoft VS Code\Code.exe"
            )
            $codeFound = $codePaths | Where-Object { Test-Path $_ }
            if ($codeFound) {
                Write-TuiOk "[VS Code] Visual Studio Code is already installed (skipped)"
            } else {
                Write-TuiInfo "Downloading VS Code installer via curl..."
                $url = "https://update.code.visualstudio.com/latest/win32-x64-user/stable"
                $dest = "$env:TEMP\VSCodeUserSetup.exe"
                if ($hasCurl) {
                    curl.exe -L -# -o $dest $url
                } else {
                    Invoke-WebRequest -Uri $url -OutFile $dest
                }
                if (Test-Path $dest) {
                    Write-TuiInfo "Running silent VS Code setup..."
                    Start-Process -FilePath $dest -ArgumentList '/SILENT /mergetasks="!runcode,addcontextmenufiles,addcontextmenufolders"' -Wait
                    Write-TuiOk "[VS Code] Visual Studio Code installed successfully"
                    Remove-Item $dest -Force -ErrorAction SilentlyContinue
                } else {
                    Write-TuiErr "Failed to download VS Code installer"
                }
            }
        }
        "steam" {
            Write-Host ""
            Write-Host "${script:C_SKY}$($script:S_INFO)${script:C_RESET} ${script:C_WHITE}[Steam] Steam Client${script:C_RESET} ${script:C_DIM}-- checking install path...${script:C_RESET}"
            $steamPaths = @(
                "${env:ProgramFiles(x86)}\Steam\steam.exe",
                "$env:ProgramFiles\Steam\steam.exe"
            )
            $steamFound = $steamPaths | Where-Object { Test-Path $_ }
            if ($steamFound) {
                Write-TuiOk "[Steam] Steam is already installed (skipped)"
            } else {
                Write-TuiInfo "Downloading Steam installer via curl..."
                $url = "https://cdn.fastly.steamstatic.com/client/installer/SteamSetup.exe"
                $dest = "$env:TEMP\SteamSetup.exe"
                if ($hasCurl) {
                    curl.exe -L -# -o $dest $url
                } else {
                    Invoke-WebRequest -Uri $url -OutFile $dest
                }
                if (Test-Path $dest) {
                    Write-TuiOk "Downloaded Steam setup -- starting installer wizard..."
                    Start-Process -FilePath $dest
                    Write-TuiWarn "Please complete the Steam installation wizard."
                } else {
                    Write-TuiErr "Failed to download Steam installer"
                }
            }
        }
        "winget" {
            Write-Host ""
            Write-Host "${script:C_SKY}$($script:S_INFO)${script:C_RESET} ${script:C_WHITE}[Winget] $($pkg.Name)${script:C_RESET} ${script:C_DIM}-- checking status...${script:C_RESET}"
            $listOutput = winget list --exact --id $pkg.Id --accept-source-agreements --disable-interactivity 2>$null
            if ($listOutput -match [regex]::Escape($pkg.Id)) {
                Write-TuiOk "[Winget] $($pkg.Name) is already installed (skipped)"
            } else {
                Write-TuiInfo "Installing $($pkg.Name) via Winget..."
                winget install -e --id $pkg.Id --accept-package-agreements --accept-source-agreements --disable-interactivity
                if ($LASTEXITCODE -eq 0) {
                    Write-TuiOk "[Winget] $($pkg.Name) installed successfully"
                } else {
                    Write-TuiErr "[Winget] Failed to install $($pkg.Name) (check output above)"
                }
            }
        }
        "blur_explorer" {
            Write-Host ""
            Write-TuiInfo "Launching Blur Explorer registration..."
            & "$PSScriptRoot\..\libs\blur_explorer\register.ps1"
        }
        "vscode_menu" {
            Write-Host ""
            Write-TuiInfo "Launching VS Code Context Menu setup..."
            & "$PSScriptRoot\..\utils\add-vscode-context-menu.ps1"
        }
    }
}

Write-Host ""
Write-TuiOk "Installation script finished."
