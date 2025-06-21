;#SingleInstance Force
;#NoEnv
;#Include %A_ScriptDir%\SQLiteDB.ahk
;
;; Initialize database
;db := new SQLiteDB()
;if !db.OpenDB(A_ScriptDir . "\games.db") {
;    MsgBox, 16, DB Error, % "Failed to open DB.`n" db.ErrorMsg
;    ExitApp
;}
;
;; Create simple GUI
;Gui, Add, Text,, Search for game:
;Gui, Add, Edit, vSearchTerm w300
;Gui, Add, Button, gSearch, Search
;Gui, Add, ListView, vGameList w700 h400, Game ID|Title
;Gui, Show,, Game Search
;return
;
;Search:
;    Gui, Submit, NoHide
;
;    ; Check if search term is not empty
;    if (SearchTerm = "") {
;        return
;    }
;
;    ; Basic search query with proper SQL escaping
;    escapedTerm := EscapeSQL(SearchTerm)
;    query := "SELECT GameId, GameTitle FROM games WHERE GameTitle LIKE '%" . escapedTerm . "%' OR GameId LIKE '%" . escapedTerm . "%' LIMIT 50"
;
;    ; Execute query
;    if !db.GetTable(query, result) {
;        MsgBox, 16, Error, % "Query failed:`nError: " . db.ErrorMsg . "`nQuery: " . query
;        return
;    }
;
;    ; Clear ListView
;    Gui, ListView, GameList
;    LV_Delete()
;
;    ; Check if we have results
;    if (!result || result.RowCount = 0) {
;        LV_Add("", "No results found", "")
;        return
;    }
;
;    ; Add results to ListView
;    Loop % result.RowCount {
;        if (result.GetRow(A_Index, row)) {
;            ; Access row data properly - check if row is an object or array
;            if (IsObject(row)) {
;                gameId := row[1]
;                gameTitle := row[2]
;            } else {
;                ; If row is not properly formatted, show debug info
;                gameId := "Debug: " . A_Index
;                gameTitle := "Row data issue"
;            }
;            LV_Add("", gameId, gameTitle)
;        }
;    }
;return
;
;
;EscapeSQL(str) {
;    if (str = "")
;        return ""
;
;    ; Escape single quotes by doubling them
;    StringReplace, str, str, ', '', All
;
;    ; Escape SQL wildcards
;    StringReplace, str, str, `%, `%`%, All
;    StringReplace, str, str, `_, `_`_, All
;
;    return str
;}
;
;GuiClose:
;ExitApp

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

    ; Build WHERE clause using your working search logic
    where := "WHERE (GameTitle LIKE '%" EscapeSQL(SearchTerm) "%' OR GameId LIKE '%" EscapeSQL(SearchTerm) "%')"

    ; Add filters if checked
    if (FilterFavorite)
        where .= " AND Favorite = 1"
    if (FilterPlayed)
        where .= " AND Played = 1"
    if (FilterPSN)
        where .= " AND PSN = 1"

    ; Execute query
    sql := "SELECT GameId, GameTitle, Format FROM games " where " ORDER BY GameTitle LIMIT 200"
    if !db.GetTable(sql, result) {
        MsgBox, 16, Error, % "Query failed:`n" db.ErrorMsg
        return
    }

    ; Update ListView
    LV_Delete()
    Loop % result.RowCount {
        result.GetRow(A_Index, row)
        LV_Add("", row1, row2, row3)
    }

    ; Auto-size columns
    LV_ModifyCol(1, "AutoHdr")
    LV_ModifyCol(2, "AutoHdr")
return

; Double-click to launch game
LV_DoubleClick:
    row := LV_GetNext()
    if !row
        return

    LV_GetText(gameId, row, 1)
    LV_GetText(gameTitle, row, 2)

    ; Get full record
    if db.GetTable("SELECT Eboot FROM games WHERE GameId = '" EscapeSQL(gameId) "'", result) && result.RowCount {
        result.GetRow(1, row)
        ebootPath := row1
        runCommand := "rpcs3.exe --no-gui --fullscreen """ ebootPath """"

        MsgBox, 4, Confirm Launch, % "Launch this game?`n`n" gameTitle "`n(" gameId ")"
        IfMsgBox, Yes
        {
            IniWrite, %runCommand%, %A_ScriptDir%\launcher.ini, RUN_GAME, RunCommand
            MsgBox, 64, Success, Ready to launch!
        }
    }
return

EscapeSQL(str) {
    StringReplace, str, str, ', '', All
    StringReplace, str, str, `%, `%`%, All
    return str
}

GuiClose:
ExitApp