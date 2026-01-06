# SOBAT HR - Backend API

Smart Operations & Business Administrative Tool - Human Resources Information System

## Tech Stack

- **Framework**: Laravel 11
- **Language**: PHP 8.2+
- **Database**: PostgreSQL
- **Authentication**: Laravel Sanctum
- **Architecture**: Repository Pattern + API Resources

## Features

### 🔐 Authentication & Authorization
- Role-based access control (RBAC)
- JWT token authentication via Laravel Sanctum
- Multiple user roles: Super Admin, Admin Cabang, Manager, Staff

### 👥 Employee Management
- Complete employee database (CRUD)
- Employee profile with contract management
- Multi-branch organization structure
- Digital document management

### ⏰ Attendance System
- Fingerprint device integration ready
- Automatic attendance calculation
- Work hours tracking
- Monthly attendance reports

### 💰 Payroll Engine
- Automatic salary calculation
- BPJS (Health & Employment) computation
- PPh21 tax calculation
- PDF slip gaji generation (ready)

### 📝 Request & Approval System
- Leave (Cuti) requests
- Overtime (Lembur) requests
- Reimbursement requests
- Resignation requests
- Multi-level approval workflow

### 🔄 Shift Management
- Flexible shift scheduling
- Multi-day shift patterns
- Branch-specific shifts

### 📊 Dashboard & Analytics
- Employee statistics
- Turnover rate analysis
- Attendance heatmap
- Contract expiration monitoring

## Installation

### Prerequisites
- PHP 8.2 or higher
- Composer
- PostgreSQL
- Laragon (recommended for Windows)

### Step 1: Clone & Install Dependencies

```bash
cd sobat-api
composer install
```

### Step 2: Environment Configuration

Copy `.env.example` to `.env`:
```bash
copy .env.example .env
```

Update database configuration in `.env`:
```env
DB_CONNECTION=pgsql
DB_HOST=127.0.0.1
DB_PORT=5432
DB_DATABASE=sobat_hr
DB_USERNAME=postgres
DB_PASSWORD=your_password
```

### Step 3: Generate Application Key

```bash
php artisan key:generate
```

### Step 4: Run Migrations

```bash
php artisan migrate
```

### Step 5: Seed Database (Optional)

```bash
php artisan db:seed
```

This will create:
- 4 default roles (super_admin, admin_cabang, manager, staff)
- Sample organizations (HQ, Jakarta Branch, Surabaya Branch)
- 5 test users with employees
- 3 shift schedules

### Step 6: Start Development Server

```bash
php artisan serve
```

API will be available at: `http://localhost:8000`

## Default Credentials

After seeding, use these credentials:

**Super Admin:**
- Email: `admin@sobat.co.id`
- Password: `password123`

**Admin Jakarta:**
- Email: `admin.jakarta@sobat.co.id`
- Password: `password123`

**Staff:**
- Email: `john.doe@sobat.co.id`
- Password: `password123`

## API Documentation

See [API_DOCUMENTATION.md](./API_DOCUMENTATION.md) for complete API reference.

### Quick Start API Test

1. **Login:**
```bash
POST http://localhost:8000/api/auth/login
Content-Type: application/json

{
  "email": "admin@sobat.co.id",
  "password": "password123"
}
```

2. **Get Current User:**
```bash
GET http://localhost:8000/api/auth/me
Authorization: Bearer {token}
```

3. **List Employees:**
```bash
GET http://localhost:8000/api/employees
Authorization: Bearer {token}
```

## Project Structure

```
sobat-api/
├── app/
│   ├── Http/
│   │   ├── Controllers/
│   │   │   └── Api/          # API Controllers
│   │   ├── Middleware/       # Custom Middleware
│   │   └── Resources/        # API Resources (Transformers)
│   ├── Models/               # Eloquent Models
│   └── Repositories/         # Repository Pattern Implementation
├── database/
│   ├── migrations/           # Database Migrations
│   └── seeders/              # Database Seeders
├── routes/
│   ├── api.php              # API Routes
│   └── web.php              # Web Routes
└── config/                   # Configuration Files
```

## Development Guidelines

### Repository Pattern
Business logic is separated using Repository Pattern:
- `EmployeeRepository` - Employee operations
- `PayrollRepository` - Payroll calculations

### API Resources
Consistent data transformation using Laravel Resources:
- `EmployeeResource`
- `PayrollResource`
- `AttendanceResource`
- etc.

### Middleware
- `auth:sanctum` - Authentication
- `role:super_admin` - Role-based access

### Code Style
Follow Laravel PSR-12 coding standards.

## Testing

```bash
# Run tests
php artisan test

# Run with coverage
php artisan test --coverage
```

## Deployment Checklist

- [ ] Update `.env` for production
- [ ] Set `APP_ENV=production`
- [ ] Set `APP_DEBUG=false`
- [ ] Configure proper database credentials
- [ ] Run migrations: `php artisan migrate --force`
- [ ] Cache config: `php artisan config:cache`
- [ ] Cache routes: `php artisan route:cache`
- [ ] Optimize autoloader: `composer install --optimize-autoloader --no-dev`

## Roadmap (3-Month Milestones)

### ✅ Month 1 (January 2026)
- [x] Laravel API setup
- [x] Authentication with Sanctum
- [x] Database schema & migrations
- [x] CRUD for Master Data (Employees, Organizations)
- [x] Role-based access control

### 🔄 Month 2 (February 2026)
- [ ] Payroll Engine (BPJS/PPh21)
- [ ] Fingerprint Integration
- [ ] Approval Workflow Logic
- [ ] PDF Slip Gaji Generator

### 📅 Month 3 (March 2026)
- [ ] Flutter Mobile App
- [ ] Final Testing & Bug Fixes
- [ ] Production Deployment
- [ ] User Acceptance Testing

## Support & Contact

For issues or questions, contact the development team.

## License

This project is proprietary software. All rights reserved.

---

**Built with ❤️ for efficient HR Management**


In order to ensure that the Laravel community is welcoming to all, please review and abide by the [Code of Conduct](https://laravel.com/docs/contributions#code-of-conduct).

## Security Vulnerabilities

If you discover a security vulnerability within Laravel, please send an e-mail to Taylor Otwell via [taylor@laravel.com](mailto:taylor@laravel.com). All security vulnerabilities will be promptly addressed.

## License

The Laravel framework is open-sourced software licensed under the [MIT license](https://opensource.org/licenses/MIT).
