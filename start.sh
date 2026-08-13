#!/bin/bash

# Hotel Reservation System - Start Script (Bash)
# Usage: ./start.sh [options]

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Functions
echo_success() {
    echo -e "${GREEN}$1${NC}"
}

echo_error() {
    echo -e "${RED}$1${NC}"
}

echo_warning() {
    echo -e "${YELLOW}$1${NC}"
}

echo_info() {
    echo -e "${CYAN}$1${NC}"
}

# Parse arguments
REMOTE=false
POSTGRES=false
BCK=false
MULTIPLE=false
BACKEND_PORT=8000
FRONTEND_PORT=3000
SEED_DATA=false
PURGE_DATA=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --remote)
            REMOTE=true
            shift
            ;;
        --postgres)
            POSTGRES=true
            shift
            ;;
        --bck)
            BCK=true
            shift
            ;;
        --multiple)
            MULTIPLE=true
            shift
            ;;
        --port)
            shift
            if [ -z "$1" ]; then
                echo_error "--port requires two arguments: backend_port frontend_port"
                cd "$ORIGINAL_DIR"
                exit 1
            fi
            BACKEND_PORT="$1"
            shift
            if [ -z "$1" ]; then
                echo_error "--port requires two arguments: backend_port frontend_port"
                cd "$ORIGINAL_DIR"
                exit 1
            fi
            FRONTEND_PORT="$1"
            shift
            ;;
        --seed-data)
            SEED_DATA=true
            shift
            ;;
        --purge-seed-data)
            PURGE_DATA=true
            shift
            ;;
        *)
            echo_error "Unknown option: $1"
            cd "$ORIGINAL_DIR"
            exit 1
            ;;
    esac
done

# Get script directory and save original directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ORIGINAL_DIR="$(pwd)"
BACKEND_DIR="$SCRIPT_DIR/backend"
FRONTEND_DIR="$SCRIPT_DIR/frontend"
VENV_PYTHON="$BACKEND_DIR/venv/bin/python"

# Get local IP address if remote mode
LOCAL_IP="localhost"
if [ "$REMOTE" = true ]; then
    # Try to get the local IP address
    LOCAL_IP=$(hostname -I 2>/dev/null | awk '{print $1}')
    if [ -z "$LOCAL_IP" ] || [ "$LOCAL_IP" = "127.0.0.1" ]; then
        # Fallback methods
        LOCAL_IP=$(ip route get 1 2>/dev/null | awk '{print $7}' | head -1)
        if [ -z "$LOCAL_IP" ]; then
            LOCAL_IP=$(ifconfig 2>/dev/null | grep "inet " | grep -v 127.0.0.1 | awk '{print $2}' | head -1)
        fi
        if [ -z "$LOCAL_IP" ]; then
            LOCAL_IP="0.0.0.0"
        fi
    fi
fi

echo_info "========================================"
echo_info "Hotel Reservation System - Start"
echo_info "========================================"
echo ""
echo_info "Configuration:"
echo "  Remote Mode: $([ "$REMOTE" = true ] && echo "Enabled (IP: $LOCAL_IP)" || echo "Disabled (localhost)")"
echo "  Database: $([ "$POSTGRES" = true ] && echo "PostgreSQL" || echo "SQLite")"
echo "  Background: $([ "$BCK" = true ] && echo "Enabled" || echo "Disabled")"
echo "  Multiple Instances: $([ "$MULTIPLE" = true ] && echo "Enabled" || echo "Disabled")"
echo "  Backend Port: $BACKEND_PORT"
echo "  Frontend Port: $FRONTEND_PORT"
echo ""

# Kill all existing Python and Node processes (skip if --multiple is used)
if [ "$MULTIPLE" = false ]; then
    echo_info "========================================"
    echo_info "Cleaning up existing processes"
    echo_info "========================================"

    echo_info "Killing existing Python processes..."
    pkill -f "python.*manage.py" 2>/dev/null || true
    pkill -f "python.*runserver" 2>/dev/null || true
    if [ $? -eq 0 ]; then
        echo_success "Python processes killed"
    else
        echo_info "No existing Python processes found"
    fi

    echo_info "Killing existing Node processes..."
    pkill -f "node.*vite" 2>/dev/null || true
    pkill -f "node.*npm.*dev" 2>/dev/null || true
    pkill -f "npm.*run.*dev" 2>/dev/null || true
    if [ $? -eq 0 ]; then
        echo_success "Node processes killed"
    else
        echo_info "No existing Node processes found"
    fi

    # Wait for processes to terminate
    sleep 2

    # Check and free ports
    echo_info "Checking port availability..."
    if lsof -Pi :8000 -sTCP:LISTEN -t >/dev/null 2>&1; then
        echo_warning "Port 8000 is in use, attempting to free it..."
        lsof -ti:8000 -sTCP:LISTEN | xargs kill -9 2>/dev/null || true
        sleep 1
    fi

    if lsof -Pi :3000 -sTCP:LISTEN -t >/dev/null 2>&1; then
        echo_warning "Port 3000 is in use, attempting to free it..."
        lsof -ti:3000 -sTCP:LISTEN | xargs kill -9 2>/dev/null || true
        sleep 1
    fi

    echo_success "Ports 8000 and 3000 are available"
    echo ""
