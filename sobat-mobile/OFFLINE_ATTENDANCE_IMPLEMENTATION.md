# Offline Attendance Implementation Summary

## 📋 Overview

Implemented a **Hybrid Offline Attendance System** for SOBAT HR that supports both:
- **Operational Track** (Outlet employees): QR Code + Selfie validation
- **Head Office Track** (Office employees): GPS + Selfie validation

The system uses **Store-and-Forward** architecture - data is saved locally when offline and automatically synced to the server when internet is available.

---

## ✅ Completed Implementation

### **Backend (Laravel API)**

#### 1. Database Migrations
- `2026_03_16_000001_add_offline_fields_to_attendances_table.php`
  - Added fields: `track_type`, `validation_method`, `is_offline`, `qr_code_data`, `outlet_id`, `floor_number`, `device_timestamp`, `server_timestamp`, `time_discrepancy_seconds`, `device_id`, `device_uptime_seconds`, `review_status`, `review_notes`

- `2026_03_16_000002_create_qr_code_locations_table.php`
  - Master table for QR code locations per outlet/floor

- `2026_03_16_000003_add_track_type_to_users_and_employees.php`
  - Added `track_type` field to differentiate HO vs Operational employees

#### 2. Models
- `app/Models/QrCodeLocation.php` - QR code location master model

#### 3. Services
- `app/Services/QrCodeValidationService.php` - Validates QR codes against master data
- `app/Services/GeofenceValidationService.php` - Validates GPS coordinates against office geofence
- `app/Services/TimestampTamperingDetectionService.php` - Detects time manipulation attempts

#### 4. Controllers
- `app/Http/Controllers/Api/OfflineSyncController.php`
  - `sync()` - Main offline attendance submission endpoint
  - `getOfflineSubmissions()` - Admin view of offline submissions
  - `reviewSubmission()` - Admin approve/reject submissions
  - `getStatistics()` - Dashboard statistics
  - `generateQrCodes()` - Generate QR codes for outlets
  - `getQrCodes()` - List/manage QR codes

#### 5. API Routes
```php
POST   /api/attendance/offline-sync                      // Submit offline attendance
GET    /api/attendance/offline-submissions               // Admin: List submissions
POST   /api/attendance/offline-submissions/{id}/review   // Admin: Review submission
GET    /api/attendance/offline-statistics                // Admin: Statistics
POST   /api/attendance/generate-qr-codes                 // Admin: Generate QR codes
GET    /api/attendance/qr-codes                          // Admin: List QR codes
```

---

### **Mobile (Flutter)**

#### 1. Dependencies Added (pubspec.yaml)
```yaml
sqflite: ^2.3.0           # Local SQLite database
mobile_scanner: ^3.4.0    # QR code scanning
workmanager: ^0.5.1       # Background sync service
connectivity_plus: ^5.0.2 # Internet connectivity monitoring
```

#### 2. Services
- `lib/services/database_helper.dart` - SQLite database helper for offline queue
- `lib/services/connectivity_service.dart` - Internet connectivity monitoring
- `lib/services/offline_attendance_service.dart` - Offline attendance operations
- `lib/services/background_sync_service.dart` - WorkManager background sync

#### 3. Models
- `lib/models/offline_attendance.dart` - Offline attendance data model

#### 4. Screens
- `lib/screens/attendance/offline_qr_scanner_screen.dart` - QR code scanner for operational track
- `lib/screens/attendance/offline_selfie_screen.dart` - Universal selfie camera
- `lib/screens/attendance/offline_attendance_handler.dart` - Offline flow orchestrator

#### 5. App Initialization
- Updated `lib/main.dart` to initialize:
  - `ConnectivityService` - Monitors internet status
  - `initializeBackgroundSync()` - Background sync every 15 minutes

---

## 🏗️ System Architecture

### Data Flow

