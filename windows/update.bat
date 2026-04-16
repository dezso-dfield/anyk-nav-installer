@echo off
setlocal enabledelayedexpansion
title ÁNYK – NAV  •  Frissítés – Windows

net session >nul 2>&1
if %errorLevel% neq 0 (
    powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

cls
echo.
echo   +==========================================+
echo   ^|    ÁNYK - NAV  *  Frissites - Windows   ^|
echo   +==========================================+
echo.

set "INSTALL_DIR=%USERPROFILE%\abevjava"
set "CONFIG_FILE=%USERPROFILE%\.abevjava\abevjavapath.cfg"
set "DOWNLOAD_URL=https://nav.gov.hu/pfile/programFile?path=/nyomtatvanyok/letoltesek/nyomtatvanykitolto_programok/nyomtatvany_apeh/keretprogramok/AbevJava"
set "JAR_FILE=%TEMP%\abevjava_install.jar"
set "BACKUP=%TEMP%\anyk_backup"

if exist "%CONFIG_FILE%" (
    for /f "tokens=3" %%a in ('findstr "abevjava.path" "%CONFIG_FILE%"') do set "INSTALL_DIR=%%a"
)
if not exist "%INSTALL_DIR%" (
    echo   [!] Az ANYK nincs telepitve. Futtasd az install.bat-ot.
    pause & exit /b 1
)
echo   Telepitesi konyvtar: %INSTALL_DIR%

echo.
echo   [1/4] Biztonsagi mentes...
if exist "%BACKUP%" rd /s /q "%BACKUP%"
mkdir "%BACKUP%"
for %%d in (nyomtatvanyok nyomtatvanyok_archivum beallitasok mentesek) do (
    if exist "%INSTALL_DIR%\%%d" xcopy /e /i /q "%INSTALL_DIR%\%%d" "%BACKUP%\%%d" >nul
)
echo   [OK] Mentes: %BACKUP%

echo.
echo   [2/4] Frissites...
if exist "%INSTALL_DIR%\abevjava_update.bat" (
    cd /d "%INSTALL_DIR%"
    call abevjava_update.bat
) else (
    powershell -NoProfile -Command "Invoke-WebRequest -Uri '%DOWNLOAD_URL%' -OutFile '%JAR_FILE%' -UseBasicParsing"
    echo   Konyvtar: %INSTALL_DIR%
    pause
    java -jar "%JAR_FILE%"
    del /f /q "%JAR_FILE%" 2>nul
)

echo.
echo   [3/4] Adatok visszaallitasa...
for %%d in (nyomtatvanyok nyomtatvanyok_archivum beallitasok mentesek) do (
    if exist "%BACKUP%\%%d" xcopy /e /i /q "%BACKUP%\%%d" "%INSTALL_DIR%\%%d" >nul
)
rd /s /q "%BACKUP%" 2>nul
echo   [OK] Adatok visszaallitva

echo.
echo   [4/4] Kesz.
echo.
echo   +==========================================+
echo   ^|       Frissites sikeresen kesz!         ^|
echo   +==========================================+
echo.
pause
