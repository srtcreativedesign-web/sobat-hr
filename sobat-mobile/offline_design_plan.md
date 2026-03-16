TO DO LIST IMPLEMENTASI ABSENSI OFFLINE (SISTEM GLOBAL)

CATATAN PENTING:
Sistem "Offline" (Simpan-Kirim) kini berlaku untuk SELURUH karyawan (HO & Operasional).
Perbedaan hanya terletak pada metode validasi lokasinya:
- Track Operasional: Validasi menggunakan SCAN QR CODE + SELFIE.
- Track Head Office: Validasi menggunakan KOORDINAT GPS + SELFIE.

BAGIAN 1: FLUTTER (MOBILE APP)
1. Penyesuaian UI Dashboard: Pesan "Mode Offline Aktif" muncul untuk semua user saat internet mati.
2. Inisialisasi SQLite secara global untuk menampung antrian (queue) absen dari semua track.
3. Logika Validasi Berdasarkan Track:
   - IF operational: Buka Kamera Scanner QR.
   - IF head_office: Ambil koordinat GPS terakhir yang tersedia (Last Known Location).
4. Kamera Selfie Universal: Semua absen offline wajib ambil foto (untuk bukti kehadiran fisik).
5. Mekanisme Enkripsi: Mengunci metadata (QR atau GPS) bersamaan dengan foto dan jam internal.
6. Background Sync Manager: Service otomatis yang memantau internet dan mengirim antrian SQLite ke server.

BAGIAN 2: LARAVEL (API SERVER)
1. Update endpoint POST /api/attendance/offline-sync:
   - Tambahkan field validation_method (qr_code atau gps).
   - Tambahkan field gps_coordinates (latitude, longitude) untuk HO.
2. Logika validasi server:
   - Jika QR: Cocokkan dengan master QR outlet.
   - Jika GPS: Cek radius (geofence) seperti absensi online biasa.
3. Integrasi log audit: Menandai absen sebagai "Offline Created" di dashboard admin.

BAGIAN 3: OPERASIONAL
1. Setup master data koordinat GPS untuk kantor pusat (Head Office).
2. Cetak & tempel stiker QR Code khusus hanya di outlet-outlet operasional.

============================================================

DESIGN SYSTEM PLAN (ARSITEKTUR HYBRID OFFLINE)

KONSEP UTAMA
Aplikasi Sobat HR kini bersifat "Offline-First". Setiap kali tombol absen ditekan, aplikasi akan mengecek internet. Jika gagal/timeout, data akan otomatis masuk ke "Brankas Lokal" (SQLite) di HP untuk dikirim nanti.

KOMPONEN SISTEM
1. GLOBAL STORE-AND-FORWARD
Arsitektur penampungan data sementara yang tidak membeda-bedakan track. Semua data masuk ke antrian yang sama di SQLite sebelum dilempar ke server.

2. DIFFERENTIAL VALIDATION LOGIC
Sistem secara cerdas memilih metode pembuktian lokasi:
- OPERASIONAL: Karena GPS sering error/bertumpuk di bandara, validasi dipaksa menggunakan QR Code fisik.
- HEAD OFFICE: Karena lingkungan kantor biasanya terbuka/terdeteksi GPS baik, validasi tetap menggunakan koordinat GPS (yang diambil secara offline lalu dikirim saat online).

3. SECURE TIMESTAMPING
Untuk semua user, jam absen diambil dari waktu sistem saat tombol ditekan (bukan waktu saat terkirim ke server). Proteksi manipulasi jam dilakukan dengan mencatat "Uptime" perangkat sejak booting.

4. UNIFIED BACKGROUND SYNC
Satu service latar belakang yang sama menangani sinkronisasi untuk semua jenis karyawan. Karyawan HO yang absen di basement parkir (tanpa sinyal) akan otomatis terabsen begitu dia sampai di meja kerja yang ada WiFi/Sinyal.

FLOW DATA
TEKAN ABSEN > CEK INTERNET (FAILED) > TENTUKAN TRACK > (SCAN QR / AMBIL GPS) > FOTO SELFIE > SIMPAN SQLITE > SYNC SAAT ONLINE > SERVER VALIDASI.

2. QR LOCATOR (VIRTUAL GEOFENCE)
Menggantikan GPS yang tidak akurat di dalam gedung. QR Code menjadi bukti fisik bahwa karyawan benar-benar berada di titik outlet tersebut.

3. LIVENESS CHECK (WIDE CAMERA)
Kamera depan dipaksa mengambil gambar bidang lebar. Dokumentasi foto wajib menyertakan latar belakang outlet untuk verifikasi manual oleh admin jika diperlukan.

4. SYNC MANAGER (BACKGROUND TASK)
Modul di Flutter yang terus berjalan di latar belakang. Tugasnya hanya memantau internet. Begitu sinyal terdeteksi (meski lemah), dia akan mencoba mengirimkan antrian absen satu per satu.

FLOW DATA
Karyawan Scan QR > Ambil Foto > Enkripsi Data > Masuk SQLite Lokal > Notifikasi "Absen Disimpan" > Internet Aktif > Data Terkirim Otomatis > Update Dashboard Web Secara Real-time.

PENCEGAHAN KECURANGAN
1. Device ID Lock: Satu akun hanya bisa absen di satu HP yang terdaftar.
2. Time Tampering Check: Sistem mendeteksi jika jam manual HP diubah secara drastis dari waktu sinkronisasi terakhir.
3. Background Verification: Foto selfie yang tidak menampilkan area outlet akan ditandai oleh sistem untuk direview HR.
