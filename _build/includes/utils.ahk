GetSystemInfo() {
    return "User: " A_UserName
        . "`nComputer: " A_ComputerName
        . "`nOS: " GetWindowsVersion()
        . "`nArch: " (A_Is64bitOS ? "64-bit" : "32-bit")
        . "`nScreen: " A_ScreenWidth "x" A_ScreenHeight
        . "`nCPU: " GetCPUInfo()
        . "`nGPU: " GetGPUInfo()
}

GetCPUInfo() {
    return RunPowerShell("Get-CimInstance Win32_Processor | Select-Object -ExpandProperty Name")
}

GetGPUInfo() {
    return RunPowerShell("Get-CimInstance Win32_VideoController | Select-Object -ExpandProperty Name")
}

GetWindowsVersion() {
    return RunPowerShell("Get-CimInstance Win32_OperatingSystem | Select-Object Caption, Version, BuildNumber | ForEach-Object { $_.Caption + ' Version ' + $_.Version + ' (Build ' + $_.BuildNumber + ')' }")
}

RunPowerShell(psCmd) {
    tmpFile := A_Temp "\ps_output.txt"
    RunWait, %ComSpec% /c powershell -NoProfile -Command "%psCmd%" > "%tmpFile%" 2>&1,, Hide
    FileRead, output, %tmpFile%
    FileDelete, %tmpFile%
    return Trim(output)
}