# SOBAT HR - Complete Setup Instructions

## Project Structure Overview

```
sobat_hr/
├── sobat-api/          # Laravel 11 Backend API
├── sobat-web/          # Next.js 15 Frontend Web Admin
└── context.md          # Project blueprint
```

---

## 🔧 Backend Setup (Laravel API)

### 1. Navigate to Backend Directory
```bash
cd sobat-api
```

### 2. Install PHP Dependencies
```bash
composer install
```

### 3. Setup Environment
```bash
# Copy environment file
copy .env.example .env

# Generate application key
php artisan key:generate
```

### 4. Configure Database
Edit `.env` file:
```env
DB_CONNECTION=pgsql
DB_HOST=127.0.0.1
DB_PORT=5432
DB_DATABASE=sobat_hr
DB_USERNAME=postgres
DB_PASSWORD=your_password
```

### 5. Create Database
In PostgreSQL:
```sql
CREATE DATABASE sobat_hr;
```

### 6. Run Migrations & Seeders
```bash
# Run migrations
php artisan migrate

# Seed test data
php artisan db:seed
```

### 7. Start Laravel Server
```bash
php artisan serve
```

**Backend API running at:** `http://localhost:8000`

---

## 🌐 Frontend Setup (Next.js Web)

### 1. Navigate to Frontend Directory
```bash
cd sobat-web
```

### 2. Install Node Dependencies
```bash
npm install
```

### 3. Environment Configuration
File `.env.local` already configured:
```env
NEXT_PUBLIC_API_URL=http://localhost:8000/api
NEXT_PUBLIC_APP_NAME=SOBAT HR
```

### 4. Start Development Server
```bash
npm run dev
```

**Frontend running at:** `http://localhost:3000`

---

## ✅ Verification Steps

### 1. Test Backend API
Open browser or Postman:
```
GET http://localhost:8000/api/auth/me
```
Should return error (not authenticated)

### 2. Test Backend Login
```
POST http://localhost:8000/api/auth/login
Content-Type: application/json

{
  "email": "admin@sobat.co.id",
  "password": "password123"
}
```
Should return token and user data

### 3. Test Frontend
1. Open `http://localhost:3000`
2. Click "Login"
3. Enter credentials:
   - Email: `admin@sobat.co.id`
   - Password: `password123`
4. Should redirect to dashboard

---

## 🔑 Default Test Accounts

After running seeders:

| Role | Email | Password |
|------|-------|----------|
| Super Admin | admin@sobat.co.id | password123 |
| Admin Jakarta | admin.jakarta@sobat.co.id | password123 |
| Admin Surabaya | admin.surabaya@sobat.co.id | password123 |
| Staff | john.doe@sobat.co.id | password123 |
| Staff | jane.smith@sobat.co.id | password123 |

---

## 📦 What's Included

### Backend (Laravel API)
✅ Authentication with Laravel Sanctum  
✅ 10 API Controllers (Auth, Employee, Organization, etc.)  
✅ 9 Models with complete relationships  
✅ Repository Pattern implementation  
✅ Role-based access control  
✅ Database seeders with test data  
✅ Complete API documentation  
✅ 70+ API endpoints  

### Frontend (Next.js)
✅ App Router architecture  
✅ TypeScript configuration  
✅ Tailwind CSS styling  
✅ Zustand state management  
✅ Axios API client  
✅ Authentication flow  
✅ Protected routes  
✅ Login & Dashboard pages  

---

## 🛠️ Troubleshooting

### Backend Issues

**Port 8000 already in use:**
```bash
# Run on different port
php artisan serve --port=8080

# Update frontend .env.local
NEXT_PUBLIC_API_URL=http://localhost:8080/api
```

**Database connection error:**
1. Make sure PostgreSQL is running
2. Verify database exists
3. Check credentials in `.env`

**Migration errors:**
```bash
# Fresh start
php artisan migrate:fresh --seed
```

### Frontend Issues

**Port 3000 already in use:**
```bash
# Kill process
npx kill-port 3000

# Or use different port
npm run dev -- -p 3001
```

**API connection error:**
1. Ensure backend is running on port 8000
2. Check `.env.local` has correct API URL
3. Verify CORS is not blocking requests

**Module not found:**
```bash
# Reinstall dependencies
rm -rf node_modules package-lock.json
npm install
```

---

## 🚀 Quick Start Commands

### Start Both Servers

**Terminal 1 (Backend):**
```bash
cd sobat-api
php artisan serve
```

**Terminal 2 (Frontend):**
```bash
cd sobat-web
npm run dev
```

---

## 📚 Documentation

### Backend
- [API Documentation](./sobat-api/API_DOCUMENTATION.md)
- [Setup Summary](./sobat-api/SETUP_SUMMARY.md)
- [Quick Start](./sobat-api/QUICK_START.md)
- [README](./sobat-api/README.md)

### Frontend
- [README](./sobat-web/README.md)

---

## 🎯 Development Workflow

### Typical Flow:
1. Start backend API server
2. Start frontend dev server
3. Login via frontend UI
4. Test API endpoints through frontend
5. Check browser DevTools for debugging
6. Check Laravel logs: `storage/logs/laravel.log`

### Making Changes:
- **Backend**: Changes auto-reload with `php artisan serve`
- **Frontend**: Hot reload enabled, changes reflect instantly

---

## 📊 Project Status

### Month 1 - ✅ COMPLETED
- [x] Laravel 11 API fully setup
- [x] Database schema & migrations
- [x] Authentication with Sanctum
- [x] Complete CRUD operations
- [x] Next.js frontend initialized
- [x] Login & basic dashboard

### Month 2 - 🔄 IN PROGRESS
- [ ] Payroll engine enhancement
- [ ] Fingerprint integration
- [ ] Approval workflow implementation
- [ ] Dashboard analytics
- [ ] Employee management UI

### Month 3 - 📅 PLANNED
- [ ] Flutter mobile app
- [ ] Final testing
- [ ] Production deployment

---

## 🎉 Success Indicators

You've successfully set up the project when:

✅ Backend API responds at `http://localhost:8000`  
✅ Frontend app loads at `http://localhost:3000`  
✅ Can login via frontend UI  
✅ Dashboard displays user info  
✅ No console errors in browser  
✅ No errors in Laravel logs  

---

## 📞 Need Help?

1. Check error messages in:
   - Browser console (F12)
   - Laravel logs (`storage/logs/laravel.log`)
   - Terminal output

2. Common issues documented in Troubleshooting section

3. Review API documentation for endpoint usage

---

**Happy Development! 🚀**

Built with ❤️ for efficient HR Management
