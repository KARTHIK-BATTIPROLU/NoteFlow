@echo off
echo Fixing Windows Firewall for NoteFlow Backend
echo.

REM Delete old rule if exists
netsh advfirewall firewall delete rule name="NoteFlow Backend Port 8000" 2>nul

REM Add new rule allowing all connections
netsh advfirewall firewall add rule name="NoteFlow Backend Port 8000" dir=in action=allow protocol=TCP localport=8000 profile=any

if %errorlevel% equ 0 (
    echo.
    echo SUCCESS! Firewall configured.
    echo.
    echo Your phone should now be able to connect to:
    echo http://192.168.0.8:8000
    echo.
) else (
    echo.
    echo FAILED! Run this file as Administrator.
    echo.
)

pause
