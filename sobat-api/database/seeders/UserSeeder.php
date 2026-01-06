<?php

namespace Database\Seeders;

use App\Models\User;
use App\Models\Role;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class UserSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $superAdminRole = Role::where('name', 'super_admin')->first();
        $adminCabangRole = Role::where('name', 'admin_cabang')->first();
        $staffRole = Role::where('name', 'staff')->first();

        // Super Admin
        User::create([
            'name' => 'Super Admin',
            'email' => 'admin@sobat.co.id',
            'password' => Hash::make('password123'),
            'role_id' => $superAdminRole->id,
        ]);

        // Admin Cabang Jakarta
        User::create([
            'name' => 'Admin Jakarta',
            'email' => 'admin.jakarta@sobat.co.id',
            'password' => Hash::make('password123'),
            'role_id' => $adminCabangRole->id,
        ]);

        // Admin Cabang Surabaya
        User::create([
            'name' => 'Admin Surabaya',
            'email' => 'admin.surabaya@sobat.co.id',
            'password' => Hash::make('password123'),
            'role_id' => $adminCabangRole->id,
        ]);

        // Staff
        User::create([
            'name' => 'John Doe',
            'email' => 'john.doe@sobat.co.id',
            'password' => Hash::make('password123'),
            'role_id' => $staffRole->id,
        ]);

        User::create([
            'name' => 'Jane Smith',
            'email' => 'jane.smith@sobat.co.id',
            'password' => Hash::make('password123'),
            'role_id' => $staffRole->id,
        ]);
    }
}
