; tests.ahk
#NoTrayIcon
#SingleInstance force

testsFailed := false

; Example test
if !FileExist("config.ini") {
    MsgBox, 16, Test Failed, config.ini not found!
    testsFailed := true
}

; Add more test conditions here...

ExitApp, testsFailed ? 1 : 0


Gui, Color, 4A4A4A        ; Grey
Gui, Font, cFFFFFF s10, Segoe UI Emoji ; White font, size 10
Gui, Margin, 10, 10

;Top Text controls
Gui, Add, Text, vPriorityLabel x10 y14 w90, Select Priority:
Gui, Add, DropDownList, vPriorityChoice x95 y12 w234 r6, Idle|Below Normal|Normal|Above Normal|High|Realtime
Gui, Add, Button, gSetPriority      x330  y10 w160 h30, % Chr(0x2728)   " Set Priority"    	    ;✨

;Row 1 buttons
;Gui, Add, Text, gSetRPCS3Path hwndhSetRPCS3Path x10 y50 w160 h30 +Center +0x200 Border BackgroundTrans, % Chr(0x1F50D) " Set RPCS3 Path" ;🔍
;Gui, Add, Text, gSetRPCS3Path       x10 y50 w160 h30  +Center +0x200 Border BackgroundTrans, % Chr(0x1F50D) " Set RPCS3 Path"       ;🔍
;Gui, Add, Text, gSelectEboot      x170 y50 w160 h30 +Center +0x200 Border BackgroundTrans, % Chr(0x267B)  " Select EBOOT.BIN"     ;♻
;Gui, Add, Text, gRunGame          x330 y50 w160 h30 +Center +0x200 Border BackgroundTrans, % Chr(0x1F3AE) " Run Game"  	        ;🎮

Gui, Add, Text, gSetRPCS3Path hwndhSetRPCS3Path     x10 y50 w160 h30    +Center +0x200 Border BackgroundTrans, % Chr(0x1F50D) " Set RPCS3 Path"     ;🔍
Gui, Add, Text, gSelectEboot hwndhSelectEboot       x170 y50 w160 h30   +Center +0x200 Border BackgroundTrans, % Chr(0x267B) "  Select EBOOT.BIN"   ;♻
Gui, Add, Text, gRunGame hwndhRunGame               x330 y50 w160 h30   +Center +0x200 Border BackgroundTrans, % Chr(0x1F3AE) " Run Game"           ;🎮

;Show current process priority
Gui, Add, Text, vCurrentPriorityText x10 w200, Checking...

Gui, Color, 4A4A4A        ; Slightly lighter dark grey
Gui, Font, cFFFFFF s10    ; White font, size 10

;Status bar at bottom
Gui, Add, StatusBar, x9 y150 w470 h21 vStatusBar1
Gui, Show, , RPCS3 Priority Control Launcher

;Timer to update priority display
SetTimer, UpdatePriority, 2000
;Force one immediate update
Gosub, UpdatePriority

SB_SetText("RPCS3 Priority Control Launcher Ready.")

return

SB_SetText(msg) {
    GuiControl,, StatusBar1, %msg%
}

ClickableControls := [hSetRPCS3Path, hSelectEboot, hRunGame]  ; Add all your hwnds here

SetTimer, CheckHover, 100
CheckHover:
MouseGetPos,,, win, ctrl
for _, hwnd in ClickableControls {
    if (ctrl = hwnd) {
        DllCall("SetCursor", "Ptr", DllCall("LoadCursor", "Ptr", 0, "Ptr", 32649, "Ptr")) ; Hand cursor
        return
    }
}
DllCall("SetCursor", "Ptr", DllCall("LoadCursor", "Ptr", 0, "Ptr", 32512, "Ptr")) ; Arrow cursor
return