@echo off
setlocal enabledelayedexpansion
title ÁNYK – NAV Manager – Windows

net session >nul 2>&1
if %errorLevel% neq 0 (
    powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

:: PowerShell Windows Forms GUI — dispatches to sub-scripts
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
"^
Add-Type -AssemblyName System.Windows.Forms; ^
Add-Type -AssemblyName System.Drawing; ^
$DIR = Split-Path -Parent '%~f0'; ^
$CONFIG = \"$env:USERPROFILE\.abevjava\abevjavapath.cfg\"; ^
^
function Is-Installed { return (Test-Path $CONFIG) -and (Test-Path (Get-Dir)) }; ^
function Get-Dir { ^
    if (Test-Path $CONFIG) { return ((Get-Content $CONFIG ^| Select-String 'abevjava.path') -split '= ')[1].Trim() } ^
    return \"$env:USERPROFILE\abevjava\" ^
}; ^
^
do { ^
    $installed = Is-Installed; ^
    $status = if ($installed) { '[OK] Telepítve: ' + (Get-Dir) } else { '[--] Nincs telepítve' }; ^
    ^
    $f = New-Object System.Windows.Forms.Form; ^
    $f.Text = 'ÁNYK – NAV Manager'; ^
    $f.Size = New-Object System.Drawing.Size(420,360); ^
    $f.StartPosition = 'CenterScreen'; ^
    $f.FormBorderStyle = 'FixedDialog'; ^
    $f.MaximizeBox = $false; ^
    $f.BackColor = [System.Drawing.Color]::FromArgb(245,245,245); ^
    ^
    $lbl = New-Object System.Windows.Forms.Label; ^
    $lbl.Text = 'ÁNYK – NAV'; ^
    $lbl.Font = New-Object System.Drawing.Font('Segoe UI',18,[System.Drawing.FontStyle]::Bold); ^
    $lbl.Location = '20,18'; $lbl.Size = '380,40'; ^
    $lbl.ForeColor = [System.Drawing.Color]::FromArgb(0,100,180); ^
    $f.Controls.Add($lbl); ^
    ^
    $sub = New-Object System.Windows.Forms.Label; ^
    $sub.Text = 'Általános Nyomtatványkitöltő – Hivatalos NAV szoftver'; ^
    $sub.Font = New-Object System.Drawing.Font('Segoe UI',9); ^
    $sub.Location = '20,60'; $sub.Size = '380,18'; ^
    $sub.ForeColor = [System.Drawing.Color]::Gray; ^
    $f.Controls.Add($sub); ^
    ^
    $st = New-Object System.Windows.Forms.Label; ^
    $st.Text = $status; ^
    $st.Font = New-Object System.Drawing.Font('Segoe UI',9,[System.Drawing.FontStyle]::Italic); ^
    $st.Location = '20,85'; $st.Size = '380,18'; ^
    $st.ForeColor = if ($installed) { [System.Drawing.Color]::FromArgb(0,130,0) } else { [System.Drawing.Color]::Gray }; ^
    $f.Controls.Add($st); ^
    ^
    $sep = New-Object System.Windows.Forms.Label; ^
    $sep.BorderStyle = 'Fixed3D'; $sep.Location = '20,112'; $sep.Size = '370,2'; ^
    $f.Controls.Add($sep); ^
    ^
    $mkBtn = { param($t,$x,$y,$c) ^
        $b = New-Object System.Windows.Forms.Button; ^
        $b.Text = $t; ^
        $b.Location = New-Object System.Drawing.Point($x,$y); ^
        $b.Size = '170,46'; ^
        $b.Font = New-Object System.Drawing.Font('Segoe UI',11,[System.Drawing.FontStyle]::Bold); ^
        $b.FlatStyle = 'Flat'; $b.FlatAppearance.BorderSize = 0; ^
        $b.BackColor = $c; $b.ForeColor = [System.Drawing.Color]::White; $b.Cursor = 'Hand'; ^
        return $b ^
    }; ^
    ^
    $bI = &$mkBtn 'Telepítés'   20  125 ([System.Drawing.Color]::FromArgb(0,120,215)); ^
    $bU = &$mkBtn 'Frissítés'  210  125 ([System.Drawing.Color]::FromArgb(0,153,76)); ^
    $bD = &$mkBtn 'Eltávolítás' 20  182 ([System.Drawing.Color]::FromArgb(200,50,50)); ^
    $bL = &$mkBtn 'Indítás'    210  182 ([System.Drawing.Color]::FromArgb(0,100,140)); ^
    ^
    $bX = New-Object System.Windows.Forms.Button; ^
    $bX.Text = 'Kilépés'; $bX.Location = '148,250'; $bX.Size = '120,34'; ^
    $bX.Font = New-Object System.Drawing.Font('Segoe UI',10); ^
    $bX.FlatStyle = 'Flat'; $bX.FlatAppearance.BorderSize = 0; ^
    $bX.BackColor = [System.Drawing.Color]::FromArgb(100,100,100); $bX.ForeColor = [System.Drawing.Color]::White; ^
    ^
    $note = New-Object System.Windows.Forms.Label; ^
    $note.Text = 'Az ÁNYK az NAV hivatalos szoftverje. Ez csak egy telepítősegéd.'; ^
    $note.Font = New-Object System.Drawing.Font('Segoe UI',8); ^
    $note.Location = '20,300'; $note.Size = '380,18'; ^
    $note.ForeColor = [System.Drawing.Color]::Gray; ^
    $f.Controls.Add($note); ^
    ^
    $bI.Add_Click({ $f.Tag='install';   $f.Close() }); ^
    $bU.Add_Click({ $f.Tag='update';    $f.Close() }); ^
    $bD.Add_Click({ $f.Tag='uninstall'; $f.Close() }); ^
    $bL.Add_Click({ $f.Tag='launch';    $f.Close() }); ^
    $bX.Add_Click({ $f.Tag='exit';      $f.Close() }); ^
    $f.Controls.AddRange(@($bI,$bU,$bD,$bL,$bX)); ^
    $f.ShowDialog() ^| Out-Null; ^
    ^
    switch ($f.Tag) { ^
        'install'   { Start-Process 'cmd' -ArgumentList \"/c call `\"%DIR%\install.bat`\"\" -Wait } ^
        'update'    { Start-Process 'cmd' -ArgumentList \"/c call `\"%DIR%\update.bat`\"\" -Wait } ^
        'uninstall' { Start-Process 'cmd' -ArgumentList \"/c call `\"%DIR%\uninstall.bat`\"\" -Wait } ^
        'launch'    { if (Is-Installed) { Start-Process 'cmd' -ArgumentList \"/c cd /d `\"$(Get-Dir)`\" && abevjava_start.bat\" } else { [System.Windows.Forms.MessageBox]::Show('Az ÁNYK nincs telepítve!','ÁNYK','OK','Error') } } ^
        'exit'      { break } ^
    } ^
} while ($f.Tag -ne 'exit') ^
"
