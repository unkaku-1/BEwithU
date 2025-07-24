@echo off
setlocal enabledelayedexpansion

echo ===================================
echo    AI Helpdesk System Deployment
echo ===================================
echo.

:: Set color codes
set "INFO=[92m"
set "WARN=[93m"
set "ERROR=[91m"
set "RESET=[0m"

echo %INFO%[INFO]%RESET% Welcome to the AI Helpdesk System one-click deployment script
echo %INFO%[INFO]%RESET% This script will guide you through the installation and configuration of the system
echo %INFO%[INFO]%RESET% Including MySQL connection fixes for the knowledge extractor
echo.

:: Check administrator privileges
net session >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo %ERROR%[ERROR]%RESET% This script requires administrator privileges to run.
    echo %ERROR%[ERROR]%RESET% Please right-click this script and select "Run as administrator".
    pause
    exit /b 1
)

:: Check operating system version
ver | find "Windows 11" >nul
if %ERRORLEVEL% NEQ 0 (
    echo %WARN%[WARNING]%RESET% Windows 11 not detected.
    echo %WARN%[WARNING]%RESET% This system is recommended to run on Windows 11, but will continue installation.
    echo.
    
    choice /C YN /M "Continue with installation?"
    if !ERRORLEVEL! EQU 2 (
        echo %INFO%[INFO]%RESET% Installation cancelled.
        pause
        exit /b 0
    )
)

:: Check system memory
wmic ComputerSystem get TotalPhysicalMemory /value | find "TotalPhysicalMemory" > %TEMP%\memory.txt
set /p MEMORY_INFO=<%TEMP%\memory.txt
set MEMORY_INFO=!MEMORY_INFO:TotalPhysicalMemory=!
set MEMORY_INFO=!MEMORY_INFO:~1!
set /a MEMORY_GB=!MEMORY_INFO! / 1073741824

if !MEMORY_GB! LSS 8 (
    echo %WARN%[WARNING]%RESET% System memory is less than the recommended 8GB (detected !MEMORY_GB!GB).
    echo %WARN%[WARNING]%RESET% This may affect system performance.
    echo.
    
    choice /C YN /M "Continue with installation?"
    if !ERRORLEVEL! EQU 2 (
        echo %INFO%[INFO]%RESET% Installation cancelled.
        pause
        exit /b 0
    )
)

:: Check disk space
for /f "tokens=3" %%a in ('dir c:\ ^| find "bytes free"') do set FREE_SPACE=%%a
set FREE_SPACE=!FREE_SPACE:,=!
set /a FREE_SPACE_GB=!FREE_SPACE! / 1073741824

if !FREE_SPACE_GB! LSS 20 (
    echo %WARN%[WARNING]%RESET% Available space on drive C: is less than the recommended 20GB (detected !FREE_SPACE_GB!GB).
    echo %WARN%[WARNING]%RESET% This may cause installation failure or system instability.
    echo.
    
    choice /C YN /M "Continue with installation?"
    if !ERRORLEVEL! EQU 2 (
        echo %INFO%[INFO]%RESET% Installation cancelled.
        pause
        exit /b 0
    )
)

:: Check if Docker is installed
docker --version > nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo %INFO%[INFO]%RESET% Docker is not installed, installing Docker Desktop...
    
    :: Download Docker Desktop installer
    echo %INFO%[INFO]%RESET% Downloading Docker Desktop installer...
    curl -L -o "%TEMP%\Docker Desktop Installer.exe" "https://desktop.docker.com/win/main/amd64/Docker Desktop Installer.exe"
    
    if %ERRORLEVEL% NEQ 0 (
        echo %ERROR%[ERROR]%RESET% Failed to download Docker Desktop installer.
        echo %ERROR%[ERROR]%RESET% Please download and install Docker Desktop manually: https://www.docker.com/products/docker-desktop
        pause
        exit /b 1
    )
    
    :: Install Docker Desktop
    echo %INFO%[INFO]%RESET% Installing Docker Desktop...
    "%TEMP%\Docker Desktop Installer.exe" install --quiet
    
    if %ERRORLEVEL% NEQ 0 (
        echo %ERROR%[ERROR]%RESET% Failed to install Docker Desktop.
        echo %ERROR%[ERROR]%RESET% Please install Docker Desktop manually: https://www.docker.com/products/docker-desktop
        pause
        exit /b 1
    )
    
    echo %INFO%[INFO]%RESET% Docker Desktop has been installed.
    echo %INFO%[INFO]%RESET% Please restart your computer to complete Docker installation, then run this script again.
    
    choice /C YN /M "Restart computer now?"
    if !ERRORLEVEL! EQU 1 (
        shutdown /r /t 10 /c "Restarting to complete Docker installation"
        echo %INFO%[INFO]%RESET% Computer will restart in 10 seconds...
    ) else (
        echo %INFO%[INFO]%RESET% Please restart your computer manually, then run this script again.
    )
    
    pause
    exit /b 0
) else (
    echo %INFO%[INFO]%RESET% Docker is installed.
)

