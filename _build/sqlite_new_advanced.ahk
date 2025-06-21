#SingleInstance Force
#NoEnv
#Include %A_ScriptDir%\SQLiteDB.ahk

; Initialize database
db := new SQLiteDB()
if !db.OpenDB(A_ScriptDir . "\games.db") {
    MsgBox, 16, DB Error, % "Failed to open DB.`n" db.ErrorMsg
    ExitApp
}

; Create simple GUI
Gui, Add, Text,, Search for game:
Gui, Add, Edit, vSearchTerm w300
Gui, Add, Button, gSearch, Search
Gui, Add, ListView, w700 h400, Game ID|Title
Gui, Show,, Game Search
return

Search:
    Gui, Submit, NoHide

    ; Basic search query
    query := "SELECT GameId, GameTitle FROM games WHERE GameTitle LIKE '%" EscapeSQL(SearchTerm) "%' OR GameId LIKE '%" EscapeSQL(SearchTerm) "%' LIMIT 50"

    if !db.GetTable(query, result) {
        MsgBox, 16, Error, % "Query failed:`n" db.ErrorMsg
        return
    }

    ; Clear and repopulate ListView
    LV_Delete()
    if (result.RowCount = 0) {
        LV_Add("", "No results found", "")
    } else {
        Loop % result.RowCount {
            result.GetRow(A_Index, row)
            LV_Add("", row1, row2)
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