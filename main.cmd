@echo off
setlocal
cd /d "%~dp0"

:menu
cls
echo =========================================
echo   Dots-Windows Main Menu
echo =========================================
echo.
echo 1. Install dots
echo 2. Update dots
echo 3. Install Cursor Scheme
echo 4. Exit
echo.
set /p choice="Enter your choice (1-4): "

if "%choice%"=="1" goto install_dots
if "%choice%"=="2" goto update_dots
if "%choice%"=="3" goto install_cursor
if "%choice%"=="4" goto end

echo Invalid choice. Please try again.
timeout /t 2 >nul
goto menu

:install_dots
echo.
echo #############################
echo MAIN SCRIPT
echo #############################
echo.
echo Pulling latest changes...
git pull
echo.
call scripts\run.cmd
echo.
pause
goto menu

:update_dots
echo.
call update.cmd
echo.
pause
goto menu

:install_cursor
echo.
powershell.exe -ExecutionPolicy Bypass -File "%~dp0cursors\apply-cursor.ps1"
goto menu

:end
endlocal
exit /b 0
