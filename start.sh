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
        *)
            echo_error "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
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
echo ""

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

# Start Backend
echo_info "========================================"
echo_info "Starting Backend"
echo_info "========================================"

if [ ! -f "$VENV_PYTHON" ]; then
    echo_error "Virtual environment not found. Run setup.sh first."
    exit 1
fi

cd "$BACKEND_DIR"

# Determine host and port
BACKEND_HOST=$([ "$REMOTE" = true ] && echo "0.0.0.0" || echo "127.0.0.1")
BACKEND_PORT=8000

echo_info "Backend URL: http://$LOCAL_IP:$BACKEND_PORT/api"

if [ "$BCK" = true ]; then
    echo_info "Starting backend in background..."
    BACKEND_LOG="$BACKEND_DIR/backend.log"
    BACKEND_PID_FILE="$BACKEND_DIR/backend.pid"
    
    # Kill existing processes
    pkill -f "manage.py runserver" 2>/dev/null || true
    
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
fi

# Start Frontend (only if not in background mode or if background mode with separate handling)
if [ "$BCK" = false ]; then
    echo ""
    echo_info "========================================"
    echo_info "Starting Frontend"
    echo_info "========================================"
    
    if [ ! -d "$FRONTEND_DIR" ]; then
        echo_error "Frontend directory not found"
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
    FRONTEND_PORT=3000
    
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
else
    echo ""
    echo_info "========================================"
    echo_info "Starting Frontend (Background)"
    echo_info "========================================"
    
    if [ ! -d "$FRONTEND_DIR" ]; then
        echo_error "Frontend directory not found"
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
    FRONTEND_PORT=3000
    
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
    
    # Kill existing processes
    pkill -f "vite" 2>/dev/null || true
    pkill -f "npm run dev" 2>/dev/null || true
    
    # Start in background using nohup
    nohup npm run dev > "$FRONTEND_LOG" 2>&1 &
    FRONTEND_PID=$!
    echo $FRONTEND_PID > "$FRONTEND_PID_FILE"
    
    echo_success "Frontend started in background (PID: $FRONTEND_PID)"
    echo_info "Logs: $FRONTEND_LOG"
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