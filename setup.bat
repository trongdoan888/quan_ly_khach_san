@echo off
REM Hotel Reservation System - Setup Script (Windows CMD)
REM Usage: setup.bat [options]

REM Get script directory and save original directory
set SCRIPT_DIR=%~dp0
set ORIGINAL_DIR=%cd%

REM Initialize variables
set POSTGRES=false
set CREATE_SU=false
set SKIP_DEPS=false
set FORCE=false
set NO_COLLECTSTATIC=false
set DEV=false
set CHECK=false
set SKIP_NODE=false

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
echo Unknown option: %~1
exit /b 1
:done_parsing

REM Set directory paths
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
    echo [WARNING] Node.js is not installed
    echo [INFO] Please install Node.js manually to enable frontend setup
    echo [INFO] Download Node.js LTS from: https://nodejs.org/
    echo [INFO] After installation, restart your terminal and run setup again
    echo [INFO] Or use --skip-node flag to skip Node.js installation (backend only)
    if "%SKIP_NODE%"=="false" (
        cd /d "%ORIGINAL_DIR%"
        exit /b 1
    )
) else (
    echo [SUCCESS] Node.js is already installed
    node --version
    npm --version
)

echo [SUCCESS] Prerequisites check complete
echo .

REM Backend Setup
echo ========================================
echo Backend Setup
echo ========================================

if not exist "%BACKEND_DIR%" (
    echo [ERROR] Backend directory not found: %BACKEND_DIR%
    cd /d "%ORIGINAL_DIR%"
    exit /b 1
)

cd /d "%BACKEND_DIR%"

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
        REM Try to create venv
        python -m venv venv
        if errorlevel 1 (
            echo [ERROR] Failed to create virtual environment
            echo [INFO] Trying alternative method...
            REM Clean up failed attempt
            if exist "%VENV_DIR%" rmdir /s /q "%VENV_DIR%"
            REM Try with --clear flag
            python -m venv --clear venv
            if errorlevel 1 (
                echo [ERROR] Virtual environment creation failed completely
                cd /d "%ORIGINAL_DIR%"
                exit /b 1
            )
        )
        REM Verify venv was created successfully
        if not exist "%VENV_PYTHON%" (
            echo [ERROR] Virtual environment creation failed - python.exe not found
            echo [INFO] Cleaning up failed venv and using system Python instead
            if exist "%VENV_DIR%" rmdir /s /q "%VENV_DIR%"
            set VENV_PYTHON=python
        )
    )
    if exist "%VENV_PYTHON%" (
        echo [SUCCESS] Virtual environment created
    ) else (
        echo [WARNING] Using system Python instead of virtual environment
    )
) else (
    echo [SUCCESS] Virtual environment already exists
)

REM Activate virtual environment and upgrade pip
echo Activating virtual environment...
if not "%CHECK%"=="true" (
    if exist "%VENV_PYTHON%" (
        "%VENV_PYTHON%" -m pip install --upgrade pip
        if errorlevel 1 (
            echo [WARNING] Failed to upgrade pip in virtual environment, trying system pip
            python -m pip install --upgrade pip
        )
    ) else (
        echo [WARNING] Virtual environment python not found, using system Python
        python -m pip install --upgrade pip
    )
)

REM Install dependencies
if "%SKIP_DEPS%"=="false" (
    echo Installing Python dependencies...
    if not "%CHECK%"=="true" (
        if exist "%VENV_PYTHON%" (
            "%VENV_PYTHON%" -m pip install -r requirements.txt
            if errorlevel 1 (
                echo [WARNING] Failed to install dependencies in virtual environment, trying system pip
                python -m pip install -r requirements.txt
                if errorlevel 1 (
                    echo [ERROR] Failed to install Python dependencies
                    cd /d "%ORIGINAL_DIR%"
                    exit /b 1
                )
            )
        ) else (
            echo [WARNING] Virtual environment not found, using system Python
            python -m pip install -r requirements.txt
            if errorlevel 1 (
                echo [ERROR] Failed to install Python dependencies
                cd /d "%ORIGINAL_DIR%"
                exit /b 1
            )
        )
    )
    echo [SUCCESS] Python dependencies installed
) else (
    echo [WARNING] Skipping Python dependency installation
)

REM Configure database if needed
if "%POSTGRES%"=="true" (
    echo Configuring for PostgreSQL...
    set ENV_FILE=%BACKEND_DIR%.env
    if exist "%ENV_FILE%" (
        powershell -Command "(Get-Content '%ENV_FILE%') -replace 'DB_NAME=.*', 'DB_NAME=hotel_reservation' -replace 'DB_USER=.*', 'DB_USER=postgres' -replace 'DB_PASSWORD=.*', 'DB_PASSWORD=postgres' -replace 'DB_HOST=.*', 'DB_HOST=localhost' -replace 'DB_PORT=.*', 'DB_PORT=5432' | Set-Content '%ENV_FILE%'"
    )
    echo [SUCCESS] PostgreSQL configured
)

REM Run migrations
echo Running database migrations...
if not "%CHECK%"=="true" (
    if exist "%VENV_PYTHON%" (
        "%VENV_PYTHON%" manage.py makemigrations
        "%VENV_PYTHON%" manage.py migrate
    ) else (
        python manage.py makemigrations
        python manage.py migrate
    )
    if errorlevel 1 (
        echo [ERROR] Failed to run migrations
        cd /d "%ORIGINAL_DIR%"
        exit /b 1
    )
)
echo [SUCCESS] Database migrations completed

REM Create superuser
if "%CREATE_SU%"=="true" (
    echo Creating superuser...
    if not "%CHECK%"=="true" (
        if exist "%VENV_PYTHON%" (
            echo from django.contrib.auth import get_user_model; User = get_user_model(); User.objects.create_superuser('admin', 'admin@hotel.com', 'admin123') if not User.objects.filter(username='admin').exists() else None | "%VENV_PYTHON%" manage.py shell
        ) else (
            echo from django.contrib.auth import get_user_model; User = get_user_model(); User.objects.create_superuser('admin', 'admin@hotel.com', 'admin123') if not User.objects.filter(username='admin').exists() else None | python manage.py shell
        )
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
    if exist "%VENV_PYTHON%" (
        "%VENV_PYTHON%" seed_data.py
    ) else (
        python seed_data.py
    )
    if errorlevel 1 (
        echo [WARNING] Seed data loading failed or already loaded
    )
)
echo [SUCCESS] Seed data loaded

REM Collect static files
if "%NO_COLLECTSTATIC%"=="false" (
    echo Collecting static files...
    if not "%CHECK%"=="true" (
        if exist "%VENV_PYTHON%" (
            "%VENV_PYTHON%" manage.py collectstatic --noinput
        ) else (
            python manage.py collectstatic --noinput
        )
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
    if not exist "%FRONTEND_DIR%" (
        echo [ERROR] Frontend directory not found: %FRONTEND_DIR%
        cd /d "%ORIGINAL_DIR%"
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
