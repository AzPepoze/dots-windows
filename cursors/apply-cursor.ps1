# ============================================================================
#  cursors\apply-cursor.ps1 - Cursor Scheme Applicator
# ============================================================================
. "$PSScriptRoot\..\libs\tui\tui.ps1"
$ErrorActionPreference = "Stop"

$cursorsDir = $PSScriptRoot
$folders = Get-ChildItem -Path $cursorsDir -Directory

if ($folders.Count -eq 0) {
    Write-TuiErr "No cursor folders found in $cursorsDir"
    Wait-TuiPause
    exit 1
}

$items = [System.Collections.ArrayList]@()
foreach ($f in $folders) {
    $items.Add([PSCustomObject]@{
        Name = $f.Name
        Description = "Cursor Scheme"
        Folder = $f
    }) | Out-Null
}

Clear-Host
$selectedItem = Invoke-TuiSingleSelect -Title "Select Cursor Scheme" -Items $items -Header "Cursor Schemes" -SubTitle "Pick a cursor pack to apply system-wide."

if ($null -eq $selectedItem) {
    Write-TuiSkip "Selection cancelled."
    exit 0
}

$selectedFolder = $selectedItem.Folder
$targetDir = $selectedFolder.FullName
$schemeName = $selectedFolder.Name

Write-TuiInfo "Installing '$schemeName' from $targetDir..."

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

$arrow     = Get-CursorFile "arrow" "pointer"
$helpsel   = Get-CursorFile "helpsel" "help"
$working   = Get-CursorFile "working" "appstarting"
$busy      = Get-CursorFile "busy" "wait"
$crosshair = Get-CursorFile "cross" "crosshair"
$ibeam     = Get-CursorFile "ibeam" "text"
$nwpen     = Get-CursorFile "pen" "nwpen"
$unavail   = Get-CursorFile "unavail" "no"
$ns        = Get-CursorFile "ns" "sizens"
$ew        = Get-CursorFile "ew" "sizewe"
$nwse      = Get-CursorFile "nwse" "sizenwse"
$nesw      = Get-CursorFile "nesw" "sizenesw"
$move      = Get-CursorFile "move" "sizeall"
$uparrow   = Get-CursorFile "up" "uparrow"
$link      = Get-CursorFile "link" "hand"

if (-not $arrow) {
    Write-TuiErr "Could not find main 'arrow' cursor in $targetDir"
    Start-Sleep -Seconds 2
    exit 1
}

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

Write-TuiInfo "Broadcasting cursor update to system..."

$code = @"
using System.Runtime.InteropServices;
public class Win32Cursor {
    [DllImport("user32.dll", EntryPoint = "SystemParametersInfo")]
    public static extern bool SystemParametersInfo(uint uiAction, uint uiParam, uint pvParam, uint fWinIni);
}
"@
try { Add-Type -TypeDefinition $code -ErrorAction SilentlyContinue } catch {}
[Win32Cursor]::SystemParametersInfo(0x0057, 0, 0, 0x01 -bor 0x02) | Out-Null

Write-TuiOk "Cursor scheme '$schemeName' applied!"
Write-TuiDim "  Move your mouse to view the newly active scheme."
Start-Sleep -Seconds 1