```
┌─────────────────────────────────────────────────────────────┐
│  USER PRESSES ABSEN                                         │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│  CHECK INTERNET CONNECTION                                  │
└────────────────────┬────────────────────────────────────────┘
                     │
         ┌───────────┴───────────┐
         │                       │
    ✅ ONLINE               ❌ OFFLINE
         │                       │
         │                       ▼
         │            ┌─────────────────────────┐
         │            │ DETERMINE TRACK TYPE    │
         │            │ - head_office           │
         │            │ - operational           │
         │            └───────────┬─────────────┘
         │                        │
         │           ┌────────────┴────────────┐
         │           │                         │
         │    ┌──────▼──────┐          ┌──────▼──────┐
         │    │ HEAD OFFICE │          │ OPERATIONAL │
         │    │   (GPS)     │          │  (QR Code)  │
         │    └──────┬──────┘          └──────┬──────┘
         │           │                         │
         └───────────┴────────────┬────────────┘
                                  │
                                  ▼
┌─────────────────────────────────────────────────────────────┐
│  TAKE SELFIE (Front Camera, Wide Angle)                     │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│  ENCRYPT & SAVE TO SQLite                                   │
│  - Photo (Base64)                                           │
│  - Metadata (QR/GPS, Timestamp, Device ID)                  │
│  - Status: is_synced = 0                                    │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│  SHOW SUCCESS: "Absen Disimpan"                             │
│  Background sync will handle the rest                       │
└─────────────────────────────────────────────────────────────┘
                     │
                     │ (When internet detected)
                     ▼
┌─────────────────────────────────────────────────────────────┐
│  WORKMANAGER (Every 15 minutes)                             │
│  - Check connectivity                                       │
│  - Get unsynced records                                     │
│  - Send to server one by one                                │
│  - Mark as synced on success                                │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│  LARAVEL API: /api/attendance/offline-sync                  │
│  1. Validate device ID                                      │
│  2. Validate QR/GPS                                         │
│  3. Detect timestamp tampering                              │
│  4. Save photo                                              │
│  5. Create attendance record                                │
│  6. Flag for review if anomalies                            │
└─────────────────────────────────────────────────────────────┘
```

---

## 🔒 Fraud Prevention

| Layer | Implementation | Applies To |
|-------|---------------|------------|
| **Device ID Lock** | One account = One registered device | All tracks |
| **Timestamp Tampering Detection** | Compare device time vs server time (±5 min tolerance) | All tracks |
| **Device Uptime Tracking** | Track time since boot to detect clock changes | All tracks |
| **QR Code Validation** | Match against master outlet/floor database | Operational only |
| **GPS Geofence** | Validate coordinates within office radius | HO only |
| **Liveness Detection** | Wide-angle selfie showing work environment | All tracks |
| **Review Queue** | HR can review flagged submissions | All tracks |

---

## 📱 User Flow

### Operational Track (Outlet)
1. User opens attendance screen
2. System detects **no internet** + **operational track**
3. Shows offline instructions dialog
4. User clicks "Mulai Absen"
5. **QR Scanner opens** → User scans QR code on wall
6. **Selfie camera opens** → User takes photo with store background
7. Data encrypted and saved to SQLite
8. Success message: "Absensi berhasil disimpan! Data akan otomatis terkirim saat ada internet."

### Head Office Track
1. User opens attendance screen
2. System detects **no internet** + **head_office track**
3. Shows offline instructions dialog
4. User clicks "Mulai Absen"
5. **GPS captured** automatically
6. **Selfie camera opens** → User takes photo
7. Data encrypted and saved to SQLite
8. Success message (same as above)

### Background Sync
1. WorkManager runs every 15 minutes
2. Checks for internet connectivity
3. If online, gets all unsynced records
4. Sends to server one by one
5. Marks as synced on success
6. Cleans up old records (>7 days)

---

## 🚀 Deployment Steps

### 1. Backend Setup
```bash
cd sobat-hr/sobat-api

# Run migrations
php artisan migrate

# Generate QR codes for all outlets
# (Call the API endpoint or create a seeder)
curl -X POST http://localhost:8000/api/attendance/generate-qr-codes \
  -H "Authorization: Bearer YOUR_ADMIN_TOKEN"
```

