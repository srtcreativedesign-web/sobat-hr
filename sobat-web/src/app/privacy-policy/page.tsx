export default function PrivacyPolicyPage() {
    return (
        <div style={{ maxWidth: 800, margin: '0 auto', padding: '40px 20px', fontFamily: 'system-ui, sans-serif', lineHeight: 1.8, color: '#333' }}>
            <h1 style={{ fontSize: 28, marginBottom: 8 }}>Kebijakan Privasi</h1>
            <p style={{ color: '#666', marginBottom: 32 }}>Terakhir diperbarui: 13 April 2026</p>

            <p>Aplikasi <strong>SOBAT HR</strong> (&quot;Aplikasi&quot;) dikembangkan oleh <strong>SRT Corp</strong> (&quot;Kami&quot;). Kebijakan Privasi ini menjelaskan bagaimana kami mengumpulkan, menggunakan, dan melindungi informasi pribadi Anda saat menggunakan Aplikasi.</p>

            <h2>1. Informasi yang Kami Kumpulkan</h2>
            <ul>
                <li><strong>Data Pribadi:</strong> Nama, email, nomor telepon, tanggal lahir, alamat, dan informasi kepegawaian yang Anda berikan saat pendaftaran atau penggunaan fitur HR.</li>
                <li><strong>Data Kehadiran:</strong> Lokasi GPS dan foto selfie saat melakukan absensi, yang digunakan untuk verifikasi kehadiran.</li>
                <li><strong>Data Wajah (Face Data):</strong> Foto wajah karyawan yang diambil melalui kamera depan perangkat saat proses pendaftaran wajah (face enrollment) dan saat check-in absensi (attendance selfie). Aplikasi menggunakan Google ML Kit Face Detection yang berjalan sepenuhnya di perangkat (on-device) untuk mendeteksi keberadaan wajah secara real-time sebelum pengambilan foto. Aplikasi hanya mengumpulkan foto wajah 2D (format JPEG); tidak ada face embeddings, biometric templates, face maps 3D, atau data biometrik lainnya yang disimpan secara permanen.</li>
                <li><strong>Data Perangkat:</strong> Informasi perangkat seperti model, sistem operasi, dan identifikasi unik perangkat untuk keperluan teknis.</li>
            </ul>

            <h2>2. Penggunaan Informasi</h2>
            <p>Informasi yang dikumpulkan digunakan untuk:</p>
            <ul>
                <li>Mengelola data kepegawaian dan kehadiran karyawan.</li>
                <li>Memproses pengajuan cuti, lembur, reimbursement, dan permintaan lainnya.</li>
                <li>Verifikasi identitas melalui pengenalan wajah saat absensi.</li>
                <li>Mengirimkan notifikasi terkait status pengajuan dan pengumuman perusahaan.</li>
                <li>Meningkatkan kualitas layanan dan pengalaman pengguna.</li>
            </ul>

            <h2>3. Pengumpulan, Penggunaan, Penyimpanan, dan Retensi Data Wajah</h2>

            <h3>3.1. Data Wajah yang Dikumpulkan</h3>
            <p>Aplikasi SOBAT HR mengumpulkan foto wajah (&quot;Data Wajah&quot;) dalam dua proses:</p>
            <ul>
                <li><strong>Pendaftaran Wajah (Face Enrollment):</strong> Satu foto wajah referensi diambil dari kamera depan perangkat. Foto ini digunakan sebagai acuan identitas karyawan. Sebelum pengambilan foto, aplikasi menggunakan Google ML Kit Face Detection yang berjalan sepenuhnya di perangkat (on-device) untuk memvalidasi bahwa wajah terdeteksi dengan benar, posisi wajah berada di tengah frame, dan hanya ada satu wajah dalam frame.</li>
                <li><strong>Foto Absensi (Attendance Selfie):</strong> Satu foto selfie diambil dari kamera depan setiap kali karyawan melakukan check-in absensi. Foto ini digunakan untuk memverifikasi bahwa karyawan yang melakukan check-in adalah orang yang sama dengan yang terdaftar.</li>
            </ul>
            <p>Aplikasi hanya mengumpulkan foto wajah 2D dalam format JPEG yang telah dikompresi. Aplikasi <strong>tidak</strong> mengumpulkan atau menyimpan face embeddings, biometric templates, face maps 3D, atau data geometri wajah secara permanen. Deteksi wajah pada perangkat menggunakan Google ML Kit berjalan sepenuhnya secara lokal di perangkat pengguna dan tidak mengirimkan data apapun ke Google atau pihak ketiga lainnya.</p>

            <h3>3.2. Penggunaan Data Wajah</h3>
            <p>Data Wajah yang dikumpulkan digunakan <strong>secara eksklusif</strong> untuk tujuan berikut:</p>
            <ul>
                <li><strong>Verifikasi Identitas Kehadiran:</strong> Foto enrollment digunakan sebagai referensi untuk dibandingkan dengan foto selfie saat check-in absensi. Perbandingan dilakukan di server kami menggunakan library open-source face_recognition (berbasis dlib) untuk memastikan bahwa karyawan yang melakukan absensi adalah orang yang benar.</li>
                <li><strong>Pencegahan Kecurangan:</strong> Sistem ini mencegah absensi palsu (buddy punching), yaitu situasi di mana seseorang melakukan absensi untuk orang lain.</li>
                <li><strong>Peninjauan HR:</strong> Jika verifikasi wajah gagal atau tidak cocok (mismatch), foto akan ditandai untuk ditinjau oleh administrator HR perusahaan.</li>
            </ul>
            <p>Data Wajah <strong>tidak digunakan</strong> untuk iklan, profiling pengguna, pemasaran, pelacakan, atau tujuan lain selain verifikasi identitas kehadiran karyawan sebagaimana dijelaskan di atas.</p>

            <h3>3.3. Berbagi Data Wajah dengan Pihak Ketiga</h3>
            <p>Data Wajah <strong>tidak dijual, dibagikan, atau diungkapkan</strong> kepada pihak ketiga manapun. Secara spesifik:</p>
            <ul>
                <li>Tidak ada layanan pengenalan wajah pihak ketiga (seperti AWS Rekognition, Google Cloud Vision, atau Microsoft Azure Face) yang digunakan. Seluruh pemrosesan perbandingan wajah dilakukan di server milik kami sendiri menggunakan library open-source.</li>
                <li>Google ML Kit Face Detection yang digunakan pada perangkat berjalan sepenuhnya secara offline dan lokal di perangkat; tidak ada data wajah yang dikirimkan ke Google.</li>
                <li>Tidak ada pihak ketiga yang memiliki akses ke Data Wajah yang tersimpan di server kami.</li>
            </ul>

            <h3>3.4. Penyimpanan Data Wajah</h3>
            <p>Data Wajah disimpan dan ditransmisikan sebagai berikut:</p>
            <ul>
                <li><strong>Transmisi:</strong> Foto dikirim dari perangkat ke server melalui koneksi HTTPS yang terenkripsi.</li>
                <li><strong>Server:</strong> Foto enrollment disimpan di server yang dikelola oleh perusahaan. Foto absensi disimpan di server yang sama.</li>
                <li><strong>Perangkat Mobile:</strong> Foto hanya disimpan sementara di direktori temporary perangkat selama proses upload dan tidak disimpan secara permanen di perangkat.</li>
                <li><strong>Keamanan:</strong> Akses ke endpoint upload foto dilindungi oleh autentikasi bearer token dan rate limiting (maksimum 6 permintaan per menit) untuk mencegah penyalahgunaan.</li>
            </ul>

            <h3>3.5. Retensi dan Penghapusan Data Wajah</h3>
            <ul>
                <li><strong>Foto Enrollment:</strong> Disimpan selama karyawan masih aktif terdaftar di perusahaan. Foto akan dihapus ketika data karyawan dihapus dari sistem atau ketika karyawan meminta penghapusan.</li>
                <li><strong>Foto Absensi:</strong> Disimpan untuk keperluan audit kehadiran dan dibersihkan secara otomatis melalui proses pembersihan terjadwal (scheduled cleanup) yang berjalan setiap hari.</li>
                <li><strong>Face Encodings:</strong> Tidak pernah disimpan secara permanen. Face encodings dihitung ulang setiap kali ada proses verifikasi dan langsung dihapus dari memori setelah perbandingan selesai.</li>
            </ul>

            <h3>3.6. Hak Pengguna terkait Data Wajah</h3>
            <p>Karyawan memiliki hak untuk:</p>
            <ul>
                <li>Menghapus Data Wajah enrollment mereka kapan saja melalui pengaturan profil di aplikasi atau dengan menghubungi administrator HR. Penghapusan foto enrollment akan menonaktifkan fitur verifikasi wajah sampai karyawan melakukan pendaftaran ulang.</li>
                <li>Meminta informasi mengenai Data Wajah apa saja yang tersimpan.</li>
                <li>Menolak penggunaan fitur pengenalan wajah (dengan konsekuensi fitur verifikasi absensi melalui wajah tidak dapat digunakan).</li>
            </ul>

            <h2>4. Penyimpanan dan Keamanan Data Umum</h2>
            <p>Kami menyimpan data Anda di server yang aman dan menerapkan langkah-langkah keamanan yang wajar untuk melindungi informasi pribadi Anda dari akses, penggunaan, atau pengungkapan yang tidak sah.</p>

            <h2>5. Berbagi Informasi</h2>
            <p>Kami <strong>tidak menjual atau membagikan</strong> informasi pribadi Anda kepada pihak ketiga, kecuali:</p>
            <ul>
                <li>Diperlukan oleh hukum atau peraturan yang berlaku.</li>
                <li>Diperlukan untuk operasional internal perusahaan (HRD, manajemen).</li>
            </ul>

            <h2>6. Hak Pengguna</h2>
            <p>Anda berhak untuk:</p>
            <ul>
                <li>Mengakses dan memperbarui data pribadi Anda.</li>
                <li>Meminta penghapusan data pribadi Anda, termasuk Data Wajah.</li>
                <li>Menolak penggunaan data untuk tujuan tertentu.</li>
            </ul>

            <h2>7. Izin Aplikasi</h2>
            <ul>
                <li><strong>Kamera:</strong> Digunakan untuk pengambilan foto wajah saat pendaftaran wajah (face enrollment), foto selfie saat check-in absensi, dan upload dokumen.</li>
                <li><strong>Lokasi:</strong> Digunakan untuk verifikasi lokasi saat absensi.</li>
                <li><strong>Penyimpanan:</strong> Digunakan untuk menyimpan dan mengakses file dokumen.</li>
            </ul>

            <h2>8. Kontak</h2>
            <p>Jika Anda memiliki pertanyaan mengenai Kebijakan Privasi ini, silakan hubungi kami di:</p>
            <p><strong>Email:</strong> support@srtcorp.com</p>

            <div style={{ marginTop: 48, paddingTop: 24, borderTop: '1px solid #eee', color: '#999', fontSize: 14 }}>
                &copy; 2026 SRT Corp. All rights reserved.
            </div>
        </div>
    );
}
