@echo off

REM -------------------------------------------------------
REM [Runall Mode]
REM -------------------------------------------------------
if /I "%1"=="runall" (
	@REM echo Pulling latest changes...
	@REM git pull
	@REM call scripts/load_config.cmd

    echo [RUNALL MODE]

    echo [DEBUG] Initial Path: %cd%
    echo [DEBUG] Script Path: %~dp0

    pushd "%~dp0"

    echo [DEBUG] Current Path after pushd: %cd%

    if not exist "../startup" (
        echo [ERROR] "../startup" folder not found in "%~dp0"
        popd
        pause
        exit /b
    )

    echo [INFO] "../startup" folder found. Starting files...
    echo --------------------------------------------------------

    for %%f in ("../startup\*") do (
        echo [INFO] Running: "%%f"
        start "" "%%f"
    )

    echo --------------------------------------------------------
    echo [SUCCESS] All files in startup folder have been executed.

    popd
    exit /b
)

REM -------------------------------------------------------
REM [Setup Mode]
REM -------------------------------------------------------
echo [SETUP MODE] Creating Scheduled Task...
echo.

set "taskName=RunStartupFolder"
set "taskCommand=\"%~f0\" runall"

echo.

schtasks /Delete /TN "%taskName%" /F >nul 2>&1
schtasks /Create /SC ONLOGON /TN "%taskName%" /TR "%taskCommand%" /F

if "%errorlevel%"=="0" (
    echo [SUCCESS] Task "%taskName%" created successfully.
) else (
    echo [ERROR] Failed to create Task "%taskName%".
	pause
)