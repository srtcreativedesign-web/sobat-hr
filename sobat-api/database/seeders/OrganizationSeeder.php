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
        // Headquarters
        $hq = Organization::create([
            'name' => 'PT SOBAT Indonesia',
            'type' => 'headquarters',
            'address' => 'Jakarta, Indonesia',
            'city' => 'Jakarta',
        ]);

        // Branches
        $jakartaBranch = Organization::create([
            'name' => 'Jakarta Branch',
            'type' => 'branch',
            'parent_id' => $hq->id,
            'address' => 'Jakarta Selatan',
            'city' => 'Jakarta',
        ]);

        $surabayaBranch = Organization::create([
            'name' => 'Surabaya Branch',
            'type' => 'branch',
            'parent_id' => $hq->id,
            'address' => 'Surabaya',
            'city' => 'Surabaya',
        ]);

        // Departments under Jakarta Branch
        Organization::create([
            'name' => 'IT Department',
            'type' => 'department',
            'parent_id' => $jakartaBranch->id,
        ]);

        Organization::create([
            'name' => 'HR Department',
            'type' => 'department',
            'parent_id' => $jakartaBranch->id,
        ]);

        Organization::create([
            'name' => 'Finance Department',
            'type' => 'department',
            'parent_id' => $jakartaBranch->id,
        ]);
    }
}
