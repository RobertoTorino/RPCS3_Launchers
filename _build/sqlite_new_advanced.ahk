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
Gui, Add, ListView, vGameList w700 h400, Game ID|Title
Gui, Show,, Game Search
return

Search:
    Gui, Submit, NoHide

    ; Check if search term is not empty
    if (SearchTerm = "") {
        return
    }

    ; Basic search query with proper SQL escaping
    escapedTerm := EscapeSQL(SearchTerm)
    query := "SELECT GameId, GameTitle FROM games WHERE GameTitle LIKE '%" . escapedTerm . "%' OR GameId LIKE '%" . escapedTerm . "%' LIMIT 50"

    ; Execute query
    if !db.GetTable(query, result) {
        MsgBox, 16, Error, % "Query failed:`nError: " . db.ErrorMsg . "`nQuery: " . query
        return
    }

    ; Clear ListView
    Gui, ListView, GameList
    LV_Delete()

    ; Check if we have results
    if (!result || result.RowCount = 0) {
        LV_Add("", "No results found", "")
        return
    }

    ; Add results to ListView
    Loop % result.RowCount {
        if (result.GetRow(A_Index, row)) {
            ; Access row data properly - check if row is an object or array
            if (IsObject(row)) {
                gameId := row[1]
                gameTitle := row[2]
            } else {
                ; If row is not properly formatted, show debug info
                gameId := "Debug: " . A_Index
                gameTitle := "Row data issue"
            }
            LV_Add("", gameId, gameTitle)
        }
    }
return

EscapeSQL(str) {
    if (str = "")
        return ""

    ; Escape single quotes for SQL
    StringReplace, str, str, ', '', All
    ; Escape wildcards if needed
    StringReplace, str, str, %, `%, All
    StringReplace, str, str, _, `_, All
    return str
}

GuiClose:
ExitApp
