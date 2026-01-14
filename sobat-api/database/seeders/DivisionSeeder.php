<?php

namespace Database\Seeders;

use App\Models\Organization;
use Illuminate\Database\Seeder;

class DivisionSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $divisions = [
            'Holding',
            'HR',
            'TnD',
            'IT Development',
            'Business Development',
            'FAT',
            'FnB',
            'Cellular',
            'Project',
            'Wrapping',
            'Minimarket',
            'Reflexology',
            'HANS',
            'Money Changer',
            'CCTV',
        ];

        foreach ($divisions as $name) {
            Organization::firstOrCreate(
                ['name' => $name],
                [
                    'type' => 'division',
                    'parent_id' => null, // Top level or adjust if needed
                    'address' => null,
                    'city' => null,
                ]
            );
        }
    }
}
