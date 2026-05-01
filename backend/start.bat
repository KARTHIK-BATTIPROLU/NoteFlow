@echo off
REM NoteFlow Backend Startup Script for Windows

echo ==================================
echo NoteFlow Backend Startup
echo ==================================
echo.

REM Check if Python is installed
python --version >nul 2>&1
if errorlevel 1 (
    echo X Python is not installed. Please install Python 3.8 or higher.
    pause
    exit /b 1
)

echo √ Python found

REM Install dependencies
echo.
echo Installing dependencies...
pip install -r requirements.txt

REM Initialize database
echo.
echo Initializing database...
python init_db.py

REM Start the server
echo.
echo ==================================
echo Starting FastAPI server...
echo ==================================
echo.
echo API will be available at:
echo   - Local: http://localhost:8000
echo   - Android Emulator: http://10.0.2.2:8000
echo   - API Docs: http://localhost:8000/docs
echo.
echo Press Ctrl+C to stop the server
echo.

uvicorn main:app --reload --host 0.0.0.0 --port 8000
