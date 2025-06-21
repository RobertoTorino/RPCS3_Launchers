#SingleInstance Force
#NoEnv
#Include %A_ScriptDir%\SQLiteDB.ahk

db := new SQLiteDB()
if !db.OpenDB(A_ScriptDir . "\games.db") {
    err := db.ErrorMsg
    MsgBox, 16, DB Error, Failed to open DB.`n%err%
    ExitApp
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
    ; Start with a working query that we know passes the tests
    sql := "SELECT GameId, GameTitle, Eboot, Icon0, Pic1, Favorite FROM games " . whereClause . " ORDER BY GameTitle LIMIT 100"

    MsgBox, 0, Debug SQL, Executing SQL:`n%sql%

    ; Try the query and check for errors immediately
    queryResult := db.GetTable(sql, result)

    if (!queryResult) {
        ; Get detailed error information
        errMsg := db.ErrorMsg
        errCode := db.ErrorCode
        sqlText := db.SQL

        ; Try to get more detailed SQLite error
        dbErrorCode := db._ErrCode()
        dbErrorMsg := db._ErrMsg()

        MsgBox, 16, Query Error Details, Query failed:`n`nClass Error Message: %errMsg%`nClass Error Code: %errCode%`n`nDirect SQLite Error Code: %dbErrorCode%`nDirect SQLite Error Message: %dbErrorMsg%`n`nSQL: %sql%

        ; Try a simpler query to isolate the problem
        MsgBox, 0, Trying Simpler, Trying simpler query without IFNULL...

        simpleSQL := "SELECT GameId, GameTitle FROM games " . whereClause . " ORDER BY GameTitle LIMIT 5"
        if (db.GetTable(simpleSQL, simpleResult)) {
            MsgBox, 0, Simple Works, Simple query works! The issue might be with specific columns or IFNULL.

            ; Try adding columns one by one
            testSQL := "SELECT GameId, GameTitle, Eboot FROM games " . whereClause . " ORDER BY GameTitle LIMIT 5"
            if (!db.GetTable(testSQL, testResult)) {
                MsgBox, 16, Eboot Issue, Problem is with Eboot column
                return
            }

            testSQL := "SELECT GameId, GameTitle, Eboot, Icon0 FROM games " . whereClause . " ORDER BY GameTitle LIMIT 5"
            if (!db.GetTable(testSQL, testResult)) {
                MsgBox, 16, Icon0 Issue, Problem is with Icon0 column
                return
            }

            testSQL := "SELECT GameId, GameTitle, Eboot, Icon0, Pic1 FROM games " . whereClause . " ORDER BY GameTitle LIMIT 5"
            if (!db.GetTable(testSQL, testResult)) {
                MsgBox, 16, Pic1 Issue, Problem is with Pic1 column
                return
            }

            testSQL := "SELECT GameId, GameTitle, Eboot, Icon0, Pic1, Favorite FROM games " . whereClause . " ORDER BY GameTitle LIMIT 5"
            if (!db.GetTable(testSQL, testResult)) {
                MsgBox, 16, Favorite Issue, Problem is with Favorite column combination
                return
            }

            ; If we get here, use the working simple query
            MsgBox, 0, Using Simple, All individual columns work. Using simple query.
            PopulateListView(testResult, false)  ; false = no full column support

        } else {
            MsgBox, 16, Simple Failed, Even simple query failed. Check your WHERE clause.
        }
        return
    }

    ; Query succeeded
    PopulateListView(result, true)  ; true = full column support
}

PopulateListView(result, fullColumns) {
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

            GameIds%A_Index% := tempGameId
            GameTitles%A_Index% := tempGameTitle

            if (fullColumns) {
                ; Full column support
                tempEbootPath := row[3]
                tempIconPath := row[4]
                tempPicPath := row[5]
                tempFavorite := row[6]

                EbootPaths%A_Index% := tempEbootPath
                IconPaths%A_Index% := tempIconPath
                PicPaths%A_Index% := tempPicPath
                FavoriteStatus%A_Index% := tempFavorite

                favoriteIcon := (tempFavorite = 1) ? "★" : ""
                LV_Add("", favoriteIcon, tempGameId, tempGameTitle)
            } else {
                ; Limited column support - set defaults
                EbootPaths%A_Index% := (row.MaxIndex() >= 3) ? row[3] : ""
                IconPaths%A_Index% := ""
                PicPaths%A_Index% := ""
                FavoriteStatus%A_Index% := 0

                LV_Add("", "", tempGameId, tempGameTitle)
            }
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
