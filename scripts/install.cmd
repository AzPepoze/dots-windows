@echo off
echo.
echo #############################
echo INSTALLING
echo #############################
echo.
setlocal EnableDelayedExpansion

:: ==============================================================================
:: CONFIGURATION
:: ==============================================================================

:: List of Scoop packages to install (space separated)
set SCOOP_PKGS=steam micaforeveryone

:: List of Winget Package IDs to install (space separated)
:: (VS Code is handled separately due to custom override)
set WINGET_PKGS=SoftDeluxe.FreeDownloadManager Nilesoft.Shell StartIsBack.StartAllBack Microsoft.PowerToys Zen-Team.Zen-Browser AutoHotkey.AutoHotkey JanDeDobbeleer.OhMyPosh

:: ==============================================================================
:: MAIN SCRIPT
:: ==============================================================================

echo Checking for Scoop...
where scoop >nul 2>nul
if %errorlevel% neq 0 (
    echo [ERROR] Scoop is not installed.
    echo Please install Scoop first by running the following command in PowerShell:
    echo     iex "& {$(irm get.scoop.sh)} -RunAsAdmin"
    echo.
    pause
    exit /b 1
)

echo Checking for Winget...
where winget >nul 2>nul
if %errorlevel% neq 0 (
    echo [ERROR] Winget is not installed or not in PATH.
    echo Please install "App Installer" from the Microsoft Store or GitHub.
    echo.
    pause
    exit /b 1
)

echo.
echo Adding necessary Scoop buckets...

call scoop bucket add extras
call scoop bucket add games
call scoop bucket add nerd-fonts

echo.
echo Installing applications via Scoop...

for %%p in (%SCOOP_PKGS%) do (
    call :InstallScoop %%p
)

echo.
echo Installing applications via Winget...

echo.
echo [Winget] Installing Microsoft Visual Studio Code with custom options...

winget install -e --id Microsoft.VisualStudioCode ^
  --override "/SILENT /mergetasks=""!runcode,addcontextmenufiles,addcontextmenufolders""" ^
  --accept-package-agreements --accept-source-agreements

for %%p in (%WINGET_PKGS%) do (
    call :InstallWinget %%p
)

echo.
echo All installed!
endlocal
goto :EOF

:: ==============================================================================
:: FUNCTIONS
:: ==============================================================================

:InstallScoop
echo.
echo [Scoop] Installing %1...
call scoop install %1
goto :EOF

:InstallWinget
echo.
echo [Winget] Installing %1...
winget install -e --id %1 --accept-package-agreements --accept-source-agreements
goto :EOF
