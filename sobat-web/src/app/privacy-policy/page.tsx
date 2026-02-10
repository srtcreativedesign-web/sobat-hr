export default function PrivacyPolicyPage() {
    return (
        <div style={{ maxWidth: 800, margin: '0 auto', padding: '40px 20px', fontFamily: 'system-ui, sans-serif', lineHeight: 1.8, color: '#333' }}>
            <h1 style={{ fontSize: 28, marginBottom: 8 }}>Kebijakan Privasi</h1>
            <p style={{ color: '#666', marginBottom: 32 }}>Terakhir diperbarui: 10 Februari 2026</p>

            <p>Aplikasi <strong>SOBAT HR</strong> (&quot;Aplikasi&quot;) dikembangkan oleh <strong>SRT Corp</strong> (&quot;Kami&quot;). Kebijakan Privasi ini menjelaskan bagaimana kami mengumpulkan, menggunakan, dan melindungi informasi pribadi Anda saat menggunakan Aplikasi.</p>

            <h2>1. Informasi yang Kami Kumpulkan</h2>
            <ul>
                <li><strong>Data Pribadi:</strong> Nama, email, nomor telepon, tanggal lahir, alamat, dan informasi kepegawaian yang Anda berikan saat pendaftaran atau penggunaan fitur HR.</li>
                <li><strong>Data Kehadiran:</strong> Lokasi GPS dan foto selfie saat melakukan absensi, yang digunakan untuk verifikasi kehadiran.</li>
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

            <h2>3. Penyimpanan dan Keamanan Data</h2>
            <p>Kami menyimpan data Anda di server yang aman dan menerapkan langkah-langkah keamanan yang wajar untuk melindungi informasi pribadi Anda dari akses, penggunaan, atau pengungkapan yang tidak sah.</p>

            <h2>4. Berbagi Informasi</h2>
            <p>Kami <strong>tidak menjual atau membagikan</strong> informasi pribadi Anda kepada pihak ketiga, kecuali:</p>
            <ul>
                <li>Diperlukan oleh hukum atau peraturan yang berlaku.</li>
                <li>Diperlukan untuk operasional internal perusahaan (HRD, manajemen).</li>
            </ul>

            <h2>5. Hak Pengguna</h2>
            <p>Anda berhak untuk:</p>
            <ul>
                <li>Mengakses dan memperbarui data pribadi Anda.</li>
                <li>Meminta penghapusan data pribadi Anda.</li>
                <li>Menolak penggunaan data untuk tujuan tertentu.</li>
            </ul>

            <h2>6. Izin Aplikasi</h2>
            <ul>
                <li><strong>Kamera:</strong> Digunakan untuk foto absensi dan upload dokumen.</li>
                <li><strong>Lokasi:</strong> Digunakan untuk verifikasi lokasi saat absensi.</li>
                <li><strong>Penyimpanan:</strong> Digunakan untuk menyimpan dan mengakses file dokumen.</li>
            </ul>

            <h2>7. Kontak</h2>
            <p>Jika Anda memiliki pertanyaan mengenai Kebijakan Privasi ini, silakan hubungi kami di:</p>
            <p><strong>Email:</strong> support@srtcorp.com</p>

            <div style={{ marginTop: 48, paddingTop: 24, borderTop: '1px solid #eee', color: '#999', fontSize: 14 }}>
                &copy; 2026 SRT Corp. All rights reserved.
            </div>
        </div>
    );
}
