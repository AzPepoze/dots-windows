#Requires AutoHotkey v2.0

#t:: {
    try {
        Run "wt"
    } catch {
        Run "powershell"
    }
}
