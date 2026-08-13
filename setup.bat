@echo off
REM Hotel Reservation System - Setup Script (Windows CMD)
REM Usage: setup.bat [options]

setlocal enabledelayedexpansion

REM Get script directory and save original directory
set SCRIPT_DIR=%~dp0
set ORIGINAL_DIR=%cd%

echo ========================================
echo Hotel Reservation System - Setup
echo ========================================
echo.
echo [INFO] Script directory: %SCRIPT_DIR%
echo [INFO] Current directory: %ORIGINAL_DIR%
echo.

REM Initialize variables
set POSTGRES=false
set CREATE_SU=false
set SKIP_DEPS=false
set FORCE=false
set NO_COLLECTSTATIC=false
set DEV=false
set CHECK=false
set SKIP_NODE=false
set SEED_DATA=false
set PURGE_DATA=false

REM Parse arguments
:parse_args
if "%~1"=="" goto done_parsing
if /i "%~1"=="--postgres" (
    set POSTGRES=true
    shift
    goto parse_args
)
if /i "%~1"=="--create-su" (
    set CREATE_SU=true
    shift
    goto parse_args
)
if /i "%~1"=="--skip-deps" (
    set SKIP_DEPS=true
    shift
    goto parse_args
)
if /i "%~1"=="--force" (
    set FORCE=true
    shift
    goto parse_args
)
if /i "%~1"=="--no-collectstatic" (
    set NO_COLLECTSTATIC=true
    shift
    goto parse_args
)
if /i "%~1"=="--dev" (
    set DEV=true
    shift
    goto parse_args
)
if /i "%~1"=="--check" (
    set CHECK=true
    shift
    goto parse_args
)
if /i "%~1"=="--skip-node" (
    set SKIP_NODE=true
    shift
    goto parse_args
)
if /i "%~1"=="--seed-data" (
    set SEED_DATA=true
    set SKIP_NODE=true
    shift
    goto parse_args
)
if /i "%~1"=="--purge-seed-data" (
    set PURGE_DATA=true
    set SKIP_NODE=true
    shift
    goto parse_args
)
echo [ERROR] Unknown option: %~1
cd /d "%ORIGINAL_DIR%"
endlocal
exit /b 1
:done_parsing

REM Set directory paths
set BACKEND_DIR=%SCRIPT_DIR%backend
set FRONTEND_DIR=%SCRIPT_DIR%frontend

echo [INFO] Backend directory: %BACKEND_DIR%
echo [INFO] Frontend directory: %FRONTEND_DIR%
echo.

REM Check prerequisites
echo Checking prerequisites...
echo [INFO] Checking Python...
echo [DEBUG] Starting Python check...
where python >nul 2>&1
echo [DEBUG] where python returned errorlevel: %errorlevel%
if errorlevel 1 (
    echo [ERROR] Python is not installed or not in PATH
    echo [INFO] Please install Python 3.8 or higher from: https://www.python.org/
    cd /d "%ORIGINAL_DIR%"
    endlocal
    exit /b 1
)
echo [SUCCESS] Python found
python --version
echo [DEBUG] Completed Python check

echo [INFO] Checking pip...
echo [DEBUG] Starting pip check...
where pip >nul 2>&1
echo [DEBUG] where pip returned errorlevel: %errorlevel%
if errorlevel 1 (
    echo [ERROR] pip is not installed or not in PATH
    echo [INFO] pip should be installed with Python
    cd /d "%ORIGINAL_DIR%"
    endlocal
    exit /b 1
)
echo [SUCCESS] pip found
echo [DEBUG] Completed pip check

