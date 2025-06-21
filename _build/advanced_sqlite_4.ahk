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
    ; Try the absolute simplest query first
    sql := "SELECT GameId, GameTitle FROM games " . whereClause . " ORDER BY GameTitle LIMIT 100"
    MsgBox, 0, Trying Simple, Trying simple query: %sql%

    if !db.GetTable(sql, result) {
        MsgBox, 16, Simple Query Failed, Simple query failed - there may be an issue with your WHERE clause or data.
        return
    }

    MsgBox, 0, Simple Success, Simple query worked! Found results. Now trying with more columns...

    ; Try adding Eboot
    sql := "SELECT GameId, GameTitle, Eboot FROM games " . whereClause . " ORDER BY GameTitle LIMIT 100"
    if !db.GetTable(sql, result) {
        MsgBox, 16, Eboot Failed, Query failed when adding Eboot column. Using simple version.
        ; Fall back to simple query
        sql := "SELECT GameId, GameTitle FROM games " . whereClause . " ORDER BY GameTitle LIMIT 100"
        db.GetTable(sql, result)
        PopulateBasic(result)
        return
    }

    MsgBox, 0, Eboot Success, Eboot column works! Trying Icon0...

    ; Try adding Icon0
    sql := "SELECT GameId, GameTitle, Eboot, Icon0 FROM games " . whereClause . " ORDER BY GameTitle LIMIT 100"
    if !db.GetTable(sql, result) {
        MsgBox, 16, Icon0 Failed, Query failed when adding Icon0 column. Using basic version.
        ; Fall back to basic query
        sql := "SELECT GameId, GameTitle, Eboot FROM games " . whereClause . " ORDER BY GameTitle LIMIT 100"
        db.GetTable(sql, result)
        PopulateWithEboot(result)
        return
    }

    MsgBox, 0, Icon0 Success, Icon0 column works! Trying Pic1...

    ; Try adding Pic1
    sql := "SELECT GameId, GameTitle, Eboot, Icon0, Pic1 FROM games " . whereClause . " ORDER BY GameTitle LIMIT 100"
    if !db.GetTable(sql, result) {
        MsgBox, 16, Pic1 Failed, Query failed when adding Pic1 column. Using version without Pic1.
        ; Fall back to version without Pic1
        sql := "SELECT GameId, GameTitle, Eboot, Icon0 FROM games " . whereClause . " ORDER BY GameTitle LIMIT 100"
        db.GetTable(sql, result)
        PopulateWithIcon(result)
        return
    }

    MsgBox, 0, Pic1 Success, Pic1 column works! Trying Favorite...

    ; Try adding Favorite
    sql := "SELECT GameId, GameTitle, Eboot, Icon0, Pic1, Favorite FROM games " . whereClause . " ORDER BY GameTitle LIMIT 100"
    if !db.GetTable(sql, result) {
        MsgBox, 16, Favorite Failed, Query failed when adding Favorite column. Using version without Favorite.
        ; Fall back to version without Favorite
        sql := "SELECT GameId, GameTitle, Eboot, Icon0, Pic1 FROM games " . whereClause . " ORDER BY GameTitle LIMIT 100"
        db.GetTable(sql, result)
        PopulateWithPic(result)
        return
    }

    MsgBox, 0, All Success, All columns work! Using full version.
    PopulateFull(result)
}

PopulateBasic(result) {
    LV_Delete()
    if (result.RowCount = 0) {
        LV_Add("", "", "No results found", "")
        return
    }

    Loop, % result.RowCount {
        row := ""
        if result.GetRow(A_Index, row) {
            GameIds%A_Index% := row[1]
            GameTitles%A_Index% := row[2]
            EbootPaths%A_Index% := ""
            IconPaths%A_Index% := ""
            PicPaths%A_Index% := ""
            FavoriteStatus%A_Index% := 0
            LV_Add("", "", row[1], row[2])
        }
    }
    LV_ModifyCol(2, "AutoHdr")
    LV_ModifyCol(3, "AutoHdr")
}

PopulateWithEboot(result) {
    LV_Delete()
    if (result.RowCount = 0) {
        LV_Add("", "", "No results found", "")
        return
    }

    Loop, % result.RowCount {
        row := ""
        if result.GetRow(A_Index, row) {
            GameIds%A_Index% := row[1]
            GameTitles%A_Index% := row[2]
            EbootPaths%A_Index% := row[3]
            IconPaths%A_Index% := ""
            PicPaths%A_Index% := ""
            FavoriteStatus%A_Index% := 0
            LV_Add("", "", row[1], row[2])
        }
    }
    LV_ModifyCol(2, "AutoHdr")
    LV_ModifyCol(3, "AutoHdr")
}

PopulateWithIcon(result) {
    LV_Delete()
    if (result.RowCount = 0) {
        LV_Add("", "", "No results found", "")
        return
    }

    Loop, % result.RowCount {
        row := ""
        if result.GetRow(A_Index, row) {
            GameIds%A_Index% := row[1]
            GameTitles%A_Index% := row[2]
            EbootPaths%A_Index% := row[3]
            IconPaths%A_Index% := row[4]
            PicPaths%A_Index% := ""
            FavoriteStatus%A_Index% := 0
            LV_Add("", "", row[1], row[2])
        }
    }
    LV_ModifyCol(2, "AutoHdr")
    LV_ModifyCol(3, "AutoHdr")
}

PopulateWithPic(result) {
    LV_Delete()
    if (result.RowCount = 0) {
        LV_Add("", "", "No results found", "")
        return
    }

    Loop, % result.RowCount {
        row := ""
        if result.GetRow(A_Index, row) {
            GameIds%A_Index% := row[1]
            GameTitles%A_Index% := row[2]
            EbootPaths%A_Index% := row[3]
            IconPaths%A_Index% := row[4]
            PicPaths%A_Index% := row[5]
            FavoriteStatus%A_Index% := 0
            LV_Add("", "", row[1], row[2])
        }
    }
    LV_ModifyCol(2, "AutoHdr")
    LV_ModifyCol(3, "AutoHdr")
}

PopulateFull(result) {
    LV_Delete()
    if (result.RowCount = 0) {
        LV_Add("", "", "No results found", "")
        return
    }

    Loop, % result.RowCount {
        row := ""
        if result.GetRow(A_Index, row) {
            GameIds%A_Index% := row[1]
            GameTitles%A_Index% := row[2]
            EbootPaths%A_Index% := row[3]
            IconPaths%A_Index% := row[4]
            PicPaths%A_Index% := row[5]
            FavoriteStatus%A_Index% := row[6]

            favoriteIcon := (row[6] = 1) ? "★" : ""
            LV_Add("", favoriteIcon, row[1], row[2])
        }
    }
    LV_ModifyCol(1, 25)
    LV_ModifyCol(2, "AutoHdr")
    LV_ModifyCol(3, "AutoHdr")
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
        MsgBox, 16, Database Error, Failed to update favorite status
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
