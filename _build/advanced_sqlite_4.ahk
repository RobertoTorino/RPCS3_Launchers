#SingleInstance Force
#NoEnv
#Include %A_ScriptDir%\SQLiteDB.ahk

db := new SQLiteDB()
if !db.OpenDB(A_ScriptDir . "\games.db") {
    err := db.ErrorMsg
    MsgBox, 16, DB Error, Failed to open DB.`n%err%
    ExitApp
}

; Test basic connectivity first
MsgBox, 0, Testing, Testing basic database query...

; Test 1: Very simple query
sql := "SELECT COUNT(*) FROM games"
if !db.GetTable(sql, result) {
    errMsg := db.ErrorMsg
    MsgBox, 16, Test 1 Failed, Simple COUNT query failed:`n%errMsg%
    ExitApp
} else {
    result.GetRow(1, row)
    rowCount := row[1]
    MsgBox, 0, Test 1 Success, Found %rowCount% games in database
}

; Test 2: Basic SELECT with just GameId and GameTitle
sql := "SELECT GameId, GameTitle FROM games LIMIT 5"
if !db.GetTable(sql, result) {
    errMsg := db.ErrorMsg
    MsgBox, 16, Test 2 Failed, Basic SELECT failed:`n%errMsg%
    ExitApp
} else {
    rowCount := result.RowCount
    MsgBox, 0, Test 2 Success, Basic SELECT works. Found %rowCount% rows
}

; Test 3: Add WHERE clause
sql := "SELECT GameId, GameTitle FROM games WHERE GameTitle LIKE '%a%' LIMIT 5"
if !db.GetTable(sql, result) {
    errMsg := db.ErrorMsg
    MsgBox, 16, Test 3 Failed, WHERE clause failed:`n%errMsg%
    ExitApp
} else {
    rowCount := result.RowCount
    MsgBox, 0, Test 3 Success, WHERE clause works. Found %rowCount% rows
}

