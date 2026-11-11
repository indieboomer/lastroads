@echo off
cd /d "%~dp0"
if not exist tools\godot\Godot_v4.5.1-stable_win64.exe (
  powershell -NoProfile -ExecutionPolicy Bypass -File tools\setup.ps1
  if errorlevel 1 exit /b 1
)
if not exist debug-logs mkdir debug-logs
if not exist .godot\imported (
  if not exist .godot mkdir .godot
  tools\godot\Godot_v4.5.1-stable_win64.exe --headless --path . --editor --import --quit --log-file .godot\first-import.log
)
tools\godot\Godot_v4.5.1-stable_win64.exe --path . --log-file debug-logs/runtime.log %*
