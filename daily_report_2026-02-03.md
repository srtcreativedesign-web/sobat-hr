Laporan Harian - 3 Februari 2026

Ringkasan Pekerjaan

Hari ini fokus pada perbaikan bug dan penambahan fitur di aplikasi SOBAT HR (Mobile & Web Admin).

--------------------------------------------------------------------------------

Pekerjaan yang Diselesaikan

1. Perbaikan Form Pengajuan Sakit (Mobile)
Masalah: Form pengajuan sakit tidak menampilkan field Tanggal dan Upload Surat Dokter.

Penyebab: Menu mengirimkan string "Sick Leave" (hasil lokalisasi) ke form, sedangkan logika form mengharapkan string internal "Sakit".

Solusi: Mengubah submission_menu_screen.dart untuk selalu mengirimkan kode internal ('Cuti', 'Sakit', 'Lembur') terlepas dari bahasa aplikasi.

File yang diubah:
- sobat-mobile/lib/screens/submission/submission_menu_screen.dart

--------------------------------------------------------------------------------

2. Menonaktifkan Tombol Wallet di Profile Page (Mobile)
Permintaan: Menonaktifkan navigasi tombol wallet di bottom navigation bar pada halaman Profile.

Solusi: Menghapus logika navigasi ke /payroll pada onTap index 3 di ProfileScreen.

File yang diubah:
- sobat-mobile/lib/screens/profile/profile_screen.dart

--------------------------------------------------------------------------------

3. Menghapus Tombol "Generate PDF" di Dashboard (Web)
Permintaan: Menghapus tombol Generate PDF dari tabel "Contract Expiring Soon".

Solusi: Menghapus kolom "Action", tombol, dan fungsi handleGenerateContract dari dashboard.

File yang diubah:
- sobat-web/src/app/dashboard/page.tsx

--------------------------------------------------------------------------------

4. Membulatkan Tampilan Hari Kontrak (Web)
Masalah: Jumlah hari tersisa kontrak menampilkan angka desimal panjang (contoh: -26.814783593136575).

Solusi: Menggunakan Math.round() untuk membulatkan angka menjadi integer.

File yang diubah:
- sobat-web/src/app/dashboard/page.tsx

--------------------------------------------------------------------------------

5. Mengaktifkan Ikon Notifikasi Dashboard (Web)
Permintaan: Membuat ikon notifikasi (bell) di dashboard dapat diklik dan mengarah ke halaman notifikasi.

Solusi:
1. Membuat halaman baru /notifications dengan tampilan daftar notifikasi.
2. Fitur: Menampilkan semua notifikasi, highlight notifikasi belum dibaca, tombol "Mark All as Read".
3. Menghubungkan ikon notifikasi di dashboard ke halaman tersebut.

File yang dibuat:
- sobat-web/src/app/notifications/page.tsx

File yang diubah:
- sobat-web/src/app/dashboard/page.tsx

--------------------------------------------------------------------------------

6. Redesign Kartu Absensi (Mobile)
Permintaan: Mengubah desain kartu absensi di attendance_screen.dart agar seragam dengan desain di Home Screen (Gradient, Glassmorphism, Tombol Putih).

Solusi:
1. Mengubah background container menjadi Gradient.
2. Menambahkan efek Glassmorphism.
3. Memaksa tombol "Masuk" dan "Pulang" berwarna putih (text dark) baik saat aktif maupun disabled (disabledBackgroundColor: Colors.white).

File yang diubah:
- sobat-mobile/lib/screens/attendance/attendance_screen.dart

--------------------------------------------------------------------------------

7. Perbaikan Bug Update Tanggal Lahir (Mobile & Backend)
Masalah: Tanggal lahir tidak tersimpan atau tidak muncul setelah update profil.

Akar Masalah:
1. Backend: EmployeeResource mencoba membaca property $this->date_of_birth yang tidak ada (seharusnya $this->birth_date), sehingga API mengembalikan null.
2. Backend: Salah mapping field base_salary (seharusnya basic_salary) dan contract_type (seharusnya employment_status).
3. Frontend: Format tanggal yang dikirim ke API mengandung waktu (ISO8601), disederhanakan menjadi yyyy-MM-dd.

Solusi:
1. Memperbaiki mapping field di EmployeeResource.php.
2. Update EditProfileScreen.dart untuk force refresh data dari server saat halaman dibuka.
3. Update format pengiriman tanggal menjadi yyyy-MM-dd.

File yang diubah:
- sobat-api/app/Http/Resources/EmployeeResource.php
- sobat-mobile/lib/screens/profile/edit_profile_screen.dart

--------------------------------------------------------------------------------

8. Perbaikan Layar Feedback (Mobile)
Masalah: Error compile Target of URI doesn't exist 'package:http/http.dart' pada feedback_screen.dart.

Solusi: Migrasi logika upload file dari library http (yang tidak terinstall) ke library Dio (yang sudah digunakan di project), serta memperbaiki import dart:io yang hilang.

File yang diubah:
- sobat-mobile/lib/screens/feedback/feedback_screen.dart

--------------------------------------------------------------------------------

Security Review
Halaman notifikasi baru telah diperiksa keamanannya:
- [v] Autentikasi terverifikasi sebelum fetch data
- [v] Handler 401 redirect ke login
- [v] Backend menggunakan Laravel guards (data hanya milik user yang login)
- [v] Tidak ada XSS vulnerability (menggunakan React escaping)
- [v] Proteksi IDOR pada mark-as-read

--------------------------------------------------------------------------------

Status
Semua pekerjaan telah selesai dan siap untuk testing.
