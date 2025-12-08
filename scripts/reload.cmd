@echo off
echo.
echo #############################
echo RELOADING
echo #############################
echo.
echo Stopping komorebic and yasb...

taskkill /IM komorebic.exe /F >nul 2>&1
taskkill /IM yasb.exe /F >nul 2>&1

timeout /t 2 /nobreak >nul

echo Starting komorebic and yasb...

komorebic.exe start --whkd
timeout /t 1 /nobreak >nul

start "" yasb

echo Reload complete.