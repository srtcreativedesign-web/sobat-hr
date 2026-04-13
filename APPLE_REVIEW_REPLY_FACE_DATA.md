# Apple App Review Reply — Face Data Usage

Below are our detailed responses to each question regarding how SOBAT HR uses face data.


## 1. What face data does the app collect?

SOBAT HR collects facial photographs (2D JPEG images) in two contexts:

a) Face Enrollment: A single reference face photo is captured from the device's front-facing camera when an employee registers their face. Before capturing, the app uses Google ML Kit Face Detection running entirely on-device to validate that exactly one face is present, the face is centered in the frame, and head rotation is within acceptable limits (less than 45 degrees).

b) Attendance Check-in Selfie: A single selfie photo is captured from the front-facing camera each time an employee performs an attendance check-in.

The app does NOT collect or store any of the following: face embeddings, biometric templates, 3D face maps, face geometry data, or any persistent biometric identifiers. Only standard 2D JPEG photographs are collected. Face detection on the device (Google ML Kit) runs entirely locally and does not transmit any data to Google or any third party.


## 2. Complete and clear explanation of all planned uses of the collected face data

The collected face data is used exclusively for the following purposes:

a) Employee Identity Verification for Attendance: The enrolled face photo serves as a reference image. When an employee checks in for attendance, the check-in selfie is compared against the enrolled reference photo on our server using the open-source face_recognition library (based on dlib) with a strict tolerance threshold of 0.5. This comparison determines whether the person checking in matches the registered employee.

b) Fraud Prevention (Anti-Buddy Punching): The face verification system prevents employees from performing attendance check-ins on behalf of other employees, ensuring the integrity of attendance records.

c) HR Administrative Review: If the face verification result is a mismatch or failure, the attendance record is flagged as "needs review" for the company's HR administrator to inspect manually.

Face data is NOT used for advertising, user profiling, marketing, tracking, analytics, or any purpose other than the employee attendance identity verification described above.


## 3. Will the face data be shared with any third parties? Where will this information be stored?

Face data is NOT shared with, sold to, or disclosed to any third parties. Specifically:

- No third-party facial recognition services (such as AWS Rekognition, Google Cloud Vision, Microsoft Azure Face, or similar services) are used. All face comparison processing is performed on our own company-controlled server using the open-source face_recognition library (dlib).
- Google ML Kit Face Detection used on the device runs entirely offline and locally on the device. No face data is sent to Google.
- No third party has access to the face data stored on our server.

Storage locations:

- Enrolled face photos are stored on our company-controlled server in a dedicated directory (face_enrollments/).
- Attendance check-in selfie photos are stored on the same company-controlled server in a separate directory (attendance_photos/).
- On the mobile device, photos are stored only temporarily in the device's temporary directory during the upload process and are not retained permanently on the device.
- All data transmission between the device and server occurs over encrypted HTTPS connections.
- Access to the face photo upload endpoint is protected by bearer token authentication and rate limiting (maximum 6 requests per minute).


## 4. How long will face data be retained?

- Enrolled face photos: Retained for the duration of the employee's active employment at their company. The photo is deleted when the employee's record is removed from the system or when the employee requests deletion of their face data.
- Attendance check-in selfie photos: Retained for attendance audit purposes and subject to automated daily cleanup. Orphaned photos (those no longer associated with an active attendance record) are automatically deleted by a scheduled cleanup job that runs daily.
- Face encodings (mathematical representations used for comparison): These are NEVER stored permanently. They are computed in memory each time a verification is performed and are immediately discarded from memory after the comparison is complete. No persistent biometric identifiers are stored at any point.
- Employees may request deletion of their enrolled face data at any time through the app's profile settings or by contacting their HR administrator. Deleting the enrolled face photo disables face-verified attendance until the employee re-enrolls.


## 5. Where in the privacy policy is the app's collection, use, disclosure, sharing, and retention of face data explained? Identify the specific sections.

