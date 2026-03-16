# Quick Start Guide: Testing Offline Attendance

## Prerequisites

1. Backend server running (Laravel API)
2. Mobile app installed on device/emulator
3. Admin access for QR code generation

---

## Step 1: Run Backend Migrations

```bash
cd /Applications/XAMPP/xamppfiles/htdocs/sobat-hr/sobat-api

# Run database migrations
php artisan migrate
```

Expected output:
```
INFO  Migrated: 2026_03_16_000001_add_offline_fields_to_attendances_table
INFO  Migrated: 2026_03_16_000002_create_qr_code_locations_table
INFO  Migrated: 2026_03_16_000003_add_track_type_to_users_and_employees
```

---

## Step 2: Generate QR Codes for Outlets

```bash
# Make sure your API is running
# Then call the QR generation endpoint

# Option A: Using curl
curl -X POST http://localhost:8000/api/attendance/generate-qr-codes \
  -H "Authorization: Bearer YOUR_ADMIN_TOKEN" \
  -H "Accept: application/json"

# Option B: Using Laravel Tinker
php artisan tinker
>>> $service = new \App\Services\QrCodeValidationService();
>>> $service->batchGenerateForOutlets();
```

Save the QR codes output - you'll need them for testing.

---

## Step 3: Install Mobile Dependencies

```bash
cd /Applications/XAMPP/xamppfiles/htdocs/sobat-hr/sobat-mobile

# Install new packages
flutter pub get

# If you encounter issues, clean first
flutter clean
flutter pub get
```

---

## Step 4: Assign Track Type to Test User

```sql
-- In your database management tool (phpMyAdmin, TablePlus, etc.)

-- Find your test user's employee_id first
SELECT id, user_id, full_name, email FROM employees WHERE email = 'your.test@email.com';

-- Set track type (choose one)
-- For Operational testing:
UPDATE employees SET track_type = 'operational' WHERE user_id = YOUR_USER_ID;

-- For Head Office testing:
UPDATE employees SET track_type = 'head_office' WHERE user_id = YOUR_USER_ID;

-- Also update users table
UPDATE users SET track_type = 'operational' WHERE id = YOUR_USER_ID;
```

---

## Step 5: Build and Run Mobile App

```bash
# For Android
flutter run

# For testing on real device (recommended for GPS/QR)
# Make sure USB debugging is enabled
```

---

## Step 6: Test Offline Attendance Flow

### Test 1: Operational Track (QR Code)

1. **Prepare:**
   - Print or display the QR code from Step 2
   - Turn on Airplane mode (no internet)

2. **Open App:**
   - Login with test user
   - Go to Attendance (Presensi)

3. **Start Offline Flow:**
   - App should detect no internet
   - Shows "Mode Offline - Outlet" dialog
   - Click "Mulai Absen"

4. **Scan QR Code:**
   - Point camera at QR code
   - Wait for beep/vibration
   - Should auto-proceed to selfie

5. **Take Selfie:**
   - Front camera opens
   - Take photo with background visible
   - Wait for "Menyimpan..."

6. **Verify:**
   - Should see success message
   - Check SQLite: Data saved locally

7. **Test Sync:**
   - Turn off Airplane mode
   - Wait 15 minutes OR trigger sync manually
   - Check backend: Data should appear in `attendances` table

### Test 2: Head Office Track (GPS)

1. **Prepare:**
   - Turn on Airplane mode
   - Make sure GPS is enabled

2. **Set Track:**
   - Update user to `head_office` track (Step 4)

3. **Open App:**
   - Go to Attendance

4. **Start Offline Flow:**
   - Shows "Mode Offline - Kantor" dialog
   - Click "Mulai Absen"

5. **GPS Capture:**
   - App gets GPS coordinates
   - May take a few seconds

6. **Take Selfie:**
   - Same as operational track

7. **Verify:**
   - Success message
   - Data saved locally

---

## Step 7: Verify Backend Data

```sql
-- Check offline submissions
SELECT 
    id,
    employee_id,
    track_type,
    validation_method,
    is_offline,
    review_status,
    device_timestamp,
    server_timestamp,
    time_discrepancy_seconds
FROM attendances
WHERE is_offline = TRUE
ORDER BY device_timestamp DESC;

-- Check QR code locations
SELECT * FROM qr_code_locations;
```

---

## Step 8: Test Admin Features

### View Offline Submissions
```bash
curl http://localhost:8000/api/attendance/offline-submissions \
  -H "Authorization: Bearer YOUR_ADMIN_TOKEN"
```

### Review Submission
```bash
curl -X POST http://localhost:8000/api/attendance/offline-submissions/123/review \
  -H "Authorization: Bearer YOUR_ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "review_status": "approved",
    "review_notes": "Test approval"
  }'
```

### Get Statistics
```bash
curl http://localhost:8000/api/attendance/offline-statistics \
  -H "Authorization: Bearer YOUR_ADMIN_TOKEN"
```

---

## Troubleshooting

### Mobile: "No unsynced records" but data exists
```dart
// Check database directly
// Use Device File Explorer (Android Studio)
// Navigate to: /data/data/co.sobat.sobat_hr/databases/offline_attendance.db
// Open with DB Browser for SQLite
```

### Backend: Sync fails with 401
```bash
# Token might be expired
# Login again to get fresh token
curl -X POST http://localhost:8000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@sobat.co.id","password":"password123"}'
```

### QR Scanner not working
- Check camera permissions
- Ensure QR code is well-lit
- Try different distance (15-30cm)

### GPS not working
- Enable location services
- Check permission in Android settings
- Try outdoors for better signal

### Background sync not running
```bash
# Check WorkManager status (Android)
adb shell dumpsys jobscheduler | grep sobat_hr

# Force sync (development only)
# In Flutter code, call triggerImmediateSync()
```

---

## Debug Tips

### Mobile Logs
```bash
# Run app with verbose logging
flutter run --verbose

# Filter for offline attendance logs
flutter run 2>&1 | grep -i "offline"
```

### Backend Logs
```bash
# Tail Laravel logs
tail -f storage/logs/laravel.log | grep -i "offline"
```

### Database Inspection
```bash
# SQLite command line (mobile)
adb shell
cd /data/data/co.sobat.sobat_hr/databases/
sqlite3 offline_attendance.db

# Query
SELECT * FROM offline_attendances;
```

---

## Expected Results

✅ **Successful Test:**
- Offline attendance saved locally
- Auto-synced when internet available
- Appears in backend `attendances` table
- `is_offline = 1`, `review_status = 'approved'`
- Photo saved in `storage/app/public/attendance_photos/offline/`

❌ **Common Issues:**
- Sync fails: Check token, internet, server logs
- QR not scanning: Check permission, lighting
- GPS timeout: Move outdoors, enable high accuracy

---

**Testing Date:** March 16, 2026  
**Version:** 1.0.0  
**Status:** Ready for QA testing
