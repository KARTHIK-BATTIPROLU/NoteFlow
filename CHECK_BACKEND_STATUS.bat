@echo off
echo ========================================
echo NoteFlow Backend Status Check
echo ========================================
echo.

echo [1] Checking if backend is running on port 8000...
netstat -an | findstr :8000 > nul
if %errorlevel% equ 0 (
    echo     ✓ Backend is RUNNING on port 8000
) else (
    echo     ✗ Backend is NOT running
    echo.
    echo     To start backend, run: backend\start.bat
    goto :end
)

echo.
echo [2] Checking your PC's IP address...
for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr "IPv4"') do (
    echo     IP: %%a
)

echo.
echo [3] Testing backend API...
curl -s http://localhost:8000 > nul 2>&1
if %errorlevel% equ 0 (
    echo     ✓ Backend API is responding
    curl -s http://localhost:8000
) else (
    echo     ✗ Backend API is not responding
)

echo.
echo [4] Checking Windows Firewall rule...
netsh advfirewall firewall show rule name="NoteFlow Backend Port 8000" > nul 2>&1
if %errorlevel% equ 0 (
    echo     ✓ Firewall rule exists
) else (
    echo     ✗ Firewall rule NOT found
    echo.
    echo     To add firewall rule, run as Administrator:
    echo     ADD_FIREWALL_RULE.bat
)

:end
echo.
echo ========================================
echo Status Check Complete
echo ========================================
echo.
echo To test from your phone browser:
echo http://YOUR_IP_ADDRESS:8000
echo.
pause
