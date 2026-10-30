
@echo off
setlocal EnableExtensions
cd /d "%~dp0"
title Criador de Video Lofi
color 0A

echo =====================================
echo       CRIADOR DE VIDEO LOFI
echo =====================================
echo.

where ffmpeg >nul 2>&1
if errorlevel 1 (
    echo ERRO: FFmpeg nao encontrado!
    goto FIM
)

set "PS1=%TEMP%\criar_lofi_%RANDOM%_%RANDOM%.ps1"

echo Criando seletor de arquivos...

> "%PS1%" echo Add-Type -AssemblyName System.Windows.Forms
>> "%PS1%" echo $ErrorActionPreference = 'Stop'
>> "%PS1%" echo $v = New-Object System.Windows.Forms.OpenFileDialog
>> "%PS1%" echo $v.Title = 'Selecione o video'
>> "%PS1%" echo $v.Filter = 'Videos^|*.mp4;*.mkv;*.mov;*.webm'
>> "%PS1%" echo if ($v.ShowDialog() -ne 'OK') { exit 1 }
>> "%PS1%" echo $a = New-Object System.Windows.Forms.OpenFileDialog
>> "%PS1%" echo $a.Title = 'Selecione as musicas'
>> "%PS1%" echo $a.Filter = 'Audios^|*.mp3;*.wav;*.m4a;*.flac;*.aac'
>> "%PS1%" echo $a.Multiselect = $true
>> "%PS1%" echo if ($a.ShowDialog() -ne 'OK') { exit 1 }
>> "%PS1%" echo $s = New-Object System.Windows.Forms.SaveFileDialog
>> "%PS1%" echo $s.Filter = 'MP4^|*.mp4'
>> "%PS1%" echo $s.FileName = 'lofi_final.mp4'
>> "%PS1%" echo if ($s.ShowDialog() -ne 'OK') { exit 1 }
>> "%PS1%" echo $dir = Join-Path $env:TEMP ('lofi_' + [guid]::NewGuid())
>> "%PS1%" echo New-Item -ItemType Directory -Path $dir ^| Out-Null
>> "%PS1%" echo try {
>> "%PS1%" echo $lista = Join-Path $dir 'lista.txt'
>> "%PS1%" echo $final = Join-Path $dir 'audio.m4a'
>> "%PS1%" echo $linhas = @()
>> "%PS1%" echo $i = 0
>> "%PS1%" echo foreach ($f in ($a.FileNames ^| Sort-Object)) {
>> "%PS1%" echo $i++
>> "%PS1%" echo Write-Host "Convertendo musica $i de $($a.FileNames.Count)"
>> "%PS1%" echo $out = Join-Path $dir ('musica_' + $i + '.m4a')
>> "%PS1%" echo ^& ffmpeg -y -i $f -vn -ar 44100 -ac 2 -c:a aac -b:a 192k $out
>> "%PS1%" echo if ($LASTEXITCODE -ne 0) { throw 'Erro ao converter audio' }
>> "%PS1%" echo $linhas += "file '$($out.Replace('\','/'))'"
>> "%PS1%" echo }
>> "%PS1%" echo [System.IO.File]::WriteAllLines($lista,$linhas)
>> "%PS1%" echo Write-Host 'Juntando musicas...'
>> "%PS1%" echo ^& ffmpeg -y -f concat -safe 0 -i $lista -c:a copy $final
>> "%PS1%" echo if ($LASTEXITCODE -ne 0) { throw 'Erro ao juntar musicas' }
>> "%PS1%" echo Write-Host 'Criando video final...'
>> "%PS1%" echo ^& ffmpeg -y -stream_loop -1 -i $v.FileName -i $final -map 0:v:0 -map 1:a:0 -c:v libx264 -preset ultrafast -crf 23 -pix_fmt yuv420p -c:a copy -shortest -movflags +faststart $s.FileName
>> "%PS1%" echo if ($LASTEXITCODE -ne 0) { throw 'Erro ao criar video' }
>> "%PS1%" echo Write-Host 'VIDEO CRIADO COM SUCESSO!'
>> "%PS1%" echo Write-Host $s.FileName
>> "%PS1%" echo } finally {
>> "%PS1%" echo Remove-Item $dir -Recurse -Force -ErrorAction SilentlyContinue
>> "%PS1%" echo }

powershell -NoProfile -STA -ExecutionPolicy Bypass -File "%PS1%"
set "RESULTADO=%ERRORLEVEL%"

del "%PS1%" >nul 2>&1

if not "%RESULTADO%"=="0" (
    echo.
    echo ERRO OU CANCELAMENTO!
    echo Codigo do erro: %RESULTADO%
)

:FIM
echo.
echo =====================================
echo Pressione qualquer tecla para sair.
pause >nul
exit /b
