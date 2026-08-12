# Hotel Reservation System - Setup Script (PowerShell)
# Usage: .\setup.ps1 [options]

param(
    [switch]$postgres,
    [switch]$create_su,
    [switch]$skip_deps,
    [switch]$force,
    [switch]$no_collectstatic,
    [switch]$dev,
    [switch]$check
)

# Color output functions
function Write-ColorOutput($ForegroundColor) {
    $fc = $host.UI.RawUI.ForegroundColor
    $host.UI.RawUI.ForegroundColor = $ForegroundColor
    if ($args) {
        Write-Output $args
    }
    $host.UI.RawUI.ForegroundColor = $fc
}

function Write-Success { Write-ColorOutput Green @args }
function Write-Error { Write-ColorOutput Red @args }
function Write-Warning { Write-ColorOutput Yellow @args }
function Write-Info { Write-ColorOutput Cyan @args }

# Get script directory
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$BackendDir = Join-Path $ScriptDir "backend"
$FrontendDir = Join-Path $ScriptDir "frontend"

Write-Info "========================================"
Write-Info "Hotel Reservation System - Setup"
Write-Info "========================================"
Write-Output ""

# Check mode
if ($check) {
    Write-Info "Running in CHECK mode - no changes will be made"
    Write-Output ""
}

# Function to check if command exists
function Test-Command {
    param($Command)
    try {
        $null = Get-Command $Command -ErrorAction Stop
        return $true
    } catch {
        return $false
    }
}

# Check prerequisites
Write-Info "Checking prerequisites..."
$PythonInstalled = Test-Command "python"
$NodeInstalled = Test-Command "node"
$PipInstalled = Test-Command "pip"
$NpmInstalled = Test-Command "npm"

if (-not $PythonInstalled) {
    Write-Error "Python is not installed or not in PATH"
    exit 1
}

if (-not $PipInstalled) {
    Write-Error "pip is not installed or not in PATH"
    exit 1
}

if (-not $NodeInstalled) {
    Write-Warning "Node.js is not installed - frontend setup will be skipped"
}

if (-not $NpmInstalled -and $NodeInstalled) {
    Write-Warning "npm is not installed - frontend setup will be skipped"
}

Write-Success "Prerequisites check complete"
Write-Output ""

# Backend Setup
Write-Info "========================================"
Write-Info "Backend Setup"
Write-Info "========================================"

if (-not (Test-Path $BackendDir)) {
    Write-Error "Backend directory not found: $BackendDir"
    exit 1
}

Set-Location $BackendDir

# Check/create virtual environment
$VenvDir = Join-Path $BackendDir "venv"
$VenvPython = Join-Path $VenvDir "Scripts\python.exe"

if ($force -and (Test-Path $VenvDir)) {
    Write-Warning "Force mode: Removing existing virtual environment..."
    if (-not $check) {
        Remove-Item -Recurse -Force $VenvDir
    }
}

if (-not (Test-Path $VenvDir)) {
    Write-Info "Creating virtual environment..."
    if (-not $check) {
        python -m venv venv
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Failed to create virtual environment"
            exit 1
        }
    }
    Write-Success "Virtual environment created"
} else {
    Write-Success "Virtual environment already exists"
}

# Activate virtual environment
Write-Info "Activating virtual environment..."
if (-not $check) {
    & $VenvPython -m pip install --upgrade pip
}

# Install dependencies
if (-not $skip_deps) {
    Write-Info "Installing Python dependencies..."
    if (-not $check) {
        & $VenvPython -m pip install -r requirements.txt
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Failed to install Python dependencies"
            exit 1
        }
    }
    Write-Success "Python dependencies installed"
} else {
    Write-Warning "Skipping Python dependency installation"
}

