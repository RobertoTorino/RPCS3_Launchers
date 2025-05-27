;YouTube @game_play267
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
scriptTitle := "TTT2 Launcher"
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

;IniRead, rpcs3Path, %iniFile%, RPCS3, Path
;if (rpcs3Path = "" or !FileExist(rpcs3Path))
;{
;   MsgBox, 0, Warning, RPCS3 path not set or invalid. Please set the path.
;}

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

;MsgBox % GetSystemInfo()

;Launch RPCS3 with PowerShell script to set priority initially
;Run, powershell.exe -ExecutionPolicy Bypass -File "RPCS3_SetPriority.ps1"
;SoundPlay, %A_ScriptDir%\GoodMorning.wav
;Sleep, 3000
;Gosub, UpdatePriority

;Show GUI for priority management
Gui, Font, s10, Segoe UI Emoji
;Gui, +Resize
Gui, Margin, 10, 10

;Top Text controls
Gui, Add, Text, vPriorityLabel x10 y14 w90, Select Priority:
Gui, Add, DropDownList, vPriorityChoice x95 y12 w234 r6, Idle|Below Normal|Normal|Above Normal|High|Realtime
Gui, Add, Button, gSetPriority      x330  y10 w160 h30, % Chr(0x2728)   " Set Priority"    	    ;✨

;Row 1 buttons
Gui, Add, Button, gSetRPCS3Path 	x10  y50 w160 h30, % Chr(0x1F50D)   " Set RPCS3 Path" 	    ;🔍
Gui, Add, Button, gSelectEboot      x170 y50 w160 h30, % Chr(0x267B)    " Select EBOOT.BIN"     ;♻
Gui, Add, Button, gRunRPCS3         x330 y50 w160 h30, % Chr(0x2622)    " Run RPCS3"  	        ;☢

;Row 2 buttons
Gui, Add, Button, gViewLog          x10  y90 w160 h30, % Chr(0x1F52D)   " View Logs"  			;🔭
Gui, Add, Button, gHandleClearLog   x170 y90 w160 h30, % Chr(0x1F5D1)   " Clear Logs"  			;🗑
Gui, Add, Button, gExitAHK          x330 y90 w160 h30, % Chr(0x23FB)    " Exit AHK"  			;⏻

;Row 3 buttons
Gui, Add, Button, gShowSysInfo 		x10  y130 w160 h30, % Chr(0x1F4BB)  " Show System Info"  	;💻
Gui, Add, Button, gShowHelp 		x170 y130 w160 h30, % Chr(0x1F4AC)  " Show RPCS3 Help"  	;💬
;Gui, Add, Button, gRestartRPCS3     x330 y130 w160 h30, % Chr(0x21BB)   " Restart RPCS3"  	    ;↻

;Row 4 buttons
Gui, Add, Button, gShowVersion 		x10  y170 w160 h30, % Chr(0x1F579)  " Show RPCS3 Version"  	;🕹️
Gui, Add, Button, gInstallFirmware 	x170 y170 w160 h30, % Chr(0x1F6E0)  " Install Firmware"  	;🛠️
Gui, Add, Button, gInstallPKG 		x330 y170 w160 h30, % Chr(0x2699)   " Install PKG File"  	;⚙️

;Row 5 buttons
Gui, Add, Button, gOpenWebsite      x10  y210 w160 h30, % Chr(0x1F310)   " Download RPCS3"      ;🌐
Gui, Add, Button, gOpenDiscord      x170 y210 w160 h30, % Chr(0x1F310)   " RPCS3 Discord"       ;🌐
Gui, Add, Button, gKillRPCS3        x330 y210 w160 h30, % Chr(0x1F480)   " Kill RPCS3"          ;💀

;Show current process priority
Gui, Add, Text, vCurrentPriorityText x10 w200, Checking...

;Status bar at bottom
Gui, Add, StatusBar, x9 y150 w470 h21

