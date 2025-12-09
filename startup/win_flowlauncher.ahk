global start := 0

CheckFlowLauncher() {
    Process, Exist, Flow.Launcher.exe
    return ErrorLevel
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
    if (A_PriorKey = "LWin" && A_TickCount - start < 500 && CheckFlowLauncher()) {
         Send, ^!{Space}
    }
    start := 0
return