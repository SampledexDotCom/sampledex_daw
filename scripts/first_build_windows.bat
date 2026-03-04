@echo off
setlocal
powershell -ExecutionPolicy Bypass -NoProfile -File "%~dp0first_build_windows.ps1" %*
endlocal
