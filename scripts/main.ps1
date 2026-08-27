# ============================================================================
#  scripts\main.ps1 - Main Interactive Menu for Dots-Windows
# ============================================================================
. "$PSScriptRoot\..\libs\tui\tui.ps1"

function Show-MainMenu {
    while ($true) {
        $menuItems = [System.Collections.ArrayList]@(
            [PSCustomObject]@{ Id = "install"; Name = "Install dots"; Description = "pull + interactive install + load config" }
            [PSCustomObject]@{ Id = "update";  Name = "Update dots";  Description = "git pull + sync dotfiles" }
            [PSCustomObject]@{ Id = "cursor";  Name = "Install Cursor Scheme"; Description = "interactive cursor pack picker" }
            [PSCustomObject]@{ Id = "ctt";     Name = "Chris Titus Windows Utility"; Description = "irm https://christitus.com/win | iex" }
            [PSCustomObject]@{ Id = "help";    Name = "Help";         Description = "view documentation & keybindings" }
            [PSCustomObject]@{ Id = "exit";    Name = "Exit";         Description = "close this menu" }
        )

        $choice = Invoke-TuiSingleSelect -Title "Main Menu" -Items $menuItems -Header "Dots-Windows -- AzPepoze Dotfiles" -SubTitle "Manage dotfiles, package installations, cursors, and startup tasks."

        if ($null -eq $choice -or $choice.Id -eq "exit") {
            Write-TuiOk "Goodbye!"
            break
        }

        switch ($choice.Id) {
            "install" {
                Clear-Host
                Write-TuiHeader "Install Dots"
                Write-TuiInfo "Pulling latest changes..."
                Write-TuiSeparator
                git pull
                Write-Host ""
                & "$PSScriptRoot\run.ps1"
                Wait-TuiPause "Press any key to return to the main menu..."
            }
            "update" {
                Clear-Host
                & "$PSScriptRoot\update.ps1"
                Wait-TuiPause "Press any key to return to the main menu..."
            }
            "cursor" {
                Clear-Host
                & "$PSScriptRoot\..\cursors\apply-cursor.ps1"
                Wait-TuiPause "Press any key to return to the main menu..."
            }
            "ctt" {
                Clear-Host
                Write-TuiHeader "Chris Titus Tech Windows Utility"
                Write-TuiInfo "Launching CTT Windows Utility..."
                Write-TuiDim "  Command: irm https://christitus.com/win | iex"
                Write-Host ""
                powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "irm https://christitus.com/win | iex"
                Wait-TuiPause "Press any key to return to the main menu..."
            }
            "help" {
                Clear-Host
                Write-TuiHeader "Help & Documentation -- Dots-Windows"
                Write-Host "$script:C_BOLD$script:C_PINK Navigation:$script:C_RESET"
                Write-Host "  $script:C_DIM Use the [Up/Down] arrow keys to navigate and press [Enter] to select.$script:C_RESET"
                Write-Host "  $script:C_DIM In multi-select menus, press [Space] to check/uncheck and [A] to toggle all.$script:C_RESET"
                Write-Host ""
                Write-Host "$script:C_BOLD$script:C_PINK Structure:$script:C_RESET"
                Write-Host "  $script:C_WHITE dots/user$script:C_RESET     $script:C_DIM -> Copied to $env:USERPROFILE (Windows Terminal, PowerShell profile)$script:C_RESET"
                Write-Host "  $script:C_WHITE libs/tui/$script:C_RESET     $script:C_DIM -> Shared TUI formatting and selection menus$script:C_RESET"
                Write-Host "  $script:C_WHITE scripts/$script:C_RESET      $script:C_DIM -> Pure operational logic (install, config sync, startup runner)$script:C_RESET"
                Write-Host "  $script:C_WHITE cursors/$script:C_RESET      $script:C_DIM -> Custom cursor schemes (keqing, etc.)$script:C_RESET"
                Write-Host "  $script:C_WHITE startup/$script:C_RESET      $script:C_DIM -> AutoHotkey scripts and startup task shortcuts$script:C_RESET"
                Write-Host ""
                Wait-TuiPause "Press any key to return to the main menu..."
            }
        }
    }
}

Show-MainMenu