### 2. Mobile Setup
```bash
cd sobat-hr/sobat-mobile

# Install dependencies
flutter pub get

# For Android, ensure minimum SDK version is 21+
# (Required by workmanager and mobile_scanner)

# Build and run
flutter run
```

### 3. QR Code Printing
1. Call `/api/attendance/qr-codes` to get all QR codes
2. Export to CSV/Excel
3. Print QR codes with labels (e.g., "OUTLET-CKG-LT1")
4. Laminate and stick at each outlet floor

### 4. Employee Track Assignment
Update `users` and `employees` tables with correct `track_type`:
```sql
-- Example: Set all outlet employees to operational
UPDATE employees e
JOIN organizations o ON e.department = o.name
SET e.track_type = 'operational'
WHERE o.type IN ('outlet', 'branch');

-- Head office remains as 'head_office' (default)
```

---

## 🧪 Testing Checklist

### Backend
- [ ] Run migrations successfully
- [ ] Test QR code validation service
- [ ] Test GPS geofence validation
- [ ] Test timestamp tampering detection
- [ ] Test offline sync endpoint with Postman
- [ ] Test admin review endpoints
- [ ] Test QR code generation

### Mobile
- [ ] Test QR scanner (operational track)
- [ ] Test GPS capture (HO track)
- [ ] Test selfie camera
- [ ] Test offline storage (SQLite)
- [ ] Test background sync (wait 15 min or trigger manually)
- [ ] Test sync with various network conditions
- [ ] Test device ID lock (try login on different device)

### Integration
- [ ] End-to-end offline flow (no internet → scan/take photo → save → sync)
- [ ] Admin can view offline submissions
- [ ] Admin can approve/reject submissions
- [ ] Statistics show correct data

---

## 📝 API Payload Examples

### Submit Offline Attendance
```json
POST /api/attendance/offline-sync
Authorization: Bearer {token}

{
  "employee_id": 123,
  "track_type": "operational",
  "validation_method": "qr_code",
  "qr_code_data": "OUTLET-1-LT1-1710590000-ABC1",
  "photo_base64": "data:image/jpeg;base64,/9j/4AAQSkZJRg...",
  "device_timestamp": "2026-03-16T08:00:00.000Z",
  "device_id": "abc123xyz",
  "device_uptime_seconds": 3600,
  "attendance_type": "office"
}
```

### Response
```json
{
  "success": true,
  "message": "Attendance synced successfully",
  "data": {
    "attendance_id": 456,
    "review_status": "approved",
    "requires_review": false
  }
}
```

---

## ⚠️ Known Limitations

1. **Device Uptime**: Currently returns `null` on Flutter side (requires native code for accurate reading)
2. **Background Sync Interval**: Minimum 15 minutes on Android (OS limitation)
3. **Photo Size**: Base64 encoding increases size - consider compression for production
4. **iOS Background Sync**: WorkManager is Android-only; iOS requires different approach (BackgroundTasks)

---

## 🔧 Future Enhancements

1. **Native Device Uptime**: Platform channel to get actual boot time
2. **Batch Sync**: Send multiple records in one request
3. **Photo Compression**: Better compression algorithm for base64
4. **iOS Background Tasks**: Implement BackgroundTasks framework for iOS
5. **QR Code Generator UI**: In-app QR code generation and printing
6. **Offline Dashboard**: Show pending offline submissions count in app

---

## 📞 Support

For issues or questions:
- Check logs: `storage/logs/laravel.log` (backend)
- Debug prints: Check Flutter console (mobile)
- Database: Inspect `offline_attendance.db` (mobile, in app documents folder)

---

**Implementation Date:** March 16, 2026  
**Status:** Core features complete, ready for testing  
**Next Steps:** Integration testing, QR code printing, employee track assignment
