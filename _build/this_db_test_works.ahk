#SingleInstance Force
#NoEnv
#Include %A_ScriptDir%\SQLiteDB.ahk

db := new SQLiteDB()
if !db.OpenDB(A_ScriptDir . "\games.db") {
    err := db.ErrorMsg
    MsgBox, 16, DB Error, Failed to open DB.`n%err%
    ExitApp
}

; Run a simple test query
sql := "SELECT GameId, GameTitle FROM games LIMIT 5"
if !db.GetTable(sql, result) {
    err := db.ErrorMsg
    MsgBox, 16, Query Error, Query failed:`n%err%
    ExitApp
}

output := ""
Loop, % result.RowCount {
    row := ""
    if result.GetRow(A_Index, row)
        output .= row[1] " - " row[2] "`n"
}

MsgBox, 64, Test Result, Top 5 games:`n`n%output%
ExitApp
