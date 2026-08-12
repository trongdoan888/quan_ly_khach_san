# Setup and Start Scripts Documentation

## Overview

The Hotel Reservation System includes automated setup and start scripts for Windows (CMD) and Linux/macOS (Bash). These scripts simplify the installation and running process. The start scripts automatically clean up existing processes before starting new instances.

## Scripts Available

### Setup Scripts
- `setup.bat` - Windows CMD setup script
- `setup.sh` - Linux/macOS Bash setup script

### Start Scripts
- `start.bat` - Windows CMD start script
- `start.sh` - Linux/macOS Bash start script

## Key Features

### Process Cleanup
All start scripts automatically:
- Kill existing Python processes before starting backend
- Kill existing Node processes before starting frontend
- Free ports 8000 and 3000 if they're in use
- Ensure clean startup without port conflicts

### Directory Management
All scripts ensure they:
- Return to the original directory after execution
- Maintain the user's working directory context
- Handle directory changes safely

### Platform Support
- **Windows CMD**: Native batch scripts for Windows Command Prompt
- **Linux/macOS Bash**: Unix shell scripts with full POSIX compliance

### Execute Permissions
For Linux/macOS users, scripts must be made executable:
```bash
chmod +x setup.sh start.sh
```

The scripts are created with execute permissions in the repository, but users may need to set them manually depending on their system configuration.

## Setup Script Parameters (Windows CMD & Unix)

All scripts support the same parameters across platforms.
Configures the system to use PostgreSQL instead of SQLite.

**Usage:**
```cmd
setup.bat --postgres
```

**What it does:**
- Updates `.env` file with PostgreSQL configuration
- Sets DB_NAME, DB_USER, DB_PASSWORD, DB_HOST, DB_PORT
- Configures Django to use PostgreSQL backend

### --create-su
Creates a Django superuser account.

**Usage:**
```cmd
setup.bat --create-su
```

**What it does:**
- Creates superuser with username `admin` and password `admin123`
- Email set to `admin@hotel.com`
- Skips if superuser already exists

### --skip-deps
Skips Python and Node.js dependency installation.

**Usage:**
```cmd
setup.bat --skip-deps
```

**What it does:**
- Skips `pip install -r requirements.txt`
- Skips `npm install`
- Useful when dependencies are already installed

### --force
Force recreate the virtual environment.

**Usage:**
```cmd
setup.bat --force
```

**What it does:**
- Removes existing virtual environment
- Creates fresh virtual environment
- Reinstalls all dependencies

### --no-collectstatic
Skips Django static files collection.

**Usage:**
```cmd
setup.bat --no-collectstatic
```

**What it does:**
- Skips `python manage.py collectstatic`
- Useful for development where static files aren't needed

### --dev
Install development dependencies.

**Usage:**
```cmd
setup.bat --dev
```

**What it does:**
- Installs additional development packages
- For frontend: `@types/react`, `@types/react-dom`

### --check
Check if everything is installed without making changes.

**Usage:**
```cmd
setup.bat --check
```

**What it does:**
- Validates prerequisites (Python, pip, Node, npm)
- Checks virtual environment existence
- Checks directory structure
- Reports status without making any changes

### Combined Options
All options can be combined:

```cmd
REM Full setup with PostgreSQL and superuser
setup.bat --postgres --create-su

REM Development setup with all options
setup.bat --postgres --create-su --dev --force

REM Quick check
setup.bat --check
```

## Start Script Parameters

### --multiple
Allow multiple instances of the application to run simultaneously without killing existing processes.

**Usage:**
```cmd
start.bat --multiple
```

**What it does:**
- Skips process cleanup (Python and Node processes)
- Allows multiple instances to run on different ports
- Must be used with --port to specify custom ports
- Useful for development with multiple projects

### --port
Specify custom ports for backend and frontend (in this order: backend_port frontend_port).

**Usage:**
```cmd
start.bat --port 8001 3001
```

**What it does:**
- Sets backend port to first argument (8001)
- Sets frontend port to second argument (3001)
- Must be used with --multiple to avoid port conflicts
- Allows running multiple instances on different ports

**Examples:**
```cmd
# Run on custom ports with multiple instances
start.bat --multiple --port 8001 3001

# Run on custom ports with remote access
start.bat --remote --port 8002 3002
```

### --remote
Bind to 0.0.0.0 for external access using actual IP address.

**Usage:**
```cmd
start.bat --remote
```

