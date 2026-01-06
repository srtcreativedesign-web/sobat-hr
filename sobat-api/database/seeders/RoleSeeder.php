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
                'description' => 'Super Administrator with full access to all features',
            ],
            [
                'name' => 'admin_cabang',
                'description' => 'Branch Administrator with access to branch operations',
            ],
            [
                'name' => 'manager',
                'description' => 'Manager with approval permissions',
            ],
            [
                'name' => 'staff',
                'description' => 'Regular staff/employee with basic access',
            ],
        ];

        foreach ($roles as $role) {
            Role::create($role);
        }
    }
}
