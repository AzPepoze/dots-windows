$Wallpaper = Join-Path $PSScriptRoot "..\wallpaper\1353704.jpeg"

if (-not (Test-Path $Wallpaper)) {
    Write-Host "[ERROR] Wallpaper not found at '$Wallpaper'"
    exit 1
}

Write-Host "[*] Applying wallpaper: $Wallpaper"

Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public class Wallpaper {
    [DllImport("user32.dll", SetLastError = true)]
    public static extern bool SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);
}
"@

# SPI_SETDESKWALLPAPER = 20, SPIF_UPDATEINIFILE | SPIF_SENDCHANGE = 3
$Result = [Wallpaper]::SystemParametersInfo(20, 0, $Wallpaper, 3)

if ($Result) {
    # Persist the setting so it survives logoff/reboot
    Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name Wallpaper -Value $Wallpaper
    Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name WallpaperStyle -Value "10"  # 10 = Fill
    Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name TileWallpaper -Value "0"
    Write-Host "[OK] Wallpaper applied"
} else {
    Write-Host "[ERROR] Failed to apply wallpaper"
    exit 1
}