else
    echo_info "========================================"
    echo_info "Multiple Instances Mode"
    echo_info "========================================"
    echo_info "Skipping process cleanup - allowing multiple instances"
    echo_info "Backend will use port $BACKEND_PORT"
    echo_info "Frontend will use port $FRONTEND_PORT"
    echo ""
fi

# Configure database if needed
if [ "$POSTGRES" = true ]; then
    echo_info "Configuring for PostgreSQL..."
    ENV_FILE="$BACKEND_DIR/.env"
    if [ -f "$ENV_FILE" ]; then
        sed -i.bak 's/DB_NAME=.*/DB_NAME=hotel_reservation/' "$ENV_FILE"
        sed -i.bak 's/DB_USER=.*/DB_USER=postgres/' "$ENV_FILE"
        sed -i.bak 's/DB_PASSWORD=.*/DB_PASSWORD=postgres/' "$ENV_FILE"
        sed -i.bak 's/DB_HOST=.*/DB_HOST=localhost/' "$ENV_FILE"
        sed -i.bak 's/DB_PORT=.*/DB_PORT=5432/' "$ENV_FILE"
    fi
    echo_success "PostgreSQL configured"
fi

# Configure frontend API URL if custom ports are used
if [ "$BACKEND_PORT" != "8000" ]; then
    echo_info "Configuring frontend API URL for custom port..."
    FRONTEND_ENV="$FRONTEND_DIR/.env"
    if [ -f "$FRONTEND_ENV" ]; then
        # Remove the old line and add the new one
        sed -i.bak '/VITE_API_URL=/d' "$FRONTEND_ENV"
        echo "VITE_API_URL=http://localhost:$BACKEND_PORT/api" >> "$FRONTEND_ENV"
    fi
    echo_success "Frontend API URL configured"
fi

# Start Backend
echo_info "========================================"
echo_info "Starting Backend"
echo_info "========================================"

if [ ! -f "$VENV_PYTHON" ]; then
    echo_error "Virtual environment not found. Run setup.sh first."
    cd "$ORIGINAL_DIR"
    exit 1
fi

cd "$BACKEND_DIR"

# Determine host and port
BACKEND_HOST=$([ "$REMOTE" = true ] && echo "0.0.0.0" || echo "127.0.0.1")

echo_info "Backend URL: http://$LOCAL_IP:$BACKEND_PORT/api"

if [ "$BCK" = true ]; then
    echo_info "Starting backend in background..."
    BACKEND_LOG="$BACKEND_DIR/backend.log"
    BACKEND_PID_FILE="$BACKEND_DIR/backend.pid"
    
    # Start in background using nohup
    nohup "$VENV_PYTHON" manage.py runserver "$BACKEND_HOST:$BACKEND_PORT" > "$BACKEND_LOG" 2>&1 &
    BACKEND_PID=$!
    echo $BACKEND_PID > "$BACKEND_PID_FILE"
    
    echo_success "Backend started in background (PID: $BACKEND_PID)"
    echo_info "Logs: $BACKEND_LOG"
else
    echo_info "Starting backend in foreground..."
    echo_warning "Press Ctrl+C to stop the server"
    echo ""
    
    "$VENV_PYTHON" manage.py runserver "$BACKEND_HOST:$BACKEND_PORT"
    
    # Return to original directory after stopping
    cd "$ORIGINAL_DIR"
fi

# Load sample data if requested
if [ "$SEED_DATA" = true ]; then
    echo ""
    echo_info "========================================"
    echo_info "Loading Sample Data"
    echo_info "========================================"
    echo_info "Loading sample data (50 customers, 80 rooms, 3 months of reservations)..."
    cd "$BACKEND_DIR"
    "$VENV_PYTHON" seed_data.py --sample
    if [ $? -eq 0 ]; then
        echo_success "Sample data loaded"
    else
        echo_warning "Sample data loading failed"
    fi
    cd "$ORIGINAL_DIR"
