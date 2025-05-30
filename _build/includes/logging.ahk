Log(level, msg) {
    FormatTime, timestamp,, yyyy-MM-dd HH:mm:ss
    FileAppend, [%timestamp%] [%level%] %msg%`n, %A_ScriptDir%\rpcl3.log
}

ViewLog:
    Run, notepad.exe "%A_ScriptDir%\rpcl3.log"
return

HandleClearLog:
    FileDelete, %A_ScriptDir%\rpcl3.log
return