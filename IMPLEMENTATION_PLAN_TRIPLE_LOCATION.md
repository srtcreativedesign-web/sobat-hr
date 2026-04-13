# Implementation Plan: Triple Location Hardcoded Geofencing

## Latar Belakang

Saat ini geofencing terikat ke model `Organization` — setiap organisasi/outlet punya koordinat dan radius sendiri. Pendekatan ini overengineered untuk kebutuhan aktual: **hanya ada 3 lokasi tetap** yang digunakan untuk absensi semua karyawan, tidak peduli organisasi/divisi mana.

**Pendekatan baru:** Hardcode 3 lokasi langsung di kode. Sistem auto-detect lokasi mana yang cocok berdasarkan GPS karyawan. Tidak perlu tabel database baru, tidak perlu admin panel untuk kelola lokasi.

## 3 Lokasi Tetap

| ID | Nama | Latitude | Longitude | Radius (m) |
|----|------|----------|-----------|-------------|
| `office` | Office (Kantor Pusat) | `-6.13778` | `106.62295` | `100` |
| `gudang_b3` | Gudang B3 | `-6.134087` | `106.623301` | `100` |
| `training_centre` | Training Centre | `-6.133417` | `106.629707` | `100` |

> Semua koordinat sudah lengkap. Siap untuk implementasi.

---

## Perubahan yang Diperlukan

### 1. API — Config Lokasi (file baru)

**File:** `sobat-api/config/attendance_locations.php`

Buat config file yang return array 3 lokasi hardcoded:

```php
return [
    'locations' => [
        [
            'id' => 'office',
            'name' => 'Office',
            'latitude' => -6.13778,
            'longitude' => 106.62295,
            'radius_meters' => 100,
        ],
        [
            'id' => 'gudang_b3',
            'name' => 'Gudang B3',
            'latitude' => -6.134087,
            'longitude' => 106.623301,
            'radius_meters' => 100,
        ],
        [
            'id' => 'training_centre',
            'name' => 'Training Centre',
            'latitude' => -6.133417,
            'longitude' => 106.629707,
            'radius_meters' => 100,
        ],
    ],
    'tolerance_meters' => 10,
];
```

Keuntungan config file vs constant di service: bisa di-override via `.env` jika suatu saat koordinat berubah tanpa deploy ulang kode.

---

### 2. API — Update `GeofenceValidationService`

**File:** `sobat-api/app/Services/GeofenceValidationService.php`

Tambah method baru `validateAgainstAllLocations()`:

```php
public function validateAgainstAllLocations(float $lat, float $lng): array
{
    $locations = config('attendance_locations.locations');
    $tolerance = config('attendance_locations.tolerance_meters', 10);]\

    $minDistance = PHP_FLOAT_MAX;
    $nearest = null;

    foreach ($locations as $loc) {
        $distance = $this->calculateDistance($lat, $lng, $loc['latitude'], $loc['longitude']);
        $maxAllowed = $loc['radius_meters'] + $tolerance;

        if ($distance <= $maxAllowed) {
            return [
                'valid' => true,
                'message' => 'Lokasi valid',
                'matched_location' => $loc,
                'data' => [
                    'location_id' => $loc['id'],
                    'location_name' => $loc['name'],
                    'distance_meters' => round($distance, 2),
                    'allowed_radius_meters' => $maxAllowed,
                ],
            ];
        }

        if ($distance < $minDistance) {
            $minDistance = $distance;
            $nearest = $loc;
        }
    }

    return [
        'valid' => false,
        'message' => 'Anda berada di luar jangkauan lokasi yang diizinkan.',
        'matched_location' => null,
        'data' => [
            'nearest_location' => $nearest['name'] ?? null,
            'distance_meters' => round($minDistance, 2),
        ],
    ];
}
```

Method lama (`validate()`, `getDefaultHeadOffice()`) tetap ada untuk backward compatibility tapi tidak lagi dipanggil dari flow absensi utama.

---

### 3. API — Update `AttendanceController::store()`

**File:** `sobat-api/app/Http/Controllers/Api/AttendanceController.php` (sekitar baris 103-143)

**Sebelum (current):**
```php
// Get all locations that have custom geofencing enabled
$locations = \App\Models\Organization::geofencingEnabled()->get();
// ... loop semua org, haversine check ...
```

