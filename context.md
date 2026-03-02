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
- **Primary:** Forest Green `#1A4D2E`.
- **Accent:** Neon Mint `#49FFB8`.
- **Components:** Glassmorphism, Framer Motion, GSAP.
- **Feedback:** SweetAlert2 (Web) & Modern Snackbars (Mobile).

---

## 3. SECURITY & RELIABILITY PROTOCOL (CRITICAL)

### **A. Backend Hardening**
- **Role Constants:** Menggunakan `App\Models\Role` sebagai *Single Source of Truth* untuk pengecekan hak akses (Anti-Hardcoded String).
- **IDOR Protection:** Pengecekan kepemilikan data pada endpoint `show()` dan `update()` untuk Absensi, Payroll, dan Employee (User hanya bisa melihat data milik sendiri).
- **Rate Limiting:** `throttle:login` (5/min) diterapkan pada Login, Register, PIN, dan Forgot Password untuk mencegah Bruteforce & Bot Spamming.
- **MIME Validation:** Validasi ketat `mimes:jpg,jpeg,png` pada seluruh modul upload foto untuk mencegah Remote Code Execution (RCE).
- **Mass Assignment Guard:** Kolom sensitif seperti `role_id` dilindungi dari pengisian masal via request user.
- **CSV Injection Protection:** Implementasi `ExcelSanitizer` trait pada semua modul export untuk menetralkan karakter berbahaya (`=`, `+`, `-`, `@`) di awal sel Excel.
- **Sensitive Log Cleaning:** Pengurangan logging data mentah (`$request->all()`) pada level produksi untuk melindungi data pribadi user di file log server.

### **B. Data & Storage Integrity**
- **Auto-Cleanup:** Menghapus file fisik (Foto/Lampiran) secara otomatis dari storage saat record database dihapus (Absensi/Request).
- **Rounding Logic:** Sinkronisasi pembulatan angka (`round($val, 0)`) antara database dan tampilan PDF untuk mencegah selisih nominal.
- **Geofencing Tolerance:** Penambahan buffer **10 meter** pada koordinat GPS untuk mengakomodasi ketidakteraturan sinyal perangkat mobile.

### **C. Mobile & Web Security**
- **Secure Storage:** Menggunakan `encryptedSharedPreferences` (Android) dengan satu pintu akses via `StorageService`.
- **XSS Guard:** Larangan penggunaan `dangerouslySetInnerHTML` di Frontend; rendering teks dinamis menggunakan metode React yang aman (Dashboard Activity Fix).
- **Sanctum Expiry:** Implementasi `SANCTUM_TOKEN_EXPIRATION` untuk membatasi masa aktif session token.

---

## 4. SYSTEM ARCHITECTURE

### **A. Super Admin (Web Dashboard)**
- **Dashboard:** Real-time analytics dengan proteksi XSS pada Recent Activity.
- **THR Management:** Digital Signature (Locked after first sign) & Bulk Approval.
- **Import Engine:** Optimasi pembacaan file Excel (`readDataOnly`) untuk performa server.

### **B. User / Staff (Mobile App)**
- **Attendance:** GPS Geofencing + Mandatory Selfie (Check-in & Check-out).
- **GPS Safety:** Null-check pada data koordinat sebelum eksekusi API untuk mencegah crash (NPE).
- **Permission UX:** Penanganan status `permanentlyDenied` dengan direct link ke Settings HP.

---

## 5. LATEST PROGRESS (MARCH 2, 2026)
- **Security Audit (Phase 2 Completed):** Penutupan celah CSV Injection, pembersihan log sensitif, dan pengamanan rendering Dashboard.
- **UI/UX Polish:** Implementasi SweetAlert2 di Web dan sinkronisasi timeout API 60 detik.
- **Storage Optimization:** Logika auto-delete file sampah dan kompresi gambar selfie sudah aktif.
- **Role Standardization:** Penyatuan konstanta role di Backend (Role Model) dan Frontend (Config Store).

---

## 6. INFRASTRUCTURE & BUILD COMMANDS

### **Server Side (Production)**
```bash
# Location: /var/www/sobat-hr/sobat-web
npm run build && pm2 restart sobat-web

# Permissions (API)
sudo chown -R www-data:www-data storage bootstrap/cache
sudo chmod -R 775 storage bootstrap/cache
php artisan storage:link
```

### **Mobile Build (Production)**
```bash
# Production Flag (Mandatory)
--dart-define=ENV=prod

# Build Targets
flutter build apk --release --dart-define=ENV=prod
flutter build appbundle --release --dart-define=ENV=prod
```

---
*Last Updated: 2026-03-02 by Giaa (Your AI Bodyguard) 🌸🛡️*