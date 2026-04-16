@echo off
setlocal enabledelayedexpansion
title ÁNYK – NAV Manager – Windows

:: Auto-elevate
net session >nul 2>&1
if %errorLevel% neq 0 (
    powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

:: Launch PowerShell GUI — all logic runs inside PowerShell
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
"^
Add-Type -AssemblyName System.Windows.Forms; ^
Add-Type -AssemblyName System.Drawing; ^
^
$DOWNLOAD_URL = 'https://nav.gov.hu/pfile/programFile?path=/nyomtatvanyok/letoltesek/nyomtatvanykitolto_programok/nyomtatvany_apeh/keretprogramok/AbevJava'; ^
$CONFIG_FILE  = \"$env:USERPROFILE\.abevjava\abevjavapath.cfg\"; ^
$INSTALL_DIR  = \"$env:USERPROFILE\abevjava\"; ^
$JAR_FILE     = \"$env:TEMP\abevjava_install.jar\"; ^
^
function Get-InstallDir { ^
    if (Test-Path $CONFIG_FILE) { ^
        $line = Get-Content $CONFIG_FILE ^| Select-String 'abevjava.path'; ^
        if ($line) { return ($line -split '= ')[1].Trim() } ^
    } ^
    return $INSTALL_DIR ^
} ^
^
function Is-Installed { return (Test-Path (Get-InstallDir)) } ^
^
function Show-Status { ^
    if (Is-Installed) { return 'Telepítve: ' + (Get-InstallDir) } ^
    return 'Nincs telepítve' ^
} ^
^
function Show-MainForm { ^
    $form = New-Object System.Windows.Forms.Form; ^
    $form.Text = 'ÁNYK – NAV Manager'; ^
    $form.Size = New-Object System.Drawing.Size(420, 380); ^
    $form.StartPosition = 'CenterScreen'; ^
    $form.FormBorderStyle = 'FixedDialog'; ^
    $form.MaximizeBox = $false; ^
    $form.BackColor = [System.Drawing.Color]::FromArgb(245,245,245); ^
    ^
    $title = New-Object System.Windows.Forms.Label; ^
    $title.Text = 'ÁNYK – NAV'; ^
    $title.Font = New-Object System.Drawing.Font('Segoe UI', 18, [System.Drawing.FontStyle]::Bold); ^
    $title.Location = New-Object System.Drawing.Point(20,20); ^
    $title.Size = New-Object System.Drawing.Size(380,40); ^
    $title.ForeColor = [System.Drawing.Color]::FromArgb(0,100,180); ^
    $form.Controls.Add($title); ^
    ^
    $subtitle = New-Object System.Windows.Forms.Label; ^
    $subtitle.Text = 'Általános Nyomtatványkitöltő – Hivatalos NAV szoftver'; ^
    $subtitle.Font = New-Object System.Drawing.Font('Segoe UI', 9); ^
    $subtitle.Location = New-Object System.Drawing.Point(20,62); ^
    $subtitle.Size = New-Object System.Drawing.Size(380,20); ^
    $subtitle.ForeColor = [System.Drawing.Color]::Gray; ^
    $form.Controls.Add($subtitle); ^
    ^
    $statusBox = New-Object System.Windows.Forms.Label; ^
    $statusBox.Text = Show-Status; ^
    $statusBox.Font = New-Object System.Drawing.Font('Segoe UI', 9, [System.Drawing.FontStyle]::Italic); ^
    $statusBox.Location = New-Object System.Drawing.Point(20,90); ^
    $statusBox.Size = New-Object System.Drawing.Size(380,20); ^
    $statusBox.ForeColor = [System.Drawing.Color]::FromArgb(0,130,0); ^
    $form.Controls.Add($statusBox); ^
    ^
    $sep = New-Object System.Windows.Forms.Label; ^
    $sep.BorderStyle = 'Fixed3D'; ^
    $sep.Location = New-Object System.Drawing.Point(20,118); ^
    $sep.Size = New-Object System.Drawing.Size(370,2); ^
    $form.Controls.Add($sep); ^
    ^
    $btnStyle = { param($btn,$x,$y,$color) ^
        $btn.Location = New-Object System.Drawing.Point($x,$y); ^
        $btn.Size = New-Object System.Drawing.Size(170,48); ^
        $btn.Font = New-Object System.Drawing.Font('Segoe UI', 11, [System.Drawing.FontStyle]::Bold); ^
        $btn.FlatStyle = 'Flat'; ^
        $btn.BackColor = $color; ^
        $btn.ForeColor = [System.Drawing.Color]::White; ^
        $btn.FlatAppearance.BorderSize = 0; ^
        $btn.Cursor = 'Hand'; ^
    }; ^
    ^
    $btnInstall = New-Object System.Windows.Forms.Button; $btnInstall.Text = '  Telepítés'; &$btnStyle $btnInstall 20 130 ([System.Drawing.Color]::FromArgb(0,120,215)); ^
    $btnUpdate  = New-Object System.Windows.Forms.Button; $btnUpdate.Text  = '  Frissítés'; &$btnStyle $btnUpdate 210 130 ([System.Drawing.Color]::FromArgb(0,153,76)); ^
    $btnUninstall=New-Object System.Windows.Forms.Button; $btnUninstall.Text='  Eltávolítás'; &$btnStyle $btnUninstall 20 195 ([System.Drawing.Color]::FromArgb(200,50,50)); ^
    $btnLaunch  = New-Object System.Windows.Forms.Button; $btnLaunch.Text  = '  Indítás'; &$btnStyle $btnLaunch 210 195 ([System.Drawing.Color]::FromArgb(0,100,140)); ^
    $btnExit    = New-Object System.Windows.Forms.Button; $btnExit.Text    = 'Kilépés'; ^
    $btnExit.Location = New-Object System.Drawing.Point(145,275); ^
    $btnExit.Size = New-Object System.Drawing.Size(120,36); ^
    $btnExit.Font = New-Object System.Drawing.Font('Segoe UI', 10); ^
    $btnExit.FlatStyle = 'Flat'; ^
    $btnExit.BackColor = [System.Drawing.Color]::FromArgb(100,100,100); ^
    $btnExit.ForeColor = [System.Drawing.Color]::White; ^
    $btnExit.FlatAppearance.BorderSize = 0; ^
    ^
    $note = New-Object System.Windows.Forms.Label; ^
    $note.Text = 'Az ÁNYK az NAV hivatalos szoftverje. Ez csak egy telepítősegéd.'; ^
    $note.Font = New-Object System.Drawing.Font('Segoe UI', 8); ^
    $note.Location = New-Object System.Drawing.Point(20,320); ^
    $note.Size = New-Object System.Drawing.Size(380,18); ^
    $note.ForeColor = [System.Drawing.Color]::Gray; ^
    $form.Controls.Add($note); ^
    ^
    $btnInstall.Add_Click({ $form.Tag = 'install'; $form.Close() }); ^
    $btnUpdate.Add_Click({  $form.Tag = 'update';  $form.Close() }); ^
    $btnUninstall.Add_Click({ $form.Tag = 'uninstall'; $form.Close() }); ^
    $btnLaunch.Add_Click({  $form.Tag = 'launch';  $form.Close() }); ^
    $btnExit.Add_Click({    $form.Tag = 'exit';    $form.Close() }); ^
    ^
    $form.Controls.AddRange(@($btnInstall,$btnUpdate,$btnUninstall,$btnLaunch,$btnExit)); ^
    $form.ShowDialog() ^| Out-Null; ^
    return $form.Tag ^
} ^
^
do { ^
    $action = Show-MainForm; ^
    switch ($action) { ^
        'install' { ^
            $msg = 'Telepítő konzol ablak nyílik meg.\n\nFontos: A könyvtár mezőbe add meg:\n' + $INSTALL_DIR; ^
            [System.Windows.Forms.MessageBox]::Show($msg,'ÁNYK – Telepítés','OK','Information'); ^
            Start-Process 'powershell' -ArgumentList \"-NoProfile -Command \\\"`$j=Get-Command java -ErrorAction SilentlyContinue; if(-not `$j){winget install --id Azul.Zulu.8 --silent --accept-source-agreements --accept-package-agreements}; Invoke-WebRequest -Uri '$DOWNLOAD_URL' -OutFile '$JAR_FILE' -UseBasicParsing; java -jar '$JAR_FILE'\\\"\" -Wait; ^
        } ^
        'update' { ^
            $idir = Get-InstallDir; ^
            if (-not (Is-Installed)) { [System.Windows.Forms.MessageBox]::Show('Az ÁNYK nincs telepítve!','Hiba','OK','Error'); break }; ^
            $bak = \"$env:TEMP\anyk_backup\"; ^
            Copy-Item \"$idir\nyomtatvanyok\" $bak -Recurse -Force -ErrorAction SilentlyContinue; ^
            Invoke-WebRequest -Uri $DOWNLOAD_URL -OutFile $JAR_FILE -UseBasicParsing; ^
            Start-Process 'java' -ArgumentList \"-jar $JAR_FILE\" -Wait; ^
            Copy-Item \"$bak\nyomtatvanyok\" $idir -Recurse -Force -ErrorAction SilentlyContinue; ^
            Remove-Item $bak -Recurse -Force -ErrorAction SilentlyContinue; ^
            [System.Windows.Forms.MessageBox]::Show('Frissítés kész!','ÁNYK – Frissítés','OK','Information'); ^
        } ^
        'uninstall' { ^
            $idir = Get-InstallDir; ^
            $r = [System.Windows.Forms.MessageBox]::Show(\"Biztosan eltávolítod?\n\n$idir\n\nA nyomtatványok is törlődnek!\",'ÁNYK – Eltávolítás','YesNo','Warning'); ^
            if ($r -eq 'Yes') { ^
                Remove-Item $idir -Recurse -Force -ErrorAction SilentlyContinue; ^
                Remove-Item \"$env:USERPROFILE\.abevjava\" -Recurse -Force -ErrorAction SilentlyContinue; ^
                Remove-Item \"$env:USERPROFILE\Desktop\ÁNYK - NAV.lnk\" -Force -ErrorAction SilentlyContinue; ^
                [System.Windows.Forms.MessageBox]::Show('Eltávolítás kész!','ÁNYK','OK','Information'); ^
            } ^
        } ^
        'launch' { ^
            $idir = Get-InstallDir; ^
            if (Is-Installed) { Start-Process 'cmd' -ArgumentList \"/c cd /d `\"$idir`\" && abevjava_start.bat\" -WindowStyle Normal } ^
            else { [System.Windows.Forms.MessageBox]::Show('Az ÁNYK nincs telepítve!','Hiba','OK','Error') } ^
        } ^
    } ^
} while ($action -ne 'exit') ^
"
