#SingleInstance Force
#NoEnv
#Include %A_ScriptDir%\SQLiteDB.ahk

db := new SQLiteDB()
if !db.OpenDB(A_ScriptDir . "\games.db") {
    err := db.ErrorMsg
    MsgBox, 16, DB Error, Failed to open DB.`n%err%
    ExitApp
}

Gui, Add, Text,, Filters:
Gui, Add, CheckBox, vFilterFavorite, Favorite
Gui, Add, CheckBox, vFilterPlayed, Played
Gui, Add, CheckBox, vFilterPSN, PSN
Gui, Add, CheckBox, vFilterFormat, Format
Gui, Add, CheckBox, vFilterGenre, Genre

Gui, Add, Button, gPromptSearch, Search Game
Gui, Show,, Game Search Launcher
return

PromptSearch:
InputBox, searchTerm, Game Search, Enter part of the title or Game ID:
if (searchTerm = "")
    return

Gui, Submit, NoHide

filters := []
if (FilterFavorite)
    filters.Push("Favorite = 1")
if (FilterPlayed)
    filters.Push("Played = 1")
if (FilterPSN)
    filters.Push("PSN = 1")
; Format and Genre are assumed to be text values in your DB
if (FilterFormat)
    filters.Push("Format != ''")
if (FilterGenre)
    filters.Push("Genre != ''")

    Join(sep, ByRef arr) {
        out := ""
        for index, val in arr
            out .= (index > 1 ? sep : "") . val
        return out
    }


whereClause := "WHERE (GameTitle LIKE '%" . StrReplace(searchTerm, "'", "''") . "%' OR GameId LIKE '%" . StrReplace(searchTerm, "'", "''") . "%')"
if (filters.MaxIndex())
    whereClause .= " AND " . Join(" AND ", filters)


sql := "SELECT GameId, GameTitle, Eboot FROM games " . whereClause . " ORDER BY GameTitle LIMIT 50"

if !db.GetTable(sql, result) {
    MsgBox, 16, Query Error, % "Query failed:`n" . db.ErrorMsg
    return
}

if (result.RowCount = 0) {
    MsgBox, No matching games found for "%searchTerm%".
    return
}

Loop, % result.RowCount {
    row := ""
    if !result.GetRow(A_Index, row)
        continue
    msg := "Match #" . A_Index . ":`n`nGame ID: " . row[1] . "`nTitle: " . row[2] . "`n`nUse this one?"
MsgBox, 4,, %msg%
IfMsgBox Yes
{
    ebootPath := row[3]
    runCommand := "rpcs3.exe --no-gui --fullscreen """ . ebootPath . """"
    IniWrite, %runCommand%, %A_ScriptDir%\launcher.ini, RUN_GAME, RunCommand
    MsgBox, Written to INI:`n%runCommand%
    return
}
}

MsgBox, No selection made.
return

GuiClose:
ExitApp
