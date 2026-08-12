#!/bin/bash

# Hotel Reservation System - Setup Script (Bash)
# Usage: ./setup.sh [options]

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
POSTGRES=false
CREATE_SU=false
SKIP_DEPS=false
FORCE=false
NO_COLLECTSTATIC=false
DEV=false
CHECK=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --postgres)
            POSTGRES=true
            shift
            ;;
        --create-su)
            CREATE_SU=true
            shift
            ;;
        --skip-deps)
            SKIP_DEPS=true
            shift
            ;;
        --force)
            FORCE=true
            shift
            ;;
        --no-collectstatic)
            NO_COLLECTSTATIC=true
            shift
            ;;
        --dev)
            DEV=true
            shift
            ;;
        --check)
            CHECK=true
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

echo_info "========================================"
echo_info "Hotel Reservation System - Setup"
echo_info "========================================"
echo ""

# Check mode
if [ "$CHECK" = true ]; then
    echo_info "Running in CHECK mode - no changes will be made"
    echo ""
fi

# Check prerequisites
echo_info "Checking prerequisites..."

if ! command -v python3 &> /dev/null; then
    echo_error "Python 3 is not installed or not in PATH"
    exit 1
fi

if ! command -v pip3 &> /dev/null && ! command -v pip &> /dev/null; then
    echo_error "pip is not installed or not in PATH"
    exit 1
fi

if ! command -v node &> /dev/null; then
    echo_warning "Node.js is not installed - frontend setup will be skipped"
fi

if ! command -v npm &> /dev/null && command -v node &> /dev/null; then
    echo_warning "npm is not installed - frontend setup will be skipped"
fi

echo_success "Prerequisites check complete"
echo ""

# Backend Setup
echo_info "========================================"
echo_info "Backend Setup"
echo_info "========================================"

if [ ! -d "$BACKEND_DIR" ]; then
    echo_error "Backend directory not found: $BACKEND_DIR"
    exit 1
fi

cd "$BACKEND_DIR"

# Check/create virtual environment
VENV_DIR="$BACKEND_DIR/venv"

if [ "$FORCE" = true ] && [ -d "$VENV_DIR" ]; then
    echo_warning "Force mode: Removing existing virtual environment..."
    if [ "$CHECK" = false ]; then
        rm -rf "$VENV_DIR"
    fi
fi

if [ ! -d "$VENV_DIR" ]; then
    echo_info "Creating virtual environment..."
    if [ "$CHECK" = false ]; then
        python3 -m venv venv
        if [ $? -ne 0 ]; then
            echo_error "Failed to create virtual environment"
            exit 1
        fi
    fi
    echo_success "Virtual environment created"
else
    echo_success "Virtual environment already exists"
fi

# Activate virtual environment
echo_info "Activating virtual environment..."
if [ "$CHECK" = false ]; then
    source venv/bin/activate
    pip install --upgrade pip
fi

# Install dependencies
if [ "$SKIP_DEPS" = false ]; then
    echo_info "Installing Python dependencies..."
    if [ "$CHECK" = false ]; then
        pip install -r requirements.txt
        if [ $? -ne 0 ]; then
            echo_error "Failed to install Python dependencies"
            exit 1
        fi
    fi
    echo_success "Python dependencies installed"
else
    echo_warning "Skipping Python dependency installation"
fi

# Configure database
if [ "$POSTGRES" = true ]; then
    echo_info "Configuring for PostgreSQL..."
    ENV_FILE="$BACKEND_DIR/.env"
    if [ -f "$ENV_FILE" ]; then
        echo_info "Updating .env for PostgreSQL..."
        if [ "$CHECK" = false ]; then
            sed -i.bak '/# Database/d' "$ENV_FILE"
            sed -i.bak 's/DB_NAME=.*/DB_NAME=hotel_reservation/' "$ENV_FILE"
            sed -i.bak 's/DB_USER=.*/DB_USER=postgres/' "$ENV_FILE"
            sed -i.bak 's/DB_PASSWORD=.*/DB_PASSWORD=postgres/' "$ENV_FILE"
            sed -i.bak 's/DB_HOST=.*/DB_HOST=localhost/' "$ENV_FILE"
            sed -i.bak 's/DB_PORT=.*/DB_PORT=5432/' "$ENV_FILE"
        fi
    fi
    echo_success "PostgreSQL configuration applied"
