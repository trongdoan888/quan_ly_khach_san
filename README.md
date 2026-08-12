# Hotel Reservation Management System

A modern, full-stack hotel reservation management system built with Django REST Framework and React TypeScript. This system provides comprehensive functionality for managing hotel rooms, customers, and reservations with advanced features like double-booking prevention and real-time availability checking.

## 🏨 Features

### Core Functionality
- **User Authentication**: Secure JWT-based authentication with role-based access control (Admin/Staff)
- **Room Management**: Full CRUD operations for rooms with filtering and search capabilities
- **Customer Management**: Complete customer database with sensitive data masking
- **Reservation Management**: Advanced booking system with double-booking prevention
- **Availability Checking**: Real-time room availability search with date range validation
- **Dashboard**: Real-time statistics and activity monitoring

### Business Rules
- **Double-Booking Prevention**: Strict validation prevents overlapping reservations
- **Capacity Validation**: Enforces guest limits based on room capacity
- **Maintenance Restrictions**: Prevents booking rooms under maintenance
- **Data Privacy**: Government ID numbers are masked in the UI
- **Date Validation**: Ensures check-out dates are after check-in dates

## 🏗️ Architecture

### Backend
- **Framework**: Django 6.1 with Django REST Framework
- **Authentication**: JWT tokens with refresh token rotation
- **Database**: SQLite (development), PostgreSQL (production ready)
- **API Design**: RESTful API with proper HTTP status codes
- **Validation**: Comprehensive validation at model and serializer levels

### Frontend
- **Framework**: React 18 with TypeScript
- **Routing**: React Router v6
- **HTTP Client**: Axios with interceptors for token management
- **State Management**: React Context API
- **Styling**: Custom CSS with premium hotel theme

### Database Schema
```
Users (Custom User Model)
├── id, username, email, role (admin/staff)
├── first_name, last_name
└── timestamps

RoomTypes
├── id, name, description
├── base_price
└── timestamps

Rooms
├── id, room_number (unique)
├── room_type (FK), floor, capacity
├── price_per_night, status
├── description
└── timestamps

Customers
├── customer_id (PK, auto-generated)
├── full_name, email (unique)
├── phone, address
├── government_id_number (unique, masked in UI)
└── timestamps

Reservations
├── reservation_number (PK, auto-generated)
├── customer (FK), room (FK)
├── check_in_date, check_out_date
├── number_of_guests, booking_status
└── timestamps
```

## 📜 Setup & Start Scripts

The project includes automated setup and start scripts for Windows (CMD) and Linux/macOS (Bash). The start scripts automatically clean up existing processes before starting.

### Quick Start

**Windows (CMD):**
```cmd
REM Setup
setup.bat

REM Start (automatically kills existing processes)
start.bat
```

**Linux/macOS (Bash):**
```bash
# Setup
./setup.sh

# Start (automatically kills existing processes)
./start.sh

# Multiple instances with custom ports
./start.sh --multiple --port 8001 3001

# Remote access with custom ports
./start.sh --remote --port 8002 3002
```

### Setup Script Options

| Option | Description |
|--------|-------------|
| `--postgres` | Configure for PostgreSQL instead of SQLite |
| `--create-su` | Create Django superuser (admin/admin123) |
| `--skip-deps` | Skip Python/Node dependency installation |
| `--force` | Force recreate virtual environment |
| `--no-collectstatic` | Skip static files collection |
| `--dev` | Install development dependencies |
| `--check` | Check if everything is installed without making changes |

**Examples:**
```powershell
# Full setup with PostgreSQL and superuser
.\setup.ps1 --postgres --create-su

# Quick check without changes
.\setup.ps1 --check

# Development setup with all dependencies
.\setup.ps1 --dev
```

### Start Script Options

| Option | Description |
|--------|-------------|
| `--remote` | Bind to 0.0.0.0 for external access (uses actual IP) |
| `--postgres` | Use PostgreSQL instead of SQLite |
| `--bck` | Run in background with nohup |
| `--multiple` | Allow multiple instances without killing existing processes |
| `--port` | Specify custom ports (backend_port frontend_port) |

**Examples:**
```cmd
# Local development
start.bat

# Remote access with PostgreSQL
start.bat --remote --postgres

# Background mode for production
start.bat --remote --postgres --bck

# Multiple instances with custom ports
start.bat --multiple --port 8001 3001

# Remote access with custom ports
start.bat --remote --port 8002 3002
```

### Remote Access

When using `--remote` flag, the scripts will:
- Automatically detect your local IP address
- Bind services to `0.0.0.0` for external access
- Display URLs with your actual IP instead of localhost
- Configure Vite for remote access (frontend)

Example output:
```
Configuration:
  Remote Mode: Enabled (IP: 192.168.1.100)
  Database: PostgreSQL
  Background: Enabled

Backend API: http://192.168.1.100:8000/api
Frontend UI: http://192.168.1.100:3000
```