Our privacy policy has been updated and is accessible at:
[INSERT YOUR PRIVACY POLICY URL HERE, e.g., https://yourdomain.com/privacy-policy]

The following sections specifically address face data:

- Section 1 (Informasi yang Kami Kumpulkan / Information We Collect): The "Data Wajah (Face Data)" bullet point describes what face data is collected, including the types of photos, the use of Google ML Kit on-device, and what is NOT collected.

- Section 3 (Pengumpulan, Penggunaan, Penyimpanan, dan Retensi Data Wajah / Collection, Use, Storage, and Retention of Face Data): This is the dedicated face data section containing six subsections:
  - Section 3.1 (Data Wajah yang Dikumpulkan / Face Data Collected): Details on what face data is collected during enrollment and attendance.
  - Section 3.2 (Penggunaan Data Wajah / Use of Face Data): All purposes for which face data is used.
  - Section 3.3 (Berbagi Data Wajah dengan Pihak Ketiga / Sharing Face Data with Third Parties): Confirms no third-party sharing.
  - Section 3.4 (Penyimpanan Data Wajah / Storage of Face Data): Where and how face data is stored and transmitted.
  - Section 3.5 (Retensi dan Penghapusan Data Wajah / Retention and Deletion of Face Data): How long each type of face data is retained and deletion procedures.
  - Section 3.6 (Hak Pengguna terkait Data Wajah / User Rights Regarding Face Data): Employee rights to delete, request information about, or opt out of face data collection.

- Section 6 (Hak Pengguna / User Rights): Includes the right to request deletion of personal data including face data.

- Section 7 (Izin Aplikasi / App Permissions): The Camera permission description explicitly mentions face enrollment and attendance selfie capture as camera use cases.


## 6. Quote the specific text from the privacy policy concerning face data

Below are the direct quotes from our privacy policy:

From Section 1 (Information We Collect), the Face Data bullet point:

"Data Wajah (Face Data): Foto wajah karyawan yang diambil melalui kamera depan perangkat saat proses pendaftaran wajah (face enrollment) dan saat check-in absensi (attendance selfie). Aplikasi menggunakan Google ML Kit Face Detection yang berjalan sepenuhnya di perangkat (on-device) untuk mendeteksi keberadaan wajah secara real-time sebelum pengambilan foto. Aplikasi hanya mengumpulkan foto wajah 2D (format JPEG); tidak ada face embeddings, biometric templates, face maps 3D, atau data biometrik lainnya yang disimpan secara permanen."

From Section 3.1 (Face Data Collected):

"Aplikasi SOBAT HR mengumpulkan foto wajah ("Data Wajah") dalam dua proses: Pendaftaran Wajah (Face Enrollment): Satu foto wajah referensi diambil dari kamera depan perangkat. Foto ini digunakan sebagai acuan identitas karyawan. Sebelum pengambilan foto, aplikasi menggunakan Google ML Kit Face Detection yang berjalan sepenuhnya di perangkat (on-device) untuk memvalidasi bahwa wajah terdeteksi dengan benar, posisi wajah berada di tengah frame, dan hanya ada satu wajah dalam frame. Foto Absensi (Attendance Selfie): Satu foto selfie diambil dari kamera depan setiap kali karyawan melakukan check-in absensi. Foto ini digunakan untuk memverifikasi bahwa karyawan yang melakukan check-in adalah orang yang sama dengan yang terdaftar."

"Aplikasi hanya mengumpulkan foto wajah 2D dalam format JPEG yang telah dikompresi. Aplikasi tidak mengumpulkan atau menyimpan face embeddings, biometric templates, face maps 3D, atau data geometri wajah secara permanen. Deteksi wajah pada perangkat menggunakan Google ML Kit berjalan sepenuhnya secara lokal di perangkat pengguna dan tidak mengirimkan data apapun ke Google atau pihak ketiga lainnya."

From Section 3.2 (Use of Face Data):

"Data Wajah yang dikumpulkan digunakan secara eksklusif untuk tujuan berikut: Verifikasi Identitas Kehadiran: Foto enrollment digunakan sebagai referensi untuk dibandingkan dengan foto selfie saat check-in absensi. Perbandingan dilakukan di server kami menggunakan library open-source face_recognition (berbasis dlib) untuk memastikan bahwa karyawan yang melakukan absensi adalah orang yang benar. Pencegahan Kecurangan: Sistem ini mencegah absensi palsu (buddy punching), yaitu situasi di mana seseorang melakukan absensi untuk orang lain."

"Data Wajah tidak digunakan untuk iklan, profiling pengguna, pemasaran, pelacakan, atau tujuan lain selain verifikasi identitas kehadiran karyawan sebagaimana dijelaskan di atas."

From Section 3.3 (Sharing Face Data with Third Parties):

"Data Wajah tidak dijual, dibagikan, atau diungkapkan kepada pihak ketiga manapun. Secara spesifik: Tidak ada layanan pengenalan wajah pihak ketiga (seperti AWS Rekognition, Google Cloud Vision, atau Microsoft Azure Face) yang digunakan. Seluruh pemrosesan perbandingan wajah dilakukan di server milik kami sendiri menggunakan library open-source. Google ML Kit Face Detection yang digunakan pada perangkat berjalan sepenuhnya secara offline dan lokal di perangkat; tidak ada data wajah yang dikirimkan ke Google. Tidak ada pihak ketiga yang memiliki akses ke Data Wajah yang tersimpan di server kami."

From Section 3.5 (Retention and Deletion of Face Data):

"Foto Enrollment: Disimpan selama karyawan masih aktif terdaftar di perusahaan. Foto akan dihapus ketika data karyawan dihapus dari sistem atau ketika karyawan meminta penghapusan. Foto Absensi: Disimpan untuk keperluan audit kehadiran dan dibersihkan secara otomatis melalui proses pembersihan terjadwal (scheduled cleanup) yang berjalan setiap hari. Face Encodings: Tidak pernah disimpan secara permanen. Face encodings dihitung ulang setiap kali ada proses verifikasi dan langsung dihapus dari memori setelah perbandingan selesai."

From Section 3.6 (User Rights Regarding Face Data):

"Karyawan memiliki hak untuk: Menghapus Data Wajah enrollment mereka kapan saja melalui pengaturan profil di aplikasi atau dengan menghubungi administrator HR. Penghapusan foto enrollment akan menonaktifkan fitur verifikasi wajah sampai karyawan melakukan pendaftaran ulang. Meminta informasi mengenai Data Wajah apa saja yang tersimpan. Menolak penggunaan fitur pengenalan wajah (dengan konsekuensi fitur verifikasi absensi melalui wajah tidak dapat digunakan)."
