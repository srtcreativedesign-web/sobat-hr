<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\Announcement;

class AnnouncementSeeder extends Seeder
{
    public function run(): void
    {
        Announcement::create([
            'title' => 'Libur Nasional & Cuti Bersama 2026',
            'content' => 'Berdasarkan SKB 3 Menteri, berikut adalah jadwal libur nasional dan cuti bersama tahun 2026. Mohon diperhatikan untuk pengajuan cuti.',
            'category' => 'news',
            'is_published' => true,
        ]);

        Announcement::create([
            'title' => 'Pemeliharaan Sistem HRIS',
            'content' => 'Sistem akan mengalami downtime pada hari Sabtu, 20 Januari 2026 pukul 22:00 - 02:00 WIB untuk pemeliharaan rutin.',
            'category' => 'news',
            'is_published' => true,
        ]);

        Announcement::create([
            'title' => 'Kebijakan Klaim Kacamata Terbaru',
            'content' => 'Perusahaan memperbarui plafon klaim kacamata bagi karyawan tetap. Detail lengkap dapat dilihat pada lampiran.',
            'category' => 'policy',
            'is_published' => true,
        ]);
        
        Announcement::create([
             'title' => 'Draft Kebijakan Remote Working',
             'content' => 'Draft ini masih dalam tahap review dan belum berlaku efektif.',
             'category' => 'policy',
             'is_published' => false,
        ]);
    }
}
