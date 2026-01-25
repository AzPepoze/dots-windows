/*
------------------------------------------------------
Script Initialization & DLL Loading
-------------------------------------------------------
*/
#SingleInstance, Force
;#WinActivateForce
;#UseHook

; --- Configuration ---
VDA_PATH := A_ScriptDir . "\VirtualDesktopAccessor.dll"
CONFIG_PATH := A_ScriptDir . "\config.ini"
ICON_FOLDER := A_ScriptDir . "\icons"

; --- Load DLL ---
global hVirtualDesktopAccessor := DllCall("LoadLibrary", "Str", VDA_PATH, "Ptr")
if (!hVirtualDesktopAccessor)
{
    MsgBox, 0x10, VirtualDesktopAccessor Error, Could not load VirtualDesktopAccessor.dll.`n`nPath Tried: %VDA_PATH%
    ExitApp
}

/*
------------------------------------------------------
Helper Function for GetProcAddress
-------------------------------------------------------
*/
_GetProc(FuncName)
{
    global hVirtualDesktopAccessor
    ProcAddr := DllCall("GetProcAddress", "Ptr", hVirtualDesktopAccessor, "AStr", FuncName, "Ptr")
    if (!ProcAddr) {
        MsgBox, 0x10, VirtualDesktopAccessor Error, Could not find function "%FuncName%" in the DLL.`nPath: %VDA_PATH%
        DllCall("FreeLibrary", "Ptr", hVirtualDesktopAccessor)
        ExitApp
    }
    Return ProcAddr
}

GetOptionalProc(FuncName)
{
    global hVirtualDesktopAccessor
    Return DllCall("GetProcAddress", "Ptr", hVirtualDesktopAccessor, "AStr", FuncName, "Ptr")
}

/*
------------------------------------------------------
Get Function Addresses via Helper
-------------------------------------------------------
*/
; --- Core Desktop Functions ---
global GoToDesktopNumberProc         := _GetProc("GoToDesktopNumber")
global GetCurrentDesktopNumberProc   := _GetProc("GetCurrentDesktopNumber")
global GetDesktopCountProc           := _GetProc("GetDesktopCount")
global CreateDesktopProc             := _GetProc("CreateDesktop")
global MoveWindowToDesktopNumberProc := _GetProc("MoveWindowToDesktopNumber")

; --- Pinning Functions ---
global PinWindowProc                 := GetOptionalProc("PinWindow")
global UnPinWindowProc               := GetOptionalProc("UnPinWindow")
global IsPinnedWindowProc            := GetOptionalProc("IsPinnedWindow")

global PinningFunctionsAvailable := (PinWindowProc && UnPinWindowProc && IsPinnedWindowProc)

/*
-------------------------------------------------------
Load Hotkey Configuration from INI
-------------------------------------------------------
*/
IniRead, BaseSwitchModifiers, %CONFIG_PATH%, Hotkeys, SwitchWorkspace
IniRead, BaseMoveModifiers, %CONFIG_PATH%, Hotkeys, MoveToWorkspace
IniRead, PinHotkeyRaw, %CONFIG_PATH%, Hotkeys, PinToAllWorkspace

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
Loop, 9
{
    CurrentIndex := A_Index
    WorkspaceKeyIni := "Worspace" . CurrentIndex
    IniRead, WorkspaceKey, %CONFIG_PATH%, WorkspaceNumbers, %WorkspaceKeyIni%

    if (WorkspaceKey = "" || WorkspaceKey = "ERROR") {
        Continue
    }

    if (SwitchModifiersAHK != "") {
        Hotkey, % SwitchModifiersAHK . WorkspaceKey, % "SwitchToDesktop_" . CurrentIndex . "_Label"
    }
    if (MoveModifiersAHK != "") {
        Hotkey, % MoveModifiersAHK . WorkspaceKey, % "MoveWindow_" . CurrentIndex . "_Label"
    }
}

; --- Pin Hotkey ---
if (PinHotkeyAHK != "" && PinHotkeyRaw != "ERROR")
{
    if (PinningFunctionsAvailable) {
        Hotkey, %PinHotkeyAHK%, PinWindow_Label
    } else {
        MsgBox, 0x30, Config Warning, PinToAllWorkspace hotkey found (%PinHotkeyRaw%), but required pinning functions were not found in the DLL. This hotkey will be disabled.
    }
}

/*
-------------------------------------------------------
Initial Setup
-------------------------------------------------------
*/
UpdateTrayIcon(_GetCurrentDesktopNumber())

Return

/*
-------------------------------------------------------
Hotkey Labels
-------------------------------------------------------
*/
SwitchToDesktop_1_Label:
    SwitchToDesktop(1)
Return
SwitchToDesktop_2_Label:
    SwitchToDesktop(2)
Return
SwitchToDesktop_3_Label:
    SwitchToDesktop(3)
Return
SwitchToDesktop_4_Label:
    SwitchToDesktop(4)
Return
SwitchToDesktop_5_Label:
    SwitchToDesktop(5)
Return
SwitchToDesktop_6_Label:
    SwitchToDesktop(6)
Return
SwitchToDesktop_7_Label:
    SwitchToDesktop(7)
Return
SwitchToDesktop_8_Label:
    SwitchToDesktop(8)
Return
SwitchToDesktop_9_Label:
    SwitchToDesktop(9)
Return

MoveWindow_1_Label:
    MoveActiveWindowToDesktopAndFollow(1)
Return
MoveWindow_2_Label:
    MoveActiveWindowToDesktopAndFollow(2)
Return
MoveWindow_3_Label:
    MoveActiveWindowToDesktopAndFollow(3)
Return
MoveWindow_4_Label:
    MoveActiveWindowToDesktopAndFollow(4)
Return
MoveWindow_5_Label:
    MoveActiveWindowToDesktopAndFollow(5)
Return
MoveWindow_6_Label:
    MoveActiveWindowToDesktopAndFollow(6)
Return
MoveWindow_7_Label:
    MoveActiveWindowToDesktopAndFollow(7)
Return
MoveWindow_8_Label:
    MoveActiveWindowToDesktopAndFollow(8)
Return
MoveWindow_9_Label:
    MoveActiveWindowToDesktopAndFollow(9)
Return

PinWindow_Label:
    TogglePinActiveWindow()
Return

/*
-------------------------------------------------------
Core Helper Functions
-------------------------------------------------------
*/
GetCurrentWindowID()
{
    WinGet, activeHwnd, ID, A
    Return activeHwnd
}

CallWindowManagementFunc(ProcAddress, hWnd)
{
    Return DllCall(ProcAddress, "Ptr", hWnd, "Int")
}

_GetCurrentDesktopNumber()
{
    global GetCurrentDesktopNumberProc
    Return DllCall(GetCurrentDesktopNumberProc, "Int") + 1
}

UpdateTrayIcon(DesktopNumber)
{
    global ICON_FOLDER
    NumberedIconPath := ICON_FOLDER . "\" . DesktopNumber . ".ico"

    if (FileExist(NumberedIconPath)) {
        Menu, Tray, Icon, %NumberedIconPath%
    } else {
        Menu, Tray, Icon
    }
}


/*
-------------------------------------------------------
Main Logic Functions
-------------------------------------------------------
*/
SwitchToDesktop(TargetDesktopNumber)
{
    global GoToDesktopNumberProc, GetDesktopCountProc, CreateDesktopProc
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
    global MoveWindowToDesktopNumberProc, GoToDesktopNumberProc, GetDesktopCountProc, CreateDesktopProc
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
    global GetDesktopCountProc, CreateDesktopProc
    DesktopCount := DllCall(GetDesktopCountProc, "Int")
    if (TargetDesktopIndex >= DesktopCount)
    {
        NumDesktopsToCreate := TargetDesktopIndex - DesktopCount + 1
        Loop, % NumDesktopsToCreate
        {
            DllCall(CreateDesktopProc, "Int")
            Sleep, 50
        }
        Sleep, 100
    }
}

TogglePinActiveWindow()
{
    global PinWindowProc, UnPinWindowProc, IsPinnedWindowProc, PinningFunctionsAvailable
    if (!PinningFunctionsAvailable)
        return

    activeHwnd := GetCurrentWindowID()
    if (!activeHwnd)
        return

    IsPinned := CallWindowManagementFunc(IsPinnedWindowProc, activeHwnd)

    if (IsPinned) {
        CallWindowManagementFunc(UnPinWindowProc, activeHwnd)
        ToolTip, Window Unpinned
        SetTimer, RemoveToolTip, -1500
    } else {
        CallWindowManagementFunc(PinWindowProc, activeHwnd)
        ToolTip, Window Pinned
        SetTimer, RemoveToolTip, -1500
    }
}

RemoveToolTip:
    ToolTip
Return

TranslateModifiers(ModifierString)
{
    Output := RegExReplace(ModifierString, "i)\s*,\s*", "")
    Output := StrReplace(Output, "LALT", "!", 1)
    Output := StrReplace(Output, "RALT", ">!", 1)
    Output := StrReplace(Output, "ALT", "!", 1)
    Output := StrReplace(Output, "LSHIFT", "+", 1)
    Output := StrReplace(Output, "RSHIFT", "<+", 1)
    Output := StrReplace(Output, "SHIFT", "+", 1)
    Output := StrReplace(Output, "LCTRL", "^", 1)
    Output := StrReplace(Output, "RCTRL", ">^", 1)
    Output := StrReplace(Output, "CTRL", "^", 1)
    Output := StrReplace(Output, "LWIN", "#", 1)
    Output := StrReplace(Output, "RWIN", ">#", 1)
    Output := StrReplace(Output, "WIN", "#", 1)
    Return Output
}

/*
-------------------------------------------------------
Script Exit Handling
-------------------------------------------------------
*/
OnExit("Cleanup")

Cleanup(ExitReason, ExitCode)
{
    global hVirtualDesktopAccessor
    if (hVirtualDesktopAccessor) {
        DllCall("FreeLibrary", "Ptr", hVirtualDesktopAccessor)
    }
}