; Test 4: Add Eboot column
sql := "SELECT GameId, GameTitle, Eboot FROM games WHERE GameTitle LIKE '%a%' LIMIT 5"
if !db.GetTable(sql, result) {
    errMsg := db.ErrorMsg
    MsgBox, 16, Test 4 Failed, Adding Eboot failed:`n%errMsg%
    ExitApp
} else {
    rowCount := result.RowCount
    MsgBox, 0, Test 4 Success, Eboot column works. Found %rowCount% rows
}

; Test 5: Add Icon0 column
sql := "SELECT GameId, GameTitle, Eboot, Icon0 FROM games WHERE GameTitle LIKE '%a%' LIMIT 5"
if !db.GetTable(sql, result) {
    errMsg := db.ErrorMsg
    MsgBox, 16, Test 5 Failed, Adding Icon0 failed:`n%errMsg%
    ; Try alternative - maybe Icon0 has NULL values causing issues
    sql := "SELECT GameId, GameTitle, Eboot, IFNULL(Icon0, '') as Icon0 FROM games WHERE GameTitle LIKE '%a%' LIMIT 5"
    if !db.GetTable(sql, result) {
        errMsg := db.ErrorMsg
        MsgBox, 16, Test 5b Failed, Icon0 with IFNULL failed:`n%errMsg%
        ExitApp
    } else {
        MsgBox, 0, Test 5b Success, Icon0 with IFNULL works!
    }
} else {
    rowCount := result.RowCount
    MsgBox, 0, Test 5 Success, Icon0 column works. Found %rowCount% rows
}

; Test 6: Add Pic1 column
sql := "SELECT GameId, GameTitle, Eboot, IFNULL(Icon0, '') as Icon0, IFNULL(Pic1, '') as Pic1 FROM games WHERE GameTitle LIKE '%a%' LIMIT 5"
if !db.GetTable(sql, result) {
    errMsg := db.ErrorMsg
    MsgBox, 16, Test 6 Failed, Adding Pic1 failed:`n%errMsg%
    ExitApp
} else {
    rowCount := result.RowCount
    MsgBox, 0, Test 6 Success, Pic1 column works. Found %rowCount% rows
}

; Test 7: Add Favorite column
sql := "SELECT GameId, GameTitle, Eboot, IFNULL(Icon0, '') as Icon0, IFNULL(Pic1, '') as Pic1, IFNULL(Favorite, 0) as Favorite FROM games WHERE GameTitle LIKE '%a%' LIMIT 5"
if !db.GetTable(sql, result) {
    errMsg := db.ErrorMsg
    MsgBox, 16, Test 7 Failed, Adding Favorite failed:`n%errMsg%
    ExitApp
} else {
    rowCount := result.RowCount
    MsgBox, 0, Test 7 Success, All columns work! Found %rowCount% rows
}

; Test 8: Try your specific search
sql := "SELECT GameId, GameTitle, Eboot, IFNULL(Icon0, '') as Icon0, IFNULL(Pic1, '') as Pic1, IFNULL(Favorite, 0) as Favorite FROM games WHERE (GameTitle LIKE '%Tekken%' OR GameId LIKE '%Tekken%') ORDER BY GameTitle LIMIT 100"
if !db.GetTable(sql, result) {
    errMsg := db.ErrorMsg
    MsgBox, 16, Test 8 Failed, Tekken search failed:`n%errMsg%
    ExitApp
} else {
    rowCount := result.RowCount
    MsgBox, 0, Test 8 Success, Tekken search works! Found %rowCount% rows
    ; Show first result
    if (result.RowCount > 0) {
        result.GetRow(1, row)
        gameId := row[1]
        gameTitle := row[2]
        ebootPath := row[3]
        iconPath := row[4]
        picPath := row[5]
        favorite := row[6]
        MsgBox, 0, First Result, GameId: %gameId%`nTitle: %gameTitle%`nEboot: %ebootPath%`nIcon0: %iconPath%`nPic1: %picPath%`nFavorite: %favorite%
    }
}

MsgBox, 0, All Tests Passed, All database tests passed! Now loading GUI...

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

; Results section
Gui, Add, GroupBox, x10 y170 w380 h200, Results
Gui, Add, ListView, vResultsList x20 y190 w360 h150 Grid -Multi AltSubmit gListViewClick, ★|Game ID|Title
LV_ModifyCol(1, 25)
LV_ModifyCol(2, 80)
LV_ModifyCol(3, 245)

; Image preview section
Gui, Add, GroupBox, x10 y380 w380 h100, Game Preview
Gui, Add, Picture, vGameIcon x20 y400 w64 h64 gShowLargeImage,
Gui, Add, Text, vImageStatus x95 y400, Select a game to see its icon

; Action buttons
Gui, Add, Button, gToggleFavorite x95 y430 w90 h25, Toggle Favorite
Gui, Add, Button, gLaunchGame x200 y400 w80 h30, Launch
Gui, Add, Button, gClearSearch x290 y400 w80 h30, Clear

Gui, Show, w400 h490, Game Search Launcher
return

Search:
    Gui, Submit, NoHide

    searchTerm := Trim(SearchTerm)
    if (searchTerm = "") {
        MsgBox, 48, Input Required, Please enter a search term.
        return
    }

    filters := []
    if (FilterFavorite)
        filters.Push("Favorite = 1")
    if (FilterPlayed)
        filters.Push("Played = 1")
    if (FilterPSN)
        filters.Push("PSN = 1")
    if (FilterArcadeGame)
        filters.Push("ArcadeGame = 1")

    whereClause := "WHERE (GameTitle LIKE '%" . StrReplace(searchTerm, "'", "''") . "%' OR GameId LIKE '%" . StrReplace(searchTerm, "'", "''") . "%')"

    if (filters.MaxIndex() > 0)
        whereClause .= " AND " . Join(" AND ", filters)

    ExecuteQuery(whereClause)
return

ShowOnlyFavorites:
    whereClause := "WHERE Favorite = 1"
    ExecuteQuery(whereClause)
return

ShowAll:
    whereClause := ""
    ExecuteQuery(whereClause)
return

ExecuteQuery(whereClause) {
    ; Use IFNULL to handle NULL values
    sql := "SELECT GameId, GameTitle, IFNULL(Eboot, '') as Eboot, IFNULL(Icon0, '') as Icon0, IFNULL(Pic1, '') as Pic1, IFNULL(Favorite, 0) as Favorite FROM games " . whereClause . " ORDER BY GameTitle LIMIT 100"

    MsgBox, 0, Debug SQL, Executing SQL:`n%sql%

    if !db.GetTable(sql, result) {
        errMsg := db.ErrorMsg
        errCode := db.ErrorCode
        MsgBox, 16, Query Error, Query failed:`nError: %errMsg%`nError Code: %errCode%`n`nSQL: %sql%
        return
    }

    LV_Delete()

    if (result.RowCount = 0) {
        LV_Add("", "", "No results found", "")
        ClearImagePreview()
        return
    }

    Loop, % result.RowCount {
        row := ""
        if result.GetRow(A_Index, row) {
            ; Store data using proper variable names for AHK v1
            tempGameId := row[1]
            tempGameTitle := row[2]
            tempEbootPath := row[3]
            tempIconPath := row[4]
            tempPicPath := row[5]
            tempFavorite := row[6]

            GameIds%A_Index% := tempGameId
            GameTitles%A_Index% := tempGameTitle
            EbootPaths%A_Index% := tempEbootPath
            IconPaths%A_Index% := tempIconPath
            PicPaths%A_Index% := tempPicPath
            FavoriteStatus%A_Index% := tempFavorite

            favoriteIcon := (tempFavorite = 1) ? "★" : ""
            LV_Add("", favoriteIcon, tempGameId, tempGameTitle)
        }
    }

    LV_ModifyCol(1, 25)
    LV_ModifyCol(2, "AutoHdr")
    LV_ModifyCol(3, "AutoHdr")

    ClearImagePreview()
}

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
        errMsg := db.ErrorMsg
        MsgBox, 16, Database Error, Failed to update favorite status:`n%errMsg%
        return
    }

    FavoriteStatus%selectedRow% := newFavorite
    favoriteIcon := (newFavorite = 1) ? "★" : ""
    LV_Modify(selectedRow, Col1, favoriteIcon)
    UpdateFavoriteButton(selectedRow)

    statusText := (newFavorite = 1) ? "added to" : "removed from"
    gameTitle := GameTitles%selectedRow%
    MsgBox, 64, Success, %gameTitle% has been %statusText% favorites!
return

ShowLargeImage:
    if (CurrentSelectedRow <= 0)
        return

    picPath := PicPaths%CurrentSelectedRow%

    if (picPath = "" || !FileExist(picPath)) {
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

    gameId := GameIds%selectedRow%
    gameTitle := GameTitles%selectedRow%
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
        MsgBox, 64, Success, Game launch command written to INI:`n%runCommand%
    }
return

ClearSearch:
    GuiControl,, SearchTerm
    LV_Delete()
    ClearImagePreview()

    Loop, 100 {
        GameIds%A_Index% := ""
        GameTitles%A_Index% := ""
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
