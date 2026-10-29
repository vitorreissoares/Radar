@echo off
rem =========================================================
rem  Cria na area de trabalho um atalho "Radar"
rem  que abre o app. Rode uma vez so (dois cliques).
rem =========================================================
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$atalho = (New-Object -ComObject WScript.Shell).CreateShortcut([Environment]::GetFolderPath('Desktop') + '\Radar.lnk');" ^
  "$atalho.TargetPath = '%~dp0Abrir Radar.bat';" ^
  "$atalho.WorkingDirectory = '%~dp0';" ^
  "$atalho.IconLocation = '%SystemRoot%\System32\imageres.dll,109';" ^
  "$atalho.Save()"
if errorlevel 1 (
  echo Nao foi possivel criar o atalho.
) else (
  echo Atalho "Radar" criado na area de trabalho.
)
echo.
pause
