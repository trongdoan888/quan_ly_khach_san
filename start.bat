@echo off
REM Hotel Reservation System - Start Script (Windows CMD)
REM Usage: start.bat [options]

setlocal enabledelayedexpansion

REM Initialize variables
set REMOTE=false
set POSTGRES=false
set BCK=false
set MULTIPLE=false
set BACKEND_PORT=8000
set FRONTEND_PORT=3000
set SEED_DATA=false
set PURGE_DATA=false

REM Parse arguments
:parse_args
if "%~1"=="" goto done_parsing
if /i "%~1"=="--remote" (
    set REMOTE=true
    shift
    goto parse_args
)
if /i "%~1"=="--postgres" (
    set POSTGRES=true
    shift
    goto parse_args
)
if /i "%~1"=="--bck" (
    set BCK=true
    shift
    goto parse_args
)
if /i "%~1"=="--multiple" (
    set MULTIPLE=true
    shift
    goto parse_args
)
if /i "%~1"=="--port" (
    shift
    if "%~1"=="" (
        echo [ERROR] --port requires two arguments: backend_port frontend_port
        exit /b 1
    )
    set BACKEND_PORT=%~1
    shift
    if "%~1"=="" (
        echo [ERROR] --port requires two arguments: backend_port frontend_port
        exit /b 1
    )
    set FRONTEND_PORT=%~1
    shift
    goto parse_args
)
if /i "%~1"=="--seed-data" (
    set SEED_DATA=true
    shift
    goto parse_args
)
if /i "%~1"=="--purge-seed-data" (
    set PURGE_DATA=true
    shift
    goto parse_args
)
echo Unknown option: %~1
exit /b 1
:done_parsing

REM Get script directory and save original directory
set SCRIPT_DIR=%~dp0
set ORIGINAL_DIR=%CD%
set BACKEND_DIR=%SCRIPT_DIR%backend
set FRONTEND_DIR=%SCRIPT_DIR%frontend
set VENV_PYTHON=%BACKEND_DIR%\venv\Scripts\python.exe

REM Get local IP address if remote mode
set LOCAL_IP=localhost
if "%REMOTE%"=="true" (
    REM Try to get local IP using ipconfig
    for /f "tokens=2 delims=:" %%A in ('ipconfig ^| findstr /i "IPv4 Address" ^| findstr /v "127.0.0.1"') do (
        set LOCAL_IP=%%A
        goto :found_ip
    )
    :found_ip
    if "!LOCAL_IP!"=="localhost" (
        set LOCAL_IP=0.0.0.0
    )
)

echo ========================================
echo Hotel Reservation System - Start
echo ========================================
echo.
echo Configuration:
echo   Remote Mode: %REMOTE% (IP: %LOCAL_IP%)
echo   Database: %POSTGRES%
echo   Background: %BCK%
echo   Multiple Instances: %MULTIPLE%
echo   Backend Port: %BACKEND_PORT%
echo   Frontend Port: %FRONTEND_PORT%
echo.

REM Configure database if needed
if "%POSTGRES%"=="true" (
    echo Configuring for PostgreSQL...
    set ENV_FILE=%BACKEND_DIR%.env
    if exist "%ENV_FILE%" (
        REM Using CMD to replace values in .env file
        powershell -NoProfile -NonInteractive -Command "(Get-Content '%ENV_FILE%') -replace 'DB_NAME=.*', 'DB_NAME=hotel_reservation' -replace 'DB_USER=.*', 'DB_USER=postgres' -replace 'DB_PASSWORD=.*', 'DB_PASSWORD=postgres' -replace 'DB_HOST=.*', 'DB_HOST=localhost' -replace 'DB_PORT=.*', 'DB_PORT=5432' | Set-Content '%ENV_FILE%'"
    )
    echo [SUCCESS] PostgreSQL configured
)

REM Configure frontend API URL if custom ports are used
if not "%BACKEND_PORT%"=="8000" (
    echo Configuring frontend API URL for custom port...
    set FRONTEND_ENV=%FRONTEND_DIR%.env
    if exist "%FRONTEND_ENV%" (
        echo VITE_API_URL=http://localhost:%BACKEND_PORT%/api > "%FRONTEND_ENV%"
    )
    echo [SUCCESS] Frontend API URL configured
)

