#SingleInstance Force
#NoEnv
#Include %A_ScriptDir%\SQLiteDB.ahk

db := new SQLiteDB()
if !db.OpenDB(A_ScriptDir . "\games.db") {
    err := db.ErrorMsg
    MsgBox, 16, DB Error, Failed to open DB.`n%err%
    ExitApp
}

; Create integrated GUI
Gui, Font, s10, Segoe UI

; Filter section at the top
Gui, Add, GroupBox, x10 y10 w380 h80, Filters
Gui, Add, CheckBox, vFilterFavorite x20 y30, Favorite
Gui, Add, CheckBox, vFilterPlayed x100 y30, Played
Gui, Add, CheckBox, vFilterPSN x180 y30, PSN
Gui, Add, CheckBox, vFilterArcadeGame x260 y30, Arcade Games

; Search section
Gui, Add, GroupBox, x10 y100 w380 h60, Search
Gui, Add, Text, x20 y120, Game title or ID:
Gui, Add, Edit, vSearchTerm x120 y117 w180 h20
Gui, Add, Button, gSearch x310 y117 w70 h23, Search

; Results section - ListView for better display
Gui, Add, GroupBox, x10 y170 w380 h250, Results
Gui, Add, ListView, vResultsList x20 y190 w360 h200 Grid -Multi AltSubmit, Game ID|Title
LV_ModifyCol(1, 80)
LV_ModifyCol(2, 270)

; Action buttons
Gui, Add, Button, gLaunchGame x20 y400 w100 h30, Launch Selected
Gui, Add, Button, gClearSearch x130 y400 w100 h30, Clear Search

Gui, Show, w400 h450, Game Search Launcher
return

Search:
    Gui, Submit, NoHide

    ; Get search term
    searchTerm := Trim(SearchTerm)
    if (searchTerm = "") {
        MsgBox, 48, Input Required, Please enter a search term.
        return
    }

    ; Build filters array
    filters := []
    if (FilterFavorite)
        filters.Push("Favorite = 1")
    if (FilterPlayed)
        filters.Push("Played = 1")
    if (FilterPSN)
        filters.Push("PSN = 1")
    if (FilterArcadeGame)
        filters.Push("ArcadeGame = 1")

    ; Build WHERE clause
    whereClause := "WHERE (GameTitle LIKE '%" . StrReplace(searchTerm, "'", "''") . "%' OR GameId LIKE '%" . StrReplace(searchTerm, "'", "''") . "%')"

    if (filters.MaxIndex() > 0)
        whereClause .= " AND " . Join(" AND ", filters)

    ; Execute query
    sql := "SELECT GameId, GameTitle, Eboot FROM games " . whereClause . " ORDER BY GameTitle LIMIT 50"

    if !db.GetTable(sql, result) {
        MsgBox, 16, Query Error, % "Query failed:`n" . db.ErrorMsg
        return
    }

    ; Clear and populate ListView
    LV_Delete()

    if (result.RowCount = 0) {
        LV_Add("", "No results found", "")
        return
    }

    ; Add results to ListView
    Loop, % result.RowCount {
        row := ""
        if result.GetRow(A_Index, row) {
            ; Store the Eboot path in a global array for later use
            EbootPaths%A_Index% := row[3]
            LV_Add("", row[1], row[2])
        }
    }

    ; Auto-resize columns
    LV_ModifyCol(1, "AutoHdr")
    LV_ModifyCol(2, "AutoHdr")
return

LaunchGame:
    ; Get selected row
    selectedRow := LV_GetNext()
    if (!selectedRow) {
        MsgBox, 48, No Selection, Please select a game from the list.
        return
    }

    ; Get game info
    LV_GetText(gameId, selectedRow, 1)
    LV_GetText(gameTitle, selectedRow, 2)

    ; Get the stored Eboot path
    ebootPath := EbootPaths%selectedRow%

    if (ebootPath = "") {
        MsgBox, 16, Error, Could not find Eboot path for selected game.
        return
    }

    ; Confirm launch
    msg := "Launch this game?`n`nGame ID: " . gameId . "`nTitle: " . gameTitle
    MsgBox, 4, Confirm Launch, %msg%

    IfMsgBox, Yes
    {
        runCommand := "rpcs3.exe --no-gui --fullscreen """ ebootPath """"
        IniWrite, %runCommand%, %A_ScriptDir%\launcher.ini, RUN_GAME, RunCommand
        MsgBox, 64, Success, % "Game launch command written to INI:`n" runCommand
    }
return

ClearSearch:
    ; Clear search field and results
    GuiControl,, SearchTerm
    LV_Delete()

    ; Clear stored Eboot paths
    Loop, 50 {
        EbootPaths%A_Index% := ""
    }
return

; Double-click on ListView item to launch
ResultsListDoubleClick:
    Gosub, LaunchGame
return

; Helper function for joining array elements
Join(sep, ByRef arr) {
    out := ""
    for index, val in arr
        out .= (index > 1 ? sep : "") . val
    return out
}

GuiClose:
ExitApp
