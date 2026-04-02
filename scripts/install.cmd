@echo off
setlocal EnableDelayedExpansion

echo.
echo ================================================================================
echo  INSTALLATION SCRIPT
echo ================================================================================
echo.

REM ==============================================================================
REM CONFIGURATION
REM ==============================================================================

REM Scoop packages to install (space separated)
set SCOOP_PKGS=micaforeveryone

REM Winget packages to install (space separated)
REM Note: VS Code is handled separately with custom override
set WINGET_PKGS=SoftDeluxe.FreeDownloadManager M2Team.NanaZip Nilesoft.Shell StartIsBack.StartAllBack Microsoft.PowerToys Zen-Team.Zen-Browser AutoHotkey.AutoHotkey JanDeDobbeleer.OhMyPosh AntibodySoftware.WizTree Tailscale.Tailscale Parsec.Parsec Devolutions.UniGetUI

REM Steam installation URL and paths
set STEAM_URL=https://cdn.fastly.steamstatic.com/client/installer/SteamSetup.exe

REM ==============================================================================
REM MAIN SCRIPT
REM ==============================================================================

echo [*] Checking prerequisites...
echo.

where scoop >nul 2>nul
if %errorlevel% neq 0 (
    echo [ERROR] Scoop is not installed.
    echo.
    echo Please install Scoop first by running in PowerShell:
    echo iex "^& {$^(irm get.scoop.sh^)} -RunAsAdmin"
    echo.
    pause
    exit /b 1
)
echo [OK] Scoop found

where winget >nul 2>nul
if %errorlevel% neq 0 (
    echo [ERROR] Winget is not installed or not in PATH.
    echo.
    echo Please install "App Installer" from:
    echo - Microsoft Store, or
    echo - https://github.com/microsoft/winget-cli
    echo.
    pause
    exit /b 1
)
echo [OK] Winget found
echo.

echo [*] Setting up Scoop buckets...
echo.

scoop bucket list | find /i "extras" >nul 2>&1 || scoop bucket add extras
scoop bucket list | find /i "games" >nul 2>&1 || scoop bucket add games
scoop bucket list | find /i "nerd-fonts" >nul 2>&1 || scoop bucket add nerd-fonts

echo.
echo [*] Installing Scoop packages...
echo.

for %%p in (%SCOOP_PKGS%) do (
    call :InstallScoop %%p
    echo.
)

echo.
echo [*] Installing Winget packages...
echo.

echo [Winget] VS Code (with custom override)...

winget install -e --id Microsoft.VisualStudioCode ^
  --override "/SILENT /mergetasks=""!runcode,addcontextmenufiles,addcontextmenufolders""" ^
  --accept-package-agreements --accept-source-agreements

for %%p in (%WINGET_PKGS%) do (
    call :InstallWinget %%p
    echo.
)

echo.
echo [*] Optional installations...
echo.

call :AskUser "Do you want to register Blur Explorer (requires admin)?"
if %errorlevel% == 0 (
    start "Blur Explorer Registration" "%~dp0..\libs\blur_explorer\register.cmd"
) else (
    echo [SKIP] Blur Explorer registration skipped
)

echo.

call :AskUser "Do you want to install Steam?"
if %errorlevel% == 0 (
    call :CheckAndInstallSteam
) else (
    echo [SKIP] Steam installation skipped
)

echo.
endlocal
goto :EOF

REM ==============================================================================
REM FUNCTIONS
REM ==============================================================================

:IsScoopInstalled
scoop list | find /i "%1" >nul 2>nul
exit /b %errorlevel%
goto :EOF

:IsWingetInstalled
winget list --exact --id %1 >nul 2>nul
exit /b %errorlevel%
goto :EOF

REM Helper function to install Scoop packages
:InstallScoop
echo [Scoop] %1

call :IsScoopInstalled %1
if %errorlevel% equ 0 (
    echo [OK] Already installed
) else (
    call :AskUser "Install %1?"
    if %errorlevel% == 0 (
        echo Installing...
        call scoop install %1
        if %errorlevel% equ 0 (
            echo [OK] Installed
        ) else (
            echo [FAILED] Installation failed
        )
    ) else (
        echo [SKIP]
    )
)
goto :EOF

:InstallWinget
echo [Winget] %1

call :IsWingetInstalled %1
if %errorlevel% equ 0 (
    echo [OK] Already installed
) else (
    call :AskUser "Install %1?"
    if %errorlevel% == 0 (
        echo Installing...
        winget install -e --id %1 --accept-package-agreements --accept-source-agreements >nul 2>&1
        if %errorlevel% equ 0 (
            echo [OK] Installed
        ) else (
            echo [FAILED] Installation failed
        )
    ) else (
        echo [SKIP]
    )
)
goto :EOF

:AskUser
echo %~1
:ask_loop
set /p choice="[y/n]: "
if /i "%choice%"=="y" (
    exit /b 0
) else if /i "%choice%"=="n" (
    exit /b 1
) else (
    echo [!] Please enter 'y' or 'n'.
    goto ask_loop
)
goto :EOF

:CheckAndInstallSteam
echo [Steam] Checking if already installed...

if exist "!ProgramFiles(x86)!\Steam\steam.exe" (
    echo [OK] Already installed
    exit /b 0
)

if exist "!ProgramFiles!\Steam\steam.exe" (
    echo [OK] Already installed
    exit /b 0
)

echo [*] Not found. Downloading Steam installer...
powershell -Command "Invoke-WebRequest -Uri '%STEAM_URL%' -OutFile '%TEMP%\SteamSetup.exe'" >nul 2>&1

if %errorlevel% equ 0 (
    echo [OK] Starting Steam installation...
    start "" "%TEMP%\SteamSetup.exe"
    echo [!] Please complete the installation manually.
) else (
    echo [ERROR] Failed to download Steam installer.
)
exit /b 0
goto :EOF
