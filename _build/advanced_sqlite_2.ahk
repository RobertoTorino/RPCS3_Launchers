#SingleInstance Force
#NoEnv
#Include %A_ScriptDir%\SQLiteDB.ahk

; Initialize database
db := new SQLiteDB()
if !db.OpenDB(A_ScriptDir . "\games.db") {
    MsgBox, 16, DB Error, % "Failed to open DB.`n" db.ErrorMsg
    ExitApp
}

; Create improved GUI
Gui, Font, s10, Segoe UI
Gui, Add, Text, x10 y10, Search:
Gui, Add, Edit, vSearchTerm x60 y7 w300 h25
Gui, Add, Button, gSearch x370 y7 w80 h25, Search
Gui, Add, CheckBox, vFilterFavorite x460 y10, Favorite
Gui, Add, CheckBox, vFilterPlayed x550 y10, Played
Gui, Add, CheckBox, vFilterPSN x630 y10, PSN

Gui, Add, ListView, x10 y40 w780 h400 AltSubmit -Multi Grid, Game ID|Title|Format
LV_ModifyCol(1, 120), LV_ModifyCol(2, 500), LV_ModifyCol(3, 150)

Gui, Show, w800 h450, Game Search Launcher
return

Search:
    Gui, Submit, NoHide

    ; Get the search term and escape it properly
    searchTerm := Trim(SearchTerm)

    ; Build WHERE clause - fix the string concatenation
    if (searchTerm != "") {
        escapedTerm := EscapeSQL(searchTerm)
        where := "WHERE (GameTitle LIKE '%" . escapedTerm . "%' OR GameId LIKE '%" . escapedTerm . "%')"
    } else {
        where := "WHERE 1=1"  ; Always true condition when no search term
    }

    ; Add filters if checked
    if (FilterFavorite)
        where := where . " AND Favorite = 1"
    if (FilterPlayed)
        where := where . " AND Played = 1"
    if (FilterPSN)
        where := where . " AND PSN = 1"

    ; Execute query - fix string concatenation here too
    sql := "SELECT GameId, GameTitle, Format FROM games " . where . " ORDER BY GameTitle LIMIT 200"

    ; Debug output (remove after testing)
    ; MsgBox, 0, Debug, SQL: %sql%

    if !db.GetTable(sql, result) {
        MsgBox, 16, Error, % "Query failed:`n" . db.ErrorMsg . "`n`nSQL: " . sql
        return
    }

    ; Update ListView
    LV_Delete()

    if (result.RowCount = 0) {
        LV_Add("", "No results found", "", "")
    } else {
        Loop % result.RowCount {
            if (result.GetRow(A_Index, row)) {
                LV_Add("", row[1], row[2], row[3])
            }
        }
    }

    ; Auto-size columns
    LV_ModifyCol(1, "AutoHdr")
    LV_ModifyCol(2, "AutoHdr")
    LV_ModifyCol(3, "AutoHdr")
return

; Double-click to launch game
LV_DoubleClick:
    row := LV_GetNext()
    if !row
        return

    LV_GetText(gameId, row, 1)
    LV_GetText(gameTitle, row, 2)

    ; Get full record - fix string concatenation here too
    sql := "SELECT Eboot FROM games WHERE GameId = '" . EscapeSQL(gameId) . "'"
    if db.GetTable(sql, result) && result.RowCount {
        if (result.GetRow(1, row)) {
            ebootPath := row[1]
            runCommand := "rpcs3.exe --no-gui --fullscreen """ . ebootPath . """"

            MsgBox, 4, Confirm Launch, % "Launch this game?`n`n" . gameTitle . "`n(" . gameId . ")"
            IfMsgBox, Yes
            {
                IniWrite, %runCommand%, %A_ScriptDir%\launcher.ini, RUN_GAME, RunCommand
                MsgBox, 64, Success, Ready to launch!
            }
        }
    }
return

EscapeSQL(str) {
    if (str = "")
        return ""
    StringReplace, str, str, ', '', All
    StringReplace, str, str, `%, `%`%, All
    return str
}

GuiClose:
ExitApp

