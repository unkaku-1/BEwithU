@echo off
setlocal enabledelayedexpansion

echo ===================================
echo    AI Helpdesk System - Stop
echo ===================================
echo.

:: Set color codes
set "INFO=[92m"
set "WARN=[93m"
set "ERROR=[91m"
set "RESET=[0m"

echo %INFO%[INFO]%RESET% Stopping AI Helpdesk System...

:: Check if Docker is running
docker info > nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo %WARN%[WARNING]%RESET% Docker is not running.
    echo %INFO%[INFO]%RESET% System is already stopped.
    pause
    exit /b 0
)

:: Stop the system
docker-compose down

if %ERRORLEVEL% NEQ 0 (
    echo %ERROR%[ERROR]%RESET% Failed to stop the system gracefully.
    echo %WARN%[WARNING]%RESET% Attempting force stop...
    
    docker-compose down --remove-orphans
    
    if %ERRORLEVEL% NEQ 0 (
        echo %ERROR%[ERROR]%RESET% Failed to force stop the system.
        pause
        exit /b 1
    )
)

echo %INFO%[SUCCESS]%RESET% AI Helpdesk System stopped successfully!
echo.
pause