# ============================================================================
#  bootstrap.ps1 - Zero-Touch Remote Installer for Dots-Windows
#
#  Usage:
#    irm https://raw.githubusercontent.com/AzPepoze/dots-windows/main/scripts/bootstrap.ps1 | iex
# ============================================================================

$ErrorActionPreference = "Continue"

# 1. Ensure Execution Policy & Virtual Terminal Processing
try {
    Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force -ErrorAction SilentlyContinue
} catch {}

if (-not ('Win32VT' -as [type])) {
    $vtCode = @"
using System;
using System.Runtime.InteropServices;

public class Win32VT {
    private const int STD_OUTPUT_HANDLE = -11;
    private const uint ENABLE_VIRTUAL_TERMINAL_PROCESSING = 0x0004;

    [DllImport("kernel32.dll", SetLastError = true)]
    private static extern IntPtr GetStdHandle(int nStdHandle);

    [DllImport("kernel32.dll", SetLastError = true)]
    private static extern bool GetConsoleMode(IntPtr hConsoleHandle, out uint lpMode);

    [DllImport("kernel32.dll", SetLastError = true)]
    private static extern bool SetConsoleMode(IntPtr hConsoleHandle, uint dwMode);

    [DllImport("kernel32.dll", CharSet = CharSet.Auto, SetLastError = true)]
    private static extern IntPtr CreateFile(
        string lpFileName,
        uint dwDesiredAccess,
        uint dwShareMode,
        IntPtr lpSecurityAttributes,
        uint dwCreationDisposition,
        uint dwFlagsAndAttributes,
        IntPtr hTemplateFile);

    public static void EnableVT() {
        try {
            uint mode = 0;
            IntPtr hConOut = CreateFile("CONOUT$", 0x40000000 | 0x80000000, 2, IntPtr.Zero, 3, 0, IntPtr.Zero);
            if (hConOut != (IntPtr)(-1)) {
                if (GetConsoleMode(hConOut, out mode)) {
                    SetConsoleMode(hConOut, mode | ENABLE_VIRTUAL_TERMINAL_PROCESSING);
                }
            }
            IntPtr hOut = GetStdHandle(STD_OUTPUT_HANDLE);
            if (GetConsoleMode(hOut, out mode)) {
                SetConsoleMode(hOut, mode | ENABLE_VIRTUAL_TERMINAL_PROCESSING);
            }
        } catch {}
    }
}
"@
    try {
        Add-Type -TypeDefinition $vtCode -ErrorAction SilentlyContinue
    } catch {}
}

if ('Win32VT' -as [type]) {
    try { [Win32VT]::EnableVT() } catch {}
}

try {
    if (-not (Test-Path "HKCU:\Console")) {
        New-Item -Path "HKCU:\Console" -Force | Out-Null
    }
    Set-ItemProperty -Path "HKCU:\Console" -Name "VirtualTerminalLevel" -Value 1 -Type DWord -ErrorAction SilentlyContinue
} catch {}

# ANSI Colors
$ESC = [char]27
$C_RESET   = "$ESC[0m"
$C_BOLD    = "$ESC[1m"
$C_DIM     = "$ESC[38;2;185;185;200m"
$C_WHITE   = "$ESC[38;2;248;248;255m"
$C_RED     = "$ESC[38;2;255;154;162m"
$C_GREEN   = "$ESC[38;2;181;234;215m"
$C_PINK    = "$ESC[38;2;255;214;232m"
$C_SKY     = "$ESC[38;2;160;196;255m"
$C_LAVENDER= "$ESC[38;2;216;207;245m"

Clear-Host
Write-Host ""
Write-Host "${C_LAVENDER}+==========================================================+${C_RESET}"
Write-Host "${C_LAVENDER}|${C_RESET}  ${C_BOLD}${C_PINK}Dots-Windows -- Bootstrap Installer${C_RESET}"
Write-Host "${C_LAVENDER}+==========================================================+${C_RESET}"
Write-Host ""

# ==============================================================================
# 2. Check and Install Git if missing
# ==============================================================================
Write-Host "${C_SKY}[*]${C_RESET} Checking for Git..."

