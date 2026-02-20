@echo off
setlocal enabledelayedexpansion

echo =====================================
echo   MySQL Database Copy Utility
echo =====================================

REM ==========================
REM Detect current username
REM ==========================
for /f "usebackq delims=" %%A in (`whoami`) do set "full=%%A"
set "user=!full:~8!"
echo [INFO] Detected username: !user!

REM ==========================
REM Set MySQL paths (your logic)
REM ==========================
set "PROGRAMSDIR=C:\Users\!user!\AppData\Local\Programs"
set "MYSQLDIR=%PROGRAMSDIR%\mysql"
set "MYSQLBIN=%MYSQLDIR%\bin"

echo [INFO] Using MySQL bin: %MYSQLBIN%

REM ==========================
REM Verify MySQL exists
REM ==========================
if not exist "%MYSQLBIN%\mysqldump.exe" (
    echo [ERROR] MySQL not found at %MYSQLBIN%
    pause
    exit /b 1
)

REM ==========================
REM Settings
REM ==========================
set "USER=root"
set "PASS="
set "SOURCE_DB=bctcdb"
set "TARGET_DB=olddb"
set "DUMP_FILE=%TEMP%\bctcdb_dump.sql"

echo.
echo [STEP] Dumping %SOURCE_DB%...
"%MYSQLBIN%\mysqldump.exe" -u %USER% %SOURCE_DB% > "%DUMP_FILE%"
if errorlevel 1 (
    echo [ERROR] Dump failed. Aborting.
    pause
    exit /b 1
)
echo [OK] Dump created.

echo.
echo [STEP] Creating database %TARGET_DB%...
"%MYSQLBIN%\mysql.exe" -u %USER% -e "CREATE DATABASE IF NOT EXISTS %TARGET_DB%;"
if errorlevel 1 (
    echo [ERROR] Failed to create target database.
    pause
    exit /b 1
)
echo [OK] Target database ready.

echo.
echo [STEP] Importing into %TARGET_DB%...
"%MYSQLBIN%\mysql.exe" -u %USER% %TARGET_DB% < "%DUMP_FILE%"
if errorlevel 1 (
    echo [ERROR] Import failed. Source database NOT deleted.
    pause
    exit /b 1
)
echo [OK] Import successful.

echo.
echo [STEP] Cleaning up dump file...
del /f /q "%DUMP_FILE%"
echo [OK] Dump file removed.

echo.
echo [STEP] Dropping original database %SOURCE_DB%...
"%MYSQLBIN%\mysql.exe" -u %USER% -e "DROP DATABASE %SOURCE_DB%;"
if errorlevel 1 (
    echo [WARNING] Could not drop source database.
) else (
    echo [OK] Source database removed.
)

echo.
echo =====================================
echo   Operation completed successfully
echo =====================================
pause
endlocal