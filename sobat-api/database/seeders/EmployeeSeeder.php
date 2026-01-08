<?php

namespace Database\Seeders;

use App\Models\Employee;
use App\Models\User;
use App\Models\Organization;
use App\Models\Role;
use Illuminate\Database\Seeder;

class EmployeeSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $superAdminUser = User::where('email', 'admin@sobat.co.id')->first();
        $adminJakartaUser = User::where('email', 'admin.jakarta@sobat.co.id')->first();
        $adminSurabayaUser = User::where('email', 'admin.surabaya@sobat.co.id')->first();
        $johnUser = User::where('email', 'john.doe@sobat.co.id')->first();
        $janeUser = User::where('email', 'jane.smith@sobat.co.id')->first();

        $hq = Organization::where('type', 'headquarters')->first();
        $jakartaBranch = Organization::where('name', 'Jakarta Branch')->first();
        $surabayaBranch = Organization::where('name', 'Surabaya Branch')->first();

        // Super Admin Employee
        Employee::create([
            'user_id' => $superAdminUser->id,
            'organization_id' => $hq->id,
            'employee_code' => 'EMP001',
            'full_name' => 'Super Admin',
            'email' => 'admin@sobat.co.id',
            'phone' => '081234567890',
            'address' => 'Jakarta',
            'birth_date' => '1985-01-15',
            'gender' => 'male',
            'position' => 'Chief Executive Officer',
            'level' => 'Senior',
            'basic_salary' => 25000000,
            'join_date' => '2020-01-01',
            'employment_status' => 'permanent',
            'status' => 'active',
        ]);

        // Admin Jakarta Employee
        Employee::create([
            'user_id' => $adminJakartaUser->id,
            'organization_id' => $jakartaBranch->id,
            'employee_code' => 'EMP002',
            'full_name' => 'Admin Jakarta',
            'email' => 'admin.jakarta@sobat.co.id',
            'phone' => '081234567891',
            'address' => 'Jakarta',
            'birth_date' => '1988-03-20',
            'gender' => 'male',
            'position' => 'Branch Manager',
            'level' => 'Manager',
            'basic_salary' => 15000000,
            'join_date' => '2020-06-01',
            'employment_status' => 'permanent',
            'status' => 'active',
        ]);

        // Admin Surabaya Employee
        Employee::create([
            'user_id' => $adminSurabayaUser->id,
            'organization_id' => $surabayaBranch->id,
            'employee_code' => 'EMP003',
            'full_name' => 'Admin Surabaya',
            'email' => 'admin.surabaya@sobat.co.id',
            'phone' => '081234567892',
            'address' => 'Surabaya',
            'birth_date' => '1987-05-10',
            'gender' => 'female',
            'position' => 'Branch Manager',
            'level' => 'Manager',
            'basic_salary' => 15000000,
            'join_date' => '2021-01-01',
            'employment_status' => 'permanent',
            'status' => 'active',
        ]);

        // Staff - John Doe
        Employee::create([
            'user_id' => $johnUser->id,
            'organization_id' => $jakartaBranch->id,
            'employee_code' => 'EMP004',
            'full_name' => 'John Doe',
            'email' => 'john.doe@sobat.co.id',
            'phone' => '081234567893',
            'address' => 'Jakarta',
            'birth_date' => '1992-07-25',
            'gender' => 'male',
            'position' => 'Software Engineer',
            'level' => 'Junior',
            'basic_salary' => 8000000,
            'join_date' => '2022-03-15',
            'employment_status' => 'permanent',
            'status' => 'active',
        ]);

        // Staff - Jane Smith
        Employee::create([
            'user_id' => $janeUser->id,
            'organization_id' => $jakartaBranch->id,
            'employee_code' => 'EMP005',
            'full_name' => 'Jane Smith',
            'email' => 'jane.smith@sobat.co.id',
            'phone' => '081234567894',
            'address' => 'Jakarta',
            'birth_date' => '1994-09-12',
            'gender' => 'female',
            'position' => 'HR Specialist',
            'level' => 'Junior',
            'basic_salary' => 7000000,
            'join_date' => '2022-06-01',
            'employment_status' => 'contract',
            'contract_end_date' => '2026-02-01',
            'status' => 'active',
        ]);

        // Additional contract employees expiring soon
        $organizations = Organization::all();
        
        // Create a temporary user for contract employees
        $michaelUser = User::create([
            'name' => 'Michael Johnson',
            'email' => 'michael.johnson@sobat.co.id',
            'password' => bcrypt('password123'),
            'role_id' => Role::where('name', 'staff')->first()->id,
        ]);

        Employee::create([
            'user_id' => $michaelUser->id,
            'organization_id' => $jakartaBranch->id,
            'employee_code' => 'EMP006',
            'full_name' => 'Michael Johnson',
            'email' => 'michael.johnson@sobat.co.id',
            'phone' => '081234567895',
            'address' => 'Jakarta',
            'birth_date' => '1990-04-18',
            'gender' => 'male',
            'position' => 'Marketing Specialist',
            'level' => 'Junior',
            'basic_salary' => 7500000,
            'join_date' => '2024-01-15',
            'employment_status' => 'contract',
            'contract_end_date' => '2026-01-15',
            'status' => 'active',
        ]);

        $sarahUser = User::create([
            'name' => 'Sarah Williams',
            'email' => 'sarah.williams@sobat.co.id',
            'password' => bcrypt('password123'),
            'role_id' => Role::where('name', 'staff')->first()->id,
        ]);

        Employee::create([
            'user_id' => $sarahUser->id,
            'organization_id' => $surabayaBranch->id,
            'employee_code' => 'EMP007',
            'full_name' => 'Sarah Williams',
            'email' => 'sarah.williams@sobat.co.id',
            'phone' => '081234567896',
            'address' => 'Surabaya',
            'birth_date' => '1993-08-22',
            'gender' => 'female',
            'position' => 'Accountant',
            'level' => 'Junior',
            'basic_salary' => 7000000,
            'join_date' => '2024-01-20',
            'employment_status' => 'contract',
            'contract_end_date' => '2026-01-20',
            'status' => 'active',
        ]);
    }
}
