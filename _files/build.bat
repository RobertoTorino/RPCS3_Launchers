@echo off
setlocal ENABLEEXTENSIONS

REM === CONFIG ===
set SCRIPT_NAME=RPCL.ahk
set BASE_EXE_NAME=RPCS3-PCL
set FINAL_EXE_NAME=RPCL
set WAV_NAME=GOOD_MORNING.wav
set VERSION_FILE=version.dat
set RESOURCE_RC=add_resources.rc
set VERSION_TEMPLATE=version_template.txt
set VERSION_TXT=version.txt
set AHK2EXE_PATH="C:\Program Files\AutoHotkey\Compiler\Ahk2Exe.exe"
set RESOURCE_HACKER="C:\Program Files (x86)\Resource Hacker\ResourceHacker.exe"
set FILES_TO_ZIP=README.txt config.ini LICENSE version.dat

REM === TIMESTAMP ===
for /f %%i in ('powershell -NoProfile -Command "Get-Date -Format ''yyyyMMdd_HHmmss''"') do set DATETIME=%%i

REM === AUTO-INCREMENT VERSION ===
set /p CURRENT_VERSION=<%VERSION_FILE%
for /f "tokens=1-3 delims=." %%a in ("%CURRENT_VERSION%") do (
    set MAJOR=%%a
    set MINOR=%%b
    set PATCH=%%c
)
set /a PATCH+=1
set NEW_VERSION=%MAJOR%.%MINOR%.%PATCH%
echo %NEW_VERSION% > %VERSION_FILE%

REM === GET GIT TAG ===
for /f %%g in ('git describe --tags --abbrev=0 2^>nul') do set GIT_TAG=%%g
if "%GIT_TAG%"=="" set GIT_TAG=NoGitTag

REM === FINAL FILENAMES ===
set FINAL_EXE=%FINAL_EXE_NAME%_%NEW_VERSION%.exe
set ZIP_NAME=%FINAL_EXE_NAME%_%NEW_VERSION%.zip

REM === CLEANUP ===
if exist %BASE_EXE_NAME%.exe del %BASE_EXE_NAME%.exe
if exist %FINAL_EXE% del %FINAL_EXE%
if exist %RESOURCE_RC% del %RESOURCE_RC%
if exist build.log del build.log
if exist %ZIP_NAME% del %ZIP_NAME%

REM === CREATE version.txt from TEMPLATE ===
copy /Y %VERSION_TEMPLATE% %VERSION_TXT% >nul
powershell -Command ^
  "(Get-Content '%VERSION_TXT%') -replace '%%VERSION%%','%NEW_VERSION%' -replace '%%DATETIME%%','%DATETIME%' -replace '%%GIT_TAG%%','%GIT_TAG%' | Set-Content '%VERSION_TXT%'"

REM === COMPILE SCRIPT ===
echo 🔨 Compiling %SCRIPT_NAME% ...
%AHK2EXE_PATH% /in %SCRIPT_NAME% /out %BASE_EXE_NAME%.exe /bin AutoHotkeyU64.exe /icon icon.ico /versioninfo %VERSION_TXT%
if errorlevel 1 (
    echo ❌ Failed to compile AHK script.
    exit /b 1
)

REM === CREATE .RC FILE for embedding resources ===
(
    echo RCDATA GOOD_MORNING %WAV_NAME%
    echo RCDATA VERSION_FILE version.dat
) > %RESOURCE_RC%

REM === EMBED RESOURCES ===
echo 📦 Embedding resources into EXE ...
%RESOURCE_HACKER% -open %BASE_EXE_NAME%.exe -save %FINAL_EXE% -action addoverwrite -res %RESOURCE_RC% -log build.log
if errorlevel 1 (
    echo ❌ Failed to embed resources.
    exit /b 1
)

REM === CLEANUP ===
del %RESOURCE_RC%
del build.log

REM === PACKAGE ZIP ===
echo 📦 Creating ZIP: %ZIP_NAME% ...
powershell -NoProfile -Command ^
  "$files = @('%FINAL_EXE%', %FILES_TO_ZIP:"=,'%'); Compress-Archive -Path $files -DestinationPath '%ZIP_NAME%' -Force"

if errorlevel 1 (
    echo ❌ Failed to create ZIP file.
    exit /b 1
)

REM === LOG TO CHANGELOG ===
echo [%DATETIME%] Built %FINAL_EXE% version %NEW_VERSION% tag %GIT_TAG% >> changelog.txt

echo ✅ Build and ZIP complete: %ZIP_NAME%

endlocal
