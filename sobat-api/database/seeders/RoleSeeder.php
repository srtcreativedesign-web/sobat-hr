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
            [
                'name' => 'super_admin',
                'display_name' => 'Super Admin',
                'description' => 'Super Administrator with full access to all features',
            ],
            [
                'name' => 'admin_cabang',
                'display_name' => 'Admin Cabang',
                'description' => 'Branch Administrator with access to branch operations',
            ],
            [
                'name' => 'manager',
                'display_name' => 'Manager',
                'description' => 'Manager with approval permissions',
            ],
            [
                'name' => 'staff',
                'display_name' => 'Staff',
                'description' => 'Regular staff/employee with basic access',
            ],
        ];

        foreach ($roles as $role) {
            Role::create($role);
        }
    }
}
