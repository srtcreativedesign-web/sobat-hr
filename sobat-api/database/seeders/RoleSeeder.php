<?php

namespace Database\Seeders;

use App\Models\Role;
use Illuminate\Database\Seeder;

class RoleSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $roles = [
            // Track Operasional - No Approval
            [
                'name' => 'crew',
                'display_name' => 'Crew',
                'description' => 'Crew operasional',
                'approval_level' => null,
            ],
            [
                'name' => 'leader',
                'display_name' => 'Leader',
                'description' => 'Leader operasional',
                'approval_level' => null,
            ],
            // Track Office - No Approval
            [
                'name' => 'staff',
                'display_name' => 'Staff',
                'description' => 'Staff kantor',
                'approval_level' => null,
            ],
            // Approval Level 1
            [
                'name' => 'spv',
                'display_name' => 'Supervisor',
                'description' => 'Supervisor dengan akses approval level 1',
                'approval_level' => 1,
            ],
            // Approval Level 2
            [
                'name' => 'manager_divisi',
                'display_name' => 'Manager Divisi',
                'description' => 'Manager Divisi dengan akses approval level 2',
                'approval_level' => 2,
            ],
            // Approval Level 3 (Super Admin / Manager HRD)
            [
                'name' => 'super_admin',
                'display_name' => 'Super Admin / Manager HRD',
                'description' => 'Super Admin dan Manager HRD dengan akses approval level 3 (full access)',
                'approval_level' => 3,
            ],
        ];

        foreach ($roles as $role) {
            Role::create($role);
        }
    }
}