**What it does:**
- Automatically detects local IP address
- Binds backend to `0.0.0.0:8000`
- Binds frontend to `0.0.0.0:3000`
- Updates Vite config for remote access
- Displays URLs with actual IP instead of localhost

**Example Output:**
```
Configuration:
  Remote Mode: Enabled (IP: 192.168.1.100)
  Database: SQLite
  Background: Disabled

Backend API: http://192.168.1.100:8000/api
Frontend UI: http://192.168.1.100:3000
```

### --postgres
Use PostgreSQL instead of SQLite.

**Usage:**
```cmd
start.bat --postgres
```

**What it does:**
- Updates `.env` file with PostgreSQL configuration
- Ensures Django is configured to use PostgreSQL

### --bck
Run services in background with nohup.

**Usage:**
```cmd
start.bat --bck
```

**What it does:**
- Starts backend in background using nohup/Start-Process
- Starts frontend in background using nohup/Start-Process
- Saves process IDs to PID files
- Writes logs to `backend.log` and `frontend.log`
- Allows terminal to be closed while services run
- Note: Running start script again will automatically kill existing processes

### Combined Options
All options can be combined:

```cmd
REM Remote access with PostgreSQL in background
start.bat --remote --postgres --bck

REM Local development with PostgreSQL
start.bat --postgres

REM Remote access in background
start.bat --remote --bck

REM Multiple instances with custom ports
start.bat --multiple --port 8001 3001

REM Remote access with custom ports
start.bat --remote --port 8002 3002
```

## Platform-Specific Notes

### Windows (CMD)
- Scripts use Windows CMD batch syntax
- Virtual environment activation: `venv\Scripts\activate`
- Process management: `taskkill`, `tasklist`
- IP detection: Uses PowerShell command from CMD
- Directory management: Uses `cd /d` for drive changes

### Linux/macOS (Bash)
- Scripts use Bash syntax
- Must make scripts executable: `chmod +x *.sh`
- Virtual environment activation: `source venv/bin/activate`
- Process management: `nohup`, `pgrep`, `kill`
- IP detection: Uses `hostname -I`, `ip route`, `ifconfig`

## Common Workflows

### Initial Setup
```cmd
REM Windows
setup.bat --postgres --create-su
```

```bash
# Linux/macOS
./setup.sh --postgres --create-su
```

### Development
```cmd
REM Windows
start.bat
```

```bash
# Linux/macOS
./start.sh
```

### Production with Remote Access
```cmd
REM Windows
start.bat --remote --postgres --bck
```

```bash
# Linux/macOS
./start.sh --remote --postgres --bck
```

### Troubleshooting
```cmd
REM Check setup without changes
setup.bat --check

REM Force recreate everything
setup.bat --force --postgres --create-su
```

## File Locations

### Backend
- Virtual environment: `backend/venv/`
- Environment file: `backend/.env`
- Log files: `backend/backend.log`
- PID file: `backend/backend.pid`

### Frontend
- Node modules: `frontend/node_modules/`
- Environment file: `frontend/.env`
- Log files: `frontend/frontend.log`
- PID file: `frontend/frontend.pid`

## Error Handling

The scripts include comprehensive error handling:

- **Prerequisites check**: Validates Python, pip, Node, npm are installed
- **Directory validation**: Ensures backend/frontend directories exist
- **Process management**: Handles existing processes gracefully
- **Configuration**: Validates and updates configuration files
- **Dependency installation**: Reports and handles installation failures

## Security Considerations

- **Environment variables**: `.env` files are never committed
- **Passwords**: Demo passwords are for development only
- **Remote access**: Use firewall rules to restrict access
- **Background processes**: Logs may contain sensitive information

## Troubleshooting

### Port Already in Use
If you get "port already in use" errors:
1. The start script automatically kills existing processes
2. Check for other processes using the ports
3. Kill conflicting processes manually

### Virtual Environment Issues
If you encounter virtual environment problems:
1. Run setup with `--force` flag
2. This will recreate the virtual environment

### IP Detection Issues
If remote mode doesn't detect the correct IP:
1. Manually set the IP in your hosts file
2. Use `0.0.0.0` directly in browser
3. Check your network configuration

### Permission Issues (Linux/macOS)
If you get permission errors:
1. Make scripts executable: `chmod +x *.sh`
2. Check file permissions: `ls -la *.sh`
3. Run with sudo if necessary (not recommended)

## Support

For issues with the scripts:
1. Check the error messages carefully
2. Run with `--check` flag to diagnose issues
3. Review the manual setup instructions in README.md
4. Check log files in backend/ and frontend/ directories