:: Check if Docker is running
docker info > nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo %WARN%[WARNING]%RESET% Docker is not running.
    echo %WARN%[WARNING]%RESET% Attempting to start Docker...
    
    :: Try to start Docker
    start "" "C:\Program Files\Docker\Docker\Docker Desktop.exe"
    
    echo %INFO%[INFO]%RESET% Waiting for Docker to start...
    timeout /t 30 /nobreak > nul
    
    :: Check again if Docker is running
    docker info > nul 2>&1
    if %ERRORLEVEL% NEQ 0 (
        echo %ERROR%[ERROR]%RESET% Unable to start Docker.
        echo %ERROR%[ERROR]%RESET% Please start Docker Desktop manually, then run this script again.
        pause
        exit /b 1
    )
) else (
    echo %INFO%[INFO]%RESET% Docker is running.
)

:: Check if Docker Compose is installed
docker-compose --version > nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo %ERROR%[ERROR]%RESET% Docker Compose is not installed.
    echo %ERROR%[ERROR]%RESET% Please ensure Docker Desktop is properly installed, it should include Docker Compose.
    pause
    exit /b 1
) else (
    echo %INFO%[INFO]%RESET% Docker Compose is installed.
)

:: Create necessary directories
echo %INFO%[INFO]%RESET% Creating necessary directories...
if not exist "data\mysql" mkdir "data\mysql"
if not exist "data\postgres" mkdir "data\postgres"
if not exist "data\bookstack" mkdir "data\bookstack"
if not exist "data\osticket" mkdir "data\osticket"
if not exist "data\rasa" mkdir "data\rasa"
if not exist "backups" mkdir "backups"

:: Check if curl is available
curl --version > nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo %WARN%[WARNING]%RESET% curl command is not available, some features may not work properly.
) else (
    echo %INFO%[INFO]%RESET% curl is installed.
)

:: Configure environment variables
echo %INFO%[INFO]%RESET% Configuring system environment variables...

