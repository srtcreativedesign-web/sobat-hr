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

        $hq = Organization::where('code', 'HQ')->first();
        $jakartaBranch = Organization::where('code', 'JKT')->first();
        $surabayaBranch = Organization::where('code', 'SBY')->first();

        $superAdminRole = Role::where('name', 'super_admin')->first();
        $adminCabangRole = Role::where('name', 'admin_cabang')->first();
        $staffRole = Role::where('name', 'staff')->first();

        // Super Admin Employee
        Employee::create([
            'user_id' => $superAdminUser->id,
            'organization_id' => $hq->id,
            'role_id' => $superAdminRole->id,
            'employee_number' => 'EMP001',
            'full_name' => 'Super Admin',
            'email' => 'admin@sobat.co.id',
            'phone' => '081234567890',
            'address' => 'Jakarta',
            'date_of_birth' => '1985-01-15',
            'join_date' => '2020-01-01',
            'position' => 'Chief Executive Officer',
            'department' => 'Management',
            'base_salary' => 25000000,
            'status' => 'active',
            'contract_type' => 'permanent',
        ]);

        // Admin Jakarta Employee
        Employee::create([
            'user_id' => $adminJakartaUser->id,
            'organization_id' => $jakartaBranch->id,
            'role_id' => $adminCabangRole->id,
            'employee_number' => 'EMP002',
            'full_name' => 'Admin Jakarta',
            'email' => 'admin.jakarta@sobat.co.id',
            'phone' => '081234567891',
            'address' => 'Jakarta',
            'date_of_birth' => '1988-03-20',
            'join_date' => '2020-06-01',
            'position' => 'Branch Manager',
            'department' => 'Management',
            'base_salary' => 15000000,
            'status' => 'active',
            'contract_type' => 'permanent',
        ]);

        // Admin Surabaya Employee
        Employee::create([
            'user_id' => $adminSurabayaUser->id,
            'organization_id' => $surabayaBranch->id,
            'role_id' => $adminCabangRole->id,
            'employee_number' => 'EMP003',
            'full_name' => 'Admin Surabaya',
            'email' => 'admin.surabaya@sobat.co.id',
            'phone' => '081234567892',
            'address' => 'Surabaya',
            'date_of_birth' => '1987-05-10',
            'join_date' => '2021-01-01',
            'position' => 'Branch Manager',
            'department' => 'Management',
            'base_salary' => 15000000,
            'status' => 'active',
            'contract_type' => 'permanent',
        ]);

        // Staff - John Doe
        Employee::create([
            'user_id' => $johnUser->id,
            'organization_id' => $jakartaBranch->id,
            'role_id' => $staffRole->id,
            'employee_number' => 'EMP004',
            'full_name' => 'John Doe',
            'email' => 'john.doe@sobat.co.id',
            'phone' => '081234567893',
            'address' => 'Jakarta',
            'date_of_birth' => '1992-07-25',
            'join_date' => '2022-03-15',
            'position' => 'Software Engineer',
            'department' => 'IT',
            'base_salary' => 8000000,
            'status' => 'active',
            'contract_type' => 'permanent',
        ]);

        // Staff - Jane Smith
        Employee::create([
            'user_id' => $janeUser->id,
            'organization_id' => $jakartaBranch->id,
            'role_id' => $staffRole->id,
            'employee_number' => 'EMP005',
            'full_name' => 'Jane Smith',
            'email' => 'jane.smith@sobat.co.id',
            'phone' => '081234567894',
            'address' => 'Jakarta',
            'date_of_birth' => '1994-09-12',
            'join_date' => '2022-06-01',
            'position' => 'HR Specialist',
            'department' => 'HR',
            'base_salary' => 7000000,
            'status' => 'active',
            'contract_type' => 'contract',
            'contract_end_date' => '2026-06-01',
        ]);
    }
}
