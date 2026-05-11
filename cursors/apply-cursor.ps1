$ErrorActionPreference = "Stop"
$cursorsDir = $PSScriptRoot

# Get list of cursor folders
$folders = Get-ChildItem -Path $cursorsDir -Directory

if ($folders.Count -eq 0) {
    Write-Host "No cursor folders found in $cursorsDir"
    exit
}

Write-Host "Available Cursor Schemes:"
for ($i = 0; $i -lt $folders.Count; $i++) {
    Write-Host "$($i + 1). $($folders[$i].Name)"
}

$choice = Read-Host "Select a cursor scheme to install (1-$($folders.Count))"

try {
    $selectedIndex = [int]$choice - 1
    if ($selectedIndex -lt 0 -or $selectedIndex -ge $folders.Count) {
        Write-Warning "Invalid selection."
        exit
    }
} catch {
    Write-Warning "Invalid input."
    exit
}

$selectedFolder = $folders[$selectedIndex]
$targetDir = $selectedFolder.FullName
$schemeName = $selectedFolder.Name

Write-Host "Installing '$schemeName' from $targetDir..."

# Function to find either .ani or .cur for a given role
function Get-CursorFile {
    param([string]$roleName, [string]$fallback = "")
    $aniPath = Join-Path $targetDir "$roleName.ani"
    $curPath = Join-Path $targetDir "$roleName.cur"
    if (Test-Path $aniPath) { return $aniPath }
    if (Test-Path $curPath) { return $curPath }
    
    if ($fallback) {
        $aniPath = Join-Path $targetDir "$fallback.ani"
        $curPath = Join-Path $targetDir "$fallback.cur"
        if (Test-Path $aniPath) { return $aniPath }
        if (Test-Path $curPath) { return $curPath }
    }
    return ""
}

$arrow       = Get-CursorFile "arrow" "pointer"
$helpsel     = Get-CursorFile "helpsel" "help"
$working     = Get-CursorFile "working" "appstarting"
$busy        = Get-CursorFile "busy" "wait"
$crosshair   = Get-CursorFile "cross" "crosshair"
$ibeam       = Get-CursorFile "ibeam" "text"
$nwpen       = Get-CursorFile "pen" "nwpen"
$unavail     = Get-CursorFile "unavail" "no"
$ns          = Get-CursorFile "ns" "sizens"
$ew          = Get-CursorFile "ew" "sizewe"
$nwse        = Get-CursorFile "nwse" "sizenwse"
$nesw        = Get-CursorFile "nesw" "sizenesw"
$move        = Get-CursorFile "move" "sizeall"
$uparrow     = Get-CursorFile "up" "uparrow"
$link        = Get-CursorFile "link" "hand"

if (-not $arrow) {
    Write-Warning "Could not find a main 'arrow' cursor (arrow.ani or arrow.cur) in $targetDir."
    Start-Sleep -Seconds 2
    exit
}

# Registry paths
$cursorsPath = "HKCU:\Control Panel\Cursors"
$schemesPath = "$cursorsPath\Schemes"

if (-not (Test-Path -Path $schemesPath)) {
    New-Item -Path $cursorsPath -Name "Schemes" -Force | Out-Null
}

$schemeString = "$arrow,$helpsel,$working,$busy,$crosshair,$ibeam,$nwpen,$unavail,$ns,$ew,$nwse,$nesw,$move,$uparrow,$link"
Set-ItemProperty -Path $schemesPath -Name $schemeName -Value $schemeString

Set-ItemProperty -Path $cursorsPath -Name "Arrow" -Value $arrow
Set-ItemProperty -Path $cursorsPath -Name "Help" -Value $helpsel
Set-ItemProperty -Path $cursorsPath -Name "AppStarting" -Value $working
Set-ItemProperty -Path $cursorsPath -Name "Wait" -Value $busy
Set-ItemProperty -Path $cursorsPath -Name "IBeam" -Value $ibeam
Set-ItemProperty -Path $cursorsPath -Name "No" -Value $unavail
Set-ItemProperty -Path $cursorsPath -Name "SizeNS" -Value $ns
Set-ItemProperty -Path $cursorsPath -Name "SizeWE" -Value $ew
Set-ItemProperty -Path $cursorsPath -Name "SizeNWSE" -Value $nwse
Set-ItemProperty -Path $cursorsPath -Name "SizeNESW" -Value $nesw
Set-ItemProperty -Path $cursorsPath -Name "SizeAll" -Value $move
Set-ItemProperty -Path $cursorsPath -Name "Hand" -Value $link
Set-ItemProperty -Path $cursorsPath -Name "Crosshair" -Value $crosshair
Set-ItemProperty -Path $cursorsPath -Name "UpArrow" -Value $uparrow
Set-ItemProperty -Path $cursorsPath -Name "NWPen" -Value $nwpen

Set-ItemProperty -Path $cursorsPath -Name "(Default)" -Value $schemeName

Write-Host "Refreshing system cursors..."

# Refresh cursors using SystemParametersInfo
$code = @"
using System.Runtime.InteropServices;
public class Win32 {
    [DllImport("user32.dll", EntryPoint = "SystemParametersInfo")]
    public static extern bool SystemParametersInfo(uint uiAction, uint uiParam, uint pvParam, uint fWinIni);
}
"@
try {
    Add-Type -TypeDefinition $code -ErrorAction Ignore
} catch {}

[Win32]::SystemParametersInfo(0x0057, 0, 0, 0x01 -bor 0x02) | Out-Null

Write-Host "Cursor scheme '$schemeName' applied successfully!"
Start-Sleep -Seconds 2