### Background Mode

When using `--bck` flag:
- Services run in background using nohup/Start-Process
- Process IDs are saved for cleanup
- Logs are written to `backend.log` and `frontend.log`
- Use `stop.ps1` or `stop.sh` to stop services

## 🚀 Manual Setup Instructions

### Prerequisites
- Python 3.8+
- Node.js 16+ (for frontend)
- pip (Python package manager)
- Virtual environment (recommended)

### Backend Setup

1. **Navigate to backend directory**
```bash
cd backend
```

2. **Create virtual environment**
```bash
python -m venv venv

# On Windows:
venv\Scripts\activate

# On macOS/Linux:
source venv/bin/activate
```

3. **Install dependencies**
```bash
pip install -r requirements.txt
```

4. **Configure environment variables**
```bash
# Copy the example environment file
cp .env.example .env

# Edit .env with your configuration
# For development, the defaults should work fine
```

5. **Run database migrations**
```bash
python manage.py makemigrations
python manage.py migrate
```

6. **Load seed data**
```bash
python seed_data.py
```

7. **Start the development server**
```bash
python manage.py runserver
```

The backend API will be available at `http://localhost:8000`

### Frontend Setup

1. **Navigate to frontend directory**
```bash
cd frontend
```

2. **Install dependencies**
```bash
npm install
```

3. **Configure environment variables**
```bash
# The .env file is already configured for development
# VITE_API_URL=http://localhost:8000/api
```

4. **Start the development server**
```bash
npm run dev
```

The frontend will be available at `http://localhost:3000`

## 🔧 Environment Variables

### Backend (.env)
```env
# Database Configuration
DB_NAME=hotel_reservation
DB_USER=postgres
DB_PASSWORD=postgres
DB_HOST=localhost
DB_PORT=5432

# Django Configuration
SECRET_KEY=your-secret-key-here
DEBUG=True
ALLOWED_HOSTS=localhost,127.0.0.1

# JWT Configuration
JWT_ACCESS_TOKEN_LIFETIME=60
JWT_REFRESH_TOKEN_LIFETIME=1440
```

### Frontend (.env)
```env
VITE_API_URL=http://localhost:8000/api
```

## 📊 Database & Migrations

### Migration Files
- `authentication/migrations/0001_initial.py` - Custom user model
- `rooms/migrations/0001_initial.py` - Room types and rooms
- `customers/migrations/0001_initial.py` - Customer model
- `customers/migrations/0002_alter_customer_customer_id.py` - Auto-generated customer IDs
- `reservations/migrations/0001_initial.py` - Reservation model

### Running Migrations
```bash
# Create new migrations
python manage.py makemigrations

# Apply migrations
python manage.py migrate

# Show migration status
python manage.py showmigrations
```

## 🌱 Seed Data

The seed data script creates realistic demo data:

### Users
- **Admin**: username `admin`, password `admin123`
- **Staff**: username `staff`, password `staff123`

### Room Types
- Standard ($100/night)
- Deluxe ($200/night)
- Suite ($400/night)

### Rooms
- 22 rooms across 8 floors
- Various capacities (2-5 guests)
- Mixed statuses (available, occupied, maintenance)

### Customers
- 8 sample customers with realistic data
- Masked government IDs for privacy

### Reservations
- 8 sample reservations
- Various statuses (pending, confirmed, completed, cancelled)
- Different date ranges for testing

## 🧪 Testing

### Backend Tests
```bash
# Run all tests
python manage.py test

# Run specific app tests
python manage.py test authentication
python manage.py test rooms
python manage.py test customers
python manage.py test reservations

# Run with coverage
pip install coverage
coverage run --source='.' manage.py test
coverage report
```

### Test Coverage
- **Authentication**: Registration, login, protected routes
- **Rooms**: CRUD operations, validation, search
- **Customers**: CRUD operations, search, data masking
- **Reservations**: CRUD operations, double-booking prevention, availability checking

### Critical Test Cases
- ✅ Exact overlap prevention
- ✅ Partial overlap prevention
- ✅ Nested overlap prevention
- ✅ Checkout = next check-in (allowed)
- ✅ Cancelled reservations don't block availability
- ✅ Capacity validation
- ✅ Maintenance room restrictions

## 📡 API Documentation

### Authentication Endpoints
- `POST /api/auth/register/` - User registration
- `POST /api/auth/login/` - User login (returns JWT tokens)
- `POST /api/auth/logout/` - User logout
- `GET /api/auth/profile/` - Get current user profile

### Room Endpoints
- `GET /api/rooms/` - List all rooms (with filtering)
- `POST /api/rooms/` - Create new room (admin only)
- `GET /api/rooms/{id}/` - Get room details
- `PUT /api/rooms/{id}/` - Update room (admin only)
- `DELETE /api/rooms/{id}/` - Delete room (admin only)
- `GET /api/rooms/search/` - Advanced room search
- `GET /api/rooms/types/` - List room types
- `POST /api/rooms/types/` - Create room type (admin only)

