@echo off
setlocal
cd /d "%~dp0"

REM -------------------------------------------------------
REM Adds "Open with Code" to the context menu for:
REM   - All files
REM   - Folders
REM   - Folder background
REM Must be run as Administrator.
REM -------------------------------------------------------

net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Administrator privileges required.
    echo [*] Requesting elevation...
    powershell -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

REM -------------------------------------------------------
REM Locate VS Code executable
REM -------------------------------------------------------
set "CODE_EXE="

if exist "%ProgramFiles%\Microsoft VS Code\Code.exe" (
    set "CODE_EXE=%ProgramFiles%\Microsoft VS Code\Code.exe"
) else if exist "%ProgramFiles(x86)%\Microsoft VS Code\Code.exe" (
    set "CODE_EXE=%ProgramFiles(x86)%\Microsoft VS Code\Code.exe"
) else if exist "%LOCALAPPDATA%\Programs\Microsoft VS Code\Code.exe" (
    set "CODE_EXE=%LOCALAPPDATA%\Programs\Microsoft VS Code\Code.exe"
)

if not defined CODE_EXE (
    echo [ERROR] VS Code not found in default install locations.
    pause
    exit /b 1
)

echo [OK] Found VS Code: "%CODE_EXE%"
echo.

REM -------------------------------------------------------
REM Add registry entries
REM -------------------------------------------------------

REM --- All files ---
reg add "HKCR\*\shell\Open with Code" /ve /d "Open with Code" /f >nul
reg add "HKCR\*\shell\Open with Code" /v "Icon" /d "%CODE_EXE%,0" /f >nul
reg add "HKCR\*\shell\Open with Code\command" /ve /d "\"%CODE_EXE%\" \"%%1\"" /f >nul

REM --- Folders ---
reg add "HKCR\Directory\shell\Open with Code" /ve /d "Open with Code" /f >nul
reg add "HKCR\Directory\shell\Open with Code" /v "Icon" /d "%CODE_EXE%,0" /f >nul
reg add "HKCR\Directory\shell\Open with Code\command" /ve /d "\"%CODE_EXE%\" \"%%1\"" /f >nul

REM --- Folder background ---
reg add "HKCR\Directory\Background\shell\Open with Code" /ve /d "Open with Code" /f >nul
reg add "HKCR\Directory\Background\shell\Open with Code" /v "Icon" /d "%CODE_EXE%,0" /f >nul
reg add "HKCR\Directory\Background\shell\Open with Code\command" /ve /d "\"%CODE_EXE%\" \"%%V\"" /f >nul

if %errorlevel% equ 0 (
    echo [SUCCESS] "Open with Code" added to context menu.
) else (
    echo [ERROR] Failed to write registry entries.
)

echo.
pause
endlocal