REM Kill existing processes (skip if --multiple is used)
if "%MULTIPLE%"=="false" (
    echo ========================================
    echo Cleaning up existing processes
    echo ========================================

    REM Kill existing Python processes
    echo Checking for existing Python processes...
    tasklist /FI "IMAGENAME eq python.exe" 2>nul | find /I "python.exe" >nul
    if not errorlevel 1 (
        echo [INFO] Killing existing Python processes...
        taskkill /F /IM python.exe >nul 2>&1
        timeout /t 2 /nobreak >nul
        echo [SUCCESS] Python processes killed
    ) else (
        echo [INFO] No existing Python processes found
    )

    REM Kill existing Node processes
    echo Checking for existing Node processes...
    tasklist /FI "IMAGENAME eq node.exe" 2>nul | find /I "node.exe" >nul
    if not errorlevel 1 (
        echo [INFO] Killing existing Node processes...
        taskkill /F /IM node.exe >nul 2>&1
        timeout /t 2 /nobreak >nul
        echo [SUCCESS] Node processes killed
    ) else (
        echo [INFO] No existing Node processes found
    )

    REM Check if ports are available
    echo.
    echo Checking port availability...
    netstat -ano | findstr ":8000" >nul
    if not errorlevel 1 (
        echo [WARNING] Port 8000 is in use, attempting to free it...
        taskkill /F /IM python.exe >nul 2>&1
        timeout /t 2 /nobreak >nul
    )

    netstat -ano | findstr ":3000" >nul
    if not errorlevel 1 (
        echo [WARNING] Port 3000 is in use, attempting to free it...
        taskkill /F /IM node.exe >nul 2>&1
        timeout /t 2 /nobreak >nul
    )

    echo [SUCCESS] Ports 8000 and 3000 are available
    echo.
) else (
    echo ========================================
    echo Multiple Instances Mode
    echo ========================================
    echo [INFO] Skipping process cleanup - allowing multiple instances
    echo [INFO] Backend will use port %BACKEND_PORT%
    echo [INFO] Frontend will use port %FRONTEND_PORT%
    echo.
)

REM Start Backend
echo ========================================
echo Starting Backend
echo ========================================

if not exist "%VENV_PYTHON%" (
    echo [ERROR] Virtual environment not found. Run setup.bat first.
    exit /b 1
)

cd /d "%BACKEND_DIR%"

REM Determine host and port
set BACKEND_HOST=127.0.0.1
if "%REMOTE%"=="true" set BACKEND_HOST=0.0.0.0

echo Backend URL: http://%LOCAL_IP%:%BACKEND_PORT%/api

echo Starting backend in background...

REM Start backend in background
echo Starting backend...
start /MIN /D "%BACKEND_DIR%" "" "%VENV_PYTHON%" manage.py runserver %BACKEND_HOST%:%BACKEND_PORT%

REM Wait a moment for backend to start
timeout /t 3 /nobreak >nul

echo [SUCCESS] Backend started in background

REM Load sample data if requested
if "%SEED_DATA%"=="true" (
    echo.
    echo ========================================
    echo Loading Sample Data
    echo ========================================
    echo Loading sample data (50 customers, 80 rooms, 3 months of reservations)...
    cd /d "%BACKEND_DIR%"
    "%VENV_PYTHON%" seed_data.py --sample
    if errorlevel 1 (
        echo [WARNING] Sample data loading failed
    ) else (
        echo [SUCCESS] Sample data loaded
    )
    cd /d "%ORIGINAL_DIR%"
)

REM Purge sample data if requested
if "%PURGE_DATA%"=="true" (
    echo.
    echo ========================================
    echo Purging Sample Data
    echo ========================================
    echo Purging sample data (customers, rooms, reservations)...
    cd /d "%BACKEND_DIR%"
    "%VENV_PYTHON%" seed_data.py --purge
    if errorlevel 1 (
        echo [WARNING] Sample data purging failed
    ) else (
        echo [SUCCESS] Sample data purged
    )
    cd /d "%ORIGINAL_DIR%"
)

REM Start Frontend
echo.
echo ========================================
echo Starting Frontend
echo ========================================

if not exist "%FRONTEND_DIR%" (
    echo [ERROR] Frontend directory not found
    exit /b 1
)

cd /d "%FRONTEND_DIR%"

REM Check if node_modules exists
if not exist "node_modules" (
    echo [WARNING] node_modules not found. Running npm install...
    npm.cmd install
    if errorlevel 1 (
        echo [ERROR] Failed to install frontend dependencies
        cd /d "%ORIGINAL_DIR%"
        exit /b 1
    )
)

REM Determine host and port
set FRONTEND_HOST=localhost
if "%REMOTE%"=="true" set FRONTEND_HOST=0.0.0.0

echo Frontend URL: http://%LOCAL_IP%:%FRONTEND_PORT%

REM Update vite config for remote access
if "%REMOTE%"=="true" (
    echo Configuring Vite for remote access...
    set VITE_CONFIG=%FRONTEND_DIR%\vite.config.ts
    if exist "%VITE_CONFIG%" (
        powershell -NoProfile -NonInteractive -Command "(Get-Content '%VITE_CONFIG%') -replace \"host: 'localhost'\", \"host: '0.0.0.0'\" | Set-Content '%VITE_CONFIG%'"
    )
)

echo Starting frontend in background...

REM Start frontend in background
cd /d "%FRONTEND_DIR%"
start /MIN "" cmd /c "npm.cmd run dev"
cd /d "%ORIGINAL_DIR%"

REM Wait a moment for frontend to start
timeout /t 3 /nobreak >nul

echo [SUCCESS] Frontend started in background

REM Final summary
echo.
echo ========================================
echo Services Started
echo ========================================
echo.
echo [SUCCESS] Backend API: http://%LOCAL_IP%:%BACKEND_PORT%/api
echo [SUCCESS] Frontend UI: http://%LOCAL_IP%:%FRONTEND_PORT%
echo.
echo Both services are running in background.
echo To stop services, close this terminal or use Ctrl+C.
echo.
echo Demo credentials:
echo   Admin: admin / admin123
echo   Staff: staff / staff123
echo.

REM Return to original directory
cd /d "%ORIGINAL_DIR%"

endlocal