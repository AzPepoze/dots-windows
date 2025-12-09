@echo off
echo.
echo #############################
echo LOADING CONFIG
echo #############################
echo.
set "SOURCE=%~dp0..\dots\user"
set "SOURCE_TERMINAL_SETTINGS=%SOURCE%\AppData\Local\Packages\Microsoft.WindowsTerminal\LocalState\settings.json"
set "DEST=%USERPROFILE%"

echo Copying configuration from "%SOURCE%" to "%DEST%"...
xcopy "%SOURCE%" "%DEST%" /E /Y /I

echo.

echo #############################
echo LOADING TERMINAL CONFIG
echo #############################
echo.

set "TARGET_TERMINAL_DIR="
for /d %%D in ("%DEST%\AppData\Local\Packages\Microsoft.WindowsTerminal_*") do (
    set "TARGET_TERMINAL_DIR=%%D"
    goto :FoundTerminal
)

:FoundTerminal
if defined TARGET_TERMINAL_DIR (
    echo Found Windows Terminal at: "%TARGET_TERMINAL_DIR%"
	echo "%SOURCE_TERMINAL_SETTINGS%"
    
    if exist "%SOURCE_TERMINAL_SETTINGS%" (
        echo Copying settings.json...
        if not exist "%TARGET_TERMINAL_DIR%\LocalState" mkdir "%TARGET_TERMINAL_DIR%\LocalState"
        copy /Y "%SOURCE_TERMINAL_SETTINGS%" "%TARGET_TERMINAL_DIR%\LocalState\settings.json"
    ) else (
        echo Source settings.json not found at "%SOURCE_TERMINAL_SETTINGS%"
    )
) else (
    echo Windows Terminal installation directory not found in "%DEST%\AppData\Local\Packages\"
)

echo.
echo Configuration loaded successfully.
