@echo off
echo.
echo #############################
echo INSTALLING
echo #############################
echo.
setlocal

:: ==============================================================================
:: CONFIGURATION
:: ==============================================================================

:: List of Scoop packages to install (Space separated)
set SCOOP_PKGS=steam micaforeveryone komorebi yasb whkd nerd-fonts/JetBrains-Mono

:: List of Winget Package IDs to install (Space separated)
set WINGET_PKGS=Microsoft.VisualStudioCode.Insiders  SoftDeluxe.FreeDownloadManager StartIsBack.StartAllBack Zen-Team.Zen-Browser

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
    echo Please install 'App Installer' from the Microsoft Store or GitHub.
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