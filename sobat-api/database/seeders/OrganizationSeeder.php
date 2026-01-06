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
            'code' => 'HQ',
            'type' => 'headquarters',
            'address' => 'Jakarta, Indonesia',
            'phone' => '021-12345678',
            'email' => 'hq@sobat.co.id',
        ]);

        // Branches
        $jakartaBranch = Organization::create([
            'name' => 'Jakarta Branch',
            'code' => 'JKT',
            'type' => 'branch',
            'parent_id' => $hq->id,
            'address' => 'Jakarta Selatan',
            'phone' => '021-11111111',
            'email' => 'jakarta@sobat.co.id',
        ]);

        $surabayaBranch = Organization::create([
            'name' => 'Surabaya Branch',
            'code' => 'SBY',
            'type' => 'branch',
            'parent_id' => $hq->id,
            'address' => 'Surabaya',
            'phone' => '031-22222222',
            'email' => 'surabaya@sobat.co.id',
        ]);

        // Departments under Jakarta Branch
        Organization::create([
            'name' => 'IT Department',
            'code' => 'JKT-IT',
            'type' => 'department',
            'parent_id' => $jakartaBranch->id,
        ]);

        Organization::create([
            'name' => 'HR Department',
            'code' => 'JKT-HR',
            'type' => 'department',
            'parent_id' => $jakartaBranch->id,
        ]);

        Organization::create([
            'name' => 'Finance Department',
            'code' => 'JKT-FIN',
            'type' => 'department',
            'parent_id' => $jakartaBranch->id,
        ]);
    }
}
