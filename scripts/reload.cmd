@echo off
@REM echo.
@REM echo #############################
@REM echo RELOADING
@REM echo #############################
@REM echo.
@REM echo Stopping komorebic and yasb...

@REM taskkill /IM komorebic.exe /F >nul 2>&1
@REM taskkill /IM yasb.exe /F >nul 2>&1

@REM @REM timeout /t 2 /nobreak >nul

@REM echo Starting komorebic and yasb...

@REM start "" yasb

@REM start "" komorebic.exe start --whkd
@REM timeout /t 2 /nobreak >nul
@REM komorebic.exe focus-follows-mouse enable

@REM echo Reload complete.