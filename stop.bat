@echo off
REM Hotel Reservation System - Stop Script (Windows CMD)
REM Usage: stop.bat

setlocal enabledelayedexpansion

REM Get script directory
set SCRIPT_DIR=%~dp0
set BACKEND_DIR=%SCRIPT_DIR%backend
set FRONTEND_DIR=%SCRIPT_DIR%frontend

echo ========================================
echo Hotel Reservation System - Stop
echo ========================================
echo.

REM Stop Backend
echo Stopping Backend...
set BACKEND_PID_FILE=%BACKEND_DIR%backend.pid

if exist "%BACKEND_PID_FILE%" (
    set /p BACKEND_PID=<"%BACKEND_PID_FILE%"
    tasklist /FI "PID eq %BACKEND_PID%" 2>nul | findstr "%BACKEND_PID%" >nul
    if not errorlevel 1 (
        taskkill /F /PID %BACKEND_PID% >nul 2>&1
        echo [SUCCESS] Backend stopped (PID: %BACKEND_PID%)
    ) else (
        echo [WARNING] Backend process not found (may have already stopped)
    )
    del "%BACKEND_PID_FILE%" /f >nul 2>&1
) else (
    REM Try to find and kill Django processes
    echo [INFO] Checking for Django processes...
    for /f "tokens=2" %%A in ('tasklist /FI "IMAGENAME eq python.exe" ^| findstr "manage.py"') do (
        taskkill /F /PID %%A >nul 2>&1
        echo [SUCCESS] Backend stopped (PID: %%A)
    )
    if errorlevel 1 (
        echo [WARNING] No running backend process found
    )
)

REM Stop Frontend
echo.
echo Stopping Frontend...
set FRONTEND_PID_FILE=%FRONTEND_DIR%frontend.pid

if exist "%FRONTEND_PID_FILE%" (
    set /p FRONTEND_PID=<"%FRONTEND_PID_FILE%"
    tasklist /FI "PID eq %FRONTEND_PID%" 2>nul | findstr "%FRONTEND_PID%" >nul
    if not errorlevel 1 (
        taskkill /F /PID %FRONTEND_PID% >nul 2>&1
        echo [SUCCESS] Frontend stopped (PID: %FRONTEND_PID%)
    ) else (
        echo [WARNING] Frontend process not found (may have already stopped)
    )
    del "%FRONTEND_PID_FILE%" /f >nul 2>&1
) else (
    REM Try to find and kill Node/Vite processes
    echo [INFO] Checking for Node processes...
    for /f "tokens=2" %%A in ('tasklist /FI "IMAGENAME eq node.exe" ^| findstr "vite"') do (
        taskkill /F /PID %%A >nul 2>&1
        echo [SUCCESS] Frontend stopped (PID: %%A)
    )
    if errorlevel 1 (
        REM Try npm run dev processes
        for /f "tokens=2" %%A in ('tasklist /FI "IMAGENAME eq node.exe" ^| findstr "npm"') do (
            taskkill /F /PID %%A >nul 2>&1
            echo [SUCCESS] Frontend stopped (PID: %%A)
        )
        if errorlevel 1 (
            echo [WARNING] No running frontend process found
        )
    )
)

echo.
echo [SUCCESS] All services stopped
echo.

endlocal