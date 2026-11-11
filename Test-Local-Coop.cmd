@echo off
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0tools\coop\launch-local.ps1" -GameRoot "%~dp0."
