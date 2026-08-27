#Requires AutoHotkey v2.0
#SingleInstance Force

#t:: {
    try {
        Run "wt"
    } catch {
        Run "powershell"
    }
}
