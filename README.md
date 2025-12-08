# Windows Dotfiles

This repository contains my personal configuration files (dotfiles).

**Note:** This setup is tailored specifically for my workflow. If you wish to use or modify it, please **fork this repository**.

## Installation & Usage

Ensure you have the following software installed:

- Git
- AutoHotkey
- Komorebi
- YASB
- Flow Launcher (optional, for `ToggleFlowlauncher.ahk`)

### Setup

1. **Clone the repository:**
   ```powershell

   ```

git clone <repository_url> C:\dots-windows
cd C:\dots-windows

```

2. **Run the installation script:**
   Double-click **`main.cmd`** or run it from the terminal:
   ```powershell
.\main.cmd
```

   **What `main.cmd` does:**

1. Pulls the latest changes from the git repository.
2. Executes `scripts/run.cmd`, which calls `scripts/load_config.cmd`.
3. **Copies** configuration files from `dots/user/` directly to your `%USERPROFILE%` directory.

> **⚠️ Warning:** This will overwrite existing `komorebi.json` and `.config/yasb` files in your user profile. Back up your existing configs before running!

## File Structure

```text
C:\dots-windows\
├── main.cmd                  # Main entry point (Update + Install)
├── ahk/                      # AutoHotkey Utilities
│   ├── ToggleFlowlauncher.ahk
│   ├── ToggleTaskbar.ahk
│   └── WindowsWorkspaceShortcut/ # Virtual Desktop Management
├── dots/
│   └── user/                 # Config files deployed to %USERPROFILE%
│       ├── komorebi.json     # Komorebi Configuration
│       ├── komorebi.bar.json
│       └── .config/
│           └── yasb/         # YASB Configuration
└── scripts/                  # Helper batch scripts
    ├── load_config.cmd       # Copies configs to User Profile
    └── run.cmd               # Wrapper for load_config
```

## Customization

To modify the configurations, edit the files in `dots/user/` and run `main.cmd` again to apply the changes to your user profile.


