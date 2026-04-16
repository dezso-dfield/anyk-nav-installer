@echo off
setlocal enabledelayedexpansion
title ÁNYK – NAV  •  Eltávolítás – Windows

net session >nul 2>&1
if %errorLevel% neq 0 (
    powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

cls
echo.
echo   +==========================================+
echo   ^|   ÁNYK - NAV  *  Eltavolitás - Windows  ^|
echo   +==========================================+
echo.

set "INSTALL_DIR=%USERPROFILE%\abevjava"
set "CONFIG_FILE=%USERPROFILE%\.abevjava\abevjavapath.cfg"

if exist "%CONFIG_FILE%" (
    for /f "tokens=3" %%a in ('findstr "abevjava.path" "%CONFIG_FILE%"') do set "INSTALL_DIR=%%a"
)

echo   Ez az ANYK teljes eltavolitasat vegzi.
echo.
echo   Konyvtar : %INSTALL_DIR%
echo   Config   : %USERPROFILE%\.abevjava
echo   Asztali  : ANYK - NAV
echo.
echo   [!] Nyomtatvanyok es mentesek is torlodnek!
echo.
set /p CONFIRM="  Biztosan folytatod? (igen/nem): "
if /i not "%CONFIRM%"=="igen" ( echo   Megszakitva. & pause & exit /b 0 )

echo.
if exist "%INSTALL_DIR%"           ( rd /s /q "%INSTALL_DIR%"           & echo   [OK] %INSTALL_DIR% torolve )
if exist "%USERPROFILE%\.abevjava" ( rd /s /q "%USERPROFILE%\.abevjava" & echo   [OK] Config torolve )
for %%f in (
    "%USERPROFILE%\Desktop\ANYK - NAV.lnk"
    "%USERPROFILE%\Desktop\ANYK - NAV.bat"
    "%USERPROFILE%\Desktop\AbevJava.lnk"
    "%USERPROFILE%\Desktop\AbevJava.bat"
) do ( if exist %%f ( del /f /q %%f & echo   [OK] %%~nxf torolve ) )

echo.
set /p RJ="  Eltavolitsuk a Zulu JDK 8-at is? (igen/nem): "
if /i "%RJ%"=="igen" (
    winget uninstall --id Azul.Zulu.8 --silent 2>nul && echo   [OK] Zulu JDK 8 eltavolitva
)

echo.
echo   +==========================================+
echo   ^|      ANYK sikeresen eltavolitva!        ^|
echo   +==========================================+
echo.
pause
