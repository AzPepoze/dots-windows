$LWin::
{
    if KeyWait("LWin", "T0.2")
    {
        if (A_PriorKey = "LWin")
        {
            Send "^ " ; Pure tap -> Command Palette
        }
    }
    else
    {
        Send "{LWin Down}"
        KeyWait "LWin"
        Send "{LWin Up}"
    }
}