SB_SetText("RPCS3 Arcade Launcher Ready.")

Gui, Show, , RPCS3 Priority Control

;Timer to update priority display
SetTimer, UpdatePriority, 2000
return

OpenWebsite:
Run, https://rpcs3.net/download
return

OpenDiscord:
Run, https://discord.com/invite/RPCS3
return

;System tray menu setup
Menu, Tray, Add, Open Launcher, ShowGui
Menu, Tray, Add, Exit, ExitScript
Menu, Tray, Default, Open Launcher
Menu, Tray, Click, 1

;Show the GUI window with enough height for all controls
Gui, Show, w520 h250, RPCS3 Arcade Process Priority Control, TTT2 Launcher

return

ShowHelp:
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

ShowVersion:
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

SetRPCS3Path:
    FileSelectFile, selectedPath,, 3, Select RPCS3 executable, Executable Files (*.exe)
    if (selectedPath != "" && FileExist(selectedPath)) {
        SaveRPCS3Path(selectedPath)
        MsgBox, 0, Saved, RPCS3 path saved:`n%selectedPath%
    } else {
        MsgBox, 0, Error, No valid RPCS3 executable selected.
    }
Return

GetRPCS3Path() {
    static iniFile := A_ScriptDir . "\config.ini"
    local path := ""

    if !FileExist(iniFile)
        return ""  ;config missing

    IniRead, path, %iniFile%, RPCS3, Path
    path := Trim(path, "`" " ")  ;trim quotes and spaces

    if (path != "" && FileExist(path))
        return path

    return ""  ;invalid or empty path
}

SaveRPCS3Path(path) {
    static iniFile := A_ScriptDir . "\config.ini"
    IniWrite, %path%, %iniFile%, RPCS3, Path
}

