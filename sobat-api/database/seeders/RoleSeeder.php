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
            // Approval Level 3 - HRD (Final Approver for Office Track)
            [
                'name' => 'hrd',
                'display_name' => 'Manager HRD',
                'description' => 'Manager HRD dengan akses approval level 3',
                'approval_level' => 3,
            ],
            // Approval Level 3 - COO (Final Approver for Manager-level requests)
            [
                'name' => 'coo',
                'display_name' => 'COO / Direktur Operasional',
                'description' => 'COO dengan akses approval level 3 untuk pengajuan manager',
                'approval_level' => 3,
            ],
            // Super Admin (Full Access)
            [
                'name' => 'super_admin',
                'display_name' => 'Super Admin',
                'description' => 'Super Admin dengan full access ke semua fitur',
                'approval_level' => 3,
            ],
        ];

        foreach ($roles as $role) {
            Role::updateOrCreate(
                ['name' => $role['name']],
                $role
            );
        }
    }
}
