#Requires AutoHotkey v2.0
#SingleInstance Force
;#WinActivateForce
;#UseHook

/*
------------------------------------------------------
Script Initialization & DLL Loading
-------------------------------------------------------
*/

; --- Configuration ---
VDA_PATH := A_ScriptDir "\VirtualDesktopAccessor.dll"
CONFIG_PATH := A_ScriptDir "\config.ini"
ICON_FOLDER := A_ScriptDir "\icons"

; --- Load DLL ---
hVirtualDesktopAccessor := DllCall("LoadLibrary", "Str", VDA_PATH, "Ptr")
if (!hVirtualDesktopAccessor)
{
    MsgBox("Could not load VirtualDesktopAccessor.dll.`n`nPath Tried: " VDA_PATH, "VirtualDesktopAccessor Error", 0x10)
    ExitApp
}

/*
------------------------------------------------------
Helper Function for GetProcAddress
-------------------------------------------------------
*/
_GetProc(FuncName)
{
    ProcAddr := DllCall("GetProcAddress", "Ptr", hVirtualDesktopAccessor, "AStr", FuncName, "Ptr")
    if (!ProcAddr) {
        MsgBox('Could not find function "' FuncName '" in the DLL.`nPath: ' VDA_PATH, "VirtualDesktopAccessor Error", 0x10)
        DllCall("FreeLibrary", "Ptr", hVirtualDesktopAccessor)
        ExitApp
    }
    Return ProcAddr
}

GetOptionalProc(FuncName)
{
    Return DllCall("GetProcAddress", "Ptr", hVirtualDesktopAccessor, "AStr", FuncName, "Ptr")
}

/*
------------------------------------------------------
Get Function Addresses via Helper
-------------------------------------------------------
*/
; --- Core Desktop Functions ---
GoToDesktopNumberProc         := _GetProc("GoToDesktopNumber")
GetCurrentDesktopNumberProc   := _GetProc("GetCurrentDesktopNumber")
GetDesktopCountProc           := _GetProc("GetDesktopCount")
CreateDesktopProc             := _GetProc("CreateDesktop")
MoveWindowToDesktopNumberProc := _GetProc("MoveWindowToDesktopNumber")

; --- Pinning Functions ---
PinWindowProc                 := GetOptionalProc("PinWindow")
UnPinWindowProc               := GetOptionalProc("UnPinWindow")
IsPinnedWindowProc            := GetOptionalProc("IsPinnedWindow")

PinningFunctionsAvailable := (PinWindowProc && UnPinWindowProc && IsPinnedWindowProc)

/*
-------------------------------------------------------
Load Hotkey Configuration from INI
-------------------------------------------------------
*/
BaseSwitchModifiers := IniRead(CONFIG_PATH, "Hotkeys", "SwitchWorkspace", "")
BaseMoveModifiers   := IniRead(CONFIG_PATH, "Hotkeys", "MoveToWorkspace", "")
PinHotkeyRaw        := IniRead(CONFIG_PATH, "Hotkeys", "PinToAllWorkspace", "")

; --- Translate Modifiers to AHK Symbols ---
SwitchModifiersAHK := TranslateModifiers(BaseSwitchModifiers)
MoveModifiersAHK   := TranslateModifiers(BaseMoveModifiers)
PinHotkeyAHK       := TranslateModifiers(PinHotkeyRaw)

/*
-------------------------------------------------------
Dynamic Hotkey Assignment (Loop & Pin)
-------------------------------------------------------
*/
; --- Workspace Hotkeys ---
Loop 9
{
    CurrentIndex := A_Index
    WorkspaceKeyIni := "Worspace" CurrentIndex
    WorkspaceKey := IniRead(CONFIG_PATH, "WorkspaceNumbers", WorkspaceKeyIni, "")

    if (WorkspaceKey = "") {
        Continue
    }

    if (SwitchModifiersAHK != "") {
        Hotkey(SwitchModifiersAHK WorkspaceKey, SwitchToDesktopHotkey.Bind(CurrentIndex))
    }
    if (MoveModifiersAHK != "") {
        Hotkey(MoveModifiersAHK WorkspaceKey, MoveWindowHotkey.Bind(CurrentIndex))
    }
}

; --- Pin Hotkey ---
if (PinHotkeyAHK != "" && PinHotkeyRaw != "")
{
    if (PinningFunctionsAvailable) {
        Hotkey(PinHotkeyAHK, (*) => TogglePinActiveWindow())
    } else {
        MsgBox("PinToAllWorkspace hotkey found (" PinHotkeyRaw "), but required pinning functions were not found in the DLL. This hotkey will be disabled.", "Config Warning", 0x30)
    }
}