;--- Main ---
rpcs3Path := GetRPCS3Path()
if (rpcs3Path = "") {
    MsgBox, 0, Warning, RPCS3 path not set or invalid. Please select it now.
    FileSelectFile, selectedPath,, 3, Select RPCS3 executable, Executable Files (*.exe)
    if (selectedPath != "" && FileExist(selectedPath)) {
        SaveRPCS3Path(selectedPath)
        rpcs3Path := selectedPath
        MsgBox, 0, Info, Saved RPCS3 path:`n%rpcs3Path%
    } else {
        MsgBox, 0, Error, No valid path selected. Exiting.
        ExitApp
    }
} else {
    MsgBox, 0, Info, Using RPCS3 path:`n%rpcs3Path%
}

Gui, HelpGui:Destroy
Gui, HelpGui:+Resize +MinSize
Gui, HelpGui:Font, s9, Consolas
Gui, HelpGui:Add, Edit, w600 h400 ReadOnly -Wrap, %helpOutput%
Gui, HelpGui:Show,, RPCS3 Help
return

;Make startup too slow
;ShowSysInfo:
    ;sysInfo := GetSystemInfo()

    ;Gui, SysInfoGui:Destroy  ;Destroy previous if any
    ;Gui, SysInfoGui:+Resize +MinSize
    ;Gui, SysInfoGui:Font, s10, Consolas
    ;Gui, SysInfoGui:Add, Edit, w600 h300 ReadOnly -Wrap +HScroll +VScroll, % sysInfo
    ;Gui, SysInfoGui:Show,, RPCS3 System Information

    ;Return

ShowSysInfo:
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

BrowseRPCS3Path:
    FileSelectFile, selectedPath,, 3, Select RPCS3 executable, Executable Files (*.exe)
    if (selectedPath != "")
    {
        rpcs3Path := selectedPath
        IniWrite, %rpcs3Path%, %iniFile%, RPCS3, Path
        MsgBox, 0, Saved, RPCS3 path saved:`n%rpcs3Path%
    }
Return

GetCommandOutputUniquew(cmd) {
    tmpFile := A_Temp "\rpcs3_help_output.txt"
    RunWait, %ComSpec% /c %cmd% > "%tmpFile%" 2>&1, , Hide
    FileRead, result, %tmpFile%
    FileDelete, %tmpFile%
    return result
}

InstallFirmware:
    rpcs3Path := GetRPCS3Path()
    if (rpcs3Path = "") {
        MsgBox, 0, Error, RPCS3 path not selected or invalid.
        return
    }

    ;Check if rpcs3.exe is running
    Process, Exist, rpcs3.exe
    if (ErrorLevel != 0) {
        MsgBox, 0, RPCS3 is running, RPCS3 is currently running. Kill it to install firmware?
        IfMsgBox, No
            return
        Process, Close, rpcs3.exe
        Sleep, 500
    }

    MsgBox, 0, Firmware Installation, Please select the PS3 firmware file (.PUP)
    FileSelectFile, firmwarePath, 3,, Select PS3 Firmware, *.PUP
    if (firmwarePath = "") {
        MsgBox, 0, Warning, No firmware file selected.
        return
    }

    RunWait, "%rpcs3Path%" --installfw "%firmwarePath%", , Hide
    MsgBox, 0, Done, Firmware installed successfully.
return

InstallPKG:
    rpcs3Path := GetRPCS3Path()
    if (rpcs3Path = "") {
        MsgBox, 0, Error, RPCS3 path not selected or invalid.
        return
    }

    ;Check if rpcs3.exe is running
    Process, Exist, rpcs3.exe
    if (ErrorLevel != 0) {
        MsgBox, 0, RPCS3 is running, RPCS3 is currently running. Kill it to install package?
        IfMsgBox, No
            return
        Process, Close, rpcs3.exe
        Sleep, 500
    }

    MsgBox, 0, PKG Installer, Please select a .pkg file to install.
    FileSelectFile, pkgPath,, 3, Select PKG file for --installpkg, *.pkg
    if (pkgPath = "") {
        MsgBox, 0, Warning, No package file selected.
        return
    }

    RunWait, "%rpcs3Path%" --installpkg "%pkgPath%", , Hide
    MsgBox, 0, Done, Package installed successfully.
return

HandleClearLog:
FileDelete, %A_ScriptDir%\launcher.log
TrayTip, RPCS3 Launcher, Log file cleared., 2
Log("INFO", "Log file cleared by user.")
SB_SetText("Log cleared")

return

;Timer to update priority display
SetTimer, UpdatePriority, Off
SetTimer, UpdatePriority, 3000  ;delay first update 3 seconds
return

SetPriority:
    Gui, Submit, NoHide
SetTimer, UpdatePriority, 2000
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

UpdatePriority:
    Process, Exist, rpcs3.exe
    if (!ErrorLevel) {
        GuiControl,, CurrentPriorityText, Not running
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

GetPriority(pid) {
    try {
        wmi := ComObjGet("winmgmts:")
        query := "Select Priority from Win32_Process where ProcessId=" pid
        for proc in wmi.ExecQuery(query)
            return MapPriority(proc.Priority)
        return "Unknown"
    } catch e {
        Log("ERROR", "Failed to get priority: " e.Message)
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

KillRPCS3:
    Process, Exist, rpcs3.exe
    if (ErrorLevel) {  ; ErrorLevel contains the PID if process exists
        KillAllProcesses()
        TrayTip, RPCS3, Killed all RPCS3 processes., 2
        Log("INFO", "Killed RPCS3, PowerShell, and AHK processes.")
        SB_SetText("RPCS3 processes killed")
    } else {
        TrayTip, RPCS3, No RPCS3 processes found., 2
        SB_SetText("No RPCS3 processes running")
    }
    Gui, Show ;Show or hide GUI but keep script alive
    Menu, Tray, Show  ;Ensure tray icon stays visible
return

;Disable default tray menu items (Suspend, Pause, Exit)
Menu, Tray, NoStandard

;Add your custom tray menu
Menu, Tray, Add, Show GUI, ShowGui
Menu, Tray, Add, Exit, ExitScript
Menu, Tray, Default, Show GUI
Menu, Tray, Tip, RPCS3 Launcher

;Show tray icon (usually automatic, but no harm)
Menu, Tray, Show

;Make left-click on tray icon show the GUI
Menu, Tray, Click, ShowGui

return

ShowGui:
    Gui, Show
    SB_SetText("GUI shown")
return

ExitScript:
    Log("INFO", "Exiting script via tray menu.")
    ExitApp
return

ExitAHK:
    Log("INFO", "Exiting AutoHotkey script via Exit button.")
    ExitApp
return

GuiClose:
GuiEscape:
    Gui, Hide
    TrayTip, RPCS3 Launcher, Window hidden. Use tray icon to restore., 2
    Log("INFO", "GUI closed or hidden.")
    SB_SetText("GUI hidden")
return

Esc:
    TrayTip, RPCS3 Launcher, ESC pressed. Killing all processes..., 2
    Log("WARN", "ESC pressed. Killing all processes and exiting.")
    KillAllProcesses()
    SB_SetText("All processes killed via ESC")
    ExitApp
return

SelectEboot:
    iniFile := A_ScriptDir . "\config.ini"
    FileSelectFile, selectedEboot, 3,, Select EBOOT.BIN, EBOOT.BIN
if (!ErrorLevel && selectedEboot) {
    ;Optional: Ensure it's exactly EBOOT.BIN
    SplitPath, selectedEboot, fileName
    if (fileName != "EBOOT.BIN") {
        MsgBox, 0, Invalid File, Please select a file named EBOOT.BIN.
        return
    }
    ;Save selected path to config.ini
        IniWrite, %selectedEboot%, %iniFile%, Settings, EbootPath
        MsgBox, 0, Success, EBOOT.BIN path saved to config.ini!
    }
    ; Update status bar or notify
    SB_SetText("Saved EBOOT.BIN path.")
return

RunRPCS3:
    RunWait, taskkill /im rpcs3.exe /F,, Hide
    Sleep, 1000

    ; Read paths from INI
    IniRead, rpcs3Path, %iniFile%, RPCS3, Path
    IniRead, fullEbootPath, %iniFile%, Settings, EbootPath

    ; Validate
    if (!FileExist(rpcs3Path)) {
        MsgBox, 0, Error, RPCS3 executable not found!
        return
    }
    if (!FileExist(fullEbootPath)) {
        MsgBox, 0, Error, EBOOT.BIN not found!
        return
    }

    ; Convert EBOOT.BIN to relative format
    StringReplace, ebootRel, fullEbootPath, %A_ScriptDir%\,, All
    StringReplace, ebootRel, ebootRel, \, /, All

    ; 🛠 Build correct command — entire string quoted ONCE
    cmd := """" . rpcs3Path . " --no-gui --fullscreen " . ebootRel . """"
    Log("DEBUG", "Full command: " . cmd)

    ; Run command
    Run, %ComSpec% /c %cmd%, %A_ScriptDir%, , newPID

    Sleep, 2000
    SoundPlay, %A_ScriptDir%\GoodMorning.wav
    Log("INFO", "Restarted RPCS3.")
    SB_SetText("RPCS3 restarted.")
return

ViewLog:
    Run, notepad.exe "%A_ScriptDir%\launcher.log"
    Log("INFO", "Opened log file in Notepad.")
    SB_SetText("Log file opened")
return

KillAllProcesses() {
	Run, "%A_ScriptFullPath%" activate
    RunWait, taskkill /im rpcs3.exe /F,, Hide
    RunWait, taskkill /im powershell.exe /F,, Hide
    Log("INFO", "KillAllProcesses executed.")
}

Log(level, msg) {
    FormatTime, timestamp,, yyyy-MM-dd HH:mm:ss
    FileAppend, [%timestamp%] [%level%] %msg%`n, %A_ScriptDir%\launcher.log
}
