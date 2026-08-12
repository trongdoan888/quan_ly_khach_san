@echo off
REM Hotel Reservation System - Setup Script (Windows CMD)
REM Usage: setup.bat [options]

setlocal enabledelayedexpansion

REM Initialize variables
set POSTGRES=false
set CREATE_SU=false
set SKIP_DEPS=false
set FORCE=false
set NO_COLLECTSTATIC=false
set DEV=false
set CHECK=false

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
echo Unknown option: %~1
exit /b 1
:done_parsing

REM Get script directory
set SCRIPT_DIR=%~dp0
set BACKEND_DIR=%SCRIPT_DIR%backend
set FRONTEND_DIR=%SCRIPT_DIR%frontend

echo ========================================
echo Hotel Reservation System - Setup
echo ========================================
echo.

REM Check mode
if "%CHECK%"=="true" (
    echo Running in CHECK mode - no changes will be made
    echo.
)

REM Check prerequisites
echo Checking prerequisites...
where python >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Python is not installed or not in PATH
    exit /b 1
)

where pip >nul 2>&1
if errorlevel 1 (
    echo [ERROR] pip is not installed or not in PATH
    exit /b 1
)

where node >nul 2>&1
if errorlevel 1 (
    echo [WARNING] Node.js is not installed - frontend setup will be skipped
)

where npm >nul 2>&1
if errorlevel 1 (
    if not errorlevel 1 (
        echo [WARNING] npm is not installed - frontend setup will be skipped
    )
)

echo [SUCCESS] Prerequisites check complete
echo.

REM Backend Setup
echo ========================================
echo Backend Setup
echo ========================================

if not exist "%BACKEND_DIR%" (
    echo [ERROR] Backend directory not found: %BACKEND_DIR%
    exit /b 1
)

pushd "%BACKEND_DIR%"

REM Check/create virtual environment
set VENV_DIR=%BACKEND_DIR%venv
set VENV_PYTHON=%VENV_DIR%\Scripts\python.exe

if "%FORCE%"=="true" (
    if exist "%VENV_DIR%" (
        echo [WARNING] Force mode: Removing existing virtual environment...
        if not "%CHECK%"=="true" (
            rmdir /s /q "%VENV_DIR%"
        )
    )
)

if not exist "%VENV_DIR%" (
    echo Creating virtual environment...
    if not "%CHECK%"=="true" (
        python -m venv venv
        if errorlevel 1 (
            echo [ERROR] Failed to create virtual environment
            popd
            exit /b 1
        )
    )
    echo [SUCCESS] Virtual environment created
) else (
    echo [SUCCESS] Virtual environment already exists
)

REM Activate virtual environment and upgrade pip
echo Activating virtual environment...
if not "%CHECK%"=="true" (
    "%VENV_PYTHON%" -m pip install --upgrade pip
)

REM Install dependencies
if "%SKIP_DEPS%"=="false" (
    echo Installing Python dependencies...
    if not "%CHECK%"=="true" (
        "%VENV_PYTHON%" -m pip install -r requirements.txt
        if errorlevel 1 (
            echo [ERROR] Failed to install Python dependencies
            popd
            exit /b 1
        )
    )
    echo [SUCCESS] Python dependencies installed
) else (
    echo [WARNING] Skipping Python dependency installation
)

REM Configure database
if "%POSTGRES%"=="true" (
    echo Configuring for PostgreSQL...
    set ENV_FILE=%BACKEND_DIR%.env
    if exist "%ENV_FILE%" (
        echo Updating .env for PostgreSQL...
        if not "%CHECK%"=="true" (
            powershell -Command "(Get-Content '%ENV_FILE%') -replace 'DB_NAME=.*', 'DB_NAME=hotel_reservation' -replace 'DB_USER=.*', 'DB_USER=postgres' -replace 'DB_PASSWORD=.*', 'DB_PASSWORD=postgres' -replace 'DB_HOST=.*', 'DB_HOST=localhost' -replace 'DB_PORT=.*', 'DB_PORT=5432' | Set-Content '%ENV_FILE%'"
        )
    )
    echo [SUCCESS] PostgreSQL configuration applied
) else (
    echo Using SQLite (default)
)

REM Run migrations
echo Running database migrations...
if not "%CHECK%"=="true" (
    "%VENV_PYTHON%" manage.py makemigrations
    "%VENV_PYTHON%" manage.py migrate
    if errorlevel 1 (
        echo [ERROR] Failed to run migrations
        popd
        exit /b 1
    )
)
echo [SUCCESS] Database migrations complete

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
    "%VENV_PYTHON%" seed_data.py
    if errorlevel 1 (
        echo [WARNING] Seed data loading failed or already loaded
    )
)
echo [SUCCESS] Seed data loaded

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

popd

REM Frontend Setup
echo.
echo ========================================
echo Frontend Setup
echo ========================================

where node >nul 2>&1
where npm >nul 2>&1
if not errorlevel 1 (
    if not exist "%FRONTEND_DIR%" (
        echo [ERROR] Frontend directory not found: %FRONTEND_DIR%
        exit /b 1
    )

    pushd "%FRONTEND_DIR%"

    REM Install dependencies
    if "%SKIP_DEPS%"=="false" (
        echo Installing Node.js dependencies...
        if not "%CHECK%"=="true" (
            npm install
            if errorlevel 1 (
                echo [ERROR] Failed to install Node.js dependencies
                popd
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

    popd
) else (
    echo [WARNING] Skipping frontend setup (Node.js/npm not available)
)

REM Final summary
echo.
echo ========================================
echo Setup Complete!
echo ========================================
echo.
echo [SUCCESS] Backend: %BACKEND_DIR%
echo [SUCCESS] Frontend: %FRONTEND_DIR%
echo.
echo Configuration:
echo   Database: %POSTGRES%
echo   Superuser: %CREATE_SU%
echo   Dependencies: %SKIP_DEPS%
echo   Static Files: %NO_COLLECTSTATIC%
echo.
echo Next steps:
echo   1. Run start script: start.bat [options]
echo   2. Or start manually:
echo      Backend: cd backend && venv\Scripts\python manage.py runserver
echo      Frontend: cd frontend && npm run dev
echo.
echo Demo credentials:
echo   Admin: admin / admin123
echo   Staff: staff / staff123
echo.

endlocal