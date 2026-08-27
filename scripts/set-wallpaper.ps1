# ============================================================================
#  scripts\set-wallpaper.ps1 - Desktop Wallpaper Applicator
# ============================================================================
. "$PSScriptRoot\..\libs\tui\tui.ps1"

$Wallpaper = Join-Path $PSScriptRoot "..\wallpaper\1353704.jpeg"

if (-not (Test-Path $Wallpaper)) {
    Write-TuiErr "Wallpaper not found at '$Wallpaper'"
    exit 1
}

Write-TuiInfo "Applying wallpaper: $Wallpaper"

$code = @"
using System;
using System.Runtime.InteropServices;
public class WallpaperUtil {
    [DllImport("user32.dll", SetLastError = true)]
    public static extern bool SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);
}
"@

try {
    Add-Type -TypeDefinition $code -ErrorAction SilentlyContinue
} catch {}

# SPI_SETDESKWALLPAPER = 20, SPIF_UPDATEINIFILE | SPIF_SENDCHANGE = 3
$Result = [WallpaperUtil]::SystemParametersInfo(20, 0, (Resolve-Path $Wallpaper).Path, 3)

if ($Result) {
    Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name Wallpaper -Value (Resolve-Path $Wallpaper).Path
    Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name WallpaperStyle -Value "10"  # 10 = Fill
    Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name TileWallpaper -Value "0"
    Write-TuiOk "Wallpaper applied (Fill mode)"
    exit 0
} else {
    Write-TuiErr "Failed to set wallpaper via SystemParametersInfo"
    exit 1
}
