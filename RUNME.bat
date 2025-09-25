@echo off
setlocal enabledelayedexpansion

REM ==========================
REM Detect current username
REM ==========================
for /f "usebackq delims=" %%A in (`whoami`) do set "full=%%A"
set "user=!full:~8!"
echo Detected username: !user!

REM ==========================
REM Set target MySQL folder
REM ==========================
set "PROGRAMSDIR=C:\Users\!user!\AppData\Local\Programs"
set "MYSQLDIR=%PROGRAMSDIR%\mysql"

REM ==========================
REM Check if MySQL already exists
REM ==========================
if exist "%MYSQLDIR%" (
    echo MySQL folder already exists at %MYSQLDIR%. Skipping installation.
    pause
    goto :SELFDELETE
)

REM ==========================
REM Download & extract MySQL in current directory
REM ==========================
set "VERSION=9.4.0"
set "DOWNLOAD_URL=https://dev.mysql.com/get/Downloads/MySQL-9.4/mysql-%VERSION%-winx64.zip"
set "ZIP_FILE=mysql-%VERSION%-winx64.zip"

echo Downloading MySQL %VERSION%...
powershell -Command "Start-BitsTransfer -Source '%DOWNLOAD_URL%' -Destination '%ZIP_FILE%'"

echo Extracting MySQL...
powershell -Command "Expand-Archive -Path '%ZIP_FILE%' -DestinationPath '.' -Force"
ren mysql-%VERSION%-winx64 mysql
del "%ZIP_FILE%"
echo MySQL extracted in current directory.

REM ==========================
REM Move MySQL into Programs
REM ==========================
if not exist "%PROGRAMSDIR%" mkdir "%PROGRAMSDIR%"
move /Y "mysql" "%PROGRAMSDIR%\"
echo MySQL moved to %MYSQLDIR%

REM ==========================
REM Create my.ini with forward slashes
REM ==========================
(
  echo [mysqld]
  echo basedir=C:/Users/!user!/AppData/Local/Programs/mysql
  echo datadir=C:/Users/!user!/AppData/Local/Programs/mysql/datadir
  echo port=3306
) > "%MYSQLDIR%\my.ini"
echo my.ini created.

REM ==========================
REM Initialize MySQL (insecure)
REM ==========================
"%MYSQLDIR%\bin\mysqld.exe" --defaults-file=%MYSQLDIR%/my.ini --initialize-insecure --console

:SELFDELETE
REM ==========================
REM Self-delete the script
REM ==========================
echo Deleting this script...
start "" cmd /c "ping localhost -n 2 >nul & del "%~f0""
endlocal