else
    echo_info "Using SQLite (default)"
fi

# Run migrations
echo_info "Running database migrations..."
if [ "$CHECK" = false ]; then
    python manage.py makemigrations
    python manage.py migrate
    if [ $? -ne 0 ]; then
        echo_error "Failed to run migrations"
        exit 1
    fi
fi
echo_success "Database migrations complete"

# Create superuser
if [ "$CREATE_SU" = true ]; then
    echo_info "Creating superuser..."
    if [ "$CHECK" = false ]; then
        echo "from django.contrib.auth import get_user_model; User = get_user_model(); User.objects.create_superuser('admin', 'admin@hotel.com', 'admin123') if not User.objects.filter(username='admin').exists() else None" | python manage.py shell
        if [ $? -eq 0 ]; then
            echo_success "Superuser created (username: admin)"
        else
            echo_warning "Superuser may already exist or creation failed"
        fi
    fi
fi

# Load seed data
echo_info "Loading seed data..."
if [ "$CHECK" = false ]; then
    python seed_data.py
    if [ $? -ne 0 ]; then
        echo_warning "Seed data loading failed or already loaded"
    fi
fi
echo_success "Seed data loaded"

# Collect static files
if [ "$NO_COLLECTSTATIC" = false ]; then
    echo_info "Collecting static files..."
    if [ "$CHECK" = false ]; then
        python manage.py collectstatic --noinput
    fi
    echo_success "Static files collected"
else
    echo_warning "Skipping static files collection"
fi

cd "$SCRIPT_DIR"

# Frontend Setup
echo ""
echo_info "========================================"
echo_info "Frontend Setup"
echo_info "========================================"

if command -v node &> /dev/null && command -v npm &> /dev/null; then
    if [ ! -d "$FRONTEND_DIR" ]; then
        echo_error "Frontend directory not found: $FRONTEND_DIR"
        exit 1
    fi

    cd "$FRONTEND_DIR"

    # Install dependencies
    if [ "$SKIP_DEPS" = false ]; then
        echo_info "Installing Node.js dependencies..."
        if [ "$CHECK" = false ]; then
            npm install
            if [ $? -ne 0 ]; then
                echo_error "Failed to install Node.js dependencies"
                exit 1
            fi
        fi
        echo_success "Node.js dependencies installed"
    else
        echo_warning "Skipping Node.js dependency installation"
    fi

    # Development dependencies
    if [ "$DEV" = true ]; then
        echo_info "Installing development dependencies..."
        if [ "$CHECK" = false ]; then
            npm install --save-dev @types/react @types/react-dom
        fi
        echo_success "Development dependencies installed"
    fi

    cd "$SCRIPT_DIR"
else
    echo_warning "Skipping frontend setup (Node.js/npm not available)"
fi

# Final summary
echo ""
echo_info "========================================"
echo_info "Setup Complete!"
echo_info "========================================"
echo ""
echo_success "Backend: $BACKEND_DIR"
echo_success "Frontend: $FRONTEND_DIR"
echo ""
echo_info "Configuration:"
echo "  Database: $([ "$POSTGRES" = true ] && echo "PostgreSQL" || echo "SQLite")"
echo "  Superuser: $([ "$CREATE_SU" = true ] && echo "Created" || echo "Not created")"
echo "  Dependencies: $([ "$SKIP_DEPS" = true ] && echo "Skipped" || echo "Installed")"
echo "  Static Files: $([ "$NO_COLLECTSTATIC" = true ] && echo "Skipped" || echo "Collected")"
echo ""
echo_info "Next steps:"
echo "  1. Run start script: ./start.sh [options]"
echo "  2. Or start manually:"
echo "     Backend: cd backend && source venv/bin/activate && python manage.py runserver"
echo "     Frontend: cd frontend && npm run dev"
echo ""
echo_info "Demo credentials:"
echo "  Admin: admin / admin123"
echo "  Staff: staff / staff123"
echo ""