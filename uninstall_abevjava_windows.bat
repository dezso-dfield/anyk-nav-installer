@echo off
setlocal enabledelayedexpansion
title ÁNYK – NAV Eltávolító – Windows

:: Auto-elevate
net session >nul 2>&1
if %errorLevel% neq 0 (
    powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

cls
echo.
echo   +==========================================+
echo   ^|    ÁNYK – NAV Eltávolító – Windows      ^|
echo   +==========================================+
echo.

set "INSTALL_DIR=%USERPROFILE%\abevjava"
set "CONFIG_FILE=%USERPROFILE%\.abevjava\abevjavapath.cfg"

:: Read install path from config if exists
if exist "%CONFIG_FILE%" (
    for /f "tokens=3" %%a in ('findstr "abevjava.path" "%CONFIG_FILE%"') do set "INSTALL_DIR=%%a"
)

echo   Ez eltávolítja az ÁNYK szoftvert a gépedről.
echo.
echo   Telepítési könyvtár : %INSTALL_DIR%
echo   Config könyvtár     : %USERPROFILE%\.abevjava
echo   Asztali parancsikon : ÁNYK - NAV
echo.
echo   [!] A nyomtatványok és mentések is törlődnek!
echo.
set /p CONFIRM="  Biztosan folytatod? (igen/nem): "
if /i not "%CONFIRM%"=="igen" (
    echo   Megszakítva.
    pause & exit /b 0
)

echo.
echo   Eltávolítás...

:: Remove install directory
if exist "%INSTALL_DIR%" (
    rd /s /q "%INSTALL_DIR%"
    echo   [OK] %INSTALL_DIR% törölve
) else (
    echo   [!] %INSTALL_DIR% nem található
)

:: Remove config
if exist "%USERPROFILE%\.abevjava" (
    rd /s /q "%USERPROFILE%\.abevjava"
    echo   [OK] .abevjava config törölve
)

:: Remove desktop launchers
for %%f in (
    "%USERPROFILE%\Desktop\ÁNYK - NAV.lnk"
    "%USERPROFILE%\Desktop\ÁNYK - NAV.bat"
    "%USERPROFILE%\Desktop\AbevJava.lnk"
    "%USERPROFILE%\Desktop\AbevJava.bat"
) do (
    if exist %%f (
        del /f /q %%f
        echo   [OK] Asztali ikon törölve: %%~nxf
    )
)

:: Ask about Java 8
echo.
set /p REMOVEJAVA="  Eltávolítsuk a Java 8 (Zulu) -t is? (igen/nem): "
if /i "%REMOVEJAVA%"=="igen" (
    winget uninstall --id Azul.Zulu.8 --silent 2>nul && (
        echo   [OK] Zulu JDK 8 eltávolítva
    ) || (
        echo   [!] Zulu JDK 8 nem található winget-ben
    )
)

echo.
echo   +==========================================+
echo   ^|      ÁNYK sikeresen eltávolítva!        ^|
echo   +==========================================+
echo.
pause
