; YouTube: @game_play267
; Launcher for Tekken Tag Tournament 2
#NoEnv
SendMode Input
SetWorkingDir %A_ScriptDir%
#SingleInstance force

Run, powershell.exe -ExecutionPolicy Bypass -File "RPCS3_SetPriority.ps1"

MsgBox, Run the TTT2-Launcher as Administrator!

TrayTip, RPCS3 Launcher, Setting process priority to RealTime, 5

TrayTip, RPCS3 Launcher, Press ESC to terminate RPCS3, 5

; Monitor for ESC key globally
Esc::
    TrayTip, RPCS3 Launcher, ESC pressed. Killing RPCS3..., 2
    RunWait, taskkill /im rpcs3.exe /F,, Hide
    ExitApp
return