$gitInstalled = [bool](Get-Command git -ErrorAction SilentlyContinue)

if (-not $gitInstalled) {
    # Check standard installation paths before downloading
    $standardGitPaths = @(
        "$env:ProgramFiles\Git\cmd\git.exe",
        "${env:ProgramFiles(x86)}\Git\cmd\git.exe",
        "$env:LOCALAPPDATA\Programs\Git\cmd\git.exe"
    )
    $foundGit = $standardGitPaths | Where-Object { Test-Path $_ } | Select-Object -First 1

    if ($foundGit) {
        $gitDir = Split-Path (Split-Path $foundGit)
        $env:PATH = "$gitDir\cmd;$gitDir\bin;$env:PATH"
        $gitInstalled = $true
        Write-Host "${C_GREEN}[OK]${C_RESET} Found existing Git at $foundGit"
    } else {
        Write-Host "${C_SKY}[*]${C_RESET} Git not detected. Downloading latest Git for Windows installer..."
        $gitUrl = "https://github.com/git-for-windows/git/releases/latest/download/Git-64-bit.exe"
        $installerPath = "$env:TEMP\GitSetup.exe"

        $hasCurl = [bool](Get-Command curl.exe -ErrorAction SilentlyContinue)
        if ($hasCurl) {
            curl.exe -L -# -o $installerPath $gitUrl
        } else {
            Invoke-WebRequest -Uri $gitUrl -OutFile $installerPath
        }

        if (Test-Path $installerPath) {
            Write-Host "${C_GREEN}[OK]${C_RESET} Downloaded Git setup -- starting installer..."
            Write-Host "${C_DIM}  Please complete the Git installation wizard.${C_RESET}"
            Start-Process -FilePath $installerPath -Wait

            # Refresh PATH
            $env:PATH = "C:\Program Files\Git\cmd;C:\Program Files\Git\bin;$env:PATH"
            Remove-Item -Path $installerPath -Force -ErrorAction SilentlyContinue

            if (Get-Command git -ErrorAction SilentlyContinue) {
                Write-Host "${C_GREEN}[OK]${C_RESET} Git is ready!"
            } else {
                Write-Host "${C_RED}[ERR]${C_RESET} Git was not detected in PATH after installation."
                Write-Host "${C_DIM}  Please restart your terminal and re-run the bootstrap script.${C_RESET}"
                exit 1
            }
        } else {
            Write-Host "${C_RED}[ERR]${C_RESET} Failed to download Git installer from $gitUrl"
            exit 1
        }
    }
} else {
    Write-Host "${C_GREEN}[OK]${C_RESET} Git is already installed"
}

# ==============================================================================
# 3. Clone / Update Repository at C:\dots-windows
# ==============================================================================
$targetDir = "C:\dots-windows"
$repoUrl = "https://github.com/AzPepoze/dots-windows.git"

Write-Host ""
if (-not (Test-Path $targetDir)) {
    Write-Host "${C_SKY}[*]${C_RESET} Cloning repository into ${C_WHITE}$targetDir${C_RESET}..."
    git clone $repoUrl $targetDir
    if ($LASTEXITCODE -ne 0) {
        Write-Host "${C_RED}[ERR]${C_RESET} Failed to clone repository."
        exit 1
    }
    Write-Host "${C_GREEN}[OK]${C_RESET} Repository cloned successfully"
} else {
    Write-Host "${C_SKY}[*]${C_RESET} Found existing directory at ${C_WHITE}$targetDir${C_RESET} -- pulling latest changes..."
    Push-Location $targetDir
    git pull
    Pop-Location
    Write-Host "${C_GREEN}[OK]${C_RESET} Repository updated"
}

# ==============================================================================
# 4. Launch Main Menu
# ==============================================================================
Write-Host ""
Write-Host "${C_BOLD}${C_PINK}Installed to:${C_RESET} ${C_WHITE}C:\dots-windows${C_RESET} ${C_DIM}(run future updates from here)${C_RESET}"
Write-Host ""
Write-Host "${C_GREEN}[OK]${C_RESET} Launching Main Menu..."
Start-Sleep -Seconds 1

Set-Location $targetDir
& "$targetDir\scripts\main.ps1"
