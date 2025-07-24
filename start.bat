@echo off
setlocal enabledelayedexpansion

echo ===================================
echo    AI Helpdesk System - Start
echo ===================================
echo.

:: Set color codes
set "INFO=[92m"
set "WARN=[93m"
set "ERROR=[91m"
set "RESET=[0m"

echo %INFO%[INFO]%RESET% Starting AI Helpdesk System...

:: Check if Docker is running
docker info > nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo %ERROR%[ERROR]%RESET% Docker is not running.
    echo %ERROR%[ERROR]%RESET% Please start Docker Desktop first.
    pause
    exit /b 1
)

:: Start the system
docker-compose up -d

if %ERRORLEVEL% NEQ 0 (
    echo %ERROR%[ERROR]%RESET% Failed to start the system.
    pause
    exit /b 1
)

echo %INFO%[INFO]%RESET% System is starting...
timeout /t 30 /nobreak > nul

:: Check service status
echo %INFO%[INFO]%RESET% Checking service status...
docker-compose ps

echo.
echo %INFO%[SUCCESS]%RESET% AI Helpdesk System started successfully!
echo.
echo Access URLs:
echo  - Frontend: http://localhost:80
echo  - Rasa API: http://localhost:5005
echo  - BookStack: http://localhost:8080
echo  - osTicket: http://localhost:8081
echo.
pause