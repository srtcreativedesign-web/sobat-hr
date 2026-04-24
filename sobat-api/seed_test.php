<?php
require 'vendor/autoload.php';
$app = require_once 'bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

use App\Models\User;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\DB;

DB::statement('SET FOREIGN_KEY_CHECKS=0;');

User::truncate();
DB::table('employees')->truncate();

$user = User::create([
    'name' => 'Demo HRIS',
    'email' => 'admin@sobat.co.id',
    'password' => Hash::make('password123'),
    'role_id' => 1,
]);

DB::table('employees')->insert([
    'user_id' => $user->id,
    'employee_code' => 'EMP001',
    'full_name' => 'Demo HRIS',
    'email' => 'admin@sobat.co.id',
    'phone' => '081234567890',
    'organization_id' => 1,
    'division_id' => 1,
    'status' => 'active',
    'position' => 'Developer',
    'track' => 'office',
    'job_level' => 'staff',
    'join_date' => '2020-01-01',
    'created_at' => now(),
    'updated_at' => now(),
]);

DB::statement('SET FOREIGN_KEY_CHECKS=1;');
echo "Test User created!\n";
