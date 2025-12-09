@echo off
echo.
echo #############################
echo RELOADING
echo #############################
echo.
echo Stopping komorebic and yasb...

taskkill /IM komorebic.exe /F >nul 2>&1
taskkill /IM yasb.exe /F >nul 2>&1

@REM timeout /t 2 /nobreak >nul

echo Starting komorebic and yasb...

start "" yasb

start "" komorebic.exe start --whkd
timeout /t 2 /nobreak >nul
komorebic.exe focus-follows-mouse enable

echo Reload complete.