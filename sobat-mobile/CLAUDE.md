# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

See also: `../CLAUDE.md` for full-system architecture (API, Web, Mobile).

## Commands

```bash
flutter pub get                                              # Install deps
flutter run --dart-define=DEV_HOST=YOUR_IP                   # Dev run (pass local IP)
flutter run --dart-define=ENV=prod                           # Run against production API
flutter test                                                 # Run tests
flutter analyze                                              # Static analysis
flutter build apk --release --dart-define=ENV=prod           # Android APK
flutter build appbundle --release --dart-define=ENV=prod     # Android AAB
flutter build ios --release --dart-define=ENV=prod           # iOS
flutter clean && flutter pub get                             # Clean rebuild (fixes Gradle/pod issues)
```

Firebase changes require a full app stop and re-run (hot restart is not enough).

## Architecture

### Entry Point & Routing
`lib/main.dart` — Firebase init, Provider setup, global error handling, named route table. App flow: OnboardingScreen → WelcomeScreen/LoginScreen → HomeScreen. Routes are string-based (`/home`, `/payroll`, `/attendance`, etc.) defined in `MaterialApp.routes`.

### State Management
Provider pattern with two root providers in `MultiProvider`:
- **AuthProvider** (`lib/providers/auth_provider.dart`) — login state, token lifecycle, user data
- **LocaleProvider** (`lib/providers/locale_provider.dart`) — i18n (en/id), persisted via SharedPreferences

### Service Layer (`lib/services/`)
All API services extend **`BaseService`** (`base_service.dart`), which:
- Creates Dio via `DioFactory` with base URL from `ApiConfig`
- Auto-attaches Bearer token from `StorageService` on every request
- Auto-clears storage on 401 responses (force logout)

Key services:
| Service | Purpose |
|---------|---------|
| `auth_service.dart` | Login, logout, profile, FCM token |
| `attendance_service.dart` | Check-in/out, attendance history |
| `offline_attendance_service.dart` | SQLite offline queue, sync with retries |
| `background_sync_service.dart` | WorkManager periodic sync (every 15 min) |
| `connectivity_service.dart` | Network state monitoring |
| `storage_service.dart` | FlutterSecureStorage wrapper for token/user (static methods) |
| `database_helper.dart` | SQLite (`offline_attendance.db`) setup |
| `notification_service.dart` | FCM + flutter_local_notifications |
| `security_service.dart` | Device security checks |
| `update_service.dart` | In-app update prompts |

### Config (`lib/config/`)
- **`api_config.dart`** — Environment switching via `--dart-define`. Endpoints as static const strings. `getStorageUrl()` helper for file URLs.
- **`dio_factory.dart`** — Centralized Dio creation with SSL validation (platform cert store, no cert bypass).
- **`theme.dart`** — `AppTheme` with brand colors (Deep Blue `#1C3ECA` primary, Soft Blue `#60A5FA` secondary), status colors, attendance gradients. Uses Google Fonts. Legacy aliases `colorCyan`/`colorEggplant` map to new palette.
- **`divisions_config.dart`** — Business division constants.

### Screens (`lib/screens/`)
Organized by feature: `auth/`, `home/`, `attendance/`, `payroll/`, `submission/`, `profile/`, `approval/`, `announcement/`, `notification/`, `onboarding/`, `security/`, `settings/`, `feedback/`.

### Models (`lib/models/`)
- `user.dart` — User model with JSON serialization
- `offline_attendance.dart` — Offline attendance record for SQLite queue

### Widgets (`lib/widgets/`)
Shared widgets: `custom_navbar.dart` (bottom nav), `submission_card.dart`.

### Localization
Flutter gen-l10n with `l10n.yaml`. ARB files in `lib/l10n/`. Supported: English (`en`), Indonesian (`id`). Access via `AppLocalizations.of(context)`.

## Key Patterns

- **Offline-first attendance:** Online attempt with 7s timeout → falls back to local SQLite → WorkManager syncs every 15 min. Max 10 retries before permanent failure. Photo stored as file on disk; missing photo = permanent failure (`PhotoFileNotFoundException`).
- **Singleton services:** `OfflineAttendanceService`, `ConnectivityService`, `DatabaseHelper` use factory constructor singleton pattern.
- **Storage:** Tokens and user PII in `FlutterSecureStorage` (encrypted). Preferences (locale, onboarding flag) in `SharedPreferences`. Offline attendance in SQLite.
- **Error handling:** Three-layer global error capture in `main.dart` (ErrorWidget.builder, FlutterError.onError, PlatformDispatcher.onError) funneled through `AppErrorHandler`.
- **Edge-to-edge:** Android 15+ (SDK 35) edge-to-edge display mode enabled at startup.

## Environment Configuration

Dev API URL is derived from `DEV_HOST` dart-define (default `192.168.1.12`, port `8000`). Production triggers on `--dart-define=ENV=prod` OR release mode builds. See `api_config.dart` for full logic.

## Dependencies of Note

- **Dio** for HTTP (not `http` package, except in offline sync which uses `http` directly)
- **google_mlkit_face_detection** for face enrollment auto-capture
- **mobile_scanner** for QR code scanning
- **flutter_map + latlong2** for maps (not Google Maps)
- **geolocator + geocoding** for GPS
- **camera** for photo capture
- **workmanager** for background tasks
- **sqflite** for local SQLite
- **awesome_dialog** for dialog popups
