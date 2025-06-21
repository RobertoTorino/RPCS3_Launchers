#SingleInstance Force
#NoEnv
#Include %A_ScriptDir%\SQLiteDB.ahk

db := new SQLiteDB()
if !db.OpenDB(A_ScriptDir . "\games.db") {
    err := db.ErrorMsg
    MsgBox, 16, DB Error, Failed to open DB.`n%err%
    ExitApp
}

; Debug: Check what columns exist in the games table
sql := "PRAGMA table_info(games)"
if db.GetTable(sql, result) {
    columnList := ""
    Loop, % result.RowCount {
        row := ""
        if result.GetRow(A_Index, row) {
            columnList .= row[2] . "`n"  ; Column name is in index 2
        }
    }
    MsgBox, 0, Available Columns, Available columns in games table:`n`n%columnList%
} else {
    MsgBox, 16, Error, Failed to get table info: %db.ErrorMsg%
}

; Create integrated GUI
Gui, Font, s10, Segoe UI

; Filter section at the top
Gui, Add, GroupBox, x10 y10 w380 h80, Filters
Gui, Add, CheckBox, vFilterFavorite x20 y30, Favorite
Gui, Add, CheckBox, vFilterPlayed x100 y30, Played
Gui, Add, CheckBox, vFilterPSN x180 y30, PSN
Gui, Add, CheckBox, vFilterArcadeGame x260 y30, Arcade Games

; Quick access buttons
Gui, Add, Button, gShowOnlyFavorites x20 y55 w80 h20, Show Favorites
Gui, Add, Button, gShowAll x110 y55 w60 h20, Show All

; Search section
Gui, Add, GroupBox, x10 y100 w380 h60, Search
Gui, Add, Text, x20 y120, Game title or ID:
Gui, Add, Edit, vSearchTerm x120 y117 w180 h20
Gui, Add, Button, gSearch x310 y117 w70 h23, Search

; Results section - ListView now shows favorite status
Gui, Add, GroupBox, x10 y170 w380 h200, Results
Gui, Add, ListView, vResultsList x20 y190 w360 h150 Grid -Multi AltSubmit gListViewClick, ★|Game ID|Title
LV_ModifyCol(1, 25)  ; Favorite star column
LV_ModifyCol(2, 80)  ; Game ID
LV_ModifyCol(3, 245) ; Title

; Image preview section
Gui, Add, GroupBox, x10 y380 w380 h100, Game Preview
Gui, Add, Picture, vGameIcon x20 y400 w64 h64 gShowLargeImage, ; Small icon preview
Gui, Add, Text, vImageStatus x95 y400, Select a game to see its icon

; Action buttons
Gui, Add, Button, gToggleFavorite x95 y430 w90 h25, Toggle Favorite
Gui, Add, Button, gLaunchGame x200 y400 w80 h30, Launch
Gui, Add, Button, gClearSearch x290 y400 w80 h30, Clear

Gui, Show, w400 h490, Game Search Launcher
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
    ExecuteQuery(whereClause)
return

ShowOnlyFavorites:
    ; Show only favorite games
    whereClause := "WHERE Favorite = 1"
    ExecuteQuery(whereClause)
return

ShowAll:
    ; Show all games without any filters
    whereClause := ""
    ExecuteQuery(whereClause)
return

