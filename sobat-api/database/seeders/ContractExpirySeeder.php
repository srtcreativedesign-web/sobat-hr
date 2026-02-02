<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use App\Models\Employee;
use App\Models\User;
use Carbon\Carbon;
use Illuminate\Support\Facades\Hash;
use App\Models\Organization;

class ContractExpirySeeder extends Seeder
{
    public function run()
    {
        // 1. Create User
        $user = User::firstOrCreate(
            ['email' => 'expiring@example.com'],
            [
                'name' => 'John Expiring',
                'password' => Hash::make('password'),
                'role' => 'staff',
            ]
        );

        // 2. Create Employee
        Employee::updateOrCreate(
            ['email' => 'expiring@example.com'],
            [
                'user_id' => $user->id,
                'organization_id' => Organization::first()->id ?? 1,
                'employee_code' => 'EXP001',
                'full_name' => 'John Expiring',
                'position' => 'Staff',
                'employment_status' => 'contract',
                'join_date' => Carbon::now()->subYear(),
                'contract_start_date' => Carbon::now()->subYear(),
                'contract_end_date' => Carbon::now()->addDays(15), // Reset to 15 days from now
                'status' => 'active',
            ]
        );

        $this->command->info('Created test employee John Expiring with 15 days remaining contract.');
    }
}
