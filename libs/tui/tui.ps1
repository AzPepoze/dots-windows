# ============================================================================
#  libs\tui\tui.ps1 - Unified TUI Library for PowerShell in dots-windows
#
#  Usage:
#    . "$PSScriptRoot\..\libs\tui\tui.ps1"
# ============================================================================

if ($global:_TUI_PS_LOADED) { return }
$global:_TUI_PS_LOADED = $true

# Enable Windows Virtual Terminal Processing
if (-not ('Win32VT' -as [type])) {
    $win32ConsoleCode = @"
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
        Add-Type -TypeDefinition $win32ConsoleCode -ErrorAction SilentlyContinue
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

# Generate ESC character (char 27)
$ESC = [char]27

if ($env:NO_COLOR) {
    $script:C_RESET   = ""
    $script:C_BOLD    = ""
    $script:C_DIM     = ""
    $script:C_WHITE   = ""
    $script:C_RED     = ""
    $script:C_GREEN   = ""
    $script:C_YELLOW  = ""
    $script:C_BLUE    = ""
    $script:C_MAGENTA = ""
    $script:C_CYAN    = ""
    $script:C_PINK    = ""
    $script:C_PURPLE  = ""
    $script:C_PEACH   = ""
    $script:C_MINT    = ""
    $script:C_SKY     = ""
    $script:C_LAVENDER= ""
    $script:C_LILAC   = ""
    $script:C_LEMON   = ""
} else {
    # 24-bit Pastel ANSI colors matching tui.cmd
    $script:C_RESET   = "$ESC[0m"
    $script:C_BOLD    = "$ESC[1m"
    $script:C_DIM     = "$ESC[38;2;185;185;200m"
    $script:C_WHITE   = "$ESC[38;2;248;248;255m"
    $script:C_RED     = "$ESC[38;2;255;154;162m"
    $script:C_GREEN   = "$ESC[38;2;181;234;215m"
    $script:C_YELLOW  = "$ESC[38;2;255;245;186m"
    $script:C_BLUE    = "$ESC[38;2;160;196;255m"
    $script:C_MAGENTA = "$ESC[38;2;255;175;210m"
    $script:C_CYAN    = "$ESC[38;2;155;246;255m"
    $script:C_PINK    = "$ESC[38;2;255;214;232m"
    $script:C_PURPLE  = "$ESC[38;2;195;177;225m"
    $script:C_PEACH   = "$ESC[38;2;255;223;186m"
    $script:C_MINT    = "$ESC[38;2;202;255;191m"
    $script:C_SKY     = "$ESC[38;2;160;196;255m"
    $script:C_LAVENDER= "$ESC[38;2;216;207;245m"
    $script:C_LILAC   = "$ESC[38;2;224;187;228m"
    $script:C_LEMON   = "$ESC[38;2;255;245;186m"
}

$script:S_OK   = "[OK]"
$script:S_ERR  = "[ERR]"
$script:S_WARN = "[!]"
$script:S_INFO = "[*]"
$script:S_SKIP = "[SKIP]"
$script:S_ARROW= ">>"

function Write-TuiHeader {
    param([string]$Title)
    Write-Host ""
    Write-Host "${script:C_LAVENDER}+==========================================================+${script:C_RESET}"
    Write-Host "${script:C_LAVENDER}|${script:C_RESET}  ${script:C_BOLD}${script:C_PINK}$Title${script:C_RESET}"
    Write-Host "${script:C_LAVENDER}+==========================================================+${script:C_RESET}"
    Write-Host ""
}

function Write-TuiSection {
    param([string]$Title)
    Write-Host ""
    Write-Host "${script:C_LAVENDER}-- ${script:C_PINK}$Title ${script:C_DIM}--------------------------------------------${script:C_RESET}"
    Write-Host ""
}

function Write-TuiSeparator {
    Write-Host "${script:C_DIM}------------------------------------------------------------${script:C_RESET}"
}

function Write-TuiOk   { param([string]$Msg) Write-Host "${script:C_MINT}$($script:S_OK)${script:C_RESET} $Msg" }
function Write-TuiErr  { param([string]$Msg) Write-Host "${script:C_RED}$($script:S_ERR)${script:C_RESET} $Msg" }
function Write-TuiWarn { param([string]$Msg) Write-Host "${script:C_LEMON}$($script:S_WARN)${script:C_RESET} $Msg" }
function Write-TuiInfo { param([string]$Msg) Write-Host "${script:C_SKY}$($script:S_INFO)${script:C_RESET} $Msg" }
function Write-TuiSkip { param([string]$Msg) Write-Host "${script:C_DIM}$($script:S_SKIP)${script:C_RESET} $Msg" }
function Write-TuiDim  { param([string]$Msg) Write-Host "${script:C_DIM}$Msg${script:C_RESET}" }

function Read-TuiConfirm {
    param([string]$Question)
    Write-Host ""
    Write-Host "${script:C_PEACH}$Question${script:C_RESET}"
    Write-Host -NoNewline "  [Y]es / [N]o : "
    
    try {
        while ($true) {
            $k = [Console]::ReadKey($true)
            $c = $k.KeyChar.ToString()
            if ($c -match '^[yYnN]$') {
                Write-Host $c
                return ($c -match '^[yY]$')
            }
        }
    } catch {
        # Fallback for redirected standard input
        $ans = [Console]::ReadLine()
        return ($ans -match '^[yY]')
    }
}

function Wait-TuiPause {
    param([string]$Msg = "Press any key to return...")
    Write-Host ""
    Write-Host "${script:C_DIM}  $Msg${script:C_RESET}"
    try {
        [Console]::ReadKey($true) | Out-Null
    } catch {
        # Redirected input
    }
}

function Invoke-TuiMultiSelect {
    param(
        [string]$Title = "Select Items",
        [System.Collections.ArrayList]$Items,
        [string]$Header = ""
    )

    if (-not $Items -or $Items.Count -eq 0) { return $null }

    $isRedirected = $false
    try {
        $dummy = [Console]::KeyAvailable
    } catch {
        $isRedirected = $true
    }

    if ($isRedirected) {
        Write-TuiInfo "Non-interactive session detected; using default selections."
        return ($Items | Where-Object { -not $_.IsHeader })
    }

    $total = $Items.Count
    $cursorIndex = 0
    while ($cursorIndex -lt $total -and $Items[$cursorIndex].IsHeader) {
        $cursorIndex++
    }

    try {
        [Console]::CursorVisible = $false
    } catch {}

    try {
        function Render-SelectionMenu {
            Clear-Host
            $sb = [System.Text.StringBuilder]::new()

            if ($Header) {
                [void]$sb.AppendLine("")
                [void]$sb.AppendLine("${script:C_LAVENDER}+==========================================================+${script:C_RESET}")
                [void]$sb.AppendLine("${script:C_LAVENDER}|${script:C_RESET}  ${script:C_BOLD}${script:C_PINK}$Header${script:C_RESET}")
                [void]$sb.AppendLine("${script:C_LAVENDER}+==========================================================+${script:C_RESET}")
                [void]$sb.AppendLine("")
            }

            [void]$sb.AppendLine("${script:C_LAVENDER}-- ${script:C_PINK}$Title ${script:C_DIM}--------------------------------------------${script:C_RESET}")
            [void]$sb.AppendLine("")

            for ($i = 0; $i -lt $total; $i++) {
                $it = $Items[$i]
                if ($it.IsHeader) {
                    [void]$sb.AppendLine("  ${script:C_BOLD}${script:C_PEACH}[ $($it.Name) ]${script:C_RESET}")
                } else {
                    $isCurrent = ($i -eq $cursorIndex)
                    $chk = if ($it.Selected) { "${script:C_MINT}[X]${script:C_RESET}" } else { "${script:C_DIM}[ ]${script:C_RESET}" }
                    $pointer = if ($isCurrent) { "${script:C_PINK} >> ${script:C_RESET}" } else { "    " }
                    $nameStyle = if ($isCurrent) { "${script:C_BOLD}${script:C_WHITE}" } else { "${script:C_WHITE}" }
                    $categoryStyle = "${script:C_DIM}"

                    $line = "$pointer$chk $nameStyle$($it.Name)${script:C_RESET} $categoryStyle($($it.Category))${script:C_RESET}"
                    [void]$sb.AppendLine($line)
                }
            }

            [void]$sb.AppendLine("")
            [void]$sb.AppendLine("${script:C_DIM}------------------------------------------------------------${script:C_RESET}")
            [void]$sb.AppendLine("${script:C_DIM}  [Up/Down] Move   [Space] Check/Uncheck   [A] Toggle All   [Enter] Proceed   [Q/Esc] Cancel${script:C_RESET}")

            Write-Host -NoNewline $sb.ToString()
        }

        Render-SelectionMenu
        while ($true) {
            $key = [Console]::ReadKey($true)
            switch ($key.Key) {
                'UpArrow' {
                    do {
                        $cursorIndex = if ($cursorIndex -gt 0) { $cursorIndex - 1 } else { $total - 1 }
                    } while ($Items[$cursorIndex].IsHeader)
                    Render-SelectionMenu
                }
                'DownArrow' {
                    do {
                        $cursorIndex = if ($cursorIndex -lt ($total - 1)) { $cursorIndex + 1 } else { 0 }
                    } while ($Items[$cursorIndex].IsHeader)
                    Render-SelectionMenu
                }
                'Spacebar' {
                    if (-not $Items[$cursorIndex].IsHeader) {
                        $Items[$cursorIndex].Selected = -not $Items[$cursorIndex].Selected
                    }
                    Render-SelectionMenu
                }
                'A' {
                    $selectable = $Items | Where-Object { -not $_.IsHeader }
                    $allSelected = ($selectable | Where-Object { -not $_.Selected }).Count -eq 0
                    foreach ($it in $selectable) { $it.Selected = -not $allSelected }
                    Render-SelectionMenu
                }
                'Enter' {
                    Clear-Host
                    return ($Items | Where-Object { -not $_.IsHeader })
                }
                'Escape' {
                    Clear-Host
                    return $null
                }
                'Q' {
                    Clear-Host
                    return $null
                }
            }
        }
    } finally {
        try { [Console]::CursorVisible = $true } catch {}
    }
}

function Invoke-TuiSingleSelect {
    param(
        [string]$Title = "Select Item",
        [System.Collections.ArrayList]$Items,
        [string]$Header = "",
        [string]$SubTitle = ""
    )

    if (-not $Items -or $Items.Count -eq 0) { return $null }

    $isRedirected = $false
    try {
        $dummy = [Console]::KeyAvailable
    } catch {
        $isRedirected = $true
    }

    if ($isRedirected) {
        Write-TuiInfo "Non-interactive session detected; selecting first item ($($Items[0].Name))."
        return $Items[0]
    }

    $cursorIndex = 0
    $total = $Items.Count

    try {
        [Console]::CursorVisible = $false
    } catch {}

    try {
        function Render-SingleMenu {
            Clear-Host
            $sb = [System.Text.StringBuilder]::new()

            if ($Header) {
                [void]$sb.AppendLine("")
                [void]$sb.AppendLine("${script:C_LAVENDER}+==========================================================+${script:C_RESET}")
                [void]$sb.AppendLine("${script:C_LAVENDER}|${script:C_RESET}  ${script:C_BOLD}${script:C_PINK}$Header${script:C_RESET}")
                [void]$sb.AppendLine("${script:C_LAVENDER}+==========================================================+${script:C_RESET}")
                [void]$sb.AppendLine("")
            }
            if ($SubTitle) {
                [void]$sb.AppendLine("${script:C_DIM}  $SubTitle${script:C_RESET}")
                [void]$sb.AppendLine("")
            }

            [void]$sb.AppendLine("${script:C_LAVENDER}-- ${script:C_PINK}$Title ${script:C_DIM}--------------------------------------------${script:C_RESET}")
            [void]$sb.AppendLine("")

            for ($i = 0; $i -lt $total; $i++) {
                $it = $Items[$i]
                $isCurrent = ($i -eq $cursorIndex)
                $pointer = if ($isCurrent) { "${script:C_PINK} >> ${script:C_RESET}" } else { "    " }
                $nameStyle = if ($isCurrent) { "${script:C_BOLD}${script:C_WHITE}" } else { "${script:C_WHITE}" }
                $descStyle = "${script:C_DIM}"
                $desc = if ($it.Description) { " $descStyle($($it.Description))${script:C_RESET}" } else { "" }

                $line = "$pointer$nameStyle$($it.Name)${script:C_RESET}$desc"
                [void]$sb.AppendLine($line)
            }

            [void]$sb.AppendLine("")
            [void]$sb.AppendLine("${script:C_DIM}------------------------------------------------------------${script:C_RESET}")
            [void]$sb.AppendLine("${script:C_DIM}  [Up/Down] Move   [Enter] Select   [Q/Esc] Cancel${script:C_RESET}")

            Write-Host -NoNewline $sb.ToString()
        }

        Render-SingleMenu
        while ($true) {
            $key = [Console]::ReadKey($true)
            switch ($key.Key) {
                'UpArrow' {
                    $cursorIndex = if ($cursorIndex -gt 0) { $cursorIndex - 1 } else { $total - 1 }
                    Render-SingleMenu
                }
                'DownArrow' {
                    $cursorIndex = if ($cursorIndex -lt ($total - 1)) { $cursorIndex + 1 } else { 0 }
                    Render-SingleMenu
                }
                'Enter' {
                    Clear-Host
                    return $Items[$cursorIndex]
                }
                'Escape' {
                    Clear-Host
                    return $null
                }
                'Q' {
                    Clear-Host
                    return $null
                }
            }
        }
    } finally {
        try { [Console]::CursorVisible = $true } catch {}
    }
}
