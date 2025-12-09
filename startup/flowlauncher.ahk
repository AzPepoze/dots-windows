global start := 0

CheckFlowLauncher() {
    Process, Exist, Flow.Launcher.exe
    return ErrorLevel
}

StartFlowLauncher() {
    exePath := A_LocalAppData . "\FlowLauncher\Flow.Launcher.exe"
    if (FileExist(exePath)) {
        Run, %exePath%
    } else {
        Run, Flow.Launcher.exe
    }
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
             Send, ^!{Space}
        } else {
             StartFlowLauncher()
        }
    }
    start := 0
return