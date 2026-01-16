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

        // Get Organizations
        $ceoOrg = Organization::where('code', 'CEO')->first();
        $holding1 = Organization::where('code', 'HOLD-1')->first();
        $holding2 = Organization::where('code', 'HOLD-2')->first();
        
        // Divisions
        $itDiv = Organization::where('code', 'IT')->first();
        $hrDiv = Organization::where('code', 'HR')->first();
        $miniDiv = Organization::where('code', 'MINI')->first(); // Minimarket

        // Fallback
        $defaultOrg = $ceoOrg ?? Organization::first();

        // 1. Super Admin -> CEO
        if ($superAdminUser) {
            Employee::updateOrCreate(
                ['email' => 'admin@sobat.co.id'],
                [
                    'user_id' => $superAdminUser->id,
                    'organization_id' => $ceoOrg ? $ceoOrg->id : $defaultOrg->id,
                    'employee_code' => 'EMP001',
                    'full_name' => 'Super Admin',
                    'job_level' => 'director', 
                    'track' => 'office',
                    'position' => 'Chief Executive Officer',
                    'join_date' => '2020-01-01',
                    'status' => 'active',
                ]
            );
        }

        // 2. Admin Jakarta -> Holding 1 (Manager Ops)
        if ($adminJakartaUser) {
            Employee::updateOrCreate(
                ['email' => 'admin.jakarta@sobat.co.id'],
                [
                    'user_id' => $adminJakartaUser->id,
                    'organization_id' => $holding1 ? $holding1->id : $defaultOrg->id,
                    'employee_code' => 'EMP002',
                    'full_name' => 'Admin Jakarta',
                    'job_level' => 'manager_ops',
                    'track' => 'operational',
                    'position' => 'Operational Manager',
                    'join_date' => '2020-06-01',
                    'status' => 'active',
                ]
            );
        }

        // 3. John Doe -> IT (Office Staff)
        if ($johnUser) {
            Employee::updateOrCreate(
                ['email' => 'john.doe@sobat.co.id'],
                [
                    'user_id' => $johnUser->id,
                    'organization_id' => $itDiv ? $itDiv->id : $defaultOrg->id,
                    'employee_code' => 'EMP004',
                    'full_name' => 'John Doe',
                    'job_level' => 'staff',
                    'track' => 'office',
                    'position' => 'Software Engineer',
                    'join_date' => '2022-03-15',
                    'status' => 'active',
                ]
            );
        }

        // 4. Jane Smith -> HR (Office Staff)
        if ($janeUser) {
            Employee::updateOrCreate(
                ['email' => 'jane.smith@sobat.co.id'],
                [
                    'user_id' => $janeUser->id,
                    'organization_id' => $hrDiv ? $hrDiv->id : $defaultOrg->id,
                    'employee_code' => 'EMP005',
                    'full_name' => 'Jane Smith',
                    'job_level' => 'staff',
                    'track' => 'office',
                    'position' => 'HR Specialist',
                    'join_date' => '2022-06-01',
                    'status' => 'active',
                ]
            );
        }

        // 5. Michael Johnson -> Minimarket (Operational Crew)
        $michaelUser = User::firstOrCreate(
            ['email' => 'michael.johnson@sobat.co.id'],
            [
                'name' => 'Michael Johnson',
                'password' => bcrypt('password123'),
                'role_id' => Role::where('name', 'staff')->first()->id ?? 1,
            ]
        );

        if ($michaelUser) {
            Employee::updateOrCreate(
                ['email' => 'michael.johnson@sobat.co.id'],
                [
                    'user_id' => $michaelUser->id,
                    'organization_id' => $miniDiv ? $miniDiv->id : $defaultOrg->id,
                    'employee_code' => 'EMP006',
                    'full_name' => 'Michael Johnson',
                    'job_level' => 'crew',
                    'track' => 'operational',
                    'position' => 'Store Crew',
                    'join_date' => '2024-01-15',
                    'status' => 'active',
                ]
            );
        }
    }
}
