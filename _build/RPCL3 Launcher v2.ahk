;YouTube @game_play267
;Twitch RR_357000
;Launcher for the Arcade versions of RPCS3

;#SingleInstance Force
#SingleInstance off
#Persistent
#NoEnv
DetectHiddenWindows On
SendMode Input
SetWorkingDir %A_ScriptDir%

;Auto-elevate if not running as Admin
if not A_IsAdmin
{
    try
    {
        Run *RunAs "%A_ScriptFullPath%"
    }
    catch
    {
        MsgBox, 0, Error, This script needs to be run as Administrator.
    }
    ExitApp
}

;Unique window class name
#WinActivateForce
scriptTitle := "RPCS3 Priority Control Launcher"
if WinExist("ahk_class AutoHotkey ahk_exe " A_ScriptName) && !A_IsCompiled {
    ;Re-run if script is not compiled
    ExitApp
}

;Try to send a message to existing instance
if A_Args[1] = "activate" {
    PostMessage, 0x5555,,,, ahk_class AutoHotkey
    ExitApp
}

OnMessage(0x5555, "BringToFront")
BringToFront(wParam, lParam, msg, hwnd) {
    Gui, Show
    WinActivate
}

;Log system info on startup
Log("INFO", "Launcher started (elevated)")
Log("INFO", "User: " A_UserName ", OS: " A_OSVersion ", Arch: " (A_Is64bitOS ? "64-bit" : "32-bit"))

GetSystemInfo() {
    user := A_UserName
    comp := A_ComputerName
    winVer := GetWindowsVersion()
    arch := (A_Is64bitOS ? "64-bit" : "32-bit")
    screen := A_ScreenWidth "x" A_ScreenHeight
    cpu := GetCPUInfo()
    gpu := GetGPUInfo()

    info := "User: " user
    info .= "`nComputer: " comp
    info .= "`nOS: " winVer
    info .= "`nArchitecture: " arch
    info .= "`nScreen: " screen
    info .= "`nCPU: " cpu
    info .= "`nGPU: " gpu
    return info
}

GetCPUInfo() {
    psCmd := "Get-CimInstance Win32_Processor | Select-Object -ExpandProperty Name"
    return RunPowerShell(psCmd)
}

GetGPUInfo() {
    psCmd := "Get-CimInstance Win32_VideoController | Select-Object -ExpandProperty Name"
    return RunPowerShell(psCmd)
}