/*
-------------------------------------------------------
Initial Setup
-------------------------------------------------------
*/
UpdateTrayIcon(_GetCurrentDesktopNumber())

/*
-------------------------------------------------------
Hotkey Wrappers (absorb the extra hotkey argument)
-------------------------------------------------------
*/
SwitchToDesktopHotkey(n, *) => SwitchToDesktop(n)
MoveWindowHotkey(n, *) => MoveActiveWindowToDesktopAndFollow(n)

/*
-------------------------------------------------------
Core Helper Functions
-------------------------------------------------------
*/
GetCurrentWindowID()
{
    Return WinExist("A")
}

CallWindowManagementFunc(ProcAddress, hWnd)
{
    Return DllCall(ProcAddress, "Ptr", hWnd, "Int")
}

_GetCurrentDesktopNumber()
{
    Return DllCall(GetCurrentDesktopNumberProc, "Int") + 1
}

UpdateTrayIcon(DesktopNumber)
{
    NumberedIconPath := ICON_FOLDER "\" DesktopNumber ".ico"

    if (FileExist(NumberedIconPath)) {
        TraySetIcon(NumberedIconPath)
    } else {
        TraySetIcon()
    }
}


/*
-------------------------------------------------------
Main Logic Functions
-------------------------------------------------------
*/
SwitchToDesktop(TargetDesktopNumber)
{
    TargetDesktopIndex := TargetDesktopNumber - 1
    if (TargetDesktopIndex < 0)
        return
    EnsureDesktopExists(TargetDesktopIndex)
    DllCall(GoToDesktopNumberProc, "Int", TargetDesktopIndex, "Int")
    UpdateTrayIcon(TargetDesktopNumber)
    return
}

MoveActiveWindowToDesktopAndFollow(TargetDesktopNumber)
{
    activeHwnd := GetCurrentWindowID()
    if (!activeHwnd)
        return
    TargetDesktopIndex := TargetDesktopNumber - 1
    if (TargetDesktopIndex < 0)
        return
    EnsureDesktopExists(TargetDesktopIndex)
    DllCall(MoveWindowToDesktopNumberProc, "Ptr", activeHwnd, "Int", TargetDesktopIndex, "Int")
    DllCall(GoToDesktopNumberProc, "Int", TargetDesktopIndex, "Int")
    UpdateTrayIcon(TargetDesktopNumber)
    return
}

EnsureDesktopExists(TargetDesktopIndex)
{
    DesktopCount := DllCall(GetDesktopCountProc, "Int")
    if (TargetDesktopIndex >= DesktopCount)
    {
        NumDesktopsToCreate := TargetDesktopIndex - DesktopCount + 1
        Loop NumDesktopsToCreate
        {
            DllCall(CreateDesktopProc, "Int")
            Sleep(50)
        }
        Sleep(100)
    }
}

TogglePinActiveWindow()
{
    if (!PinningFunctionsAvailable)
        return

    activeHwnd := GetCurrentWindowID()
    if (!activeHwnd)
        return

    IsPinned := CallWindowManagementFunc(IsPinnedWindowProc, activeHwnd)

    if (IsPinned) {
        CallWindowManagementFunc(UnPinWindowProc, activeHwnd)
        ToolTip("Window Unpinned")
        SetTimer(RemoveToolTip, -1500)
    } else {
        CallWindowManagementFunc(PinWindowProc, activeHwnd)
        ToolTip("Window Pinned")
        SetTimer(RemoveToolTip, -1500)
    }
}

RemoveToolTip()
{
    ToolTip()
}

TranslateModifiers(ModifierString)
{
    Output := RegExReplace(ModifierString, "i)\s*,\s*", "")
    Output := StrReplace(Output, "LALT", "!")
    Output := StrReplace(Output, "RALT", ">!")
    Output := StrReplace(Output, "ALT", "!")
    Output := StrReplace(Output, "LSHIFT", "+")
    Output := StrReplace(Output, "RSHIFT", "<+")
    Output := StrReplace(Output, "SHIFT", "+")
    Output := StrReplace(Output, "LCTRL", "^")
    Output := StrReplace(Output, "RCTRL", ">^")
    Output := StrReplace(Output, "CTRL", "^")
    Output := StrReplace(Output, "LWIN", "#")
    Output := StrReplace(Output, "RWIN", ">#")
    Output := StrReplace(Output, "WIN", "#")
    Return Output
}

/*
-------------------------------------------------------
Script Exit Handling
-------------------------------------------------------
*/
OnExit(Cleanup)

Cleanup(ExitReason, ExitCode)
{
    if (hVirtualDesktopAccessor) {
        DllCall("FreeLibrary", "Ptr", hVirtualDesktopAccessor)
    }
}
