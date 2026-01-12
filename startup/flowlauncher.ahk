#Requires AutoHotkey v1.1

WinGetTitle, CurrentWindowTitle, ahk_class Chrome_WidgetWin_1
global start := 0

CheckFlowLauncher() {
    Process, Exist, Flow.Launcher.exe
    return ErrorLevel
}

StartFlowLauncher() {
    Run, "%localappdata%\FlowLauncher\Flow.Launcher.exe"
}

~+LWin::
    Send, {RWin down}
    Send, {RWin up}
return

~LWin::
    if (!start)
        start := A_TickCount
    Send, {Blind}{vkE8}
return

~LWin Up::
    if (A_PriorKey = "LWin" && A_TickCount - start < 500) {
        if (CheckFlowLauncher()) {
            !Space::Send, {Space}
        } else {
            StartFlowLauncher()
        }
    }
    start := 0
return