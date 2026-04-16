@echo off
setlocal enabledelayedexpansion
title ÁNYK – NAV Frissítő – Windows

:: Auto-elevate
net session >nul 2>&1
if %errorLevel% neq 0 (
    powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

cls
echo.
echo   +==========================================+
echo   ^|     ÁNYK – NAV Frissítő – Windows       ^|
echo   +==========================================+
echo.

set "INSTALL_DIR=%USERPROFILE%\abevjava"
set "CONFIG_FILE=%USERPROFILE%\.abevjava\abevjavapath.cfg"
set "DOWNLOAD_URL=https://nav.gov.hu/pfile/programFile?path=/nyomtatvanyok/letoltesek/nyomtatvanykitolto_programok/nyomtatvany_apeh/keretprogramok/AbevJava"
set "JAR_FILE=%TEMP%\abevjava_install.jar"

:: Read install path
if exist "%CONFIG_FILE%" (
    for /f "tokens=3" %%a in ('findstr "abevjava.path" "%CONFIG_FILE%"') do set "INSTALL_DIR=%%a"
)

if not exist "%INSTALL_DIR%" (
    echo   [!] Az ÁNYK nincs telepítve. Futtasd az install_abevjava_windows.bat szkriptet.
    pause & exit /b 1
)

echo   Jelenlegi telepítés: %INSTALL_DIR%
echo.

:: Step 1: Backup
echo   [1/4] Nyomtatványok biztonsági mentése...
set "BACKUP=%TEMP%\anyk_backup"
if exist "%BACKUP%" rd /s /q "%BACKUP%"
mkdir "%BACKUP%"
for %%d in (nyomtatvanyok nyomtatvanyok_archivum beallitasok mentesek) do (
    if exist "%INSTALL_DIR%\%%d" xcopy /e /i /q "%INSTALL_DIR%\%%d" "%BACKUP%\%%d" >nul
)
echo   [OK] Biztonsági mentés: %BACKUP%

:: Step 2: Try built-in updater or re-download
echo.
echo   [2/4] Frissítés...
if exist "%INSTALL_DIR%\abevjava_update.bat" (
    echo   Beépített frissítő futtatása...
    cd /d "%INSTALL_DIR%"
    call abevjava_update.bat
    echo   [OK] Beépített frissítő lefutott
) else (
    echo   Letöltés NAV szerveréről...
    powershell -NoProfile -Command "Invoke-WebRequest -Uri '%DOWNLOAD_URL%' -OutFile '%JAR_FILE%' -UseBasicParsing"
    echo.
    echo   ====================================================
    echo   Könyvtár mezőbe írd be: %INSTALL_DIR%
    echo   ====================================================
    pause
    java -jar "%JAR_FILE%"
    del /f /q "%JAR_FILE%" 2>nul
)

:: Step 3: Restore
echo.
echo   [3/4] Adatok visszaállítása...
for %%d in (nyomtatvanyok nyomtatvanyok_archivum beallitasok mentesek) do (
    if exist "%BACKUP%\%%d" xcopy /e /i /q "%BACKUP%\%%d" "%INSTALL_DIR%\%%d" >nul
)
rd /s /q "%BACKUP%" 2>nul
echo   [OK] Adatok visszaállítva

:: Step 4: Done
echo.
echo   [4/4] Kész.
echo.
echo   +==========================================+
echo   ^|       Frissítés sikeresen kész!         ^|
echo   +==========================================+
echo.
pause
