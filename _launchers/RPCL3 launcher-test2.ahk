;YouTube @game_play267
;Launcher for RPCS3

;#SingleInstance Force
#SingleInstance off
#Persistent
#NoEnv
DetectHiddenWindows On
SendMode Input
SetWorkingDir %A_ScriptDir%

;Includes
#Include logging.ahk
#Include utils.ahk
#Include gui.ahk
#Include process.ahk
#Include settings.ahk

;Admin check
if not A_IsAdmin
{
    try Run *RunAs "%A_ScriptFullPath%"
    catch ExitApp
}

;Global vars
global scriptTitle := "RPCS3 Priority Control Launcher"
global IniFile := A_ScriptDir . "\rpcl3.ini"
global rpcs3Path, rpcs3Exe

;Init
InitRPCS3Vars()
Log("INFO", "Launcher started (elevated)")

;GUI
BuildGUI()
Gui, Show, w520 h300, %scriptTitle%

;Timers
SetTimer, UpdatePriority, 2000
return

GuiClose:
GuiEscape:
    Gui, Hide
return