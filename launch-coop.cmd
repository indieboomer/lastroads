@echo off
cd /d "%~dp0"
if not exist tools\godot-steam\godotsteam.452.editor.win64.exe (
  echo Steam support is not installed. Run powershell -File tools\coop\setup-steam.ps1
  exit /b 1
)
if not exist debug-logs mkdir debug-logs
tools\godot-steam\godotsteam.452.editor.win64.exe --path . --log-file debug-logs/coop-%RANDOM%-%RANDOM%.log %*
