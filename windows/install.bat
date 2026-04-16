@echo off
setlocal enabledelayedexpansion
title ÁNYK – NAV  •  Telepítés – Windows

net session >nul 2>&1
if %errorLevel% neq 0 (
    powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

cls
echo.
echo   +==========================================+
echo   ^|   ÁNYK - NAV  *  Telepítés - Windows    ^|
echo   +==========================================+
echo.

set "DOWNLOAD_URL=https://nav.gov.hu/pfile/programFile?path=/nyomtatvanyok/letoltesek/nyomtatvanykitolto_programok/nyomtatvany_apeh/keretprogramok/AbevJava"
set "JAR_FILE=%TEMP%\abevjava_install.jar"
set "INSTALL_DIR=%USERPROFILE%\abevjava"

echo   [1/4] Java 8 ellenorzese...
set "JAVA_OK=0"
java -version 2>&1 | findstr /i "1\.8\." >nul 2>&1
if %errorLevel% equ 0 ( set "JAVA_OK=1" & echo   [OK] Java 8 mar telepitve )

if "%JAVA_OK%"=="0" (
    echo   Java 8 telepitese...
    winget --version >nul 2>&1
    if %errorLevel% equ 0 (
        winget install --id Azul.Zulu.8 --silent --accept-source-agreements --accept-package-agreements
        if !errorLevel! equ 0 ( set "JAVA_OK=1" )
    )
    if "%JAVA_OK%"=="0" (
        set "ZULU_URL=https://cdn.azul.com/zulu/bin/zulu8.92.0.21-ca-jdk8.0.482-win_x64.msi"
        powershell -NoProfile -Command "Invoke-WebRequest -Uri '!ZULU_URL!' -OutFile '%TEMP%\zulu8.msi' -UseBasicParsing"
        msiexec /i "%TEMP%\zulu8.msi" /quiet /norestart ADDLOCAL=ALL
        set "JAVA_OK=1"
    )
    for /f "tokens=2*" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v Path 2^>nul') do set "PATH=%%b;%PATH%"
)
if "%JAVA_OK%"=="0" ( echo   [HIBA] Java 8 telepitese sikertelen & pause & exit /b 1 )

echo.
echo   [2/4] ANYK letoltese a NAV szerverol...
powershell -NoProfile -Command "Invoke-WebRequest -Uri '%DOWNLOAD_URL%' -OutFile '%JAR_FILE%' -UseBasicParsing"
if %errorLevel% neq 0 ( echo   [HIBA] Letoltes sikertelen & pause & exit /b 1 )
echo   [OK] Letoltve

echo.
echo   [3/4] Telepito futtatasa
echo.
echo   ====================================================
echo   Konyvtar mezoben add meg: %INSTALL_DIR%
echo   Majd: Tovabb ^> Befejez
echo   ====================================================
echo.
pause
java -jar "%JAR_FILE%"
del /f /q "%JAR_FILE%" 2>nul

echo.
echo   [4/4] Asztali parancsikon letrehozasa...
powershell -NoProfile -Command ^
  "$s=(New-Object -COM WScript.Shell).CreateShortcut('%USERPROFILE%\Desktop\ANYK - NAV.lnk');" ^
  "$s.TargetPath='%INSTALL_DIR%\abevjava_start.bat';" ^
  "$s.WorkingDirectory='%INSTALL_DIR%';" ^
  "$s.Description='ANYK - NAV nyomtatvanykitolto';" ^
  "$s.Save()"
echo   [OK] Parancsikon letrehozva

echo.
echo   +==========================================+
echo   ^|       Telepites sikeresen kesz!         ^|
echo   +==========================================+
echo.
pause
