#!/bin/bash

# Hotel Reservation System - Stop Script (Bash)
# Usage: ./stop.sh

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

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKEND_DIR="$SCRIPT_DIR/backend"
FRONTEND_DIR="$SCRIPT_DIR/frontend"

echo_info "========================================"
echo_info "Hotel Reservation System - Stop"
echo_info "========================================"
echo ""

# Stop Backend
echo_info "Stopping Backend..."
if [ -f "$BACKEND_DIR/backend.pid" ]; then
    BACKEND_PID=$(cat "$BACKEND_DIR/backend.pid")
    if ps -p "$BACKEND_PID" > /dev/null 2>&1; then
        kill "$BACKEND_PID"
        echo_success "Backend stopped (PID: $BACKEND_PID)"
    else
        echo_warning "Backend process not found (PID: $BACKEND_PID)"
    fi
    rm "$BACKEND_DIR/backend.pid"
else
    echo_info "No backend PID file found"
fi

# Also kill any Python processes running manage.py
pkill -f "python.*manage.py" 2>/dev/null || true
pkill -f "python.*runserver" 2>/dev/null || true

echo ""

# Stop Frontend
echo_info "Stopping Frontend..."
if [ -f "$FRONTEND_DIR/frontend.pid" ]; then
    FRONTEND_PID=$(cat "$FRONTEND_DIR/frontend.pid")
    if ps -p "$FRONTEND_PID" > /dev/null 2>&1; then
        kill "$FRONTEND_PID"
        echo_success "Frontend stopped (PID: $FRONTEND_PID)"
    else
        echo_warning "Frontend process not found (PID: $FRONTEND_PID)"
    fi
    rm "$FRONTEND_DIR/frontend.pid"
else
    echo_info "No frontend PID file found"
fi

# Also kill any Node processes running vite
pkill -f "node.*vite" 2>/dev/null || true
pkill -f "node.*npm.*dev" 2>/dev/null || true
pkill -f "npm.*run.*dev" 2>/dev/null || true

echo ""
echo_success "All services stopped"