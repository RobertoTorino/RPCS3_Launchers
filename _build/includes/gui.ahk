; GUI Setup
Gui, Font, s10, Segoe UI Emoji
Gui, Margin, 10, 10

; Controls
Gui, Add, Text, vPriorityLabel x10 y14 w90, Select Priority:
Gui, Add, DropDownList, vPriorityChoice x95 y12 w234 r6, Idle|Below Normal|Normal|Above Normal|High|Realtime
Gui, Add, Button, gSetPriority x330 y10 w160 h30, % Chr(0x2728) " Set Priority"

; Add all other GUI controls here...
Gui, Add, StatusBar, x9 y150 w470 h21 vStatusBar1

; Tray Menu
Menu, Tray, Add, Open Launcher, ShowGui
Menu, Tray, Add, Exit, ExitScript
Menu, Tray, Default, Open Launcher
Menu, Tray, NoStandard

ShowGui:
    Gui, Show
return