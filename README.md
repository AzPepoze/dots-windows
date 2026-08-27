# Dots-Windows

Personal Windows configuration files, package installer, and dotfile manager.

---

## Quick Start (One-Liner Install)

Open **PowerShell** and run:

```powershell
irm https://raw.githubusercontent.com/AzPepoze/dots-windows/main/bootstrap.ps1 | iex
```

### What this does automatically:

1. Detects **Git** (downloads and runs the official Git for Windows installer if missing).
2. Clones the repository directly to **`C:\dots-windows`**.
3. Auto-installs **Scoop** if missing.
4. Launches the interactive **Dots-Windows Main Menu**.

> [!IMPORTANT]
> Installed at **`C:\dots-windows`**. Always run your commands and updates from this folder.

---

## Manual Installation

If you prefer to clone manually:

1. **Clone directly to `C:\dots-windows`:**

     ```powershell
     git clone https://github.com/AzPepoze/dots-windows.git C:\dots-windows
     cd C:\dots-windows
     ```

2. **Launch the Main Menu:**
     - **From PowerShell / Windows Terminal:**
          ```powershell
          cd C:\dots-windows
          .\main.ps1
          ```
     - **From Command Prompt (CMD):**
          ```cmd
          cd /d C:\dots-windows
          main
          ```
     - **From File Explorer:**
       Open `C:\dots-windows` and double-click `main.cmd`

---

## Updating & Further Use

For any future maintenance, navigate to `C:\dots-windows` and run:

- **PowerShell:**
     ```powershell
     cd C:\dots-windows
     .\update.ps1
     ```
- **Command Prompt (CMD):**
     ```cmd
     cd /d C:\dots-windows
     update
     ```

---

## Project Structure

```
C:\dots-windows/
├── bootstrap.ps1                     # Remote 1-liner installer (irm ... | iex)
├── main.ps1                          # Interactive Main Menu
├── main.cmd                          # 1-line wrapper -> main.ps1
├── update.ps1                        # Git pull + config reload
├── update.cmd                        # 1-line wrapper -> update.ps1
├── libs/
│   ├── tui/
│   │   └── tui.ps1                   # Shared TUI styling & interactive menus
│   └── blur_explorer/
│       ├── register.ps1              # Register ExplorerBlurMica DLL
│       └── uninstall.ps1             # Unregister ExplorerBlurMica DLL
├── scripts/
│   ├── run.ps1                       # Master setup orchestrator
│   ├── install.ps1                   # Interactive checkbox package installer
│   ├── load-config.ps1               # Syncs dotfiles, Terminal settings, wallpaper
│   ├── startup.ps1                   # Startup tasks & logon scheduled task
│   └── set-wallpaper.ps1             # Wallpaper applicator (Win32 API)
├── utils/
│   └── add-vscode-context-menu.ps1   # VS Code context menu integration
├── cursors/
│   └── apply-cursor.ps1              # Interactive cursor scheme picker
└── startup/
    ├── terminal.ahk                  # AutoHotkey startup shortcuts
    ├── win_search.ahk
    └── windows_workspace_shortcut.lnk
```

---

## Acknowledgements

- [ExplorerBlurMica](https://github.com/Maplespe/ExplorerBlurMica)
- [Chris Titus Tech Windows Utility](https://github.com/ChrisTitusTech/winutil)
- [Scoop Package Manager](https://scoop.sh/)
