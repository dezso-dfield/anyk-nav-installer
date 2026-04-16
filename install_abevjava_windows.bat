@echo off
setlocal enabledelayedexpansion
title ÁNYK – NAV Telepítő – Windows

:: ============================================================
::   ÁNYK - NAV One-Click Installer for Windows
::   Supports: Windows 10 / 11 (64-bit)
:: ============================================================

:: ── Auto-elevate to Administrator ────────────────────────
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo   Adminisztrátori jogosultság szükséges. Újraindítás...
    powershell -NoProfile -Command ^
      "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

cls
echo.
echo   +==========================================+
echo   ^|    ÁNYK – NAV Telepítő – Windows        ^|
echo   ^|   Automatikus telepítő – minden lépés   ^|
echo   +==========================================+
echo.

set "DOWNLOAD_URL=https://nav.gov.hu/pfile/programFile?path=/nyomtatvanyok/letoltesek/nyomtatvanykitolto_programok/nyomtatvany_apeh/keretprogramok/AbevJava"
set "JAR_FILE=%TEMP%\abevjava_install.jar"
set "INSTALL_DIR=%USERPROFILE%\abevjava"

:: ── Step 1: Java 8 ───────────────────────────────────────
echo   [1/4] Java 8 ellenőrzése...
echo.

set "JAVA_OK=0"

:: Check if java exists and is version 8
java -version 2>&1 | findstr /i "1\.8\." >nul 2>&1
if %errorLevel% equ 0 (
    echo   [OK] Java 8 már telepítve
    set "JAVA_OK=1"
)

if "%JAVA_OK%"=="0" (
    echo   Java 8 nincs telepítve. Telepítés most...
    echo.

    :: Try winget first (Windows 10/11 built-in)
    winget --version >nul 2>&1
    if %errorLevel% equ 0 (
        echo   Telepítés winget segítségével...
        winget install --id Azul.Zulu.8 --silent --accept-source-agreements --accept-package-agreements
        if !errorLevel! equ 0 (
            echo   [OK] Java 8 telepítve winget segítségével
            set "JAVA_OK=1"
            :: Refresh PATH
            for /f "tokens=2*" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v Path 2^>nul') do set "SYS_PATH=%%b"
            set "PATH=!SYS_PATH!;%PATH%"
        )
    )

    :: Fallback: direct download
    if "%JAVA_OK%"=="0" (
        echo   Letöltés közvetlen linkről...
        set "ZULU_URL=https://cdn.azul.com/zulu/bin/zulu8.92.0.21-ca-jdk8.0.482-win_x64.msi"
        set "ZULU_MSI=%TEMP%\zulu8_jdk.msi"

        powershell -NoProfile -Command "Invoke-WebRequest -Uri '!ZULU_URL!' -OutFile '!ZULU_MSI!' -UseBasicParsing"
        if !errorLevel! neq 0 (
            echo   [HIBA] Java 8 letöltése sikertelen. Ellenőrizd az internet kapcsolatot.
            pause
            exit /b 1
        )

        msiexec /i "!ZULU_MSI!" /quiet /norestart ADDLOCAL=ALL
        if !errorLevel! neq 0 (
            echo   [HIBA] Java 8 telepítése sikertelen.
            pause
            exit /b 1
        )

        :: Refresh PATH again
        for /f "tokens=2*" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v Path 2^>nul') do set "SYS_PATH=%%b"
        set "PATH=!SYS_PATH!;%PATH%"
        set "JAVA_OK=1"
        echo   [OK] Java 8 telepítve
    )
)

if "%JAVA_OK%"=="0" (
    echo   [HIBA] Java 8 telepítése nem sikerült.
    pause
    exit /b 1
)

:: ── Step 2: Download AbevJava ────────────────────────────
echo.
echo   [2/4] AbevJava letöltése a NAV szerveréről...
echo   URL: %DOWNLOAD_URL%
echo.

powershell -NoProfile -Command "Invoke-WebRequest -Uri '%DOWNLOAD_URL%' -OutFile '%JAR_FILE%' -UseBasicParsing"
if %errorLevel% neq 0 (
    echo   [HIBA] AbevJava letöltése sikertelen. Ellenőrizd az internet kapcsolatot.
    pause
    exit /b 1
)
echo   [OK] Letöltés kész

:: ── Step 3: Run Installer ────────────────────────────────
echo.
echo   [3/4] AbevJava telepítő futtatása
echo.
echo   ====================================================
echo   FONTOS: A megnyíló ablakban a Könyvtár mezőbe
echo   írd be pontosan ezt:
echo.
echo     %INSTALL_DIR%
echo.
echo   Majd kattints a 'Tovább' gombra, végül 'Befejez'.
echo   ====================================================
echo.
pause

java -jar "%JAR_FILE%"

:: ── Step 4: Create Desktop Launcher ─────────────────────
echo.
echo   [4/4] Asztali indító és parancsikon létrehozása...

set "LAUNCHER=%USERPROFILE%\Desktop\ÁNYK - NAV.bat"
(
    echo @echo off
    echo cd /d "%INSTALL_DIR%"
    echo if exist abevjava_start.bat ^(
    echo     call abevjava_start.bat
    echo ^) else ^(
    echo     java -jar abevjava.jar cfg=cfg.enyk
    echo ^)
) > "%LAUNCHER%"

:: Create a .lnk shortcut using PowerShell
powershell -NoProfile -Command ^
  "$s=(New-Object -COM WScript.Shell).CreateShortcut('%USERPROFILE%\Desktop\ÁNYK - NAV.lnk');" ^
  "$s.TargetPath='%INSTALL_DIR%\abevjava_start.bat';" ^
  "$s.WorkingDirectory='%INSTALL_DIR%';" ^
  "$s.Description='ÁNYK – NAV nyomtatványkitöltő';" ^
  "$s.Save()"

echo   [OK] Asztali ikon létrehozva: ÁNYK - NAV

:: Cleanup
del /f /q "%JAR_FILE%" 2>nul

:: ── Done ─────────────────────────────────────────────────
echo.
echo   +==========================================+
echo   ^|       Telepítés sikeresen kész!         ^|
echo   +==========================================+
echo.
echo   ÁNYK – NAV indítása:
echo     1. Duplaklikk az 'ÁNYK - NAV' ikonra az asztalon
echo     2. Vagy: %INSTALL_DIR%\abevjava_start.bat
echo.
pause
