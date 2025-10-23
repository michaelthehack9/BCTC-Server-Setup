@echo off
setlocal enabledelayedexpansion

REM ==========================
REM Detect current username
REM ==========================
for /f "usebackq delims=" %%A in (`whoami`) do set "full=%%A"
set "user=!full:~8!"
echo Detected username: !user!

REM ==========================
REM Set target folders directly under Programs
REM ==========================
set "PROGRAMSDIR=C:\Users\!user!\AppData\Local\Programs"
set "APACHEDIR=%PROGRAMSDIR%\apache"
set "PHPDIR=%PROGRAMSDIR%\PHP"
set "DOWNLOADS=%USERPROFILE%\Downloads"

REM ==========================
REM Check if already exists
REM ==========================
if exist "%APACHEDIR%" (
    echo Apache folder already exists at %APACHEDIR%. Skipping installation.
    pause
    exit /b
)
if exist "%PHPDIR%" (
    echo PHP folder already exists at %PHPDIR%. Skipping installation.
    pause
    exit /b
)

REM ==========================
REM Download & extract Apache
REM ==========================
set "APACHE_VERSION=2.4.65-250724"
set "APACHE_URL=https://www.apachelounge.com/download/VS17/binaries/httpd-%APACHE_VERSION%-win64-VS17.zip"
set "APACHE_ZIP=%DOWNLOADS%\httpd-%APACHE_VERSION%-win64-VS17.zip"

echo Downloading Apache %APACHE_VERSION%...
powershell -Command "Start-BitsTransfer -Source '%APACHE_URL%' -Destination '%APACHE_ZIP%'"
if not exist "%PROGRAMSDIR%" mkdir "%PROGRAMSDIR%"
echo Extracting Apache...
powershell -Command "Expand-Archive -Path '%APACHE_ZIP%' -DestinationPath '%DOWNLOADS%\apache_temp' -Force"
move /Y "%DOWNLOADS%\apache_temp\Apache24" "%APACHEDIR%" >nul
rmdir /s /q "%DOWNLOADS%\apache_temp"
del "%APACHE_ZIP%"
echo Apache extracted to %APACHEDIR%.

REM ==========================
REM Download & extract PHP
REM ==========================
set "PHP_VERSION=8.4.14"
set "PHP_URL=https://windows.php.net/downloads/releases/php-8.4.13-Win32-vs17-x64.zip"
set "PHP_ZIP=%DOWNLOADS%\php-%PHP_VERSION%-Win32-vs17-x64.zip"

echo Downloading PHP %PHP_VERSION%...
powershell -Command "Start-BitsTransfer -Source '%PHP_URL%' -Destination '%PHP_ZIP%'"

echo Extracting PHP...
powershell -Command "Expand-Archive -Path '%PHP_ZIP%' -DestinationPath '%DOWNLOADS%\PHP_temp' -Force"
move /Y "%DOWNLOADS%\PHP_temp" "%PHPDIR%" >nul
del "%PHP_ZIP%"
echo PHP extracted and moved to %PHPDIR%.

REM ==========================
REM Configure php.ini
REM ==========================
if not exist "%PHPDIR%\php.ini" (
    copy "%PHPDIR%\php.ini-development" "%PHPDIR%\php.ini"
)

powershell -Command "(Get-Content '%PHPDIR%\php.ini') -replace ';extension_dir = ""ext""""','extension_dir=""""%PHPDIR:\=\\%\\ext""""' -replace ';extension=mysqli','extension=mysqli' | Set-Content '%PHPDIR%\php.ini'"

REM ==========================
REM Configure httpd.conf
REM ==========================
set "HTTPDCONF=%APACHEDIR%\conf\httpd.conf"

REM Update SRVROOT
powershell -Command "(Get-Content '%HTTPDCONF%') -replace 'Define SRVROOT ""c:/Apache24""""','Define SRVROOT """"%APACHEDIR:/=/%""""' | Set-Content '%HTTPDCONF%'"

REM Add PHP module integration
echo LoadModule php_module "%PHPDIR:/=/%/php8apache2_4.dll" >> "%HTTPDCONF%"
echo AddType application/x-httpd-php .php >> "%HTTPDCONF%"
echo PHPIniDir "%PHPDIR:/=/%" >> "%HTTPDCONF%"

REM Set ServerName to suppress AH00558 warning
echo ServerName localhost:80 >> "%HTTPDCONF%"

REM Replace DirectoryIndex with index.html index.php (handles leading spaces too)
powershell -Command "(Get-Content '%HTTPDCONF%') -replace '^\s*DirectoryIndex\s+.*','DirectoryIndex index.html index.php' | Set-Content '%HTTPDCONF%'"

REM ==========================
REM Create hideApache.vbs
REM ==========================
echo CreateObject("WScript.Shell").Run """%APACHEDIR%\bin\httpd.exe""", 0, False > "%APACHEDIR%\bin\hideApache.vbs"

REM ==========================
REM Add Apache bin to user environment variables
REM ==========================
setx APACHE_BIN "%APACHEDIR%\bin"
echo Added Apache bin to user environment variables.

REM ==========================
REM Create uninstall script
REM ==========================
(
echo taskkill /F /IM httpd.exe ^>nul 2^>^&1
echo timeout /t 5 ^>nul
echo rmdir /s /q "%APACHEDIR%"
echo rmdir /s /q "%PHPDIR%"
echo reg delete "HKCU\Environment" /v APACHE_BIN /f
) > "%PROGRAMSDIR%\uninstallApachePHP.bat"
echo Uninstall script created at %PROGRAMSDIR%\uninstallApachePHP.bat

echo.
echo ==========================
echo Apache + PHP Installation Complete
echo Start Apache with: cscript "%APACHEDIR%\bin\hideApache.vbs"
echo Your htdocs folder: %APACHEDIR%\htdocs
echo ==========================
pause
endlocal

