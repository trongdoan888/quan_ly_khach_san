@echo off
REM Simple script to run seed data
REM Works in both CMD and PowerShell

echo ========================================
echo Hotel Reservation System - Seed Data
echo ========================================
echo.

cd /d "%~dp0backend"

echo Running seed data generation...
echo This will create:
echo   - 50 customers
echo   - 80 rooms (4 floors x 20 rooms)
echo   - 3 months of reservations
echo.

python seed_data.py --sample

if errorlevel 1 (
    echo.
    echo [ERROR] Seed data generation failed
    echo.
    pause
    exit /b 1
)

echo.
echo ========================================
echo Seed Data Generation Complete!
echo ========================================
echo.
echo You can now start the application with:
echo   start.bat
echo.
pause
