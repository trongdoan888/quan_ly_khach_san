# Hotel Reservation System - Stop Script (PowerShell)
# Usage: .\stop.ps1

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
Write-Info "Hotel Reservation System - Stop"
Write-Info "========================================"
Write-Output ""

# Stop Backend
Write-Info "Stopping Backend..."
$BackendPidFile = Join-Path $BackendDir "backend.pid"

if (Test-Path $BackendPidFile) {
    $BackendPid = Get-Content $BackendPidFile
    try {
        $Process = Get-Process -Id $BackendPid -ErrorAction Stop
        if ($Process) {
            Stop-Process -Id $BackendPid -Force
            Write-Success "Backend stopped (PID: $BackendPid)"
        }
    } catch {
        Write-Warning "Backend process not found (may have already stopped)"
    }
    Remove-Item $BackendPidFile -Force
} else {
    # Try to find and kill Django processes
    $DjangoProcesses = Get-Process -Name "python" -ErrorAction SilentlyContinue | Where-Object { 
        $_.CommandLine -like "*manage.py runserver*" 
    }
    
    if ($DjangoProcesses) {
        foreach ($Process in $DjangoProcesses) {
            Stop-Process -Id $Process.Id -Force
            Write-Success "Backend stopped (PID: $($Process.Id))"
        }
    } else {
        Write-Warning "No running backend process found"
    }
}

# Stop Frontend
Write-Output ""
Write-Info "Stopping Frontend..."
$FrontendPidFile = Join-Path $FrontendDir "frontend.pid"

if (Test-Path $FrontendPidFile) {
    $FrontendPid = Get-Content $FrontendPidFile
    try {
        $Process = Get-Process -Id $FrontendPid -ErrorAction Stop
        if ($Process) {
            Stop-Process -Id $FrontendPid -Force
            Write-Success "Frontend stopped (PID: $FrontendPid)"
        }
    } catch {
        Write-Warning "Frontend process not found (may have already stopped)"
    }
    Remove-Item $FrontendPidFile -Force
} else {
    # Try to find and kill Node/Vite processes
    $NodeProcesses = Get-Process -Name "node" -ErrorAction SilentlyContinue | Where-Object { 
        $_.CommandLine -like "*vite*" -or $_.CommandLine -like "*npm run dev*" 
    }
    
    if ($NodeProcesses) {
        foreach ($Process in $NodeProcesses) {
            Stop-Process -Id $Process.Id -Force
            Write-Success "Frontend stopped (PID: $($Process.Id))"
        }
    } else {
        Write-Warning "No running frontend process found"
    }
}

Write-Output ""
Write-Success "All services stopped"
Write-Output ""