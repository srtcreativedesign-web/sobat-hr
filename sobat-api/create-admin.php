<?php

require __DIR__.'/vendor/autoload.php';

$app = require_once __DIR__.'/bootstrap/app.php';
$app->make('Illuminate\Contracts\Console\Kernel')->bootstrap();

use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;

// Get super_admin role
$role = DB::table('roles')->where('name', 'super_admin')->first();

if (!$role) {
    echo "Error: Role 'super_admin' tidak ditemukan. Jalankan seeder terlebih dahulu.\n";
    exit(1);
}

// Check if user already exists
$existingUser = DB::table('users')->where('email', 'superadmin@sobat.com')->first();

if ($existingUser) {
    // Update password
    DB::table('users')
        ->where('email', 'superadmin@sobat.com')
        ->update([
            'password' => Hash::make('Admin123!@#'),
            'updated_at' => now()
        ]);
    echo "Password untuk superadmin@sobat.com berhasil direset!\n";
} else {
    // Create new user
    DB::table('users')->insert([
        'name' => 'Administrator',
        'email' => 'superadmin@sobat.com',
        'password' => Hash::make('Admin123!@#'),
        'role_id' => $role->id,
        'created_at' => now(),
        'updated_at' => now()
    ]);
    echo "User super admin berhasil dibuat!\n";
}

echo "\n=== KREDENSIAL LOGIN ===\n";
echo "Email: superadmin@sobat.com\n";
echo "Password: Admin123!@#\n";
echo "========================\n";
