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
        // Use existing divisions from DivisionSeeder (Holding, Project, etc.)
        $holding = Organization::where('name', 'Holding')->first();
        $project = Organization::where('name', 'Project')->first();
        $defaultOrg = Organization::first();

        $org1 = $holding ? $holding->id : $defaultOrg->id;
        $org2 = $project ? $project->id : $defaultOrg->id;

        // Regular Shift (Holding)
        Shift::create([
            'name' => 'Regular Shift',
            'organization_id' => $org1,
            'start_time' => '09:00:00',
            'end_time' => '18:00:00',
        ]);

        // Night Shift (Holding)
        Shift::create([
            'name' => 'Night Shift',
            'organization_id' => $org1,
            'start_time' => '21:00:00',
            'end_time' => '06:00:00',
        ]);

        // Regular Shift (Project)
        Shift::create([
            'name' => 'Regular Shift',
            'organization_id' => $org2,
            'start_time' => '08:00:00',
            'end_time' => '17:00:00',
        ]);
    }
}
