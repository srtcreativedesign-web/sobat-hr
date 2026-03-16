Proposal Implementasi Sistem Absensi Offline Terenkripsi (Hybrid Model)
Studi Kasus: Seluruh Karyawan (Head Office & Outlet Operasional)

1. Latar Belakang Masalah
Sistem absensi standar seringkali gagal di dua kondisi ekstrim:
- Blank Spot Sinyal: Ketebalan beton gedung (basement/bandara) menyebabkan sinyal hilang.
- Ketidakakuratan GPS Vertikal: Sulit membedakan lantai outlet yang bertumpuk.

2. Solusi yang Diajukan: Sistem "Hybrid Offline"
Aplikasi dikonfigurasi menjadi "Offline-First" untuk seluruh karyawan, namun dengan perbedaan metode validasi berdasarkan unit kerja (Track):

A. Track Head Office (HO): Offline GPS
- Jika internet mati, aplikasi merekam koordinat GPS saat itu juga.
- Validasi tetap berbasis Geofence (radius kantor).
- Data disimpan di SQLite lokal dan dikirim otomatis saat internet aktif.

B. Track Operasional (Outlet): Offline QR-Code
- Menggunakan QR Code statis yang ditempel di dinding outlet.
- QR Code menjadi "GPS Fisik" yang 100% akurat untuk membedakan lantai bangunan.
- Dilengkapi selfie background wajib untuk mencegah manipulasi.

3. Alur Kerja Operasional (SOP) Universal
1. Eksekusi: Karyawan menekan tombol absen (Masuk/Pulang).
2. Validasi:
   - Tim HO: Aplikasi mengunci posisi GPS + Foto Selfie.
   - Tim Operasional: Aplikasi meminta Scan QR di dinding + Foto Selfie.
3. Penyimpanan: Data dibungkus dalam paket enkripsi dan disimpan di database internal HP (SQLite).
4. Sinkronisasi: Background service mengirim data ke Server Laravel begitu internet terdeteksi.

4. Keunggulan Sistem Hybrid
- Inklusivitas: Seluruh karyawan bisa absen meski di basement parkir atau area buta sinyal.
- Integritas Data: Semua absen offline wajib menyertakan foto selfie liveness.
- Keamanan: Metadata waktu (timestamp) dikunci sejak tombol ditekan, mencegah manipulasi jam HP.
- Efisiensi: Tim HO tidak perlu repot dengan stiker QR, sementara tim lapangan mendapatkan akurasi lokasi yang pasti.