# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

SOBAT HR is a multi-platform HR management system with three components:
- **sobat-api/** — Laravel 11 (PHP 8.2) REST API with Sanctum auth
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

## Architecture

### API Layer (Laravel)
- **Routes:** `sobat-api/routes/api.php` — 70+ API endpoints
- **Controllers:** `sobat-api/app/Http/Controllers/Api/` — thin controllers delegating to services/repositories
- **Services:** `sobat-api/app/Services/` — business logic (approval, geofence validation, QR code validation, FCM, timestamp tampering detection)
- **Repositories:** `sobat-api/app/Repositories/` — data access abstraction
- **Models:** `sobat-api/app/Models/` — 34 Eloquent models
- **Exports:** `sobat-api/app/Exports/` — Excel export classes (maatwebsite/excel)
- **Auth:** Sanctum bearer tokens, 7-day expiration
- **DB:** SQLite (dev), PostgreSQL (prod); 81 migrations, 10 seeders
- **Testing:** PHPUnit with SQLite in-memory DB (`phpunit.xml`)

### Web Frontend (Next.js)
- **App Router:** `sobat-web/src/app/` — file-based routing
- **API Client:** `sobat-web/src/lib/api-client.ts` — Axios with interceptors
- **Config:** `sobat-web/src/lib/config.ts` — API endpoint definitions
- **Auth Store:** `sobat-web/src/store/auth-store.ts` — Zustand state management
- **Components:** `sobat-web/src/components/` — reusable UI components
- **Types:** `sobat-web/src/types/` — TypeScript type definitions
- **Path alias:** `@/*` maps to `src/*`

### Mobile App (Flutter)
- **Entry:** `sobat-mobile/lib/main.dart` — Firebase init + Provider setup
- **State:** Provider pattern (`lib/providers/`)
- **Services:** `lib/services/` — API calls via Dio, offline sync, connectivity detection, background sync, FCM notifications
- **Screens:** `lib/screens/` — organized by feature (auth, home, attendance, payroll, etc.)
- **Config:** `lib/config/api_config.dart` — environment-based API URLs (dev via `--dart-define=DEV_HOST`, prod via `--dart-define=ENV=prod`)
- **Models:** `lib/models/` — data models with JSON serialization

### Key Patterns
- **Payroll variants:** Multiple payroll models/controllers exist for different business units (FNB, HO, Celluller, Hans, MM, Ref, Wrapping)
- **Offline attendance:** Two-track system — "operational" (QR scan at outlet) and "head_office" (GPS). Smart online-first logic with 7s timeout, falls back to local SQLite (`offline_attendance.db`), background sync via WorkManager every 15 min. Max 10 sync retries before a record is marked permanently failed. Photo files stored on disk (not base64 in DB); if photo is deleted before sync, the record is marked as permanent failure via `PhotoFileNotFoundException`.
- **QR attendance:** QR codes use format `OUTLET-{ORG_ID}-LT{FLOOR}-{TIMESTAMP}-{RANDOM}`, validated client-side before offline storage and server-side via `QrCodeValidationService`. Also accepts JSON and pipe-delimited QR formats.
- **Role-based access:** Role model constants control permissions across all layers
- **Device uptime:** Android reads `/proc/uptime` for tampering detection; iOS returns null (server uses timestamp comparison only)

## Security Considerations (from context.md)
- IDOR protection required on sensitive endpoints — `index()` methods must check role before returning other users' data
- Rate limiting on auth endpoints (5/min)
- Upload MIME validation: jpg, jpeg, png only
- Mass assignment protection via `$fillable`
- CSV injection protection via ExcelSanitizer trait
- Mobile uses FlutterSecureStorage for both tokens and user data (PII)
- No `dangerouslySetInnerHTML` in web frontend
- GPS coordinates must be range-validated (`latitude -90..90`, `longitude -180..180`)
- Never expose debug output, stack traces, or script output in API error responses — log server-side only
- CORS restricted to specific methods (`GET, POST, PUT, PATCH, DELETE, OPTIONS`) and headers
- Organization mutations (create/update/delete/reset) require admin roles; reset is super_admin only
- Web auth: zustand persist is the single source of truth for tokens; `api-client.ts` reads from persisted state; legacy `STORAGE_KEYS.TOKEN` synced via subscribe for pages using raw `fetch()`

## Pending Security Work
- **Refresh token rotation:** Reduce Sanctum 7-day TTL to 1-24h, add refresh endpoint + client-side refresh logic
- **SSL certificate pinning (Flutter):** Add via Dio SecurityContext + Android `network_security_config.xml` / iOS `Info.plist`
- **Rate limiting on imports:** Add `throttle` middleware to `/employees/import-master`, `/payroll-*/import` routes
- **Audit logging:** Add cross-cutting audit log (who/what/when/IP) for employee deletion, payroll approval, org changes, role changes
- **BFF proxy for web auth:** Evaluate Next.js API routes as proxy to use httpOnly cookies instead of localStorage tokens

## Environment Setup
- API base URL (dev): `http://localhost:8000/api`
- Web env: `sobat-web/.env.local` sets `NEXT_PUBLIC_API_URL`
- Mobile dev: pass `--dart-define=DEV_HOST=YOUR_LOCAL_IP` to `flutter run`
