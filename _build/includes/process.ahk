SetPriority:
    GuiControlGet, PriorityChoice
    priorityCode := {"Idle":"L", "Below Normal":"B", "Normal":"N", "Above Normal":"A", "High":"H", "Realtime":"R"}[PriorityChoice]

    Process, Exist, %rpcs3Exe%
    if (ErrorLevel) {
        Process, Priority, %ErrorLevel%, %priorityCode%
        Log("INFO", "Priority set to " PriorityChoice)
    }
return

KillRPCS3:
    Process, Exist, %rpcs3Exe%
    if (ErrorLevel) {
        RunWait, taskkill /im %rpcs3Exe% /F,, Hide
        Log("INFO", "Killed RPCS3 process")
    }
return

UpdatePriority:
    Process, Exist, %rpcs3Exe%
    if (ErrorLevel) {
        priority := GetPriority(ErrorLevel)
        GuiControl,, CurrentPriorityText, Current Priority: %priority%
    }
return