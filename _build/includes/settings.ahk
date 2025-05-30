InitRPCS3Vars() {
    global
    IniRead, rpcs3Path, %IniFile%, RPCS3, Path
    if (rpcs3Path = "") {
        MsgBox, 16, Error, RPCS3 path not configured
        return false
    }
    SplitPath, rpcs3Path, rpcs3Exe
    return true
}

SaveRPCS3Path(path) {
    global IniFile
    IniWrite, %path%, %IniFile%, RPCS3, Path
    Log("INFO", "Saved RPCS3 path: " path)
}

SetRPCS3Path:
    FileSelectFile, selectedPath,, , Select RPCS3 executable, *.exe
    if (selectedPath != "") {
        SaveRPCS3Path(selectedPath)
        global rpcs3Path := selectedPath
        SplitPath, selectedPath, rpcs3Exe
    }
return