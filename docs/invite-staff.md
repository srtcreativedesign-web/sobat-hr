# Panduan Fitur: Undang Staff / Karyawan

Dokumen ini menjelaskan desain dan langkah implementasi fitur "Undang Staff" untuk sistem SOBAT HR. Tujuannya: memungkinkan HR mengunggah daftar karyawan (Excel), mem-preview, dan mengirim undangan massal lewat email secara otomatis dengan tracking dan queuing.

## Ringkasan Alur

- HR mengunggah file Excel (template yang disediakan).
- Server mem-parse file dan mengembalikan preview baris (valid/invalid) tanpa langsung menyimpan ke DB.
- HR memilih baris yang ingin diundang lalu klik `Invite selected`.
- Backend membuat record `invitations` untuk tiap email, membuat token unik, dan menempatkan job ke queue untuk pengiriman email.
- Worker queue memproses job, mengirim email via SMTP/SendGrid/Mailgun, dan memperbarui status (queued → sent/failed).
- Penerima menerima email berisi link undangan (mengandung token). Saat klik, token diverifikasi; user diarahkan ke form pendaftaran/penyelesaian profil.

## Kenapa tidak menggunakan `mailto:`

- `mailto:` cepat dan mudah untuk kirim manual satu-dua email.
- Namun `mailto:` TIDAK cocok untuk undangan massal karena:
  - Bergantung pada email client pengguna (tidak otomatis dikirim oleh server).
  - Tidak bisa melakukan batching, retry, atau pelacakan (tracking, bounce handling).
  - Sulit melakukan personalisasi token unik untuk tiap penerima.
- Kesimpulan: `mailto:` hanya cocok untuk skenario manual kecil; untuk undang massal gunakan server-side email (Mailable + queue).

## Komponen yang Dibutuhkan

1. Frontend (Web admin):
   - Halaman `Employees -> Invite` dengan upload file, preview table, checkbox per baris, tombol `Invite selected`.
   - Menampilkan status pengiriman per email setelah enqueue (queued/sent/failed).

2. Backend endpoints (Laravel):
   - `POST /staff/import` — menerima file Excel, parse, validasi, kembalikan preview JSON (tidak menyimpan).
   - `POST /staff/invitations` — menerima array baris yang dipilih, buat `invitations` records dan enqueue send jobs.
   - `GET /invitations/:token` — verifikasi token dan arahkan ke halaman pendaftaran/complete-profile.
   - `POST /invitations/:token/accept` — buat user/employee atau link ke user yang sudah ada.

3. Database:
   - Tabel `invitations` (migration):
     - id (bigint)
     - email (string)
     - name (string, nullable)
     - payload (json) — data awal dari excel
     - token (string, unique)
     - status (enum: pending, queued, sent, failed, accepted)
     - error_message (text nullable)
     - expires_at (datetime nullable)
     - created_at / updated_at

4. Queue & Email:
   - `Mailable` template berisi link dengan token.
   - `Job` untuk mengirim email (dispatch per-invitation, supports retry/backoff).
   - Gunakan driver queue (database, Redis) dan worker (supervisor) di production.

## Validasi & Mapping Excel

- Buat template Excel minimal (kolom: name, email, nik, phone, department, position, join_date).
- Saat parsing, lakukan validasi per baris: email format, unique check (jika ingin), required fields.
- Kembalikan preview JSON: { rowIndex, rawRow, valid: true/false, errors: [...] }

## Template Email (Saran)

- Subject: "[SOBAT HR] Undangan Bergabung — Lengkapi Profil Anda"
- Body singkat, personalisasi: "Halo {name}, Anda diundang untuk bergabung di SOBAT HR. Klik link berikut untuk menyelesaikan pendaftaran: {invite_link}"
- CTA button/link ke `https://app.example.com/invite/accept?token={token}`

## Akun Otomatis saat Undangan

- Perilaku yang diminta: saat meng-queue undangan, server otomatis membuat akun untuk email yang diundang (email + password) dan mengirim kredensial tersebut dalam email undangan.
- Implementasi yang disarankan:
   - Generate password acak yang kuat (mis. 12+ chars, kombinasi huruf besar/kecil, angka, simbol) per undangan.
   - Simpan hanya hash password di tabel `users` (gunakan `Hash::make()`), jangan simpan plain password di DB.
   - Simpan metadata pada `invitations` seperti `password_sent_at` dan/atau `password_generated` flag untuk audit.
   - Di email undangan sertakan kredensial sementara (email + password) dan instruksi untuk mengganti password pada login pertama.
   - Lebih aman: sebagai alternatif kirim link sekali-pakai untuk membuat password (recommended). Jika pengguna tetap ingin menerima password, pastikan password bersifat sementara dan wajib di-reset.