# Configure database
if ($postgres) {
    Write-Info "Configuring for PostgreSQL..."
    $EnvFile = Join-Path $BackendDir ".env"
    if (Test-Path $EnvFile) {
        Write-Info "Updating .env for PostgreSQL..."
        if (-not $check) {
            (Get-Content $EnvFile) -replace '# Database.*', '' -replace 'DB_NAME.*', 'DB_NAME=hotel_reservation' -replace 'DB_USER.*', 'DB_USER=postgres' -replace 'DB_PASSWORD.*', 'DB_PASSWORD=postgres' -replace 'DB_HOST.*', 'DB_HOST=localhost' -replace 'DB_PORT.*', 'DB_PORT=5432' | Set-Content $EnvFile
        }
    }
    Write-Success "PostgreSQL configuration applied"
} else {
    Write-Info "Using SQLite (default)"
}

# Run migrations
Write-Info "Running database migrations..."
if (-not $check) {
    & $VenvPython manage.py makemigrations
    & $VenvPython manage.py migrate
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to run migrations"
        exit 1
    }
}
Write-Success "Database migrations complete"

# Create superuser
if ($create_su) {
    Write-Info "Creating superuser..."
    if (-not $check) {
        & $VenvPython manage.py createsuperuser --username admin --email admin@hotel.com --noinput
        if ($LASTEXITCODE -ne 0) {
            Write-Warning "Superuser may already exist or creation failed"
        } else {
            Write-Success "Superuser created (username: admin)"
        }
    }
}

# Load seed data
Write-Info "Loading seed data..."
if (-not $check) {
    & $VenvPython seed_data.py
    if ($LASTEXITCODE -ne 0) {
        Write-Warning "Seed data loading failed or already loaded"
    }
}
Write-Success "Seed data loaded"

# Collect static files
if (-not $no_collectstatic) {
    Write-Info "Collecting static files..."
    if (-not $check) {
        & $VenvPython manage.py collectstatic --noinput
    }
    Write-Success "Static files collected"
} else {
    Write-Warning "Skipping static files collection"
}

Set-Location $ScriptDir

# Frontend Setup
Write-Output ""
Write-Info "========================================"
Write-Info "Frontend Setup"
Write-Info "========================================"

if ($NodeInstalled -and $NpmInstalled) {
    if (-not (Test-Path $FrontendDir)) {
        Write-Error "Frontend directory not found: $FrontendDir"
        exit 1
    }

    Set-Location $FrontendDir

    # Install dependencies
    if (-not $skip_deps) {
        Write-Info "Installing Node.js dependencies..."
        if (-not $check) {
            npm install
            if ($LASTEXITCODE -ne 0) {
                Write-Error "Failed to install Node.js dependencies"
                exit 1
            }
        }
        Write-Success "Node.js dependencies installed"
    } else {
        Write-Warning "Skipping Node.js dependency installation"
    }

    # Development dependencies
    if ($dev) {
        Write-Info "Installing development dependencies..."
        if (-not $check) {
            npm install --save-dev @types/react @types/react-dom
        }
        Write-Success "Development dependencies installed"
    }

    Set-Location $ScriptDir
} else {
    Write-Warning "Skipping frontend setup (Node.js/npm not available)"
}

# Final summary
Write-Output ""
Write-Info "========================================"
Write-Info "Setup Complete!"
Write-Info "========================================"
Write-Output ""
Write-Success "Backend: $BackendDir"
Write-Success "Frontend: $FrontendDir"
Write-Output ""
Write-Info "Configuration:"
Write-Output "  Database: $(if ($postgres) { 'PostgreSQL' } else { 'SQLite' })"
Write-Output "  Superuser: $(if ($create_su) { 'Created' } else { 'Not created' })"
Write-Output "  Dependencies: $(if ($skip_deps) { 'Skipped' } else { 'Installed' })"
Write-Output "  Static Files: $(if ($no_collectstatic) { 'Skipped' } else { 'Collected' })"
Write-Output ""
Write-Info "Next steps:"
Write-Output "  1. Run start script: .\start.ps1 [options]"
Write-Output "  2. Or start manually:"
Write-Output "     Backend: cd backend && venv\Scripts\python manage.py runserver"
Write-Output "     Frontend: cd frontend && npm run dev"
Write-Output ""
Write-Info "Demo credentials:"
Write-Output "  Admin: admin / admin123"
Write-Output "  Staff: staff / staff123"
Write-Output ""