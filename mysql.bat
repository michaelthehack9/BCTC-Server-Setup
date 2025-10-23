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
set "DATADIR=%MYSQLDIR%\datadir"

REM ==========================
REM Check if MySQL already exists
REM ==========================
if exist "%MYSQLDIR%" (
    echo MySQL folder already exists at %MYSQLDIR%. Skipping installation.
    pause
    exit /b
)

REM ==========================
REM Download & extract MySQL
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
echo MySQL extracted.

REM ==========================
REM Move MySQL into Programs
REM ==========================
if not exist "%PROGRAMSDIR%" mkdir "%PROGRAMSDIR%"
move /Y "mysql" "%PROGRAMSDIR%\"
echo MySQL moved to %MYSQLDIR%

REM ==========================
REM Create my.ini
REM ==========================
if not exist "%DATADIR%" mkdir "%DATADIR%"
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
echo MySQL initialized.

REM ==========================
REM Create hideMysqld.vbs in final location with full path
REM ==========================
echo CreateObject("WScript.Shell").Run """%MYSQLDIR%\bin\mysqld.exe"" --defaults-file=""%MYSQLDIR%\my.ini""", 0, False > "%MYSQLDIR%\bin\hideMysqld.vbs"

REM ==========================
REM Start MySQL server hidden
REM ==========================
cscript "%MYSQLDIR%\bin\hideMysqld.vbs"
echo Waiting for MySQL server to be ready...

REM Wait loop until MySQL is accepting connections
:wait_mysql
"%MYSQLDIR%\bin\mysql.exe" -u root -e "SELECT 1;" >nul 2>&1
if errorlevel 1 (
    timeout /t 1 >nul
    goto wait_mysql
)
echo MySQL server is ready.

REM ==========================
REM Create new user with full privileges
REM ==========================
"%MYSQLDIR%\bin\mysql.exe" -u root -e "CREATE USER 'server'@'localhost' IDENTIFIED BY 'server'; GRANT ALL PRIVILEGES ON *.* TO 'server'@'localhost' WITH GRANT OPTION; FLUSH PRIVILEGES;"
echo User 'server' created with full privileges.

REM ==========================
REM Stop MySQL server
REM ==========================
"%MYSQLDIR%\bin\mysqladmin.exe" -u server -pserver shutdown
echo MySQL server stopped.

REM ==========================
REM Add MySQL bin to user environment variables
REM ==========================
setx MYSQL_BIN "%MYSQLDIR%\bin"
echo Added MySQL bin to user environment variables.

REM ==========================
REM Create uninstall script
REM ==========================
(
echo "%MYSQLDIR%\bin\mysqladmin.exe" -u server -pserver shutdown ^& timeout /t 5 ^>nul ^& rmdir /s /q "%MYSQLDIR%" ^& reg delete "HKCU\Environment" /v MYSQL_BIN /f
) > "%PROGRAMSDIR%\uninstallMySQL.bat"
echo Uninstall script created at %PROGRAMSDIR%\uninstallMySQL.bat

pause
endlocal