echo [INFO] Checking Node.js...
echo [DEBUG] Starting Node.js check...
where node >nul 2>&1
echo [DEBUG] where node returned errorlevel: %errorlevel%
if errorlevel 1 (
    echo [WARNING] Node.js is not installed
    echo [INFO] Please install Node.js manually to enable frontend setup
    echo [INFO] Download Node.js LTS from: https://nodejs.org/
    echo [INFO] After installation, restart your terminal and run setup again
    echo [INFO] Or use --skip-node flag to skip Node.js installation (backend only)
    echo [DEBUG] SKIP_NODE flag: %SKIP_NODE%
    if "%SKIP_NODE%"=="false" (
        echo [DEBUG] Exiting because Node.js not found and SKIP_NODE is false
        cd /d "%ORIGINAL_DIR%"
        endlocal
        exit /b 1
    )
    echo [DEBUG] Continuing despite Node.js not found because SKIP_NODE is true
) else (
    echo [SUCCESS] Node.js is already installed
    node --version
    npm --version
)
echo [DEBUG] Completed Node.js check

echo [DEBUG] Completed Node.js check
echo [DEBUG] About to print Prerequisites check complete message...

echo [SUCCESS] Prerequisites check complete
echo.
echo [DEBUG] Reached this point successfully
echo [DEBUG] Press any key to continue...
pause

echo [DEBUG] About to show Backend Setup section...

REM Backend Setup

REM Backend Setup
echo ========================================
echo Backend Setup
echo ========================================
echo [INFO] SEED_DATA flag: %SEED_DATA%
echo [INFO] SKIP_NODE flag: %SKIP_NODE%
echo [INFO] Current directory: %cd%
echo [INFO] Backend directory: %BACKEND_DIR%
echo.

echo [INFO] Checking backend directory...
if not exist "%BACKEND_DIR%" (
    echo [ERROR] Backend directory not found: %BACKEND_DIR%
    cd /d "%ORIGINAL_DIR%"
    endlocal
    exit /b 1
)
echo [SUCCESS] Backend directory found

echo [INFO] Changing to backend directory...
cd /d "%BACKEND_DIR%"
if errorlevel 1 (
    echo [ERROR] Failed to change to backend directory: %BACKEND_DIR%
    echo [INFO] Error code: %errorlevel%
    cd /d "%ORIGINAL_DIR%"
    endlocal
    exit /b 1
)
echo [SUCCESS] Changed to backend directory
echo Current directory: %cd%

REM Check/create virtual environment
set VENV_DIR=%BACKEND_DIR%venv
set VENV_PYTHON=%VENV_DIR%\Scripts\python.exe

echo [INFO] Checking virtual environment...
if "%FORCE%"=="true" (
    if exist "%VENV_DIR%" (
        echo [WARNING] Force mode: Removing existing virtual environment...
        if not "%CHECK%"=="true" (
            rmdir /s /q "%VENV_DIR%"
        )
    )
)

if not exist "%VENV_DIR%" (
    echo [INFO] Creating virtual environment...
    if not "%CHECK%"=="true" (
        python -m venv venv
        if errorlevel 1 (
            echo [ERROR] Failed to create virtual environment
            echo [INFO] Trying with --clear flag...
            if exist "%VENV_DIR%" rmdir /s /q "%VENV_DIR%"
            python -m venv --clear venv
            if errorlevel 1 (
                echo [ERROR] Virtual environment creation failed
                echo [INFO] Will use system Python instead
                set VENV_PYTHON=python
            )
        )
    )
) else (
    echo [SUCCESS] Virtual environment already exists
)

if exist "%VENV_PYTHON%" (
    echo [SUCCESS] Virtual environment ready
) else (
    echo [WARNING] Using system Python instead of virtual environment
    set VENV_PYTHON=python
)

echo [INFO] Python to use: %VENV_PYTHON%

REM Activate virtual environment and upgrade pip
echo [INFO] Upgrading pip...
if not "%CHECK%"=="true" (
    "%VENV_PYTHON%" -m pip install --upgrade pip
    if errorlevel 1 (
        echo [WARNING] Failed to upgrade pip, continuing anyway
    )
)

REM Install dependencies
if "%SKIP_DEPS%"=="false" (
    echo Installing Python dependencies...
    if not "%CHECK%"=="true" (
        "%VENV_PYTHON%" -m pip install -r requirements.txt
        if errorlevel 1 (
            echo [ERROR] Failed to install Python dependencies
            cd /d "%ORIGINAL_DIR%"
            endlocal
            exit /b 1
        )
    )
    echo [SUCCESS] Python dependencies installed
) else (
    echo [WARNING] Skipping Python dependency installation
)