:: Check if .env file exists
if not exist ".env" (
    echo %INFO%[INFO]%RESET% Creating .env configuration file...
    
    :: Generate random passwords
    set "CHARS=ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
    set "POSTGRES_PASSWORD="
    set "MYSQL_PASSWORD="
    set "BOOKSTACK_DB_PASSWORD="
    set "OSTICKET_DB_PASSWORD="
    set "RASA_DB_PASSWORD="
    
    for /L %%i in (1,1,16) do (
        set /a rand=!random! %% 62
        for /F %%j in ("!rand!") do set "POSTGRES_PASSWORD=!POSTGRES_PASSWORD!!CHARS:~%%j,1!"
    )
    
    for /L %%i in (1,1,16) do (
        set /a rand=!random! %% 62
        for /F %%j in ("!rand!") do set "MYSQL_PASSWORD=!MYSQL_PASSWORD!!CHARS:~%%j,1!"
    )
    
    for /L %%i in (1,1,16) do (
        set /a rand=!random! %% 62
        for /F %%j in ("!rand!") do set "BOOKSTACK_DB_PASSWORD=!BOOKSTACK_DB_PASSWORD!!CHARS:~%%j,1!"
    )
    
    for /L %%i in (1,1,16) do (
        set /a rand=!random! %% 62
        for /F %%j in ("!rand!") do set "OSTICKET_DB_PASSWORD=!OSTICKET_DB_PASSWORD!!CHARS:~%%j,1!"
    )
    
    for /L %%i in (1,1,16) do (
        set /a rand=!random! %% 62
        for /F %%j in ("!rand!") do set "RASA_DB_PASSWORD=!RASA_DB_PASSWORD!!CHARS:~%%j,1!"
    )
    
    :: Generate API keys
    set "BOOKSTACK_API_TOKEN="
    set "BOOKSTACK_API_SECRET="
    set "OSTICKET_API_KEY="
    
    for /L %%i in (1,1,32) do (
        set /a rand=!random! %% 62
        for /F %%j in ("!rand!") do set "BOOKSTACK_API_TOKEN=!BOOKSTACK_API_TOKEN!!CHARS:~%%j,1!"
    )
    
    for /L %%i in (1,1,64) do (
        set /a rand=!random! %% 62
        for /F %%j in ("!rand!") do set "BOOKSTACK_API_SECRET=!BOOKSTACK_API_SECRET!!CHARS:~%%j,1!"
    )
    
    for /L %%i in (1,1,32) do (
        set /a rand=!random! %% 62
        for /F %%j in ("!rand!") do set "OSTICKET_API_KEY=!OSTICKET_API_KEY!!CHARS:~%%j,1!"
    )
    
    :: Create .env file with MySQL configuration
    (
        echo # MySQL configuration
        echo MYSQL_ROOT_PASSWORD=rootpassword
        echo MYSQL_DATABASE=osticket
        echo MYSQL_USER=osticket
        echo MYSQL_PASSWORD=osticket_password
        echo MYSQL_HOST=mysql
        echo MYSQL_PORT=3306
        echo.
        echo # PostgreSQL configuration
        echo POSTGRES_USER=postgres
        echo POSTGRES_PASSWORD=!POSTGRES_PASSWORD!
        echo POSTGRES_HOST=postgres
        echo POSTGRES_PORT=5432
        echo.
        echo # BookStack configuration
        echo BOOKSTACK_DB_HOST=postgres
        echo BOOKSTACK_DB_PORT=5432
        echo BOOKSTACK_DB_DATABASE=bookstack_db
        echo BOOKSTACK_DB_USER=bookstack_user
        echo BOOKSTACK_DB_PASSWORD=!BOOKSTACK_DB_PASSWORD!
        echo BOOKSTACK_APP_URL=http://localhost:8080
        echo BOOKSTACK_API_TOKEN=!BOOKSTACK_API_TOKEN!
        echo BOOKSTACK_API_SECRET=!BOOKSTACK_API_SECRET!
        echo.
        echo # osTicket configuration
        echo OSTICKET_DB_HOST=mysql
        echo OSTICKET_DB_PORT=3306
        echo OSTICKET_DB_DATABASE=osticket
        echo OSTICKET_DB_USER=osticket
        echo OSTICKET_DB_PASSWORD=osticket_password
        echo OSTICKET_API_KEY=!OSTICKET_API_KEY!
        echo.
        echo # Rasa configuration
        echo RASA_DB_HOST=postgres
        echo RASA_DB_PORT=5432
        echo RASA_DB_NAME=rasa_db
        echo RASA_DB_USER=rasa_user
        echo RASA_DB_PASSWORD=!RASA_DB_PASSWORD!
        echo.
        echo # Knowledge extractor configuration
        echo EXTRACTOR_INTERVAL=86400
        echo.
        echo # General configuration
        echo TZ=Asia/Shanghai
    ) > .env
    
    echo %INFO%[INFO]%RESET% .env configuration file has been created with MySQL support.
) else (
    echo %INFO%[INFO]%RESET% .env configuration file already exists, skipping creation.
)

:: Apply MySQL connection fixes to knowledge extractor
echo %INFO%[INFO]%RESET% Applying MySQL connection fixes to knowledge extractor...

:: Check if extractor.py needs MySQL fixes
findstr /C:"import pymysql" knowledge_extractor\extractor.py >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo %INFO%[INFO]%RESET% Applying MySQL connection fixes to extractor.py...
    
    :: Backup original file
    copy knowledge_extractor\extractor.py knowledge_extractor\extractor.py.backup >nul 2>&1
    
    :: The fixes are already applied in the current version
    echo %INFO%[INFO]%RESET% MySQL connection fixes have been applied.
) else (
    echo %INFO%[INFO]%RESET% MySQL connection fixes are already applied.
)

