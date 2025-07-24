@echo off
setlocal enabledelayedexpansion

echo ===================================
echo   AI Helpdesk System - Monitor
echo ===================================
echo.

:: Set color codes
set "INFO=[92m"
set "WARN=[93m"
set "ERROR=[91m"
set "RESET=[0m"

echo %INFO%[INFO]%RESET% AI Helpdesk System Status Monitor
echo.

:: Check if Docker is running
docker info > nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo %ERROR%[ERROR]%RESET% Docker is not running.
    echo %ERROR%[ERROR]%RESET% Please start Docker Desktop first.
    pause
    exit /b 1
)

:MONITOR_LOOP
cls
echo ===================================
echo   AI Helpdesk System - Monitor
echo ===================================
echo.
echo Current time: %date% %time%
echo.

:: Show container status
echo %INFO%[INFO]%RESET% Container Status:
echo ----------------------------------------
docker-compose ps
echo.

:: Show resource usage
echo %INFO%[INFO]%RESET% Resource Usage:
echo ----------------------------------------
docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}\t{{.BlockIO}}"
echo.

:: Show recent logs
echo %INFO%[INFO]%RESET% Recent System Logs (last 10 lines):
echo ----------------------------------------
docker-compose logs --tail=10
echo.

:: Check service health
echo %INFO%[INFO]%RESET% Service Health Check:
echo ----------------------------------------

:: Check Frontend
curl -s -o nul -w "Frontend (Port 80): %%{http_code}\n" http://localhost:80 2>nul
if %ERRORLEVEL% NEQ 0 echo Frontend (Port 80): Connection Failed

:: Check Rasa API
curl -s -o nul -w "Rasa API (Port 5005): %%{http_code}\n" http://localhost:5005 2>nul
if %ERRORLEVEL% NEQ 0 echo Rasa API (Port 5005): Connection Failed

:: Check BookStack
curl -s -o nul -w "BookStack (Port 8080): %%{http_code}\n" http://localhost:8080 2>nul
if %ERRORLEVEL% NEQ 0 echo BookStack (Port 8080): Connection Failed

:: Check osTicket
curl -s -o nul -w "osTicket (Port 8081): %%{http_code}\n" http://localhost:8081 2>nul
if %ERRORLEVEL% NEQ 0 echo osTicket (Port 8081): Connection Failed

echo.
echo ----------------------------------------
echo Press 'R' to refresh, 'Q' to quit, or wait 30 seconds for auto-refresh
echo ----------------------------------------

:: Wait for user input or timeout
choice /C RQ /T 30 /D R /M "Your choice"
if %ERRORLEVEL% EQU 2 goto :END
if %ERRORLEVEL% EQU 1 goto :MONITOR_LOOP

:: Auto-refresh after timeout
goto :MONITOR_LOOP

:END
echo.
echo %INFO%[INFO]%RESET% Monitoring stopped.
pause