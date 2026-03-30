# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

SOBAT HR is a multi-platform HR management system with three components:
- **sobat-api/** — Laravel 12 (PHP 8.2) REST API with Sanctum auth
- **sobat-web/** — Next.js 15 (TypeScript) admin dashboard
- **sobat-mobile/** — Flutter 3.10 (Dart) mobile app

## Common Commands

### Backend (sobat-api/)
```bash
cd sobat-api
php artisan serve                          # Dev server (port 8000)
php artisan test                           # Run all tests
php artisan test --filter=TestClassName    # Run single test
./vendor/bin/pint                          # Lint/format PHP
php artisan migrate                        # Run migrations
php artisan migrate:fresh --seed           # Reset DB with seed data
```

### Web Frontend (sobat-web/)
```bash
cd sobat-web
npm run dev       # Dev server (port 3000)
npm run build     # Production build
npm run lint      # ESLint
```

### Mobile (sobat-mobile/)
```bash
cd sobat-mobile
flutter pub get                                              # Install deps
flutter run --dart-define=DEV_HOST=YOUR_IP                   # Dev run
flutter test                                                 # Run tests
flutter build apk --release --dart-define=ENV=prod           # Android APK
flutter build appbundle --release --dart-define=ENV=prod     # Android AAB
flutter build ios --release --dart-define=ENV=prod           # iOS
flutter clean && flutter pub get                             # Clean rebuild
```

### Production Deploy (Server)
```bash
# Web: /var/www/sobat-hr/sobat-web
npm run build && pm2 restart sobat-web

# API permissions
sudo chown -R www-data:www-data storage bootstrap/cache
sudo chmod -R 775 storage bootstrap/cache
php artisan storage:link
```

## Architecture

### API Layer (Laravel)
- **Routes:** `sobat-api/routes/api.php` — 180+ API endpoints
- **Controllers:** `sobat-api/app/Http/Controllers/Api/` — thin controllers delegating to services/repositories
- **Services:** `sobat-api/app/Services/` — business logic (approval, geofence validation, QR code validation, FCM, timestamp tampering detection, Groq AI for personalized payslip messages)
- **Repositories:** `sobat-api/app/Repositories/` — data access abstraction
- **Models:** `sobat-api/app/Models/` — 34 Eloquent models
- **Exports:** `sobat-api/app/Exports/` — Excel export classes (maatwebsite/excel)
- **Auth:** Sanctum bearer tokens, configurable expiration via `SANCTUM_TOKEN_EXPIRATION` env var (default 7 days / 10080 min)
- **DB:** MySQL (local dev), SQLite in-memory (tests via `phpunit.xml`)
- **Testing:** PHPUnit with SQLite in-memory DB
- **PDF:** barryvdh/laravel-dompdf for payslip generation
- **Scheduled Tasks:** `cleanup:files` runs daily at 02:00
- **Job Queues:** `face-verification` queue for async face comparison jobs

### Custom Middleware
- **`CheckRole`** — Validates user role against required roles; logs unauthorized attempts with user_id, email, role, and path
- **`NormalizeUrlMiddleware`** — Collapses consecutive slashes in URLs via 308 redirects (handles legacy client requests)

### Rate Limiting (Throttle)
| Limit | Endpoints |
|-------|-----------|
| 5/min | Login, register, forgot-password |
| 6/min | PIN setup/verify, face enrollment/enroll |
| 10/min | Payroll imports |
| 30/min | Payslip/slip generation |

### Web Frontend (Next.js)
- **App Router:** `sobat-web/src/app/` — file-based routing
- **API Client:** `sobat-web/src/lib/api-client.ts` — Axios with interceptors
- **Config:** `sobat-web/src/lib/config.ts` — API endpoint definitions
- **Auth Store:** `sobat-web/src/store/auth-store.ts` — Zustand state management
- **Components:** `sobat-web/src/components/` — reusable UI components
- **Types:** `sobat-web/src/types/` — TypeScript type definitions
- **Path alias:** `@/*` maps to `src/*`
- **Key libs:** Recharts (charts), GSAP/Motion (animations), React Signature Canvas, QRCode.react, date-fns

### Mobile App (Flutter)
- **Entry:** `sobat-mobile/lib/main.dart` — Firebase init + Provider setup
- **State:** Provider pattern (`lib/providers/`)
- **Services:** `lib/services/` — API calls via Dio, offline sync, connectivity detection, background sync, FCM notifications
- **Screens:** `lib/screens/` — organized by feature (auth, home, attendance, payroll, etc.)
- **Config:** `lib/config/api_config.dart` — environment-based API URLs (dev via `--dart-define=DEV_HOST`, prod via `--dart-define=ENV=prod`)
- **Models:** `lib/models/` — data models with JSON serialization

### Key Patterns
- **Payroll variants:** Multiple payroll models/controllers exist for different business units (FNB, HO, Celluller, Hans, MM, Ref, Wrapping)
- **Offline attendance:** Two-track system — "operational" (QR scan at outlet) and "head_office" (GPS). Smart online-first logic with 7s timeout, falls back to local SQLite (`offline_attendance.db`), background sync via WorkManager every 15 min with parallel batch processing (up to 5 concurrent syncs). Max 10 sync retries before a record is marked permanently failed. Photo files stored on disk (not base64 in DB); if photo is deleted before sync, the record is marked as permanent failure via `PhotoFileNotFoundException`. Old synced records auto-cleaned after 7 days.
- **QR attendance:** QR codes use format `{ORG_CODE}-LT{FLOOR}-{RANDOM}` (no timestamps), with fallback `OUTLET-{ORG_ID}-LT{FLOOR}-{RANDOM}` if org has no code. Validated client-side before offline storage and server-side via `QrCodeValidationService`. Also accepts JSON and pipe-delimited QR formats. QR codes stored in `QrCodeLocation` model with `is_active` tracking.
- **Face verification:** Async background processing via `VerifyAttendanceFace` job on dedicated `face-verification` queue. Compares check-in photo against enrolled face using Python (`compare_faces.py`). Status tracked per attendance: pending → verified/mismatch/failed. Max 3 retries, 30s timeout. Failed jobs mark attendance as `needs_review`. Face enrollment uses Google ML Kit (`google_mlkit_face_detection`) with auto-capture and manual fallback.
- **Role-based access:** `App\Models\Role` constants are the single source of truth for role checks across all layers — never hardcode role strings
- **Device uptime:** Android reads `/proc/uptime` for tampering detection; iOS returns null (server uses timestamp comparison only)
- **Offline attendance admin:** Endpoints for listing offline submissions, reviewing (accept/reject), viewing statistics, and generating/managing QR codes for outlets

## Design System
- **Primary:** Forest Green `#1A4D2E`
- **Accent:** Neon Mint `#49FFB8`
- **Style:** Glassmorphism, Framer Motion/GSAP animations
- **Feedback:** SweetAlert2 (Web) & Modern Snackbars (Mobile)

## Security Considerations
- IDOR protection required on sensitive endpoints — `index()` methods must check role before returning other users' data
- Upload MIME validation: jpg, jpeg, png only
- Mass assignment protection via `$fillable` — never allow `role_id` from user input
- CSV injection protection via ExcelSanitizer trait on all export modules
- Mobile uses FlutterSecureStorage (`encryptedSharedPreferences` on Android) for tokens and user data
- No `dangerouslySetInnerHTML` in web frontend
- GPS coordinates must be range-validated (`latitude -90..90`, `longitude -180..180`)
- Never expose debug output, stack traces, or script output in API error responses — log server-side only
- CORS restricted to specific methods (`GET, POST, PUT, PATCH, DELETE, OPTIONS`) and headers
- Organization mutations (create/update/delete/reset) require admin roles; reset is super_admin only
- Web auth: zustand persist is the single source of truth for tokens; `api-client.ts` reads from persisted state; legacy `STORAGE_KEYS.TOKEN` synced via subscribe for pages using raw `fetch()`
- Geofencing has 10-meter buffer for GPS signal variance

## Pending Security Work
- **Refresh token rotation:** Reduce Sanctum TTL to 1-24h, add refresh endpoint + client-side refresh logic
- **SSL certificate pinning (Flutter):** Add via Dio SecurityContext + Android `network_security_config.xml` / iOS `Info.plist`
- **Audit logging:** Add cross-cutting audit log (who/what/when/IP) for employee deletion, payroll approval, org changes, role changes
- **BFF proxy for web auth:** Evaluate Next.js API routes as proxy to use httpOnly cookies instead of localStorage tokens

## Environment Setup
- API base URL (dev): `http://localhost:8000/api`
- API base URL (prod): `https://api.sobat-hr.com/api/`
- Web env: `sobat-web/.env.local` sets `NEXT_PUBLIC_API_URL`
- Mobile dev: pass `--dart-define=DEV_HOST=YOUR_LOCAL_IP` to `flutter run`
- No CI/CD pipelines configured — builds and deploys are manual
