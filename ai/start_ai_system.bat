@echo off
echo ========================================
echo  ADVANCED CRYPTO AI SYSTEM LAUNCHER
echo  Automatic Setup and Startup System
echo ========================================
echo.

cd /d "%~dp0"

REM Check if Python is available
python --version >nul 2>&1
if errorlevel 1 (
    echo Python not found. Installing Python...
    echo Please wait, this may take several minutes...
    python setup_python_environment.py
    if errorlevel 1 (
        echo Failed to setup Python environment
        pause
        exit /b 1
    )
) else (
    echo Python found, checking environment...
)

REM Check if virtual environment exists
if not exist "venv" (
    echo Virtual environment not found. Running setup...
    python setup_python_environment.py
    if errorlevel 1 (
        echo Setup failed!
        pause
        exit /b 1
    )
)

REM Start the Android AI Integration system
echo.
echo Starting Advanced Crypto AI System...
echo This will automatically:
echo   1. Check and install dependencies
echo   2. Start AI server
echo   3. Monitor system health
echo   4. Provide API for Android app
echo.

python android_integration.py

if errorlevel 1 (
    echo.
    echo AI system failed to start!
    echo Please check the logs for more information.
    pause
    exit /b 1
)

echo.
echo AI system stopped.
pause
