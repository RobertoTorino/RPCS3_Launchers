#SingleInstance Force
#NoEnv
#Include %A_ScriptDir%\SQLiteDB.ahk
#Include %A_ScriptDir%\JSON.ahk
#Include %A_ScriptDir%\Gdip.ahk

SetWorkingDir %A_ScriptDir%

; Initialize
global db := new SQLiteDB()
global games := {}
global hbm := 0

; Paths
dbFile := A_ScriptDir "\games.db"
noImage := A_ScriptDir "\rpcl3_no_image_found.png"

; Startup Checks
if !pToken := Gdip_Startup()
{
    MsgBox 16, GDI+ Error, Failed to initialize GDI+
    ExitApp
}

if !FileExist(dbFile)
{
    MsgBox 16, File Error, Database not found at:`n%dbFile%
    ExitApp
}

if !db.OpenDB(dbFile)
{
    MsgBox 16, SQLite Error, % "Database connection failed!`n" db.ErrorMsg
    ExitApp
}

query := "SELECT GameId, GameTitle, Icon0 FROM games ORDER BY GameTitle LIMIT 10"

if db.Query(query) {
    while db.NextRow() {
        id := db.GetColumnText("GameId")
        title := db.GetColumnText("GameTitle")
        icon := db.GetColumnText("Icon0")
        display := title " [" id "]"
        GuiControl,, GameList, %display%
        games[display] := {id: id, icon: icon}
    }
    db.FreeResults()
} else {
    MsgBox, 16, Query Error, % "Query failed:`n" db.ErrorMsg
}
return



GuiClose:
{
    if (hbm)
        DeleteObject(hbm)

    db.CloseDB()
    Gdip_Shutdown(pToken)
    ExitApp
}
