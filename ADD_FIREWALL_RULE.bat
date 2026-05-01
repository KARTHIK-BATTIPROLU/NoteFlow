@echo off
REM Add Windows Firewall rule for NoteFlow Backend
REM Run this as Administrator

echo Adding Windows Firewall rule for NoteFlow Backend...
echo.

netsh advfirewall firewall add rule name="NoteFlow Backend Port 8000" dir=in action=allow protocol=TCP localport=8000

if %errorlevel% equ 0 (
    echo.
    echo SUCCESS! Firewall rule added.
    echo Port 8000 is now allowed through Windows Firewall.
    echo.
    echo You can now access the backend from your phone at:
    echo http://192.168.0.16:8000
    echo.
) else (
    echo.
    echo FAILED! You need to run this as Administrator.
    echo.
    echo Right-click this file and select "Run as administrator"
    echo.
)

pause
