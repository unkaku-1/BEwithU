@echo off
@chcp 65001 >nul
setlocal enabledelayedexpansion

echo ========================================
echo IT Helpdesk AI System Deployment Script
echo ========================================
echo.

REM Check if Docker is installed and running
echo [1/8] Checking Docker installation...
docker --version >nul 2>&1
if errorlevel 1 (
    echo ERROR: Docker is not installed or not in PATH
    echo Please install Docker Desktop and ensure it's running
    pause
    exit /b 1
)

docker info >nul 2>&1
if errorlevel 1 (
    echo ERROR: Docker daemon is not running
    echo Please start Docker Desktop and try again
    pause
    exit /b 1
)

echo Docker is installed and running
echo.

REM Check if Docker Compose is available
echo [2/8] Checking Docker Compose...
docker compose version >nul 2>&1
if errorlevel 1 (
    echo ERROR: Docker Compose is not available
    echo Please ensure Docker Desktop includes Docker Compose
    pause
    exit /b 1
)

echo Docker Compose is available
echo.

REM Create necessary directories
echo [3/8] Creating directories...
if not exist "logs" mkdir logs
if not exist "data" mkdir data
echo Directories created
echo.

REM Set environment variables
echo [4/8] Setting up environment...
set COMPOSE_PROJECT_NAME=it-helpdesk-ai
set DOCKER_BUILDKIT=1
echo Environment configured
echo.

REM Pull latest images
echo [5/8] Pulling Docker images...
echo This may take several minutes depending on your internet connection...
docker compose pull
if errorlevel 1 (
    echo WARNING: Some images failed to pull, continuing with build...
)
echo.

REM Build custom images
echo [6/8] Building custom images...
docker compose build
if errorlevel 1 (
    echo ERROR: Failed to build images
    pause
    exit /b 1
)
echo Images built successfully
echo.

REM Start services
echo [7/8] Starting services...
docker compose up -d
if errorlevel 1 (
    echo ERROR: Failed to start services
    echo Checking logs...
    docker compose logs
    pause
    exit /b 1
)
echo.

REM Wait for services to be ready
echo [8/8] Waiting for services to start...
timeout /t 30 /nobreak >nul

REM Check service status
echo Checking service status...
docker compose ps

echo.
echo ========================================
echo Deployment completed successfully!
echo ========================================
echo.
echo Service URLs:
echo - Main Application: http://localhost
echo - n8n Workflow Editor: http://localhost/n8n
echo - Knowledge Base (BookStack): http://localhost/knowledge
echo - Ticketing System (osTicket): http://localhost/tickets
echo.
echo Default Credentials:
echo - n8n: admin / admin123
echo - BookStack: admin@admin.com / password (set during first setup)
echo - osTicket: Configure during first setup
echo.
echo To stop the system: docker compose down
echo To view logs: docker compose logs
echo To restart: docker compose restart
echo.

REM Configure Windows Firewall (optional)
echo Configuring Windows Firewall...
netsh advfirewall firewall show rule name="IT Helpdesk AI HTTP" >nul 2>&1
if errorlevel 1 (
    netsh advfirewall firewall add rule name="IT Helpdesk AI HTTP" dir=in action=allow protocol=TCP localport=80 >nul 2>&1
    if errorlevel 1 (
        echo WARNING: Failed to configure firewall rule for port 80
        echo You may need to manually allow port 80 in Windows Firewall
    ) else (
        echo Firewall rule added for port 80
    )
) else (
    echo Firewall rule for port 80 already exists
)

echo.
echo System is ready! Open http://localhost in your browser
echo.
pause

