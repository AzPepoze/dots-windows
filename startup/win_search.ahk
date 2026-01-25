#Requires AutoHotkey v2.0

LWin::
{
    ; Send LWin Down immediately so combos like Win+Tab are instant
    Send "{Blind}{LWin Down}"
    
    ; Wait for the user to release the key
    KeyWait "LWin"
    
    ; Check if LWin was the last key pressed. 
    ; If yes, it means no other key (like Tab or D) was pressed, so it's a "Tap".
    if (A_PriorKey = "LWin")
    {
        ; Send a mask key (vkE8) to prevent the Start Menu from popping up
        Send "{Blind}{vkE8}"
        Send "{Blind}{LWin Up}"
        
        ; Send Win (#) + Alt (!) + Space
        Send "#!{Space}" 
    }
    else
    {
        ; If another key was pressed, just release LWin normally
        Send "{Blind}{LWin Up}"
    }
}