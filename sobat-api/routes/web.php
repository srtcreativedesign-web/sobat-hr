<?php

use Illuminate\Support\Facades\Route;

Route::get('/', function () {
    return view('welcome');
});

Route::get('/debug-roles', function () {
    \Illuminate\Support\Facades\Artisan::call('optimize:clear');
    return \App\Models\Role::all()->map(function($r) {
        return $r->name . ': ' . ($r->approval_level ?? 'NULL');
    });
});

Route::get('/seed-roles', function () {
    $roles = [
        ['name' => 'super_admin', 'display_name' => 'Super Admin', 'approval_level' => 99],
        ['name' => 'admin_cabang', 'display_name' => 'Admin Cabang', 'approval_level' => 1],
        ['name' => 'manager', 'display_name' => 'Manager', 'approval_level' => 2],
        ['name' => 'staff', 'display_name' => 'Staff', 'approval_level' => 0],
        ['name' => 'coo', 'display_name' => 'COO', 'approval_level' => 3],
        ['name' => 'hrd', 'display_name' => 'HRD', 'approval_level' => 3],
        ['name' => 'manager_divisi', 'display_name' => 'Manager Divisi', 'approval_level' => 2],
        ['name' => 'spv', 'display_name' => 'Supervisor', 'approval_level' => 1],
    ];

    foreach ($roles as $roleData) {
        \App\Models\Role::updateOrCreate(
            ['name' => $roleData['name']],
            $roleData
        );
    }

    return \App\Models\Role::all()->map(function($r) {
        return $r->name . ': ' . ($r->approval_level ?? 'NULL');
    });
});

Route::get('/seed-users', function () {
    // Ensure roles exist and get their IDs
    $cooRole = \App\Models\Role::where('name', 'coo')->first();
    $hrdRole = \App\Models\Role::where('name', 'hrd')->first();
    
    if (!$cooRole || !$hrdRole) {
        return "Roles not found. Run /seed-roles first.";
    }

    // Create or Update COO User
    $cooUser = \App\Models\User::firstOrCreate(
        ['email' => 'coo@sobat.com'],
        [
            'name' => 'COO Sobat',
            'password' => \Illuminate\Support\Facades\Hash::make('password'),
            'role_id' => $cooRole->id
        ]
    );
    // Ensure role is correct if user existed
    if ($cooUser->role_id !== $cooRole->id) {
        $cooUser->update(['role_id' => $cooRole->id]);
    }
    
    // Get first organization
    $org = \App\Models\Organization::first();
    if (!$org) {
        $org = \App\Models\Organization::create([
            'name' => 'Headquarters',
            'type' => 'office',
            'status' => 'active'
        ]);
    }

    // Create Employee record for COO if not exists
    \App\Models\Employee::firstOrCreate(
        ['user_id' => $cooUser->id],
        [
            'full_name' => 'Chief Operating Officer',
             'employee_code' => 'COO001',
             'email' => 'coo@sobat.com',
             'organization_id' => $org->id,
             'position' => 'COO',
             'department' => 'Executive',
             'basic_salary' => 0,
             'join_date' => now(),
             'status' => 'active',
             'birth_date' => '1980-01-01',
             'gender' => 'male',
             'religion' => 'Islam',
             'marital_status' => 'single'
        ]
    );

    // Create or Update HRD User
    $hrdUser = \App\Models\User::firstOrCreate(
        ['email' => 'hrd@sobat.com'],
        [
            'name' => 'HR Manager',
            'password' => \Illuminate\Support\Facades\Hash::make('password'),
            'role_id' => $hrdRole->id
        ]
    );
    if ($hrdUser->role_id !== $hrdRole->id) {
        $hrdUser->update(['role_id' => $hrdRole->id]);
    }

    // Create Employee record for HRD
    \App\Models\Employee::firstOrCreate(
        ['user_id' => $hrdUser->id],
        [
            'full_name' => 'Human Resources',
             'employee_code' => 'HRD001',
             'email' => 'hrd@sobat.com',
             'organization_id' => $org->id,
             'position' => 'HR Manager',
             'department' => 'HR',
             'basic_salary' => 0,
             'join_date' => now(),
             'status' => 'active',
             'birth_date' => '1985-01-01',
             'gender' => 'female',
             'religion' => 'Islam',
             'marital_status' => 'married'
        ]
    );

    return "Users Seeded: COO ID {$cooUser->id}, HRD ID {$hrdUser->id}";
});
