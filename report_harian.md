LAPORAN KERJA HARIAN - 25 FEBRUARI 2026

1. FITUR THR MANAGEMENT (WEB ADMIN)
- Membuat halaman THR Management lengkap di web admin (import data, tabel, filter divisi/tahun).
- Implementasi tombol Approve single & Bulk Approve untuk data THR.
- Integrasi sidebar menu THR di dashboard web admin.

2. FILTER & TABEL THR (WEB ADMIN)
- Menambahkan filter divisi (Head Office / Operational / Semua) dan filter tahun.
- Menyederhanakan tampilan: menghapus kolom THR Kotor & Pajak, relabel kolom menjadi "Jumlah THR".
- Penyesuaian format tabel pada export Excel.

3. FITUR THR SLIP MOBILE
- Implementasi halaman THR di mobile app dengan card view dan detail bottom sheet.
- Fitur download slip THR dalam format PDF.
- Menampilkan informasi Masa Kerja otomatis berdasarkan join_date karyawan.

4. NOTIFIKASI UPDATE IN-APP (MOBILE)
- Implementasi notifikasi update versi aplikasi menggunakan in_app_update.
- Pengguna mendapat notifikasi otomatis jika versi baru tersedia di Google Play Store.

5. DASHBOARD REDESIGN (MOBILE)
- Penyempurnaan dashboard: salam dinamis (Pagi/Siang/Sore/Malam), header personal dengan nama depan.
- Penambahan aksen gradasi dan visual polish pada quick action buttons.

6. PERBAIKAN BUG
- Fix error 500 saat download PDF slip THR (method generateSlip belum ada).
- Fix tampilan desimal pada Masa Kerja (casting ke integer).
- Fix type error pada parameter year di mobile (String → int parsing).
- Fix dashboard view dan layout adjustments.

STATUS: SEMUA TUGAS SELESAI DAN SUDAH DI-PUSH KE REPOSITORY.

---

LAPORAN KERJA HARIAN - 26 FEBRUARI 2026

1. SIMPLIFIKASI MODEL THR & FIX KONEKSI API (BACKEND + MOBILE)
- Migrasi ulang tabel THR dengan schema yang lebih sederhana.
- Membuat DioFactory terpusat untuk seluruh service mobile (menggantikan inisialisasi Dio manual per-service).
- Fix SSL Certificate error: menambahkan trust all certificates pada DioFactory agar koneksi ke API server berjalan lancar (solusi untuk CERTIFICATE_VERIFY_FAILED).
- Semua service (THR, Payroll, Approval, Employee, Security, Request) sudah menggunakan DioFactory.

2. FORM TANDA TANGAN DIGITAL - APPROVE THR (WEB ADMIN)
- Membuat modal popup approval dengan input Nama Penandatangan + Signature Pad digital.
- Menggunakan library react-signature-canvas yang sudah terinstall.
- Data tanda tangan (base64 PNG) dan nama disimpan di kolom details (JSON) tabel THR.
- Berlaku untuk Approve single maupun Bulk Approve.

3. VERIFIKASI PIN KEAMANAN - THR MOBILE
- Menambahkan gate PIN saat membuka menu THR di mobile (sama seperti payslip).
- Jika belum punya PIN → setup PIN dulu; jika sudah → verifikasi PIN.
- Data THR hanya tampil setelah PIN berhasil diverifikasi.

4. TANDA TANGAN DIGITAL PENERIMA - THR MOBILE
- Membuat halaman tanda tangan digital full-screen menggunakan package signature.
- Halaman muncul sebelum download slip THR pertama kali.
- Tanda tangan disimpan permanen di database (kolom details JSON), sehingga download berikutnya langsung tanpa tanda tangan ulang.

5. RENDER TANDA TANGAN DI PDF
- Bagian "Disetujui oleh" menampilkan nama + gambar tanda tangan admin.
- Bagian "Diterima oleh" menampilkan nama karyawan + gambar tanda tangan dari mobile.
- Fix CSS header PDF: ganti linear-gradient (tidak support DomPDF) dengan solid background color.

6. UPDATE HEADER PDF SLIP THR
- Judul: "SLIP TUNJANGAN HARI RAYA"
- Nama perusahaan: "SRT Corporation"
- Periode tahun THR ditampilkan secara dinamis.

7. CLEANUP KODE
- Menghapus 6 unused import api_config.dart di berbagai service files mobile.

STATUS: SEMUA TUGAS SELESAI.

---

LAPORAN KERJA HARIAN - 27 FEBRUARI 2026 (JUM'AT)

1. FIX BUG PRODUCTION LOGIN DI PLAYSTORE MUTER TERUS (STUCK LOADING)
- Penyebab utama 1: Missing `connectionTimeout` saat meng-override SSL certificate HttpClient di `DioFactory`. Saat aplikasi gagal mengontak IP lokal (misal fallback dari ENV dev), HTTP client akan nunggu tanpa batas waktu (infinity) alih-alih menampilkan pesan error "Koneksi Gagal".
- Solusi 1: Menambahkan proxy konfigurasi batas `connectionTimeout` (15 detik) ke custom `HttpClient` di `DioFactory`.

2. SETUP ENV PRODUCTION RELEASE
- Bug: Build AAB PlayStore berpotensi menggunakan URL localhost/IP lokal jika parameter `--dart-define=ENV=prod` terlupa.
- Solusi: Merubah behaviour `api_config.dart` dengan menggunakan `kReleaseMode`. Semua build rilis otomatis tersinkron ke konfigurasi `prod` (https://api.sobat-hr.com/api/) walau `--dart-define` absen.

3. FIX ANDROID KEYSTORE CORRUPTION METADATA
- Bug: `flutter_secure_storage` sering hang saat inisialisasi pada aplikasi versi update di Android karena metadata enkripsi lama dan baru bentrok.
- Solusi: Mengaktifkan `EncryptedSharedPreferences` pada opsi inisialisasi `AndroidOptions` demi stabilitas baca/tulis token Auth. 

STATUS: SEMUA BUG KRITIKAL SELESAI & TELAH DIBUILD RILIS V1.0.0+12.

---

📋 OUTSTANDING TASK (UNTUK SENIN, 2 MARET 2026)

1. UPDATE FIREBASE GOOGLE SERVICES JSON (MOBILE)
- Deskripsi: SHA-1 & SHA-256 versi production (dari Google Play App Signing) wajib dikonfigurasi sepenuhnya dengan Firebase SDK.
- Action items:
  - Download ulang file `google-services.json` terbaru dari dashboard Firebase Console (setelah SHA-1 disisipkan).
  - Timpa file lama di folder `sobat-mobile/android/app/google-services.json`.
  - Re-build dan upload update baru agar Google Services/Push Notif (FCM) tersinkron sepenuhnya dengan versi Play Store.

2. PENGUJIAN RILIS BARU (VERSION 1.0.0+13)
- Deskripsi: Melakukan end-to-end testing pada aplikasi versi rilis Play Store terbaru.
- Action items:
  - Test login menggunakan API Production.
  - Test flow notifikasi berjalan normal setelah login.
  - Test download slip THR dan sistem signature.