ExecuteQuery(whereClause) {
    ; First try a simple query to test basic columns
    testSql := "SELECT GameId, GameTitle FROM games LIMIT 1"
    if !db.GetTable(testSql, testResult) {
        MsgBox, 16, Basic Query Error, Basic query failed:`n%db.ErrorMsg%
        return
    }

    ; Try to build the query step by step to find which column is causing issues
    ; Start with basic columns
    sql := "SELECT GameId, GameTitle, Eboot FROM games " . whereClause . " ORDER BY GameTitle LIMIT 100"

    if !db.GetTable(sql, result) {
        MsgBox, 16, Query Error - Step 1, % "Basic query failed:`n" . db.ErrorMsg . "`n`nSQL: " . sql
        return
    }

    ; Test if Icon0 column exists
    iconTestSql := "SELECT Icon0 FROM games LIMIT 1"
    if !db.GetTable(iconTestSql, iconTest) {
        MsgBox, 48, Column Issue, Icon0 column might not exist or have different name:`n%db.ErrorMsg%
        ; Use basic query without images
        PopulateListViewBasic(result)
        return
    }

    ; Test if Pic1 column exists
    picTestSql := "SELECT Pic1 FROM games LIMIT 1"
    if !db.GetTable(picTestSql, picTest) {
        MsgBox, 48, Column Issue, Pic1 column might not exist or have different name:`n%db.ErrorMsg%
        ; Use basic query without images
        PopulateListViewBasic(result)
        return
    }

    ; Test if Favorite column exists
    favTestSql := "SELECT Favorite FROM games LIMIT 1"
    if !db.GetTable(favTestSql, favTest) {
        MsgBox, 48, Column Issue, Favorite column might not exist or have different name:`n%db.ErrorMsg%
        ; Use basic query without favorites
        PopulateListViewBasic(result)
        return
    }

    ; If we get here, try the full query
    fullSql := "SELECT GameId, GameTitle, Eboot, Icon0, Pic1, Favorite FROM games " . whereClause . " ORDER BY GameTitle LIMIT 100"

    if !db.GetTable(fullSql, fullResult) {
        MsgBox, 16, Full Query Error, % "Full query failed:`n" . db.ErrorMsg . "`n`nSQL: " . fullSql
        ; Fall back to basic query
        PopulateListViewBasic(result)
        return
    }

    ; Success - use full result
    PopulateListViewFull(fullResult)
}

PopulateListViewBasic(result) {
    ; Clear and populate ListView with basic info only
    LV_Delete()

    if (result.RowCount = 0) {
        LV_Add("", "", "No results found", "")
        ClearImagePreview()
        return
    }

    ; Add results to ListView and store basic paths
    Loop, % result.RowCount {
        row := ""
        if result.GetRow(A_Index, row) {
            ; Store basic info
            GameIds%A_Index% := row[1]
            EbootPaths%A_Index% := row[3]
            IconPaths%A_Index% := ""  ; No icon path available
            PicPaths%A_Index% := ""   ; No pic path available
            FavoriteStatus%A_Index% := 0  ; Default not favorite

            ; Add row without star (no favorite info)
            LV_Add("", "", row[1], row[2])
        }
    }

    ; Auto-resize columns
    LV_ModifyCol(1, 25)
    LV_ModifyCol(2, "AutoHdr")
    LV_ModifyCol(3, "AutoHdr")

    ClearImagePreview()
}

PopulateListViewFull(result) {
    ; Clear and populate ListView with full info
    LV_Delete()

    if (result.RowCount = 0) {
        LV_Add("", "", "No results found", "")
        ClearImagePreview()
        return
    }

    ; Add results to ListView and store all paths
    Loop, % result.RowCount {
        row := ""
        if result.GetRow(A_Index, row) {
            ; Store all the paths and info
            GameIds%A_Index% := row[1]
            EbootPaths%A_Index% := row[3]
            IconPaths%A_Index% := row[4]  ; Icon0 column
            PicPaths%A_Index% := row[5]   ; Pic1 column
            FavoriteStatus%A_Index% := row[6]

            ; Add row with star if favorite
            favoriteIcon := (row[6] = 1) ? "★" : ""
            LV_Add("", favoriteIcon, row[1], row[2])
        }
    }

    ; Auto-resize columns
    LV_ModifyCol(1, 25)
    LV_ModifyCol(2, "AutoHdr")
    LV_ModifyCol(3, "AutoHdr")

    ClearImagePreview()
}

