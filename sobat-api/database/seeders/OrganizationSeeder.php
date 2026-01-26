<?php

namespace Database\Seeders;

use App\Models\Organization;
use Illuminate\Database\Seeder;

class OrganizationSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $ceo = Organization::create([
            'name' => 'CEO',
            'code' => 'CEO',
            'type' => 'Board Of Directors',
            'parent_id' => null,
            'address' => 'Jl. Jendral Sudirman No. 1, Jakarta',
            'phone' => '021-1234567',
            'email' => 'hq@sobat.co.id',
            'description' => 'CEO Sobat HR. Mengelola seluruh operasional perusahaan secara nasional.',
            'latitude' => '-6.13778',
            'longitude' => '106.62295',
            'radius_meters' => 100,
        ]);
        // 2. COO
        $coo = Organization::create([
            'name' => 'Direktur Operasional',
            'code' => 'COO',
            'type' => 'Board Of Directors',
            'parent_id' => $ceo->id,
            'address' => 'Jl. Jendral Sudirman No. 1, Jakarta',
            'phone' => '021-1234567',
            'email' => 'hq@sobat.co.id',
            'description' => 'Direktur Operasional Sobat HR. Mengelola seluruh operasional perusahaan secara nasional.',
            'latitude' => '-6.13778',
            'longitude' => '106.62295',
            'radius_meters' => 100,
        ]);

        // 2. CFO
        $cfo = Organization::create([
            'name' => 'Direktur Keuangan',
            'code' => 'CFO',
            'type' => 'Board Of Directors',
            'parent_id' => $ceo->id,
            'address' => 'Jl. MH Thamrin No. 10, Jakarta Pusat',
            'phone' => '021-9876543',
            'email' => 'jkt@sobat.co.id',
            'description' => 'Menangani Semua Aspek Keuangan Perusahaan.',
            'latitude' => '-6.13778',
            'longitude' => '106.62295',
            'radius_meters' => 100,
        ]);

        // 3. Holdings
        $holdings1 = Organization::create([
            'name' => 'Holding 1',
            'code' => 'HOLD-1',
            'type' => 'Holdings',
            'parent_id' => $coo->id,
            'line_style' => 'solid',
            'description' => 'Menangani rekrutmen, payroll, dan kesejahteraan karyawan.',
        ]);

        $holdings2 = Organization::create([
            'name' => 'Holding 2',
            'code' => 'HOLD-2',
            'type' => 'Holdings',
            'parent_id' => $coo->id,
            'line_style' => 'solid',
            'description' => 'Menangani rekrutmen, payroll, dan kesejahteraan karyawan.',
        ]);

        // 4. Branch Surabaya (Child of HQ)
        $holdings3 = Organization::create([
            'name' => 'Holding 3',
            'code' => 'HOLD-3',
            'type' => 'Holdings',
            'parent_id' => $cfo->id,
            'line_style' => 'solid',
            'description' => 'Menangani rekrutmen, payroll, dan kesejahteraan karyawan.',
        ]);

        // 5. Holding 1 Divisions (Retail & Operations)
        $retailDivisions = [
            ['name' => 'Minimarket', 'code' => 'MINI', 'type' => 'Minimarket'],
            ['name' => 'Wrapping', 'code' => 'WRAP', 'type' => 'Wrapping'],
            ['name' => 'Reflexiology', 'code' => 'REFL', 'type' => 'Reflexiology'],
            ['name' => 'Celluller', 'code' => 'CELL', 'type' => 'Celluller'],
            ['name' => 'Hans', 'code' => 'HANS', 'type' => 'Hans'],
            ['name' => 'FnB', 'code' => 'FNB', 'type' => 'FnB'],
        ];

        foreach ($retailDivisions as $div) {
            Organization::create([
                'name' => $div['name'],
                'code' => $div['code'],
                'type' => $div['type'],
                'parent_id' => $holdings1->id,
                'description' => 'Divisi ' . $div['name'],
            ]);
        }

        // 6. Holding 2 Divisions (Office & Support)
        $officeDivisions = [
            ['name' => 'Human Resources', 'code' => 'HR', 'type' => 'HR'],
            ['name' => 'Information Technology', 'code' => 'IT', 'type' => 'IT'],
            ['name' => 'TnD', 'code' => 'TND', 'type' => 'TnD'],
            ['name' => 'Bussiness Development', 'code' => 'BD', 'type' => 'Bussiness Development'],
            ['name' => 'Finance Accounting Tax', 'code' => 'FAT', 'type' => 'FAT'],
            ['name' => 'Project', 'code' => 'PROJ', 'type' => 'Project'],
        ];

        foreach ($officeDivisions as $div) {
            Organization::create([
                'name' => $div['name'],
                'code' => $div['code'],
                'type' => $div['type'],
                'parent_id' => $holdings2->id, // Assigned to Holding 2
                'description' => 'Divisi ' . $div['name'],
            ]);
        }

        // 7. Holding 3 Divisions (General Services)
        $generalDivisions = [
            ['name' => 'CCTV', 'code' => 'CCTV', 'type' => 'CCTV'],
            ['name' => 'Cleaner', 'code' => 'CLN', 'type' => 'Cleaner'],
        ];

        foreach ($generalDivisions as $div) {
            Organization::create([
                'name' => $div['name'],
                'code' => $div['code'],
                'type' => $div['type'],
                'parent_id' => $holdings3->id, // Assigned to Holding 3
                'description' => 'Divisi ' . $div['name'],
            ]);
        }
    }
}