- Keamanan & catatan operasional:
   - Hindari logging plain passwords di server logs.
   - Batasi masa berlaku password sementara (mis. 7 hari) dan force-reset pada first-login.
   - Pertimbangkan kebijakan MFA atau verifikasi tambahan untuk akun sensitif.
   - Beri tahu penerima untuk menghapus email berisi password jika diperlukan.

   ## Menampilkan Password Sementara di Preview Import

   - Permintaan: ketika HR meng-upload Excel, sistem otomatis generate password sementara per baris dan tampilkan kolom `temporary_password` pada preview di web admin.
   - Alur singkat:
      1. HR upload Excel dan server mem-parse baris.
      2. Untuk tiap row valid, server generate password kripto-secure (panjang ≥12) dan sertakan hanya pada response preview JSON sebagai `temporary_password`.
      3. UI menampilkan kolom `temporary_password` secara sementara sehingga HR bisa mendownload/print atau melihatnya.
      4. Saat HR menekan `Invite selected`, backend akan membuat `users` (simpan hash password), atau membuat `invitations` yang menyimpan metadata dan `password_generated_at`.
      5. Setelah user menerima email dan melakukan first-login / accept token, sistem menghapus/menyembunyikan `temporary_password` pada admin UI dan mengganti dengan status `Akun berhasil login`.

   - Keamanan penting:
      - Jangan simpan plain `temporary_password` dalam log atau file. Jika perlu menyimpan sementara, enkripsi field di DB (mis. AES) dan batasi hak akses.
      - Pertimbangkan menampilkan password hanya sekali pada preview dan menyediakan tombol `Download CSV` satu kali yang menyertakan password (atau generate printable list) — beri peringatan keamanan.
      - Alternatif lebih aman: tampilkan hanya one-time set-password link di email, bukan password plaintext.

   - Database & field rekomendasi:
      - `invitations.password_generated_at` (datetime)
      - `invitations.password_encrypted` (text nullable) — gunakan enkripsi aplikatif jika menyimpan plain-like value.
      - `users.password` — selalu simpan hash via `Hash::make()`.

   - UI behavior:
      - Pada preview: `temporary_password` kolom terlihat dan dapat di-CSV-export.
      - Setelah user login/accept: update invitation status ke `accepted`, hapus `password_encrypted`, dan pada UI ubah cell menjadi `Akun berhasil login`.

   Catatan: pendekatan ini cepat untuk HR, tetapi membawa risiko kebocoran. Jika keamanan menjadi prioritas, gunakan one-time set-password link atau QR token.

## Keamanan & Operasional

- Token: gunakan UUID v4 atau random 32+ chars, simpan hash jika perlu.
- Token harus sekali pakai dan memiliki expiry (mis. 7 hari).
- Kirim email melalui provider (SendGrid/Mailgun/Postmark) untuk deliverability dan webhooks.
- Tangani bounce/complaint via webhook untuk menandai `failed` atau `bounced` di DB.

## Monitoring & Retry

- Gunakan job retries dan exponential backoff.
- Simpan logs untuk setiap pengiriman (sent_at, provider_id, response).
- UI harus menampilkan status dan tombol `Retry` untuk failed invitations.

## Langkah Implementasi Awal (prioritas)

1. Buat migration `invitations`.
2. Implement `POST /staff/import` menggunakan `maatwebsite/excel` dan kembalikan preview.
3. Buat frontend `Invite` page: upload + preview + select rows.
4. Implement `POST /staff/invitations` untuk menyimpan dan enqueue jobs.
5. Buat `InvitationMailable` + `SendInvitationJob` dan konfigurasi queue worker.

## Perintah & cek cepat (Laravel)

```bash
composer require maatwebsite/excel
php artisan make:migration create_invitations_table
php artisan make:mail InvitationMail --markdown=emails.invitation
php artisan make:job SendInvitationJob
php artisan make:controller StaffInvitationController
php artisan queue:work --tries=3
```

## Testing

- Manual: upload sample Excel (10 rows), pilih semua, klik invite. Periksa queue worker logs dan inbox test email.
- Automated: unit test parsing, integration test job dispatch, fungsional test endpoint accept token.

## Catatan tambahan

- Untuk skala besar (ratusan/ ribuan), pertimbangkan batching, rate limiting, dan provider yang mendukung high throughput.
- Simpan template Excel dan contoh file di repo: `docs/invite-template.xlsx`.

---
Dokumen ini bisa dikembangkan lagi menjadi checklist PR dan contoh implementasi kode. Beri tahu langkah mana yang ingin dikerjakan terlebih dahulu.