; Rest of the functions remain the same...
ListViewClick:
    selectedRow := LV_GetNext()
    if (selectedRow > 0) {
        ShowGameIcon(selectedRow)
        UpdateFavoriteButton(selectedRow)
    } else {
        ClearImagePreview()
    }
return

ShowGameIcon(rowIndex) {
    iconPath := IconPaths%rowIndex%

    if (iconPath != "" && FileExist(iconPath)) {
        GuiControl,, GameIcon, %iconPath%
        GuiControl,, ImageStatus, Click icon for larger view
        CurrentSelectedRow := rowIndex
    } else {
        GuiControl,, GameIcon,
        GuiControl,, ImageStatus, No icon available
        CurrentSelectedRow := rowIndex
    }
}

UpdateFavoriteButton(rowIndex) {
    isFavorite := FavoriteStatus%rowIndex%
    if (isFavorite = 1) {
        GuiControl,, Button8, Remove Favorite
    } else {
        GuiControl,, Button8, Add Favorite
    }
}

ToggleFavorite:
    selectedRow := LV_GetNext()
    if (!selectedRow) {
        MsgBox, 48, No Selection, Please select a game from the list.
        return
    }

    gameId := GameIds%selectedRow%
    currentFavorite := FavoriteStatus%selectedRow%
    newFavorite := (currentFavorite = 1) ? 0 : 1

    sql := "UPDATE games SET Favorite = " . newFavorite . " WHERE GameId = '" . StrReplace(gameId, "'", "''") . "'"

    if !db.Exec(sql) {
        MsgBox, 16, Database Error, % "Failed to update favorite status:`n" . db.ErrorMsg
        return
    }

    FavoriteStatus%selectedRow% := newFavorite
    favoriteIcon := (newFavorite = 1) ? "★" : ""
    LV_Modify(selectedRow, Col1, favoriteIcon)
    UpdateFavoriteButton(selectedRow)

    statusText := (newFavorite = 1) ? "added to" : "removed from"
    LV_GetText(gameTitle, selectedRow, 3)
    MsgBox, 64, Success, % gameTitle . " has been " . statusText . " favorites!"
return

ShowLargeImage:
    if (CurrentSelectedRow <= 0 || PicPaths%CurrentSelectedRow% = "")
        return

    picPath := PicPaths%CurrentSelectedRow%

    if (!FileExist(picPath)) {
        MsgBox, 48, Image Not Found, Large image not available for this game.
        return
    }

    Gui, 2: New, +Resize +MaximizeBox, Game Image
    Gui, 2: Add, Picture, x10 y10, %picPath%
    Gui, 2: Show, w600 h400
return

2GuiClose:
    Gui, 2: Destroy
return

ClearImagePreview() {
    GuiControl,, GameIcon,
    GuiControl,, ImageStatus, Select a game to see its icon
    GuiControl,, Button8, Toggle Favorite
    CurrentSelectedRow := 0
}

LaunchGame:
    selectedRow := LV_GetNext()
    if (!selectedRow) {
        MsgBox, 48, No Selection, Please select a game from the list.
        return
    }

    LV_GetText(gameId, selectedRow, 2)
    LV_GetText(gameTitle, selectedRow, 3)
    ebootPath := EbootPaths%selectedRow%

    if (ebootPath = "") {
        MsgBox, 16, Error, Could not find Eboot path for selected game.
        return
    }

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
    GuiControl,, SearchTerm
    LV_Delete()
    ClearImagePreview()

    Loop, 100 {
        GameIds%A_Index% := ""
        EbootPaths%A_Index% := ""
        IconPaths%A_Index% := ""
        PicPaths%A_Index% := ""
        FavoriteStatus%A_Index% := ""
    }
return

ResultsListDoubleClick:
    Gosub, LaunchGame
return

Join(sep, ByRef arr) {
    out := ""
    for index, val in arr
        out .= (index > 1 ? sep : "") . val
    return out
}

GuiClose:
ExitApp