### Customer Endpoints
- `GET /api/customers/` - List all customers (with filtering)
- `POST /api/customers/` - Create new customer
- `GET /api/customers/{customer_id}/` - Get customer details
- `PUT /api/customers/{customer_id}/` - Update customer
- `DELETE /api/customers/{customer_id}/` - Delete customer
- `GET /api/customers/search/` - Search customers

### Reservation Endpoints
- `GET /api/reservations/` - List all reservations (with filtering)
- `POST /api/reservations/` - Create new reservation
- `GET /api/reservations/{reservation_number}/` - Get reservation details
- `PUT /api/reservations/{reservation_number}/` - Update reservation
- `DELETE /api/reservations/{reservation_number}/` - Delete reservation
- `POST /api/reservations/check-availability/` - Check room availability
- `GET /api/reservations/statistics/` - Get dashboard statistics

### API Response Format
```json
{
  "count": 25,
  "next": "http://localhost:8000/api/rooms/?page=2",
  "previous": null,
  "results": [...]
}
```

### Error Response Format
```json
{
  "field_name": ["Error message"],
  "non_field_errors": ["General error message"]
}
```

## 👤 Demo Credentials

### Admin Account
- **Username**: `admin`
- **Password**: `admin123`
- **Role**: Admin (full access)

### Staff Account
- **Username**: `staff`
- **Password**: `staff123`
- **Role**: Staff (limited access)

## 🚀 Deployment

### Backend Deployment (Production)

1. **Update environment variables**
```env
DEBUG=False
SECRET_KEY=your-production-secret-key
DB_NAME=your-production-db
DB_USER=your-production-user
DB_PASSWORD=your-production-password
ALLOWED_HOSTS=yourdomain.com,www.yourdomain.com
```

2. **Use PostgreSQL**
```python
# In settings.py, uncomment PostgreSQL configuration
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': config('DB_NAME'),
        'USER': config('DB_USER'),
        'PASSWORD': config('DB_PASSWORD'),
        'HOST': config('DB_HOST'),
        'PORT': config('DB_PORT'),
    }
}
```

3. **Collect static files**
```bash
python manage.py collectstatic
```

4. **Use a production WSGI server**
```bash
pip install gunicorn
gunicorn hotel_reservation.wsgi:application
```

5. **Set up CORS for production**
```python
# In settings.py
CORS_ALLOWED_ORIGINS = [
    "https://yourdomain.com",
    "https://www.yourdomain.com",
]
```

### Frontend Deployment (Production)

1. **Build the application**
```bash
npm run build
```

2. **Configure production API URL**
```env
VITE_API_URL=https://api.yourdomain.com/api
```

3. **Deploy to hosting service**
- Vercel, Netlify, or any static hosting service
- Or serve with Nginx/Apache

### Docker Deployment (Optional)

Create `Dockerfile` for backend:
```dockerfile
FROM python:3.11
WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY . .
CMD ["gunicorn", "hotel_reservation.wsgi:application"]
```

Create `Dockerfile` for frontend:
```dockerfile
FROM node:18
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
RUN npm run build
CMD ["npm", "run", "preview"]
```

## 🎨 UI/UX Design

### Color Palette
- **Primary**: Deep Navy `#0F172A`
- **Accent**: Champagne Gold `#C9A227`
- **Background**: Warm Ivory `#F8F7F3`
- **Cards**: White
- **Text**: Dark Charcoal
- **Success**: Green `#10B981`
- **Warning**: Amber `#F59E0B`
- **Error**: Red `#EF4444`

### Design Features
- Clean professional typography
- Spacious layout with consistent padding
- 12-16px card radius
- 8-10px input/button radius
- Elegant shadows for depth
- Responsive design (desktop/tablet/mobile)
- Professional sidebar navigation
- Loading states and empty states
- Toast notifications for feedback
- Confirmation dialogs for destructive actions

## 🔒 Security Features

- **JWT Authentication**: Secure token-based authentication
- **Password Hashing**: Django's secure password hashing
- **CORS Protection**: Configured CORS for API access
- **SQL Injection Prevention**: Django ORM parameterized queries
- **XSS Protection**: Django's built-in XSS protection
- **CSRF Protection**: Django's CSRF tokens
- **Data Masking**: Sensitive government IDs masked in UI
- **Role-Based Access**: Admin vs staff permissions

## 📝 License

This project is created for educational purposes.

## 🤝 Contributing

This is a demonstration project. For contributions:
1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## 📞 Support

For issues or questions:
- Check the API documentation above
- Review the test files for usage examples
- Examine the seed data for data structure reference

---

**Built with ❤️ using Django REST Framework and React TypeScript**
