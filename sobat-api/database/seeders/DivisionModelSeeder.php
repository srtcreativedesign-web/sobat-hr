<?php

namespace Database\Seeders;

use App\Models\Division;
use Illuminate\Database\Seeder;

class DivisionModelSeeder extends Seeder
{
    public function run(): void
    {
        $divisions = [
            ['name' => 'Holding', 'code' => 'HOLD'],
            ['name' => 'HR', 'code' => 'HR'],
            ['name' => 'TnD', 'code' => 'TND'],
            ['name' => 'IT Development', 'code' => 'IT'],
            ['name' => 'Business Development', 'code' => 'BD'],
            ['name' => 'FAT', 'code' => 'FAT'],
            ['name' => 'FnB', 'code' => 'FNB'],
            ['name' => 'Cellular', 'code' => 'CELL'],
            ['name' => 'Project', 'code' => 'PROJ'],
            ['name' => 'Wrapping', 'code' => 'WRAP'],
            ['name' => 'Minimarket', 'code' => 'MINI'],
            ['name' => 'Reflexology', 'code' => 'REFL'],
            ['name' => 'HANS', 'code' => 'HANS'],
            ['name' => 'Money Changer', 'code' => 'MC'],
            ['name' => 'CCTV', 'code' => 'CCTV'],
        ];

        foreach ($divisions as $div) {
            Division::firstOrCreate(
                ['name' => $div['name']],
                ['code' => $div['code']]
            );
        }
    }
}