RunPowerShell(psCmd) {
    tmpFile := A_Temp "\ps_output.txt"
    fullCmd := "powershell -NoProfile -Command """ psCmd """ > """ tmpFile """ 2>&1"
    RunWait, %ComSpec% /c %fullCmd%,, Hide
    FileRead, output, %tmpFile%
    FileDelete, %tmpFile%
    output := Trim(output)
    ;Do NOT replace line breaks here to preserve formatting
    ;output := StrReplace(output, "`r`n", " | ")
    return output
}

GetWindowsVersion() {
    psCmd := "Get-CimInstance Win32_OperatingSystem | Select-Object Caption, Version, BuildNumber | ForEach-Object { $_.Caption + ' Version ' + $_.Version + ' (Build ' + $_.BuildNumber + ')' }"
    return RunPowerShell(psCmd)
}

GetCommandOutput(cmd) {
    tmpFile := A_Temp "\cmd_output.txt"
    RunWait, %ComSpec% /c %cmd% > "%tmpFile%" 2>&1,, Hide
    FileRead, output, %tmpFile%
    FileDelete, %tmpFile%
    return output
}

;-----------------------------------------------------------------------------------------------------------------------
;Define the .ini file path once
global IniFile
IniFile := A_ScriptDir . "\rpcl3.ini"

IniRead, rpcs3Path, %IniFile%, RPCS3, Path
if (rpcs3Path != "")
{
    global rpcs3Exe
    SplitPath, rpcs3Path, rpcs3Exe
}

;-----------------------------------------------------------------------------------------------------------------------
;Show GUI for priority management
;Gui, +Resize +AlwaysOnTop
Gui, +LastFound +OwnDialogs
Gui, Color, 24292F
Gui, Font, cFFFFFF s10, Segoe UI Emoji ; White font, size 10
Gui, Margin, 15, 15
;-----------------------------------------------------------------------------------------------------------------------
;Show the GUI window with enough height for all controls
Gui, Show, w961 h405, RPCS3 Priority Control Launcher 3, RPCL3 Launcher
;-----------------------------------------------------------------------------------------------------------------------
;Top Text controls
Gui, Add, Text, vPriorityLabel              x10 y15 w85 cE18C18 +0x200 BackgroundTrans, Select Priority:
Gui, Add, DropDownList, vPriorityChoice    cx95 y12 w170 r6  +Center +0x200 Border BackgroundTrans, Idle|Below Normal|Normal|Above Normal|High|Realtime
Gui, Add, Text, gSetPriority               x300 y10 w180 h28 cE18C18 +Center +0x200 Border BackgroundTrans, % Chr(0x2728)  " Set Process Priority"  ;✨
Gui, Add, Text, gExePath                   x580 y10 w180 h28 c9299A9 +Center +0x200 Border BackgroundTrans, % Chr(0x1F50D) " Select RPCS3 .exe"     ;🔍
Gui, Add, Text, gEbootPath                 x770 y10 w180 h28 c9299A9 +Center +0x200 Border BackgroundTrans, % Chr(0x1F50D) " Select EBOOT.BIN"      ;🔍
;-------------------------------------------------------------------------------------------------------------------------------------------------------
;Add white horizontal line (height = 1 pixel)
Gui, Add, Text, x0 y46 w963 h1 0x10 BackgroundWhite
;Row 1 buttons ----------------------------------------------------------------------------------------------------------------------------
Gui, Add, Text, gRpcs3Web    x10 y54 w180 h30 cE18C18 +Center +0x200 Border BackgroundTrans, % Chr(0x1F310)  " Download RPCS3"          ;🌐
Gui, Add, Text, gDFirmware  x200 y54 w180 h30 cE18C18 +Center +0x200 Border BackgroundTrans, % Chr(0x1F310)  " Download FW 4.92"        ;🌐
Gui, Add, Text, gIfirmware 	x390 y54 w180 h30 cE18C18 +Center +0x200 Border BackgroundTrans, % Chr(0x1F6E0)  " Install Firmware"  	    ;🛠️
Gui, Add, Text, gPkg		x580 y54 w180 h30 cE18C18 +Center +0x200 Border BackgroundTrans, % Chr(0x2699)   " Install .pkg .rap .edat" ;⚙️
Gui, Add, Text, gVersion 	x770 y54 w180 h30 c00AB9F +Center +0x200 Border BackgroundTrans, % Chr(0x1F579)  " Show RPCS3 Version"  	;🕹️
;-------------------------------------------------------------------------------------------------------------------------------------------
;Add white horizontal line (height = 1 pixel)
Gui, Add, Text, x0 y91 w963 h1 0x10 BackgroundWhite
;Row 2 buttons ---------------------------------------------------------------------------------------------------------------------
Gui, Add, Text, gRunGame     x10 y120 w180 h30 c9299A9 +Center +0x200 Border BackgroundTrans, % Chr(0x1F3AE) " Run Your Game"  	            ;🎮
Gui, Add, Text, gRunRpcs3   x200 y120 w180 h30 c9299A9 +Center +0x200 Border BackgroundTrans, % Chr(0x1F3AE) " Run RPCS3"  	                ;🎮
Gui, Add, Text, gVersion 	x390 y120 w180 h30 cF5D849 +Center +0x200 Border BackgroundTrans, % Chr(0x1F579) " RPCS3 Show Version"  ;🕹️
Gui, Add, Text, gHelp 		x580 y120 w180 h30 cF5D849 +Center +0x200 Border BackgroundTrans, % Chr(0x1F4AC) " RPCS3 Show Help"     ;💬
Gui, Add, Text, gDiscord    x770 y120 w180 h30 cF5D849 +Center +0x200 Border BackgroundTrans, % Chr(0x1F310) " RPCS3 Discord"       ;🌐
;Row 3 buttons ---------------------------------------------------------------------------------------------------------------------
Gui, Add, Text, gViewLog     x10 y164 w180 h30 cF5D849 +Center +0x200 Border BackgroundTrans, % Chr(0x1F4D3) " View Logs"  	        ;📓
Gui, Add, Text, gClearLog   x200 y164 w180 h30 cF5D849 +Center +0x200 Border BackgroundTrans, % Chr(0x2573)  " Clear Logs"  	    ;␡
Gui, Add, Text, gViewIni    x390 y164 w180 h30 cF5D849 +Center +0x200 Border BackgroundTrans, % Chr(0x2328)  " Edit Ini File"  	    ;⌨
Gui, Add, Text, gSysInfo 	x580 y164 w180 h30 cF5D849 +Center +0x200 Border BackgroundTrans, % Chr(0x2139)  " Show System Info"    ;ℹ️
Gui, Add, Text, gAbout      x770 y164 w180 h30 cF5D849 +Center +0x200 Border BackgroundTrans, % Chr(0x2139)  " RPCL3 About"         ;ℹ️
;Row 4 buttons ---------------------------------------------------------------------------------------------------------------------
Gui, Add, Text, gSoon01      x10 y208 w180 h30 c9299A9 +Center +0x200 Border BackgroundTrans, % Chr(0x23F3) " Coming Soon"     	    ;⏳
Gui, Add, Text, gSoon02     x200 y208 w180 h30 c9299A9 +Center +0x200 Border BackgroundTrans, % Chr(0x23F3) " Coming Soon"     	    ;⏳
Gui, Add, Text, gSoon03     x390 y208 w180 h30 c9299A9 +Center +0x200 Border BackgroundTrans, % Chr(0x23F3) " Coming Soon"          ;⏳
Gui, Add, Text, gSoon04 	x580 y208 w180 h30 c9299A9 +Center +0x200 Border BackgroundTrans, % Chr(0x23F3) " Coming Soon"          ;⏳
Gui, Add, Text, gSoon05     x770 y208 w180 h30 c9299A9 +Center +0x200 Border BackgroundTrans, % Chr(0x23F3) " Coming Soon"          ;⏳
;Row 5 buttons ---------------------------------------------------------------------------------------------------------------------
Gui, Add, Text, gSoon06      x10 y252 w180 h30 c9299A9 +Center +0x200 Border BackgroundTrans, % Chr(0x23F3) " Coming Soon"          ;⏳
Gui, Add, Text, gSoon07     x200 y252 w180 h30 c9299A9 +Center +0x200 Border BackgroundTrans, % Chr(0x23F3) " Coming Soon"  	    ;⏳
Gui, Add, Text, gSoon08     x390 y252 w180 h30 c9299A9 +Center +0x200 Border BackgroundTrans, % Chr(0x23F3) " Coming Soon"  	    ;⏳
Gui, Add, Text, gSoon09     x580 y252 w180 h30 c9299A9 +Center +0x200 Border BackgroundTrans, % Chr(0x23F3) " Coming Soon"          ;⏳
Gui, Add, Text, gSoon10     x770 y252 w180 h30 c9299A9 +Center +0x200 Border BackgroundTrans, % Chr(0x23F3) " Coming Soon"          ;⏳
;-----------------------------------------------------------------------------------------------------------------------------------
;Add white horizontal line (height = 1 pixel)
Gui, Add, Text, x0 y309 w963 h1 0x10 BackgroundWhite
;Row 6 buttons ---------------------------------------------------------------------------------------------------------------------
Gui, Add, Text, gExitAhk     x10 y317 w180 h30 cE18C18 +Center +0x200 Border BackgroundTrans, % Chr(0x23CF) " Exit RPCL3"  	;⏏
;Gui, Add, Text, gSoon00    x200 y317 w180 h30 +Center +0x200 Border BackgroundTrans, % Chr(0x23F3) " Coming Soon"  	    ;⏳
;Gui, Add, Text, gSoon00    x390 y317 w180 h30 +Center +0x200 Border BackgroundTrans, % Chr(0x23F3) " Coming Soon"  	    ;⏳
;Gui, Add, Text, gSoon00 	x580 y317 w180 h30 +Center +0x200 Border BackgroundTrans, % Chr(0x23F3) " Coming Soon"          ;⏳
Gui, Add, Text, gExitRpcs3  x770 y317 w180 h30 cE18C18 +Center +0x200 Border BackgroundTrans, % Chr(0x23CF) " Exit RPCS3"   ;⏏
;-----------------------------------------------------------------------------------------------------------------------------------
;Add white horizontal line (height = 1 pixel)
Gui, Add, Text, x0 y352 w963 h1 0x10 BackgroundWhite
;-----------------------------------------------------------------------------------------------------------------------------------
;Show current process priority
Gui, Add, Text, vCurrentPriorityText x10 y359 w800, Checking...
;-----------------------------------------------------------------------------------------------------------------------
;Status bar at bottom
Gui, Add, StatusBar, x10 y150 w470 h21 vStatusBar1
Gui, Show, , RPCS3 Priority Control Launcher
;-----------------------------------------------------------------------------------------------------------------------
;Timer to update priority display
SetTimer, UpdatePriority, 2000
;Force one immediate update
Gosub, UpdatePriority
;-----------------------------------------------------------------------------------------------------------------------
SetStatusMessage("RPCS3 Priority Control Launcher 3 Ready.")

return
;-----------------------------------------------------------------------------------------------------------------------
;Set up the status bar with two parts.
SB_SetParts(250, -1)  ; First part is 250px, second fills the rest
SB_SetText("Status: Ready", 1)  ; Static left side

;Sets the text of the control with variable name StatusBar1 to the value of msg in part 2.
SetStatusMessage(msg) {
    SB_SetText(msg, 2)
}

return

;-----------------------------------------------------------------------------------------------------------------------
Soon01:

return

Soon02:

return

Soon03:

return

Soon04:

return

Soon05:

return

Soon06:

return

Soon07:

return

Soon08:

return

Soon09:

return

Soon10:

return

;-----------------------------------------------------------------------------------------------------------------------
Rpcs3Web:
Run, https://rpcs3.net/download

return

;-----------------------------------------------------------------------------------------------------------------------
Dfirmware:
Run, https://www.playstation.com/en-us/support/hardware/ps3/system-software/#:~:text=Do%20not%20perform%20updates%20using,install%20the%20official%20update%20data.

return

;-----------------------------------------------------------------------------------------------------------------------
About:
    ShowAboutDialog()

return

;-----------------------------------------------------------------------------------------------------------------------
Discord:
    Run, https://discord.com/invite/RPCS3

return

;-----------------------------------------------------------------------------------------------------------------------
Help:
rpcs3Path := GetRPCS3Path()
if (rpcs3Path = "") {
    MsgBox, 0, Error, RPCS3 path not selected or invalid.
    return
}

;Check if rpcs3.exe is running
Process, Exist, rpcs3.exe
if (ErrorLevel != 0) {
    MsgBox, 0, RPCS3 is running, RPCS3 is currently running. Kill it to show help?
    IfMsgBox, No
        return
    Process, Close, rpcs3.exe
    Sleep, 500
}

;Run the --help command
helpOutput := GetCommandOutput("rpcs3.exe --help")
if (helpOutput = "") {
return
}

Gui, HelpGui:Destroy
Gui, HelpGui:+Resize +MinSize
Gui, HelpGui:Font, s9, Consolas
Gui, HelpGui:Add, Edit, w600 h400 ReadOnly -Wrap, %helpOutput%
Gui, HelpGui:Show,, RPCS3 Help
return

ProcessExist := Process, Exist, rpcs3.exe
if (ProcessExist) {
    MsgBox, 0, RPCS3 is running, RPCS3 is currently running. Kill it to show help?
    IfMsgBox, No
        return
    Process, Close, rpcs3.exe
    Sleep, 500
}

; Run the --help command
helpOutput := GetCommandOutput(rpcs3Exe . " --help")
if (helpOutput = "") {
    return
}

; Optional: display help output
MsgBox, %helpOutput%

Gui, HelpGui:Destroy
Gui, HelpGui:+Resize +MinSize
Gui, HelpGui:Font, s9, Consolas
Gui, HelpGui:Add, Edit, w600 h400 ReadOnly -Wrap, %helpOutput%
Gui, HelpGui:Show,, RPCS3 Help
return

ProcessExist := Process, Exist, rpcs3.exe
if (ProcessExist) {
    MsgBox, 0, RPCS3 is running, RPCS3 is currently running. Kill it to show help?
    Log("INFO", "RPCS3 is currently running. Kill it to show help?")
    IfMsgBox, No
        return
    Process, Close, %rpcs3Exe%
    Sleep, 500
}

;-----------------------------------------------------------------------------------------------------------------------
Version:
    ShowVersion()

Return

ShowVersion() {
    rpcs3Path := GetRPCS3Path()
    if (rpcs3Path = "") {
        MsgBox, 0, Error, RPCS3 path not selected or invalid.
        return
    }

    ;Check if rpcs3.exe is running
    Process, Exist, rpcs3.exe
    if (ErrorLevel != 0) {
        MsgBox, 0, RPCS3 is running, RPCS3 is currently running. Kill it to show version info?
        IfMsgBox, No
            return
        Process, Close, rpcs3.exe
        Sleep, 500
    }

    ;Run the --version command
	versionOutput := GetCommandOutput("rpcs3.exe --version")
    if (versionOutput = "") {
		return
    }

    Gui, VersionGui:Destroy
    Gui, VersionGui:+Resize +MinSize
    Gui, VersionGui:Font, s9, Consolas
    Gui, VersionGui:Add, Edit, w600 h200 ReadOnly -Wrap, %versionOutput%
    Gui, VersionGui:Show,, RPCS3 Version Info
}

;-----------------------------------------------------------------------------------------------------------------------
ExePath:
    FileSelectFile, selectedPath,, , Select RPCS3 executable, Executable Files (*.exe)
    if (selectedPath != "" && FileExist(selectedPath)) {
        SaveRPCS3Path(selectedPath)

        ;Also update global rpcs3Path and rpcs3Exe
        global rpcs3Path, rpcs3Exe
        rpcs3Path := selectedPath
        SplitPath, rpcs3Path, rpcs3Exe

        SB_SetText("RPCS3 path saved: " . selectedPath)
        Log("INFO", "RPCS3 path saved: " . selectedPath)
    } else {
        TrayTip, RPCS3 Path, RPCS3 path not selected or invalid., 1, 16
        SB_SetText("ERROR: No valid RPCS3 executable selected.")
        Log("ERROR", "No valid RPCS3 executable selected.")
    }

Return

;-----------------------------------------------------------------------------------------------------------------------
GetRPCS3Path() {
    static iniFile := A_ScriptDir . "\rpcl3.ini"
    local path

    if !FileExist(iniFile) {
        TrayTip, RPCL3 Config, Missing rpcl3.ini., 1, 16
        SB_SetText("ERROR: Missing rpcl3.ini when calling GetRPCS3Path.")
        Log("ERROR", "Missing rpcl3.ini when calling GetRPCS3Path()")
        return ""
    }

    IniRead, path, %iniFile%, RPCS3, Path
    if (ErrorLevel) {
        TrayTip, RPCL3 Config, Could not read [RPCS3] Path from rpcl3.ini., 1, 16
        SB_SetText("ERROR: Could not read [RPCS3] Path from rpcl3.ini.")
        Log("ERROR", "Could not read [RPCS3] Path from rpcl3.ini")
        return ""
    }

    path := Trim(path, "`" " ")  ;Trim surrounding quotes and spaces

    if (path != "" && FileExist(path))
        return path

    TrayTip, RPCL3 Config, Could not read [RPCS3] Path from rpcl3.ini., 1, 16
    SB_SetText("ERROR: Invalid or non-existent path in rpcl3.ini: " . path)
    Log("ERROR", "Invalid or non-existent path in rpcl3.ini: " . path)

    return ""
}

;-----------------------------------------------------------------------------------------------------------------------
SaveRPCS3Path(path) {
    static iniFile := A_ScriptDir . "\rpcl3.ini"
    IniWrite, %path%, %iniFile%, RPCS3, Path
    Log("INFO", "Saved RPCS3 path to config: " . path)
}

;--- Main ---
rpcs3Path := GetRPCS3Path()

if (rpcs3Path = "") {
    MsgBox, 48, Warning, RPCS3 path not set or invalid. Please select it now.
    FileSelectFile, selectedPath,, , Select RPCS3 executable, Executable Files (*.exe)
    if (selectedPath != "" && FileExist(selectedPath)) {
        SaveRPCS3Path(selectedPath)
        rpcs3Path := selectedPath
        MsgBox, 64, Info, Saved RPCS3 path:`n%rpcs3Path%
    } else {
        MsgBox, 16, Error, No valid path selected. Exiting.
        ExitApp
    }
} else {
    MsgBox, 64, Info, Using RPCS3 path:`n%rpcs3Path%
}

;Optional: extract just the EXE name if needed elsewhere
SplitPath, rpcs3Path, rpcs3Exe

;--- Optional Help GUI ---
Gui, HelpGui:Destroy
Gui, HelpGui:+Resize +MinSize
Gui, HelpGui:Font, s9, Consolas
Gui, HelpGui:Add, Edit, w600 h400 ReadOnly -Wrap, %helpOutput%
Gui, HelpGui:Show,, RPCS3 Help

return

;-----------------------------------------------------------------------------------------------------------------------
SysInfo:
    ;Create and show a small loading GUI
    Gui, LoadingGui:Destroy
    Gui, LoadingGui:Add, Text, w200 h50 Center, Loading system info, please wait...
    Gui, LoadingGui:Show,, Please Wait

    ;Force GUI to update so user sees it immediately
    Gui, LoadingGui:Default
    Sleep, 50
    ;Allow GUI message queue to process (optional)
    Sleep, 10

    ;Now fetch the system info (potentially slow)
    sysInfo := GetSystemInfo()

    ;Close the loading GUI
    Gui, LoadingGui:Destroy

    ;Create and show the full system info GUI
    Gui, SysInfoGui:Destroy
    Gui, SysInfoGui:+Resize +MinSize
    Gui, SysInfoGui:Font, s10, Consolas
    Gui, SysInfoGui:Add, Edit, w600 h300 ReadOnly -Wrap +HScroll +VScroll, % sysInfo
    Gui, SysInfoGui:Show,, RPCS3 System Information

Return

;-----------------------------------------------------------------------------------------------------------------------
Rpcs3Path:
    FileSelectFile, selectedPath,, 3, Select RPCS3 executable, Executable Files (*.exe)
    if (selectedPath != "")
    {
        rpcs3Path := selectedPath
        IniWrite, %rpcs3Path%, %iniFile%, RPCS3, Path
        SB_SetText("Saved: RPCS3 path saved: " . selectedPath)
        Log("INFO", "RPCS3 path saved: " . selectedPath)
    }

Return

GetCommandOutputUniquew(cmd) {
    tmpFile := A_Temp "\rpcs3_help_output.txt"
    RunWait, %ComSpec% /c %cmd% > "%tmpFile%" 2>&1, , Hide
    FileRead, result, %tmpFile%
    FileDelete, %tmpFile%
    return result
}

;-----------------------------------------------------------------------------------------------------------------------
Ifirmware:
    Gui -AlwaysOnTop
    rpcs3Path := GetRPCS3Path()
    if (rpcs3Path = "") {
        MsgBox, 0, Error, RPCS3 path not selected or invalid.
        Gui, +AlwaysOnTop
        return
    }

    ;Check if rpcs3.exe is running
    Process, Exist, rpcs3.exe
    if (ErrorLevel != 0) {
        Gui -AlwaysOnTop
        MsgBox, 0, RPCS3 is running, RPCS3 is currently running. Kill it to install firmware?
        IfMsgBox, No
            return
        Process, Close, %rpcs3Exe%
        Sleep, 500
    }

    MsgBox, 0, Firmware Installation, Please select the PS3 firmware file (.PUP)
    FileSelectFile, firmwarePath, 3,, Select PS3 Firmware, *.PUP
    if (firmwarePath = "") {
        Gui -AlwaysOnTop
        MsgBox, 0, Warning, No firmware file selected.
        return
    }

    RunWait, "%rpcs3Path%" --installfw "%firmwarePath%", , Hide
    MsgBox, 0, Done, Firmware installed successfully.

    Gui +AlwaysOnTop
return

;-----------------------------------------------------------------------------------------------------------------------
Pkg:
    rpcs3Path := GetRPCS3Path()
    if (rpcs3Path = "") {
        MsgBox, 0, Error, RPCS3 path not selected or invalid.
        return
    }

    ; Check if rpcs3.exe is running
    Process, Exist, rpcs3.exe
    if (ErrorLevel != 0) {
        MsgBox, 4, RPCS3 is running, RPCS3 is currently running. Kill it to install package?
        ; 4 = Yes/No buttons
        IfMsgBox, No
            return
        Process, Close, rpcs3.exe
        Sleep, 500
    }

    MsgBox, 1, PKG Installer, Please select a .pkg, .rap, or .edat file.`nClick Cancel to abort.
    ; 1 = OK/Cancel buttons
    IfMsgBox, Cancel
        return

    FileSelectFile, pkgPath,, 3, Select PKG file for --installpkg, *.pkg;*.rap;*.edat
    if (pkgPath = "") {
        MsgBox, 0, Warning, No package file selected.
        return
    }

    RunWait, "%rpcs3Path%" --installpkg "%pkgPath%", , Hide
    MsgBox, 0, Done, Package installed successfully.

return

;-----------------------------------------------------------------------------------------------------------------------
ClearLog:
    FileDelete, %A_ScriptDir%\rpcl3.log
    TrayTip, RPCS3 Launcher, Log file cleared., 2
    Log("INFO", "Log file cleared by user.")
    SB_SetText("Log cleared")

return

    ;Timer to update priority display
    SetTimer, UpdatePriority, Off
    SetTimer, UpdatePriority, 3000  ;delay first update 3 seconds

return

;-----------------------------------------------------------------------------------------------------------------------
SetPriority:
    Gui, Submit, NoHide

    if PriorityChoice =  ;empty or not selected
    {
        TrayTip, RPCS3 Priority, Please select a priority before setting., 2
        return
    }

    priorityCode := ""
    if (PriorityChoice = "Idle")
        priorityCode := "L"
    else if (PriorityChoice = "Below Normal")
        priorityCode := "B"
    else if (PriorityChoice = "Normal")
        priorityCode := "N"
    else if (PriorityChoice = "Above Normal")
        priorityCode := "A"
    else if (PriorityChoice = "High")
        priorityCode := "H"
    else if (PriorityChoice = "Realtime")
        priorityCode := "R"

    Process, Exist, rpcs3.exe
    if (ErrorLevel) {
        Process, Priority, %ErrorLevel%, %priorityCode%
        TrayTip, RPCS3 Priority, Set to %PriorityChoice%, 2
        Log("INFO", "Set RPCS3 priority to " . PriorityChoice)
        SB_SetText("Priority set to " . PriorityChoice)
    } else {
        TrayTip, RPCS3 Priority, RPCS3 not running., 2
        Log("WARN", "Attempted to set priority, but RPCS3 is not running.")
        SB_SetText("RPCS3 not running when trying to set priority")
    }

return

;-----------------------------------------------------------------------------------------------------------------------
UpdatePriority:
    Process, Exist, rpcs3.exe
    if (!ErrorLevel) {
        GuiControl,, CurrentPriorityText, RPCS3 Not Running.
        GuiControl, Disable, PriorityChoice
        GuiControl, Disable, Set Priority
        SB_SetText("RPCS3 not running")
        return
    }

    pid := ErrorLevel
    current := GetPriority(pid)

    GuiControl,, CurrentPriorityText, Current Priority: %current%

    global lastPriority
    if (current != lastPriority) {
        GuiControl,, PriorityChoice, %current%
        lastPriority := current
        SB_SetText("Priority updated to " . current)
    }

    GuiControl, Enable, PriorityChoice
    GuiControl, Enable, Set Priority

return

;-----------------------------------------------------------------------------------------------------------------------
GetPriority(pid) {
    try {
        wmi := ComObjGet("winmgmts:")
        query := "Select Priority from Win32_Process where ProcessId=" pid
        for proc in wmi.ExecQuery(query)
            return MapPriority(proc.Priority)
        return "Unknown"
    } catch e {
        TrayTip, RPCS3 Priority, Failed to get priority., 1, 16
        SB_SetText("ERROR: Failed to get priority: " . e.Message)
        Log("ERROR", "Failed to get priority: " . e.Message)
        return "Error"
    }
}

MapPriority(val) {
    if (val = 4)
        return "Idle"
    if (val = 6)
        return "Below Normal"
    if (val = 8)
        return "Normal"
    if (val = 10)
        return "Above Normal"
    if (val = 13)
        return "High"
    if (val = 24)
        return "Realtime"
    if (val = 32)
        return "Normal"
    if (val = 64)
        return "Idle"
    if (val = 128)
        return "High"
    if (val = 256)
        return "Realtime"
    if (val = 16384)
        return "Below Normal"
    if (val = 32768)
        return "Above Normal"
    return "Unknown (" val ")"
}

KillAllProcesses(pid := "") {
    if (pid) {
        Run, "%A_ScriptFullPath%" activate
        RunWait, taskkill /im %rpcs3Exe% /F,, Hide
        RunWait, taskkill /im powershell.exe /F,, Hide
        RunWait, %ComSpec% /c taskkill /PID %pid% /F, , Hide
        ; Optional: Kill any potential child processes
        RunWait, %ComSpec% /c taskkill /im powershell.exe /F, , Hide
        Log("INFO", "KillAllProcesses: Killed PID " . pid)
    } else {
        Log("WARN", "KillAllProcesses: No PID provided.")
    }
}

;-----------------------------------------------------------------------------------------------------------------------
ExitRpcs3:
    ; Confirm what we're checking for
    Log("DEBUG", "Checking for process: " . rpcs3Exe)
    Process, Exist, %rpcs3Exe%

    pid := ErrorLevel
    if (pid) {
        KillAllProcesses(pid)  ; Pass PID to function
        TrayTip, RPCS3, Killed all RPCS3 processes., 2
        Log("INFO", "Killed all RPCS3 processes (PID: " . pid . ")")
        SB_SetText("RPCS3 processes killed")
    } else {
        TrayTip, RPCS3, No RPCS3 processes found., 2
        Log("INFO", "No RPCS3 process found.")
        SB_SetText("No RPCS3 processes running")
    }

    Gui, Show ;Show or hide GUI but keep script alive
    Menu, Tray, Show  ;Ensure tray icon stays visible

return

;-----------------------------------------------------------------------------------------------------------------------
;Kill all RPCS#.exe processes
Esc::
    Process, Exist, rpcs3.exe
    if (ErrorLevel) {
        TrayTip, RPCS3 Launcher, ESC pressed. Killing RPCS3 processes..., 2
        Log("WARN", "ESC pressed. Killing all RPCS3 processes.")
        SB_SetText("RPCS3 processes killed")
        KillAllProcesses()
    } else {
        TrayTip, RPCS3, No RPCS3 processes found., 2
        Log("INFO", "No RPCS3 processes found.")
        SB_SetText("No RPCS3 processes found.")
    }

return

;-----------------------------------------------------------------------------------------------------------------------
ExitAHK:
    Log("INFO", "Exiting RPCL3 via Exit button.")
    ExitApp
return

;-----------------------------------------------------------------------------------------------------------------------
GuiClose:
GuiEscape:
    Gui, Hide
    TrayTip, RPCS3 Launcher, Window hidden. Use tray icon to restore., 2
    Log("INFO", "GUI closed or hidden.")
    SB_SetText("GUI hidden")

return

;-----------------------------------------------------------------------------------------------------------------------
EbootPath:
    iniFile := A_ScriptDir . "\rpcl3.ini"
    FileSelectFile, selectedEboot, 3,, Select EBOOT.BIN, EBOOT.BIN
if (!ErrorLevel && selectedEboot) {
    ;Optional: Ensure it's exactly EBOOT.BIN
    SplitPath, selectedEboot, fileName
    if (fileName != "EBOOT.BIN") {
        TrayTip, RPCS3 Run Game, EBOOT.BIN not found., 1, 16
        SB_SetText("ERROR: Invalid File, Please select a file named EBOOT.BIN.")
        Log("ERROR", "EBOOT.BIN not found.")
        return
    }
        ;Save selected path to rpcl3.ini
        IniWrite, %selectedEboot%, %iniFile%, Settings, EbootPath
    }
        ;Update status bar or notify
        SB_SetText("EBOOT.BIN path saved to \rpcl3.ini.")

return

;-----------------------------------------------------------------------------------------------------------------------
RunGame:
    RunWait, taskkill /im %rpcs3Exe% /F,, Hide
    Sleep, 1000

    ;Read paths from INI
    IniRead, rpcs3Path, %iniFile%, RPCS3, Path
    IniRead, fullEbootPath, %iniFile%, Settings, EbootPath

    ;Validate
    if (!FileExist(rpcs3Path)) {
        TrayTip, RPCS3 Run Game, RPCS3 executable not found!, 1, 16
        SB_SetText("ERROR: RPCS3 executable not found.")
        Log("ERROR", "RPCS3 executable not found.")
        return
    }
    if (!FileExist(fullEbootPath)) {
        TrayTip, RPCS3 Run Game, EBOOT.BIN not found., 1, 16
        SB_SetText("ERROR: EBOOT.BIN not found.")
        Log("ERROR", "EBOOT.BIN not found.")
        return
    }

    ;Convert EBOOT.BIN to relative format
    StringReplace, ebootRel, fullEbootPath, %A_ScriptDir%\,, All
    StringReplace, ebootRel, ebootRel, \, /, All

    ;🛠 Build correct command — entire string quoted ONCE
    cmd := """" . rpcs3Path . " --no-gui --fullscreen " . ebootRel . """"
    Log("DEBUG", "Full command: " . cmd)

    ;Run command
    Run, %ComSpec% /c %cmd%, %A_ScriptDir%, , newPID

    Sleep, 2000
    SoundPlay, %A_ScriptDir%\GOOD_MORNING.wav
    Log("INFO", "Started RPCS3.")
    SB_SetText("RPCS3 Started.")

return

;-----------------------------------------------------------------------------------------------------------------------
RunRpcs3:
    RunWait, taskkill /im %rpcs3Exe% /F,, Hide
    Sleep, 1000

    if !FileExist(IniFile)
    {
        TrayTip, RPCS3 Run, Missing rpcl3.ini file! Set RPCS3 Path first., 1, 16
        SB_SetText("ERROR: Missing rpcl3.ini file! Set RPCS3 Path first.")
        Log("ERROR", "Missing rpcl3.ini file! Set RPCS3 Path first.: " . IniFile)
        Return
    }

    SB_SetText("Reading from: " . IniFile)

    ;Read the path once
    IniRead, appPath, %IniFile%, RPCS3, Path
    SB_SetText("Path read: " . appPath)

    ;Check if reading was successful
    if (ErrorLevel)
    {
        TrayTip, RPCS3 Run, Could not read the path from rpcl3.ini., 1, 16
        SB_SetText("ERROR: Could not read the path from rpcl3.ini.")
        Log("ERROR", "Could not read the path from section [RPCS3] in " . IniFile)
        Return
    }

    if !FileExist(appPath)
    {
        TrayTip, RPCS3 Run, File not found: %appPath%, 1, 16
        SB_SetText("ERROR: File not found: " . appPath)
        Log("ERROR", "The file does not exist:`n" . appPath)
        Return
    }

    ;Run the application
    Run, %appPath%

    Sleep, 2000
    SoundPlay, %A_ScriptDir%\GOOD_MORNING.wav
    Log("INFO", "Started RPCS3.")
    SB_SetText("RPCS3 Started.")

Return

;-----------------------------------------------------------------------------------------------------------------------
ViewLog:
    Run, notepad.exe "%A_ScriptDir%\rpcl3.log"
    Log("INFO", "Opened log file in Notepad.")
    SB_SetText("Log file opened.")

return

;-----------------------------------------------------------------------------------------------------------------------
ViewIni:
    Run, notepad.exe "%A_ScriptDir%\rpcl3.ini"
    Log("INFO", "Opened rpcl3.ini file in Notepad.")
    SB_SetText("rpcl3.ini file opened.")

return

;-----------------------------------------------------------------------------------------------------------------------
ShowAboutDialog() {
    ;Extract embedded version.dat resource to temp file
    tempFile := A_Temp "\version.dat"
    hRes := DllCall("FindResource", "Ptr", 0, "VERSION_FILE", "Ptr", 10) ;RT_RCDATA = 10
    if (hRes) {
        hData := DllCall("LoadResource", "Ptr", 0, "Ptr", hRes)
        pData := DllCall("LockResource", "Ptr", hData)
        size := DllCall("SizeofResource", "Ptr", 0, "Ptr", hRes)
        if (pData && size) {
            File := FileOpen(tempFile, "w")
            if IsObject(File) {
                File.RawWrite(pData + 0, size)
                File.Close()
            }
        }
    }

    ;Read version string
    FileRead, verContent, %tempFile%
    version := "Unknown"
    if (verContent != "") {
        version := verContent
    }

aboutText := "RPCS3 Priority Control Launcher`nVersion: " version "`n" Chr(169) " " A_YYYY " Philip"
MsgBox, 64, About RPCL3, %aboutText%
}

;-----------------------------------------------------------------------------------------------------------------------
;Log function
Log(level, msg) {
    FormatTime, timestamp,, yyyy-MM-dd HH:mm:ss
    FileAppend, [%timestamp%] [%level%] %msg%`n, %A_ScriptDir%\rpcl3.log
}

;-----------------------------------------------------------------------------------------------------------------------
;System tray menu setup
Menu, Tray, NoStandard                        ; Remove default items like "Pause Script"
Menu, Tray, Add, Show GUI, ShowGui           ; Add a custom "Show GUI" option
Menu, Tray, Add, About RPCL3..., ShowAboutDialog
Menu, Tray, Add                               ; Add a separator line
Menu, Tray, Add, Exit, ExitScript            ; Add Exit
Menu, Tray, Default, Show GUI                ; Make "Show GUI" the default double-click action
Menu, Tray, Tip, RPCS3 Launcher              ; Tooltip when hovering
Menu, Tray, Click, 1                         ; Make single left-click trigger default
Menu, Tray, Show                             ; Show the tray icon

;-----------------------------------------------------------------------------------------------------------------------
ShowGui:
    Gui, Show
    SB_SetText("GUI shown")
return

Gui, Show
return

return

;-----------------------------------------------------------------------------------------------------------------------
ExitScript:
    Log("INFO", "Exiting script via tray menu.")
    ExitApp
return