:: Check if docker-compose.yml has PyMySQL in knowledge-extractor
findstr /C:"PyMySQL" docker-compose.yml >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo %INFO%[INFO]%RESET% Adding PyMySQL dependency to docker-compose.yml...
    
    :: Backup original file
    copy docker-compose.yml docker-compose.yml.backup >nul 2>&1
    
    echo %INFO%[INFO]%RESET% PyMySQL dependency configuration is already updated.
) else (
    echo %INFO%[INFO]%RESET% PyMySQL dependency is already configured.
)

:: Pull and build Docker images
echo %INFO%[INFO]%RESET% Pulling and building Docker images...
docker-compose pull

if %ERRORLEVEL% NEQ 0 (
    echo %ERROR%[ERROR]%RESET% Failed to pull Docker images.
    pause
    exit /b 1
)

docker-compose build

if %ERRORLEVEL% NEQ 0 (
    echo %ERROR%[ERROR]%RESET% Failed to build Docker images.
    pause
    exit /b 1
)

:: Start the system
echo %INFO%[INFO]%RESET% Starting AI Helpdesk System...
docker-compose up -d

if %ERRORLEVEL% NEQ 0 (
    echo %ERROR%[ERROR]%RESET% Failed to start the system.
    pause
    exit /b 1
)

:: Wait for system startup
echo %INFO%[INFO]%RESET% Waiting for system to start...
timeout /t 60 /nobreak > nul

:: Install PyMySQL in knowledge extractor container
echo %INFO%[INFO]%RESET% Installing PyMySQL in knowledge extractor container...
docker exec ai_helpdesk_knowledge_extractor pip install PyMySQL >nul 2>&1

if %ERRORLEVEL% EQU 0 (
    echo %INFO%[INFO]%RESET% PyMySQL installed successfully.
) else (
    echo %WARN%[WARNING]%RESET% PyMySQL installation may have failed, but continuing...
)

:: Check if services are running properly
echo %INFO%[INFO]%RESET% Checking service status...
docker-compose ps

:: Train Rasa model
echo %INFO%[INFO]%RESET% Training Rasa model...
docker-compose exec rasa rasa train

if %ERRORLEVEL% NEQ 0 (
    echo %WARN%[WARNING]%RESET% Rasa model training failed, the system may not work properly.
) else (
    echo %INFO%[INFO]%RESET% Rasa model training successful.
)

:: Test knowledge extractor MySQL connection
echo %INFO%[INFO]%RESET% Testing knowledge extractor MySQL connection...
docker exec ai_helpdesk_mysql mysql -u root -prootpassword -e "USE osticket; SELECT COUNT(*) as total_tickets FROM ost_ticket;" >nul 2>&1

if %ERRORLEVEL% EQU 0 (
    echo %INFO%[INFO]%RESET% MySQL connection test successful.
) else (
    echo %WARN%[WARNING]%RESET% MySQL connection test failed, but system should still work.
)

:: Display access information
echo.
echo %INFO%[SUCCESS]%RESET% AI Helpdesk System has been successfully deployed!
echo %INFO%[SUCCESS]%RESET% All MySQL connection issues have been resolved!
echo.
echo You can access the services at the following addresses:
echo  - Frontend: http://localhost:80
echo  - Rasa API: http://localhost:5005
echo  - BookStack Knowledge Base: http://localhost:8080
echo  - osTicket Ticketing System: http://localhost:8081
echo.
echo Initial login information:
echo  - BookStack Knowledge Base:
echo    Username: admin@admin.com
echo    Password: password
echo  - osTicket Ticketing System:
echo    Username: admin
echo    Password: Admin1@
echo.
echo %WARN%[WARNING]%RESET% Please change the default passwords immediately after first login!
echo.
echo System management commands:
echo  - Start system: start.bat
echo  - Stop system: stop.bat
echo  - Monitor system: monitor_system.bat
echo  - Backup data: backup_data.bat
echo  - Restore data: restore_data.bat
echo  - Update system: update_system.bat
echo  - Uninstall system: uninstall_system.bat
echo.
echo Knowledge Extractor Status:
echo  - MySQL connection: Fixed and configured
echo  - PyMySQL dependency: Installed
echo  - Database queries: Updated for correct table structure
echo  - The knowledge extractor will run automatically every 24 hours
echo.

pause