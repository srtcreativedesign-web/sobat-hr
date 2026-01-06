# SOBAT HR - Web Admin Frontend

Next.js 15 + TypeScript + Tailwind CSS + Zustand

## Tech Stack

- **Framework**: Next.js 15 (App Router)
- **Language**: TypeScript
- **Styling**: Tailwind CSS
- **State Management**: Zustand
- **HTTP Client**: Axios
- **Icons**: Lucide React
- **Charts**: Recharts
- **Date Utils**: date-fns

## Quick Start

### 1. Install Dependencies

```bash
cd sobat-web
npm install
```

### 2. Configure Environment

File `.env.local` sudah dibuat dengan konfigurasi default:
```env
NEXT_PUBLIC_API_URL=http://localhost:8000/api
NEXT_PUBLIC_APP_NAME=SOBAT HR
```

### 3. Run Development Server

```bash
npm run dev
```

Aplikasi akan berjalan di: **http://localhost:3000**

## Project Structure

```
sobat-web/
├── src/
│   ├── app/
│   │   ├── layout.tsx          # Root layout
│   │   ├── page.tsx            # Landing page
│   │   ├── globals.css         # Global styles
│   │   ├── login/
│   │   │   └── page.tsx        # Login page
│   │   └── dashboard/
│   │       └── page.tsx        # Dashboard page
│   ├── lib/
│   │   ├── config.ts           # API configuration
│   │   └── api-client.ts       # Axios instance
│   └── store/
│       └── auth-store.ts       # Zustand auth store
├── package.json
├── tsconfig.json
├── tailwind.config.ts
├── next.config.ts
└── .env.local
```

## Features Implemented

### ✅ Authentication
- Login page with form validation
- JWT token management
- Zustand store for auth state
- Protected routes
- Auto-redirect on 401

### ✅ API Integration
- Axios client with interceptors
- Auto token injection
- Error handling
- Base URL configuration

### ✅ State Management
- Zustand for global state
- Persistent storage
- Auth state management

### ✅ Styling
- Tailwind CSS configured
- Responsive design
- Modern UI components

## Available Pages

### 1. Landing Page
**URL**: `/`
- Welcome page
- Links to login and dashboard

### 2. Login Page
**URL**: `/login`
- Email & password form
- Error handling
- Default credentials displayed

### 3. Dashboard Page
**URL**: `/dashboard`
- Protected route (requires auth)
- User info display
- Quick access cards
- Logout functionality

## API Configuration

### Base URL
Default: `http://localhost:8000/api`

### Endpoints Configured
```typescript
AUTH: {
  LOGIN: '/auth/login',
  LOGOUT: '/auth/logout',
  ME: '/auth/me',
}
EMPLOYEES: '/employees'
ORGANIZATIONS: '/organizations'
ATTENDANCES: '/attendances'
SHIFTS: '/shifts'
REQUESTS: '/requests'
APPROVALS: '/approvals'
PAYROLLS: '/payrolls'
ROLES: '/roles'
DASHBOARD: {
  ANALYTICS: '/dashboard/analytics',
  TURNOVER: '/dashboard/turnover',
  HEATMAP: '/dashboard/attendance-heatmap',
}
```

## Usage Example

### Login Flow
1. Navigate to `/login`
2. Enter credentials (admin@sobat.co.id / password123)
3. Click Login
4. Redirected to `/dashboard`

### API Call Example
```typescript
import apiClient from '@/lib/api-client';
import { API_ENDPOINTS } from '@/lib/config';

// Get employees
const response = await apiClient.get(API_ENDPOINTS.EMPLOYEES);
const employees = response.data;
```

### Auth Store Usage
```typescript
import { useAuthStore } from '@/store/auth-store';

const { user, login, logout, isAuthenticated } = useAuthStore();

// Login
await login(email, password);

// Logout
await logout();

// Check auth
await checkAuth();
```

## Development Commands

```bash
# Start dev server
npm run dev

# Build for production
npm run build

# Start production server
npm start

# Run linter
npm run lint
```

## Next Steps

### Phase 1 (Week 1-2)
- [ ] Employee list page with table
- [ ] Employee detail page
- [ ] Employee create/edit form
- [ ] Pagination & search

### Phase 2 (Week 3-4)
- [ ] Attendance page with calendar
- [ ] Attendance report
- [ ] Shift management
- [ ] Organization structure

### Phase 3 (Week 5-6)
- [ ] Payroll list & calculation
- [ ] Request management
- [ ] Approval workflow
- [ ] Dashboard analytics

### Phase 4 (Week 7-8)
- [ ] Charts & visualizations
- [ ] Export to PDF/Excel
- [ ] User profile management
- [ ] Settings

## Environment Variables

```env
# Required
NEXT_PUBLIC_API_URL=http://localhost:8000/api

# Optional
NEXT_PUBLIC_APP_NAME=SOBAT HR
```

## Dependencies

### Core
- next: ^15.1.4
- react: ^19.0.0
- react-dom: ^19.0.0

### State & Data
- zustand: ^5.0.2 (State management)
- axios: ^1.7.9 (HTTP client)

### UI & Styling
- tailwindcss: ^3.4.1
- lucide-react: ^0.468.0 (Icons)

### Utilities
- date-fns: ^4.1.0 (Date formatting)
- recharts: ^2.15.0 (Charts)

## Browser Support

- Chrome (latest)
- Firefox (latest)
- Safari (latest)
- Edge (latest)

## Tips

1. **Hot Reload**: File changes auto-reload in browser
2. **TypeScript**: Full type safety across the app
3. **Tailwind**: Use utility classes for styling
4. **Zustand**: Lightweight alternative to Redux
5. **API Client**: Axios configured with auth headers

## Troubleshooting

### Port already in use
```bash
# Kill process on port 3000
npx kill-port 3000

# Or run on different port
npm run dev -- -p 3001
```

### API connection error
- Check if Laravel API is running on port 8000
- Verify `.env.local` has correct API URL
- Check browser console for CORS errors

### Build errors
```bash
# Clear Next.js cache
rm -rf .next

# Reinstall dependencies
rm -rf node_modules package-lock.json
npm install
```

## License

Proprietary - All rights reserved

---

**Frontend ready for development! 🚀**
