# PROJECT BLUEPRINT: SOBAT (Smart Operations & Business Administrative Tool)

## 1. PROJECT OVERVIEW
**Goal:** Membangun sistem HRIS End-to-End dengan UI/UX Modern & Interaktif.
**Developer Mode:** Solo Developer (Speed Run).

### Tech Stack (Confirmed):
- **Backend API:** Laravel 11 (PHP) - Mature, Secure (Sanctum), Robust Payroll & Queue.
- **Web Admin Frontend:** Next.js 15 (App Router) + TypeScript.
- **Mobile Apps:** Flutter (v3.10+).
- **Database:** MySQL.
- **Integration:** Firebase (FCM), GPS Geofencing, Biometric, PDF Generator.

---

## 2. MODERN UI/UX DESIGN SYSTEM
**Design Philosophy:** "Premium, Clean, & Dynamic" (Vercel/Linear Style).
- **Primary:** Forest Green `#1A4D2E` (Solid, Trustworthy).
- **Secondary/UI:** Mint Theme `#a9eae2` (Primary Light).
- **Accent/Neon:** Neon Mint `#49FFB8` (Highlights, Glow Effects).
- **Glassmorphism:** `bg-white/95` or `bg-black/50` with `backdrop-blur-md`.

---

## 3. SECURITY & RELIABILITY PROTOCOL (CRITICAL)

### **A. Secure Storage Protocol (Mobile)**
- **Standard:** Semua data sensitif (Token, User Data) wajib diakses melalui `StorageService`.
- **Encryption:** Menggunakan `FlutterSecureStorage` dengan opsi `encryptedSharedPreferences: true` di Android.
- **Error Handling:** Implementasi `try-catch` (BadPaddingException guard) di `StorageService.getToken()` untuk mencegah crash akibat Keystore mismatch.
- **Single Source of Truth:** Semua Service (Attendance, Notification, Request) **DILARANG** menggunakan instance `FlutterSecureStorage` lokal; wajib memanggil `StorageService.getToken()`.

### **B. Production Guard**
- **Environment Logic:** Menggunakan `ApiConfig` yang ketat. Release build **WAJIB** menggunakan `--dart-define=ENV=prod`.
- **ProGuard:** Implementasi `proguard-rules.pro` untuk menjaga integritas model data (mencegah field name obfuscation pada JSON parsing).
- **Null-Safety:** Parsing JSON pada model (`User.dart`) menggunakan metode `.toString()` dan pengecekan null eksplisit untuk mencegah NPE.

---

## 4. SYSTEM ARCHITECTURE

### **A. Super Admin (Web Dashboard - Next.js)**
- **Payroll Engine:** STRICT Passive Storage. Data diimpor dari Excel 100% dipercaya (Zero Logic Calculation di System).
- **Organization:** Dynamic Parent-Child Hierarchy (CEO -> Holdings -> Departments).

### **B. User / Staff (Mobile App - Flutter)**
- **Attendance:** GPS Geofencing (Office vs Field Mode). Memerlukan koordinat Lat/Long dan Foto Selfie.
- **ESS Module:** Sick Leave (Camera), Asset Request, Overtime, Download Payslip (PDF).
- **Security:** PIN Screen, Biometric (Face/Fingerprint), FCM Push Notifications.

---

## 5. LATEST PROGRESS (MARCH 2026)
- **Security Hardening (Completed):** Refactoring `NotificationService`, `AttendanceService`, dan `RequestService` untuk standardisasi Secure Storage.
- **NPE Guard (Completed):** Perbaikan parsing model `User.dart` dan penambahan pengecekan null pada GPS `AttendanceScreen`.
- **Deployment Ready:** Build commands untuk APK & AAB sudah diverifikasi menggunakan flag `ENV=prod`.
- **Next To-Do:** Implementasi `cached_network_image` untuk optimasi loading gambar dan Finalize Permission/Role Granularity.

---

## 6. INFRASTRUCTURE & BUILD COMMANDS

### **Server Side (Production)**
```bash
# Location: /var/www/sobat-hr/sobat-web
npm run build && pm2 restart sobat-web

# Permissions (API)
sudo chown -R www-data:www-data storage bootstrap/cache
sudo chmod -R 775 storage bootstrap/cache
```

### **Mobile Build (Production)**
```bash
# Run Production
flutter run --release --dart-define=ENV=prod

# Build APK
flutter build apk --release --dart-define=ENV=prod

# Build AAB (Play Store)
flutter build appbundle --release --dart-define=ENV=prod
```

---
*Last Updated: 2026-03-02 by Giaa 🌸*