**Sesudah:**
```php
$geofenceService = app(GeofenceValidationService::class);
$result = $geofenceService->validateAgainstAllLocations(
    $validated['latitude'],
    $validated['longitude']
);

if (!$result['valid']) {
    return response()->json([
        'message' => $result['message'],
        'nearest_location' => $result['data']['nearest_location'],
        'distance' => $result['data']['distance_meters'] . ' meter',
    ], 422);
}

// Simpan info lokasi yang matched
$validated['location_id'] = $result['data']['location_id'];
$validated['location_name'] = $result['data']['location_name'];
```

**Hapus:** Logic loop `Organization::geofencingEnabled()` dan `haversineGreatCircleDistance()` helper dari controller (pindah sepenuhnya ke service).

---

### 4. API — Update `OfflineSyncController::sync()`

**File:** `sobat-api/app/Http/Controllers/Api/OfflineSyncController.php` (sekitar baris 103-152)

Ganti GPS validation block yang saat ini memanggil `getOfficeCoordinates()` + `geofenceService->validate()` menjadi:

```php
$locationValidation = $this->geofenceService->validateAgainstAllLocations(
    $gpsCoords['latitude'],
    $gpsCoords['longitude']
);
```

**Hapus:** Method `getOfficeCoordinates()` yang tidak lagi diperlukan.

---

### 5. API — Migration: Tambah kolom `location_id` di tabel `attendances`

**File baru:** `sobat-api/database/migrations/xxxx_add_location_fields_to_attendances_table.php`

```php
Schema::table('attendances', function (Blueprint $table) {
    $table->string('location_id', 30)->nullable()->after('outlet_id');
    $table->string('location_name', 100)->nullable()->after('location_id');
    $table->index('location_id');
});
```

Kolom `location_id` menyimpan ID lokasi hardcoded (`office`, `gudang_b3`, `training_centre`) agar bisa difilter/dilaporkan.

Update model `Attendance` — tambah `location_id` dan `location_name` ke `$fillable`.

---

### 6. API — Endpoint baru: GET `/attendance/locations`

**File:** `sobat-api/app/Http/Controllers/Api/AttendanceController.php` (method baru)

```php
public function getLocations()
{
    return response()->json([
        'locations' => config('attendance_locations.locations'),
    ]);
}
```

**Route:** Tambah di `routes/api.php`:
```php
Route::get('/attendance/locations', [AttendanceController::class, 'getLocations']);
```

Endpoint ini dipakai mobile app untuk mendapatkan daftar lokasi + koordinat, sehingga kalau lokasi berubah di config, mobile app otomatis ikut tanpa perlu update APK.

---

### 7. Mobile — Fetch lokasi dari API

**File:** `sobat-mobile/lib/services/attendance_service.dart`

Tambah method:
```dart
Future<List<Map<String, dynamic>>> getAttendanceLocations() async {
    final response = await dio.get('/attendance/locations');
    return List<Map<String, dynamic>>.from(response.data['locations']);
}
```

Cache result di memory/SharedPreferences agar bisa dipakai offline.

---

### 8. Mobile — Update `AttendanceScreen`

**File:** `sobat-mobile/lib/screens/attendance/attendance_screen.dart`

#### 8a. Ganti single `_officeLocation` → list of locations

```dart
// Sebelum:
LatLng? _officeLocation;
double _attendanceRadius = 100;

// Sesudah:
List<Map<String, dynamic>> _locations = [];
String? _matchedLocationName; // Nama lokasi terdekat yang valid
```

#### 8b. Update `_initOfficeLocation()` → `_initLocations()`

Fetch dari API endpoint `/attendance/locations`. Fallback ke hardcoded default jika offline dan belum ada cache.

#### 8c. Update `_checkDistance()`

Loop semua lokasi, cek jarak ke masing-masing. Set `_isWithinRange = true` jika user ada di salah satu lokasi. Simpan nama lokasi yang matched ke `_matchedLocationName`.

```dart
void _checkDistance(Position userPos) {
    bool found = false;
    String? matchedName;

    for (final loc in _locations) {
        final distance = Geolocator.distanceBetween(
            userPos.latitude, userPos.longitude,
            loc['latitude'], loc['longitude'],
        );
        if (distance <= loc['radius_meters'] + 10) {
            found = true;
            matchedName = loc['name'];
            break;
        }
    }

    setState(() {
        _isWithinRange = found;
        _matchedLocationName = matchedName;
    });
}
```

#### 8d. Update Map UI

Tampilkan **3 circle geofence** di peta (bukan hanya 1). Masing-masing dengan warna/label berbeda. Circle lokasi yang matched diberi highlight.

