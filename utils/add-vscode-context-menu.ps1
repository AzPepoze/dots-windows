# ============================================================================
#  utils\add-vscode-context-menu.ps1 - Add "Open with Code" to Context Menu
# ============================================================================
. "$PSScriptRoot\..\libs\tui\tui.ps1"
$ErrorActionPreference = "Continue"

Write-TuiHeader "VS Code -- Context Menu"

# Check Administrator privileges
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-TuiWarn "Administrator privileges required to write registry keys."
    Write-TuiInfo "Requesting elevation..."
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit 0
}

# Locate VS Code executable
$codeCandidates = @(
    "$env:LOCALAPPDATA\Programs\Microsoft VS Code\Code.exe",
    "$env:ProgramFiles\Microsoft VS Code\Code.exe",
    "${env:ProgramFiles(x86)}\Microsoft VS Code\Code.exe"
)

$codeExe = $codeCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1

if (-not $codeExe) {
    Write-TuiErr "VS Code executable not found in standard paths."
    Write-TuiDim "  Checked:"
    foreach ($c in $codeCandidates) { Write-TuiDim "    $c" }
    Wait-TuiPause
    exit 1
}

Write-TuiOk "Found VS Code: $codeExe"
Write-TuiSection "Adding Registry Keys"

$targets = @(
    @{ Path = "HKCR:\*\shell\Open with Code"; Cmd = "`"$codeExe`" `"%1`""; Label = "File" },
    @{ Path = "HKCR:\Directory\shell\Open with Code"; Cmd = "`"$codeExe`" `"%1`""; Label = "Directory" },
    @{ Path = "HKCR:\Directory\Background\shell\Open with Code"; Cmd = "`"$codeExe`" `"%V`""; Label = "Background" }
)

foreach ($t in $targets) {
    try {
        if (-not (Test-Path $t.Path)) {
            New-Item -Path $t.Path -Force | Out-Null
        }
        Set-ItemProperty -Path $t.Path -Name "(Default)" -Value "Open with Code"
        Set-ItemProperty -Path $t.Path -Name "Icon" -Value "`"$codeExe`",0"

        $cmdPath = "$($t.Path)\command"
        if (-not (Test-Path $cmdPath)) {
            New-Item -Path $cmdPath -Force | Out-Null
        }
        Set-ItemProperty -Path $cmdPath -Name "(Default)" -Value $t.Cmd
        Write-TuiOk "$($t.Label) context menu registered"
    } catch {
        Write-TuiErr "Failed to register $($t.Label) context menu: $_"
    }
}

Write-Host ""
Write-TuiOk "'Open with Code' successfully added to context menus!"
Wait-TuiPause

