# SOBAT HR - Quick Start Guide

## 🚀 5-Minute Setup

### Step 1: Install Dependencies
```bash
cd sobat-api
composer install
```

### Step 2: Setup Environment
```bash
# Copy environment file
copy .env.example .env

# Generate application key
php artisan key:generate
```

### Step 3: Configure Database
Edit `.env` file:
```env
DB_CONNECTION=pgsql
DB_HOST=127.0.0.1
DB_PORT=5432
DB_DATABASE=sobat_hr
DB_USERNAME=postgres
DB_PASSWORD=your_password
```

### Step 4: Setup Database
```bash
# Run migrations
php artisan migrate

# Seed test data
php artisan db:seed
```

### Step 5: Start Server
```bash
php artisan serve
```

Your API is now running at: **http://localhost:8000**

---

## 🧪 Test Your API

### 1. Login
```bash
POST http://localhost:8000/api/auth/login
Content-Type: application/json

{
  "email": "admin@sobat.co.id",
  "password": "password123"
}
```

**Response:**
```json
{
  "access_token": "1|xxxxxx...",
  "token_type": "Bearer",
  "user": {
    "id": 1,
    "name": "Super Admin",
    "email": "admin@sobat.co.id",
    "role": "super_admin"
  }
}
```

### 2. Get Current User
```bash
GET http://localhost:8000/api/auth/me
Authorization: Bearer {your_token}
```

### 3. List Employees
```bash
GET http://localhost:8000/api/employees
Authorization: Bearer {your_token}
```

---

## 📧 Default Test Accounts

After running `php artisan db:seed`:

| Role | Email | Password |
|------|-------|----------|
| Super Admin | admin@sobat.co.id | password123 |
| Admin Jakarta | admin.jakarta@sobat.co.id | password123 |
| Admin Surabaya | admin.surabaya@sobat.co.id | password123 |
| Staff | john.doe@sobat.co.id | password123 |
| Staff | jane.smith@sobat.co.id | password123 |

---

## 🛠️ Common Commands

### Database
```bash
# Fresh migration (drop all tables)
php artisan migrate:fresh

# Fresh migration with seeding
php artisan migrate:fresh --seed

# Rollback last migration
php artisan migrate:rollback

# Check migration status
php artisan migrate:status
```

### Cache
```bash
# Clear all cache
php artisan cache:clear
php artisan config:clear
php artisan route:clear

# Cache for production
php artisan config:cache
php artisan route:cache
```

### Development
```bash
# Start development server
php artisan serve

# Run on specific port
php artisan serve --port=8080

# Run tests
php artisan test
```

---

## 📚 Documentation

- **[API Documentation](./API_DOCUMENTATION.md)** - Complete API reference
- **[Setup Summary](./SETUP_SUMMARY.md)** - What's been implemented
- **[README](./README.md)** - Project overview

---

## ⚡ Quick API Endpoints Reference

### Authentication
```
POST   /api/auth/login          - Login
POST   /api/auth/register       - Register
POST   /api/auth/logout         - Logout
GET    /api/auth/me             - Get current user
```

### Employees
```
GET    /api/employees           - List all employees
POST   /api/employees           - Create employee
GET    /api/employees/{id}      - Get employee details
PUT    /api/employees/{id}      - Update employee
DELETE /api/employees/{id}      - Delete employee
```

### Attendance
```
GET    /api/attendances         - List attendances
POST   /api/attendances         - Record attendance
POST   /api/attendances/sync    - Sync from fingerprint
GET    /api/attendances/report/{month}/{year} - Monthly report
```

### Payroll
```
GET    /api/payrolls            - List payrolls
POST   /api/payrolls/calculate  - Calculate payroll
GET    /api/payrolls/{id}/slip  - Generate slip PDF
GET    /api/payrolls/period/{month}/{year} - Period payrolls
```

### Requests (Cuti, Lembur, etc.)
```
GET    /api/requests            - List requests
POST   /api/requests            - Create request
POST   /api/requests/{id}/submit - Submit for approval
POST   /api/requests/{id}/approve - Approve request
POST   /api/requests/{id}/reject - Reject request
```

### Dashboard
```
GET    /api/dashboard/analytics - Get analytics
GET    /api/dashboard/turnover  - Turnover rate
GET    /api/dashboard/attendance-heatmap - Attendance heatmap
```

---

## 🔧 Troubleshooting

### Error: "could not find driver"
```bash
# Enable PostgreSQL extension in php.ini
extension=pdo_pgsql
extension=pgsql
```

### Error: "No application encryption key"
```bash
php artisan key:generate
```

### Error: "Class 'Laravel\Sanctum\HasApiTokens' not found"
```bash
composer require laravel/sanctum
```

### Database connection refused
1. Make sure PostgreSQL is running
2. Check credentials in `.env`
3. Verify database exists: `CREATE DATABASE sobat_hr;`

---

## 🎯 Next Steps

1. ✅ API is ready - Test all endpoints
2. 📱 Start frontend development (Next.js or Flutter)
3. 🔗 Implement fingerprint integration
4. 📄 Add PDF generation for payroll slips
5. ✉️ Add email notifications

---

## 💡 Tips

- Use **Postman** or **Insomnia** for API testing
- Import collection from API documentation
- Check `storage/logs/laravel.log` for errors
- Use `dd()` or `logger()` for debugging

---

**Happy Coding! 🚀**
