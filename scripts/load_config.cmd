@echo off
echo.
echo #############################
echo LOADING CONFIG
echo #############################
echo.
set "SOURCE=%~dp0..\dots\user"
set "DEST=%USERPROFILE%"

echo Copying configuration from "%SOURCE%" to "%DEST%"...
xcopy "%SOURCE%" "%DEST%" /E /Y /I

echo Configuration loaded successfully.