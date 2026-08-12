# Hotel Reservation System - Start Script (PowerShell)
# Usage: .\start.ps1 [options]

param(
    [switch]$remote,
    [switch]$postgres,
    [switch]$bck
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
$VenvPython = Join-Path $BackendDir "venv\Scripts\python.exe"

# Get local IP address if remote mode
$LocalIP = "localhost"
if ($remote) {
    try {
        $LocalIP = (Get-NetIPAddress -AddressFamily IPv4 -InterfaceAlias "Wi*","Eth*" | 
                   Where-Object { $_.IPAddress -notlike "127.*" -and $_.IPAddress -notlike "169.*" } | 
                   Select-Object -First 1 -ExpandProperty IPAddress)
        if (-not $LocalIP) {
            $LocalIP = "0.0.0.0"
        }
    } catch {
        $LocalIP = "0.0.0.0"
    }
}

Write-Info "========================================"
Write-Info "Hotel Reservation System - Start"
Write-Info "========================================"
Write-Output ""
Write-Info "Configuration:"
Write-Output "  Remote Mode: $(if ($remote) { 'Enabled (IP: $LocalIP)' } else { 'Disabled (localhost)' })"
Write-Output "  Database: $(if ($postgres) { 'PostgreSQL' } else { 'SQLite' })"
Write-Output "  Background: $(if ($bck) { 'Enabled' } else { 'Disabled' })"
Write-Output ""

# Configure database if needed
if ($postgres) {
    Write-Info "Configuring for PostgreSQL..."
    $EnvFile = Join-Path $BackendDir ".env"
    if (Test-Path $EnvFile) {
        (Get-Content $EnvFile) -replace 'DB_NAME=.*', 'DB_NAME=hotel_reservation' -replace 'DB_USER=.*', 'DB_USER=postgres' -replace 'DB_PASSWORD=.*', 'DB_PASSWORD=postgres' -replace 'DB_HOST=.*', 'DB_HOST=localhost' -replace 'DB_PORT=.*', 'DB_PORT=5432' | Set-Content $EnvFile
    }
    Write-Success "PostgreSQL configured"
}

# Start Backend
Write-Info "========================================"
Write-Info "Starting Backend"
Write-Info "========================================"

if (-not (Test-Path $VenvPython)) {
    Write-Error "Virtual environment not found. Run setup.ps1 first."
    exit 1
}

Set-Location $BackendDir

# Determine host and port
$BackendHost = if ($remote) { "0.0.0.0" } else { "127.0.0.1" }
$BackendPort = 8000

Write-Info "Backend URL: http://$LocalIP:$BackendPort/api"

if ($bck) {
    Write-Info "Starting backend in background..."
    $BackendLog = Join-Path $BackendDir "backend.log"
    
    # Kill existing processes
    Get-Process -Name "python" -ErrorAction SilentlyContinue | Where-Object { 
        $_.Path -like "*venv*" 
    } | Stop-Process -Force -ErrorAction SilentlyContinue
    
    # Start in background
    $ProcessInfo = New-Object System.Diagnostics.ProcessStartInfo
    $ProcessInfo.FileName = $VenvPython
    $ProcessInfo.Arguments = "manage.py runserver $BackendHost:$BackendPort"
    $ProcessInfo.UseShellExecute = $false
    $ProcessInfo.RedirectStandardOutput = $true
    $ProcessInfo.RedirectStandardError = $true
    $ProcessInfo.CreateNoWindow = $true
    
    $BackendProcess = New-Object System.Diagnostics.Process
    $BackendProcess.StartInfo = $ProcessInfo
    $BackendProcess.Start() | Out-Null
    
    # Save PID for later cleanup
    $BackendProcess.Id | Out-File -FilePath (Join-Path $BackendDir "backend.pid")
    
    Write-Success "Backend started in background (PID: $($BackendProcess.Id))"
    Write-Info "Logs: $BackendLog"
} else {
    Write-Info "Starting backend in foreground..."
    Write-Warning "Press Ctrl+C to stop the server"
    Write-Output ""
    
    try {
        & $VenvPython manage.py runserver $BackendHost:$BackendPort
    } finally {
        Write-Warning "Backend stopped"
    }
}

# Start Frontend (only if not in background mode or if background mode with separate handling)
if (-not $bck) {
    Write-Output ""
    Write-Info "========================================"
    Write-Info "Starting Frontend"
    Write-Info "========================================"
    
    if (-not (Test-Path $FrontendDir)) {
        Write-Error "Frontend directory not found"
        exit 1
    }
    
    Set-Location $FrontendDir
    
    # Check if node_modules exists
    if (-not (Test-Path "node_modules")) {
        Write-Warning "node_modules not found. Running npm install..."
        npm install
    }
    
    # Determine host and port
    $FrontendHost = if ($remote) { "0.0.0.0" } else { "localhost"
    $FrontendPort = 3000
    
    Write-Info "Frontend URL: http://$LocalIP:$FrontendPort"
    Write-Output ""
    
    # Update vite config for remote access
    if ($remote) {
        $ViteConfig = Join-Path $FrontendDir "vite.config.ts"
        if (Test-Path $ViteConfig) {
            Write-Info "Configuring Vite for remote access..."
            (Get-Content $ViteConfig) -replace "host: 'localhost'", "host: '0.0.0.0'" | Set-Content $ViteConfig
        }
    }
    
    Write-Info "Starting frontend..."
    Write-Warning "Press Ctrl+C to stop the server"
    Write-Output ""
    
    try {
        npm run dev
    } finally {
        Write-Warning "Frontend stopped"
    }
} else {
    Write-Output ""
    Write-Info "========================================"
    Write-Info "Starting Frontend (Background)"
    Write-Info "========================================"
    
    if (-not (Test-Path $FrontendDir)) {
        Write-Error "Frontend directory not found"
        exit 1
    }
    
    Set-Location $FrontendDir
    
    # Check if node_modules exists
    if (-not (Test-Path "node_modules")) {
        Write-Warning "node_modules not found. Running npm install..."
        npm install
    }
    
    # Determine host and port
    $FrontendHost = if ($remote) { "0.0.0.0" } else { "localhost"
    $FrontendPort = 3000
    
    Write-Info "Frontend URL: http://$LocalIP:$FrontendPort"
    
    # Update vite config for remote access
    if ($remote) {
        $ViteConfig = Join-Path $FrontendDir "vite.config.ts"
        if (Test-Path $ViteConfig) {
            Write-Info "Configuring Vite for remote access..."
            (Get-Content $ViteConfig) -replace "host: 'localhost'", "host: '0.0.0.0'" | Set-Content $ViteConfig
        }
    }
    
    Write-Info "Starting frontend in background..."
    $FrontendLog = Join-Path $FrontendDir "frontend.log"
    
    # Kill existing processes
    Get-Process -Name "node" -ErrorAction SilentlyContinue | Where-Object { 
        $_.Path -like "*node*" 
    } | Stop-Process -Force -ErrorAction SilentlyContinue
    
    # Start in background using Start-Process
    $FrontendProcess = Start-Process -FilePath "npm" -ArgumentList "run", "dev" -NoNewWindow -PassThru -RedirectStandardOutput $FrontendLog -RedirectStandardError $FrontendLog
    
    # Save PID for later cleanup
    $FrontendProcess.Id | Out-File -FilePath (Join-Path $FrontendDir "frontend.pid")
    
    Write-Success "Frontend started in background (PID: $($FrontendProcess.Id))"
    Write-Info "Logs: $FrontendLog"
}

# Final summary
Write-Output ""
Write-Info "========================================"
Write-Info "Services Started"
Write-Info "========================================"
Write-Output ""
Write-Success "Backend API: http://$LocalIP:$BackendPort/api"
Write-Success "Frontend UI: http://$LocalIP:$FrontendPort"
Write-Output ""
Write-Info "Demo credentials:"
Write-Output "  Admin: admin / admin123"
Write-Output "  Staff: staff / staff123"
Write-Output ""

if ($bck) {
    Write-Info "To stop services:"
    Write-Output "  Run: .\stop.ps1"
    Write-Output "  Or manually kill processes using the PIDs"
    Write-Output ""
}