REM Run migrations
echo Running database migrations...
if not "%CHECK%"=="true" (
    "%VENV_PYTHON%" manage.py makemigrations
    "%VENV_PYTHON%" manage.py migrate
    if errorlevel 1 (
        echo [ERROR] Failed to run migrations
        cd /d "%ORIGINAL_DIR%"
        endlocal
        exit /b 1
    )
)
echo [SUCCESS] Database migrations completed

REM Create superuser
if "%CREATE_SU%"=="true" (
    echo Creating superuser...
    if not "%CHECK%"=="true" (
        echo from django.contrib.auth import get_user_model; User = get_user_model(); User.objects.create_superuser('admin', 'admin@hotel.com', 'admin123') if not User.objects.filter(username='admin').exists() else None | "%VENV_PYTHON%" manage.py shell
        if errorlevel 1 (
            echo [WARNING] Superuser may already exist or creation failed
        ) else (
            echo [SUCCESS] Superuser created (username: admin)
        )
    )
)

REM Load seed data
echo Loading seed data...
if not "%CHECK%"=="true" (
    if "%PURGE_DATA%"=="true" (
        echo [INFO] Purging sample data (customers, rooms, reservations)...
        "%VENV_PYTHON%" seed_data.py --purge
    ) else if "%SEED_DATA%"=="true" (
        echo [INFO] Generating sample data (50 customers, 80 rooms, 3 months of reservations)...
        "%VENV_PYTHON%" seed_data.py --sample
    ) else (
        "%VENV_PYTHON%" seed_data.py
    )
    if errorlevel 1 (
        echo [WARNING] Seed data operation failed
    )
)
echo [SUCCESS] Seed data operation completed

REM Collect static files
if "%NO_COLLECTSTATIC%"=="false" (
    echo Collecting static files...
    if not "%CHECK%"=="true" (
        "%VENV_PYTHON%" manage.py collectstatic --noinput
    )
    echo [SUCCESS] Static files collected
) else (
    echo [WARNING] Skipping static files collection
)

cd /d "%ORIGINAL_DIR%"

REM Frontend Setup
echo.
echo ========================================
echo Frontend Setup
echo ========================================

where node >nul 2>&1
where npm >nul 2>&1
if not errorlevel 1 (
    echo [INFO] Node.js available, setting up frontend...
    
    if not exist "%FRONTEND_DIR%" (
        echo [ERROR] Frontend directory not found: %FRONTEND_DIR%
        cd /d "%ORIGINAL_DIR%"
        endlocal
        exit /b 1
    )

    cd /d "%FRONTEND_DIR%"

    REM Install dependencies
    if "%SKIP_DEPS%"=="false" (
        echo Installing Node.js dependencies...
        if not "%CHECK%"=="true" (
            npm install
            if errorlevel 1 (
                echo [ERROR] Failed to install Node.js dependencies
                cd /d "%ORIGINAL_DIR%"
                endlocal
                exit /b 1
            )
        )
        echo [SUCCESS] Node.js dependencies installed
    ) else (
        echo [WARNING] Skipping Node.js dependency installation
    )

    REM Development dependencies
    if "%DEV%"=="true" (
        echo Installing development dependencies...
        if not "%CHECK%"=="true" (
            npm install --save-dev @types/react @types/react-dom
        )
        echo [SUCCESS] Development dependencies installed
    )
    cd /d "%ORIGINAL_DIR%"
) else (
    echo [WARNING] Skipping frontend setup (Node.js/npm not available)
)

REM Final summary
echo.
echo ========================================
echo Setup Complete!
echo ========================================
echo.
echo Backend setup: Complete
if not errorlevel 1 (
    echo Frontend setup: Complete
) else (
    echo Frontend setup: Skipped (Node.js not installed)
)
echo.
echo To start the application, run:
echo   start.bat
echo.

cd /d "%ORIGINAL_DIR%"
endlocal
echo.
echo [INFO] Setup script completed. Press any key to exit...
pause >nul
exit /b 0