fi

# Purge sample data if requested
if [ "$PURGE_DATA" = true ]; then
    echo ""
    echo_info "========================================"
    echo_info "Purging Sample Data"
    echo_info "========================================"
    echo_info "Purging sample data (customers, rooms, reservations)..."
    cd "$BACKEND_DIR"
    "$VENV_PYTHON" seed_data.py --purge
    if [ $? -eq 0 ]; then
        echo_success "Sample data purged"
    else
        echo_warning "Sample data purging failed"
    fi
    cd "$ORIGINAL_DIR"
fi

# Start Frontend (only if not in background mode or if background mode with separate handling)
if [ "$BCK" = false ]; then
    echo ""
    echo_info "========================================"
    echo_info "Starting Frontend"
    echo_info "========================================"
    
    if [ ! -d "$FRONTEND_DIR" ]; then
        echo_error "Frontend directory not found"
        cd "$ORIGINAL_DIR"
        exit 1
    fi
    
    cd "$FRONTEND_DIR"
    
    # Check if node_modules exists
    if [ ! -d "node_modules" ]; then
        echo_warning "node_modules not found. Running npm install..."
        npm install
    fi
    
    # Determine host and port
    FRONTEND_HOST=$([ "$REMOTE" = true ] && echo "0.0.0.0" || echo "localhost")
    
    echo_info "Frontend URL: http://$LOCAL_IP:$FRONTEND_PORT"
    echo ""
    
    # Update vite config for remote access
    if [ "$REMOTE" = true ]; then
        VITE_CONFIG="$FRONTEND_DIR/vite.config.ts"
        if [ -f "$VITE_CONFIG" ]; then
            echo_info "Configuring Vite for remote access..."
            sed -i.bak "s/host: 'localhost'/host: '0.0.0.0'/g" "$VITE_CONFIG"
        fi
    fi
    
    echo_info "Starting frontend..."
    echo_warning "Press Ctrl+C to stop the server"
    echo ""
    
    npm run dev
    
    # Return to original directory after stopping
    cd "$ORIGINAL_DIR"
else
    echo ""
    echo_info "========================================"
    echo_info "Starting Frontend (Background)"
    echo_info "========================================"
    
    if [ ! -d "$FRONTEND_DIR" ]; then
        echo_error "Frontend directory not found"
        cd "$ORIGINAL_DIR"
        exit 1
    fi
    
    cd "$FRONTEND_DIR"
    
    # Check if node_modules exists
    if [ ! -d "node_modules" ]; then
        echo_warning "node_modules not found. Running npm install..."
        npm install
    fi
    
    # Determine host and port
    FRONTEND_HOST=$([ "$REMOTE" = true ] && echo "0.0.0.0" || echo "localhost")
    
    echo_info "Frontend URL: http://$LOCAL_IP:$FRONTEND_PORT"
    
    # Update vite config for remote access
    if [ "$REMOTE" = true ]; then
        VITE_CONFIG="$FRONTEND_DIR/vite.config.ts"
        if [ -f "$VITE_CONFIG" ]; then
            echo_info "Configuring Vite for remote access..."
            sed -i.bak "s/host: 'localhost'/host: '0.0.0.0'/g" "$VITE_CONFIG"
        fi
    fi
    
    echo_info "Starting frontend in background..."
    FRONTEND_LOG="$FRONTEND_DIR/frontend.log"
    FRONTEND_PID_FILE="$FRONTEND_DIR/frontend.pid"
    
    # Start in background using nohup
    nohup npm run dev > "$FRONTEND_LOG" 2>&1 &
    FRONTEND_PID=$!
    echo $FRONTEND_PID > "$FRONTEND_PID_FILE"
    
    echo_success "Frontend started in background (PID: $FRONTEND_PID)"
    echo_info "Logs: $FRONTEND_LOG"
    
    # Return to original directory
    cd "$ORIGINAL_DIR"
fi

# Final summary
echo ""
echo_info "========================================"
echo_info "Services Started"
echo_info "========================================"
echo ""
echo_success "Backend API: http://$LOCAL_IP:$BACKEND_PORT/api"
echo_success "Frontend UI: http://$LOCAL_IP:$FRONTEND_PORT"
echo ""
echo_info "Demo credentials:"
echo "  Admin: admin / admin123"
echo "  Staff: staff / staff123"
echo ""

if [ "$BCK" = true ]; then
    echo_info "To stop services:"
    echo "  Run: ./stop.sh"
    echo "  Or manually kill processes using the PIDs"
    echo ""
fi

# Ensure we return to original directory
cd "$ORIGINAL_DIR"