# Laporan Harian - 3 Februari 2026

## Ringkasan Pekerjaan

Hari ini fokus pada perbaikan bug dan penambahan fitur di aplikasi **SOBAT HR** (Mobile & Web Admin).

---

## Pekerjaan yang Diselesaikan

### 1. Perbaikan Form Pengajuan Sakit (Mobile)
**Masalah:** Form pengajuan sakit tidak menampilkan field Tanggal dan Upload Surat Dokter.

**Penyebab:** Menu mengirimkan string "Sick Leave" (hasil lokalisasi) ke form, sedangkan logika form mengharapkan string internal "Sakit".

**Solusi:** Mengubah `submission_menu_screen.dart` untuk selalu mengirimkan kode internal ('Cuti', 'Sakit', 'Lembur') terlepas dari bahasa aplikasi.

**File yang diubah:**
- `sobat-mobile/lib/screens/submission/submission_menu_screen.dart`

---

### 2. Menonaktifkan Tombol Wallet di Profile Page (Mobile)
**Permintaan:** Menonaktifkan navigasi tombol wallet di bottom navigation bar pada halaman Profile.

**Solusi:** Menghapus logika navigasi ke `/payroll` pada `onTap` index 3 di `ProfileScreen`.

**File yang diubah:**
- `sobat-mobile/lib/screens/profile/profile_screen.dart`

---

### 3. Menghapus Tombol "Generate PDF" di Dashboard (Web)
**Permintaan:** Menghapus tombol Generate PDF dari tabel "Contract Expiring Soon".

**Solusi:** Menghapus kolom "Action", tombol, dan fungsi `handleGenerateContract` dari dashboard.

**File yang diubah:**
- `sobat-web/src/app/dashboard/page.tsx`

---

### 4. Membulatkan Tampilan Hari Kontrak (Web)
**Masalah:** Jumlah hari tersisa kontrak menampilkan angka desimal panjang (contoh: -26.814783593136575).

**Solusi:** Menggunakan `Math.round()` untuk membulatkan angka menjadi integer.

**File yang diubah:**
- `sobat-web/src/app/dashboard/page.tsx`

---

### 5. Mengaktifkan Ikon Notifikasi Dashboard (Web)
**Permintaan:** Membuat ikon notifikasi (bell) di dashboard dapat diklik dan mengarah ke halaman notifikasi.

**Solusi:**
1. Membuat halaman baru `/notifications` dengan tampilan daftar notifikasi.
2. Fitur: Menampilkan semua notifikasi, highlight notifikasi belum dibaca, tombol "Mark All as Read".
3. Menghubungkan ikon notifikasi di dashboard ke halaman tersebut.

**File yang dibuat:**
- `sobat-web/src/app/notifications/page.tsx`

**File yang diubah:**
- `sobat-web/src/app/dashboard/page.tsx`

---

## Security Review
Halaman notifikasi baru telah diperiksa keamanannya:
- ✅ Autentikasi terverifikasi sebelum fetch data
- ✅ Handler 401 redirect ke login
- ✅ Backend menggunakan Laravel guards (data hanya milik user yang login)
- ✅ Tidak ada XSS vulnerability (menggunakan React escaping)
- ✅ Proteksi IDOR pada mark-as-read

---

## Status
Semua pekerjaan telah selesai dan siap untuk testing.
