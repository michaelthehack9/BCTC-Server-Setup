@echo off
call :banner
call :showList
call :getInput
pause
exit /B 0

:banner
echo:
echo:
echo:
echo  ________      ________    ________      ________      ___  ___      _______
echo ^|\   __  \    ^|\   __  \  ^|\   __  \    ^|\   ____\    ^|\  \^|\  \    ^|\  ___ \
echo \ \  \^|\  \   \ \  \^|\  \ \ \  \^|\  \   \ \  \___^|    \ \  \\\  \   \ \   __/^|
echo  \ \   __  \   \ \   ____\ \ \   __  \   \ \  \        \ \   __  \   \ \  \_^|/__
echo   \ \  \ \  \   \ \  \___^|  \ \  \ \  \   \ \  \____    \ \  \ \  \   \ \  \_^|\ \
echo    \ \__\ \__\   \ \__\      \ \__\ \__\   \ \_______\   \ \__\ \__\   \ \_______\
echo     \^|__^|\^|__^|    \^|__^|       \^|__^|\^|__^|    \^|_______^|    \^|__^|\^|__^|    \^|_______^|
echo:
echo:
echo:
exit /B 0
:showList
echo:
echo:
echo:
echo ------ 1) ^Start
echo ---- 2) ^Stop
exit /B 0

:getInput
set /p input=--^> 
if %input% == 1 call :startAll
if %input% == 2 call :stopAll
exit /B 0

:startAll
%MYSQL_BIN%\hideMysqld.vbs
%APACHE_BIN%\hideApache.vbs
echo Services Started
exit /B 0

:stopAll
%MYSQL_BIN%\mysqladmin -u server -pserver shutdown
taskkill /F /im apache.exe
echo Services Stopped
exit /B 0