#### 8e. Update Status Badge

```
Sebelum: "Di dalam Area Kantor" / "Di Luar Area Kantor"
Sesudah: "Di Area Office" / "Di Area Gudang B3" / "Di Luar Area"
```

---

### 9. Mobile — Update Offline Attendance

**File:** `sobat-mobile/lib/services/offline_attendance_service.dart`

Saat menyimpan offline attendance dengan `track_type = 'head_office'`, sertakan `location_id` dan `location_name` hasil client-side geofence check ke record SQLite (untuk display purpose saja — validasi tetap server-side saat sync).

Tambah kolom `location_id` dan `location_name` ke SQLite schema di `database_helper.dart`.

---

## File yang Diubah (Ringkasan)

| # | File | Aksi | Deskripsi |
|---|------|------|-----------|
| 1 | `sobat-api/config/attendance_locations.php` | **Baru** | Config 3 lokasi hardcoded |
| 2 | `sobat-api/app/Services/GeofenceValidationService.php` | **Edit** | Tambah `validateAgainstAllLocations()` |
| 3 | `sobat-api/app/Http/Controllers/Api/AttendanceController.php` | **Edit** | Ganti logic geofence ke service baru, tambah `getLocations()` |
| 4 | `sobat-api/app/Http/Controllers/Api/OfflineSyncController.php` | **Edit** | Ganti GPS validation ke service baru, hapus `getOfficeCoordinates()` |
| 5 | `sobat-api/app/Models/Attendance.php` | **Edit** | Tambah `location_id`, `location_name` ke `$fillable` |
| 6 | `sobat-api/database/migrations/xxxx_...` | **Baru** | Tambah kolom `location_id`, `location_name` |
| 7 | `sobat-api/routes/api.php` | **Edit** | Tambah route `GET /attendance/locations` |
| 8 | `sobat-mobile/lib/services/attendance_service.dart` | **Edit** | Tambah `getAttendanceLocations()` |
| 9 | `sobat-mobile/lib/screens/attendance/attendance_screen.dart` | **Edit** | Multi-location geofence check + multi-circle map |
| 10 | `sobat-mobile/lib/services/offline_attendance_service.dart` | **Edit** | Simpan `location_id` di offline record |
| 11 | `sobat-mobile/lib/services/database_helper.dart` | **Edit** | Tambah kolom lokasi ke SQLite schema |

---

## Urutan Implementasi

1. **Dapatkan koordinat** — Koordinat GPS dan radius ketiga lokasi harus ditentukan dulu
2. **API config + service** — Buat config file, update `GeofenceValidationService` (step 1-2)
3. **API migration + model** — Buat migration, update model (step 5-6)
4. **API controllers** — Update `AttendanceController` dan `OfflineSyncController` (step 3-4)
5. **API route** — Tambah endpoint `/attendance/locations` (step 7)
6. **Test API** — Pastikan geofence validation bekerja dengan 3 lokasi
7. **Mobile service** — Tambah fetch locations (step 8)
8. **Mobile UI** — Update attendance screen dengan multi-location (step 9)
9. **Mobile offline** — Update SQLite schema dan offline flow (step 10-11)
10. **Integration test** — Test end-to-end: check-in dari masing-masing lokasi + di luar semua lokasi

---

## Yang TIDAK Berubah

- Flow absensi QR (operational track) — tetap pakai `QrCodeValidationService`, tidak terpengaruh
- Face verification — tetap jalan seperti biasa
- Offline sync flow — tetap sama, hanya validasi GPS yang berubah di server
- Timestamp tampering detection — tidak terpengaruh
- Checkout flow — tetap pakai logic yang sama (untuk head_office track, server re-validate lokasi)

---

## Pertimbangan

- **Kenapa hardcode, bukan database?** — Hanya 3 lokasi tetap, tidak perlu CRUD admin. Config file lebih sederhana dan bisa di-override via env jika perlu.
- **Kenapa endpoint API untuk lokasi?** — Agar mobile app tidak perlu update APK kalau koordinat/radius berubah. Config change di server → mobile otomatis dapat data terbaru.
- **Backward compatibility** — Kolom `outlet_id` di attendance tetap ada tapi tidak lagi dipakai untuk geofencing GPS. Kolom baru `location_id` yang dipakai.
- **Toleransi GPS** — Tetap 10 meter buffer di atas radius, sesuai sistem existing.
