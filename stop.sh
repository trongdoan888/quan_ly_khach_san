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

# Get script directory and save original directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ORIGINAL_DIR="$(pwd)"
BACKEND_DIR="$SCRIPT_DIR/backend"
FRONTEND_DIR="$SCRIPT_DIR/frontend"

echo_info "========================================"
echo_info "Hotel Reservation System - Stop"
echo_info "========================================"
echo ""

# Stop Backend
echo_info "Stopping Backend..."
BACKEND_PID_FILE="$BACKEND_DIR/backend.pid"

if [ -f "$BACKEND_PID_FILE" ]; then
    BACKEND_PID=$(cat "$BACKEND_PID_FILE")
    if kill -0 "$BACKEND_PID" 2>/dev/null; then
        kill "$BACKEND_PID"
        echo_success "Backend stopped (PID: $BACKEND_PID)"
    else
        echo_warning "Backend process not found (may have already stopped)"
    fi
    rm -f "$BACKEND_PID_FILE"
else
    # Try to find and kill Django processes
    DJANGO_PIDS=$(pgrep -f "python.*manage.py" 2>/dev/null)
    if [ -n "$DJANGO_PIDS" ]; then
        echo "$DJANGO_PIDS" | while read pid; do
            kill "$pid" 2>/dev/null
            echo_success "Backend stopped (PID: $pid)"
        done
    else
        DJANGO_PIDS=$(pgrep -f "python.*runserver" 2>/dev/null)
        if [ -n "$DJANGO_PIDS" ]; then
            echo "$DJANGO_PIDS" | while read pid; do
                kill "$pid" 2>/dev/null
                echo_success "Backend stopped (PID: $pid)"
            done
        else
            echo_warning "No running backend process found"
        fi
    fi
fi

# Stop Frontend
echo ""
echo_info "Stopping Frontend..."
FRONTEND_PID_FILE="$FRONTEND_DIR/frontend.pid"

if [ -f "$FRONTEND_PID_FILE" ]; then
    FRONTEND_PID=$(cat "$FRONTEND_PID_FILE")
    if kill -0 "$FRONTEND_PID" 2>/dev/null; then
        kill "$FRONTEND_PID"
        echo_success "Frontend stopped (PID: $FRONTEND_PID)"
    else
        echo_warning "Frontend process not found (may have already stopped)"
    fi
    rm -f "$FRONTEND_PID_FILE"
else
    # Try to find and kill Node/Vite processes
    NODE_PIDS=$(pgrep -f "node.*vite" 2>/dev/null)
    if [ -n "$NODE_PIDS" ]; then
        echo "$NODE_PIDS" | while read pid; do
            kill "$pid" 2>/dev/null
            echo_success "Frontend stopped (PID: $pid)"
        done
    else
        # Try npm run dev processes
        NPM_PIDS=$(pgrep -f "npm.*run.*dev" 2>/dev/null)
        if [ -n "$NPM_PIDS" ]; then
            echo "$NPM_PIDS" | while read pid; do
                kill "$pid" 2>/dev/null
                echo_success "Frontend stopped (PID: $pid)"
            done
        else
            echo_warning "No running frontend process found"
        fi
    fi
fi

echo ""
echo_success "All services stopped"
echo ""

# Return to original directory
cd "$ORIGINAL_DIR"