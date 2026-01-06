<?php

namespace Database\Seeders;

use App\Models\Shift;
use App\Models\Organization;
use Illuminate\Database\Seeder;

class ShiftSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $jakartaBranch = Organization::where('code', 'JKT')->first();
        $surabayaBranch = Organization::where('code', 'SBY')->first();

        // Jakarta - Regular Shift
        Shift::create([
            'name' => 'Regular Shift',
            'organization_id' => $jakartaBranch->id,
            'start_time' => '09:00:00',
            'end_time' => '18:00:00',
            'days' => json_encode(['monday', 'tuesday', 'wednesday', 'thursday', 'friday']),
        ]);

        // Jakarta - Night Shift
        Shift::create([
            'name' => 'Night Shift',
            'organization_id' => $jakartaBranch->id,
            'start_time' => '21:00:00',
            'end_time' => '06:00:00',
            'days' => json_encode(['monday', 'tuesday', 'wednesday', 'thursday', 'friday']),
        ]);

        // Surabaya - Regular Shift
        Shift::create([
            'name' => 'Regular Shift',
            'organization_id' => $surabayaBranch->id,
            'start_time' => '08:00:00',
            'end_time' => '17:00:00',
            'days' => json_encode(['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday']),
        ]);
    }
}
