<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Employee;

class EmployeeController extends Controller
{
    /**
     * Display a listing of employees
     */
    public function index(Request $request)
    {
        $query = Employee::with(['user', 'organization', 'role']);

        // Filter by organization
        if ($request->has('organization_id')) {
            $query->where('organization_id', $request->organization_id);
        }

        // Filter by status
        if ($request->has('status')) {
            $query->where('status', $request->status);
        }

        // Search by name or employee number
        if ($request->has('search')) {
            $search = $request->search;
            $query->where(function ($q) use ($search) {
                $q->where('full_name', 'like', "%{$search}%")
                    ->orWhere('employee_code', 'like', "%{$search}%");
            });
        }

        $employees = $query->paginate(20);

        return response()->json($employees);
    }

    /**
     * Store a newly created employee
     */
    public function store(Request $request)
    {
        // Allow partial employee creation for mobile profile flow.
        // Keep `full_name` required but make other HR fields nullable so
        // the client can create/update progressively.
        $validated = $request->validate([
            'user_id' => 'nullable|exists:users,id',
            'organization_id' => 'nullable|exists:organizations,id',
            'role_id' => 'nullable|exists:roles,id',
            'employee_number' => 'nullable|string|unique:employees',
            'employee_code' => 'nullable|string|unique:employees',
            'full_name' => 'required|string|max:255',
            'email' => 'nullable|email|unique:employees',
            'phone' => 'nullable|string',
            'address' => 'nullable|string',
            'date_of_birth' => 'nullable|date',
            'join_date' => 'nullable|date',
            'position' => 'nullable|string',
            'department' => 'nullable|string',
            'base_salary' => 'nullable|numeric|min:0',
            'status' => 'nullable|in:active,inactive,resigned',
            'contract_type' => 'nullable|in:permanent,contract,probation',
            'contract_end_date' => 'nullable|date',
            // Additional employee profile fields
            'place_of_birth' => 'nullable|string',
            'ktp_address' => 'nullable|string',
            'current_address' => 'nullable|string',
            'gender' => 'nullable|in:male,female',
            'religion' => 'nullable|string',
            'marital_status' => 'nullable|string',
            'ptkp_status' => 'nullable|string',
            'nik' => 'nullable|string',
            'npwp' => 'nullable|string',
            'bank_account_number' => 'nullable|string',
            'bank_account_name' => 'nullable|string',
            'father_name' => 'nullable|string',
            'mother_name' => 'nullable|string',
            'spouse_name' => 'nullable|string',
            'family_contact_number' => 'nullable|string',
            'education' => 'nullable|string',
            'supervisor_name' => 'nullable|string',
            'supervisor_position' => 'nullable|string',
            'photo_path' => 'nullable|string',
        ]);

        // Map incoming keys to actual DB columns where names differ
        $data = [];
        if (isset($validated['user_id']))
            $data['user_id'] = $validated['user_id'];
        if (isset($validated['organization_id']))
            $data['organization_id'] = $validated['organization_id'];
        if (isset($validated['role_id']))
            $data['role_id'] = $validated['role_id'];
        // support both employee_number and employee_code from clients
        if (isset($validated['employee_number']))
            $data['employee_code'] = $validated['employee_number'];
        if (isset($validated['employee_code']))
            $data['employee_code'] = $validated['employee_code'];
        $data['full_name'] = $validated['full_name'];
        if (isset($validated['email']))
            $data['email'] = $validated['email'];
        if (isset($validated['phone']))
            $data['phone'] = $validated['phone'];
        if (isset($validated['address']))
            $data['address'] = $validated['address'];
        if (isset($validated['date_of_birth']))
            $data['birth_date'] = $validated['date_of_birth'];
        if (isset($validated['birth_date']))
            $data['birth_date'] = $validated['birth_date'];
        if (isset($validated['join_date']))
            $data['join_date'] = $validated['join_date'];
        if (isset($validated['position']))
            $data['position'] = $validated['position'];
        if (isset($validated['level']))
            $data['level'] = $validated['level'];
        if (isset($validated['base_salary']))
            $data['basic_salary'] = $validated['base_salary'];
        if (isset($validated['basic_salary']))
            $data['basic_salary'] = $validated['basic_salary'];
        if (isset($validated['contract_end_date']))
            $data['contract_end_date'] = $validated['contract_end_date'];
        if (isset($validated['contract_type']))
            $data['employment_status'] = $validated['contract_type'];
        if (isset($validated['employment_status']))
            $data['employment_status'] = $validated['employment_status'];
        if (isset($validated['status']))
            $data['status'] = $validated['status'];

        // New additional fields added by migration (same names)
        $extraFields = [
            'place_of_birth',
            'ktp_address',
            'current_address',
            'gender',
            'religion',
            'marital_status',
            'ptkp_status',
            'nik',
            'npwp',
            'bank_account_number',
            'bank_account_name',
            'father_name',
            'mother_name',
            'spouse_name',
            'family_contact_number',
            'education',
            'supervisor_name',
            'supervisor_position',
            'photo_path'
        ];
        foreach ($extraFields as $f) {
            if (isset($validated[$f]))
                $data[$f] = $validated[$f];
        }

        // If user_id not provided, link created employee to the authenticated user when available
        if (empty($data['user_id'])) {
            $authUser = $request->user();
            if ($authUser) {
                $data['user_id'] = $authUser->id;
            }
        }

        // Ensure required non-null DB columns exist: generate an employee_code if missing
        if (empty($data['employee_code'])) {
            $authUser = $request->user();
            $uid = $data['user_id'] ?? ($authUser ? $authUser->id : null);
            $prefix = $uid ? ('EMP' . $uid . '-') : 'EMP-';
            $data['employee_code'] = $prefix . substr(uniqid(), -6);
        }

        // Default organization_id to first available organization if not set
        if (empty($data['organization_id'])) {
            $defaultOrg = \App\Models\Organization::first();
            if ($defaultOrg) {
                $data['organization_id'] = $defaultOrg->id;
            }
        }

        // Default required text fields to prevent MySQL errors
        if (empty($data['position'])) {
            $data['position'] = '-';
        }
        if (empty($data['join_date'])) {
            $data['join_date'] = now()->toDateString();
        }

        // Check if employee with same full_name already exists
        // If yes, update existing record instead of creating duplicate
        $existingEmployee = Employee::where('full_name', $data['full_name'])->first();

        if ($existingEmployee) {
            // Update existing employee
            $existingEmployee->update($data);
            return response()->json($existingEmployee, 200);
        } else {
            // Create new employee
            $employee = Employee::create($data);
            return response()->json($employee, 201);
        }
    }

    /**
     * Display the specified employee
     */
    public function show(string $id)
    {
        $employee = Employee::with(['user', 'organization', 'role', 'attendances', 'payrolls'])
            ->findOrFail($id);

        return response()->json($employee);
    }

    /**
     * Update the specified employee
     */
    public function update(Request $request, string $id)
    {
        $employee = Employee::findOrFail($id);

        $validated = $request->validate([
            'organization_id' => 'sometimes|exists:organizations,id',
            'role_id' => 'sometimes|exists:roles,id',
            'employee_number' => 'sometimes|string|unique:employees,employee_code,' . $id,
            'employee_code' => 'sometimes|string|unique:employees,employee_code,' . $id,
            'full_name' => 'sometimes|string|max:255',
            'email' => 'sometimes|email|unique:employees,email,' . $id,
            'phone' => 'sometimes|string',
            'address' => 'nullable|string',
            'date_of_birth' => 'nullable|date',
            'join_date' => 'nullable|date',
            'position' => 'sometimes|string',
            'level' => 'sometimes|string',
            'department' => 'sometimes|string',
            'base_salary' => 'sometimes|numeric|min:0',
            'basic_salary' => 'sometimes|numeric|min:0',
            'status' => 'sometimes|in:active,inactive,resigned',
            'contract_type' => 'sometimes|in:permanent,contract,probation',
            'employment_status' => 'sometimes|in:permanent,contract,probation',
            'contract_end_date' => 'nullable|date',
            // Additional employee profile fields
            'place_of_birth' => 'nullable|string',
            'ktp_address' => 'nullable|string',
            'current_address' => 'nullable|string',
            'gender' => 'nullable|in:male,female',
            'religion' => 'nullable|string',
            'marital_status' => 'nullable|string',
            'ptkp_status' => 'nullable|string',
            'nik' => 'nullable|string',
            'npwp' => 'nullable|string',
            'bank_account_number' => 'nullable|string',
            'bank_account_name' => 'nullable|string',
            'father_name' => 'nullable|string',
            'mother_name' => 'nullable|string',
            'spouse_name' => 'nullable|string',
            'family_contact_number' => 'nullable|string',
            'education' => 'nullable|string',
            'supervisor_name' => 'nullable|string',
            'supervisor_position' => 'nullable|string',
            'photo_path' => 'nullable|string',
        ]);

        // Map validated to actual DB columns similar to store()
        $data = [];
        if (isset($validated['organization_id']))
            $data['organization_id'] = $validated['organization_id'];
        if (isset($validated['role_id']))
            $data['role_id'] = $validated['role_id'];
        if (isset($validated['employee_number']))
            $data['employee_code'] = $validated['employee_number'];
        if (isset($validated['employee_code']))
            $data['employee_code'] = $validated['employee_code'];
        if (isset($validated['full_name']))
            $data['full_name'] = $validated['full_name'];
        if (isset($validated['email']))
            $data['email'] = $validated['email'];
        if (isset($validated['phone']))
            $data['phone'] = $validated['phone'];
        if (isset($validated['address']))
            $data['address'] = $validated['address'];
        if (isset($validated['date_of_birth']))
            $data['birth_date'] = $validated['date_of_birth'];
        if (isset($validated['birth_date']))
            $data['birth_date'] = $validated['birth_date'];
        if (isset($validated['join_date']))
            $data['join_date'] = $validated['join_date'];
        if (isset($validated['position']))
            $data['position'] = $validated['position'];
        if (isset($validated['level']))
            $data['level'] = $validated['level'];
        if (isset($validated['base_salary']))
            $data['basic_salary'] = $validated['base_salary'];
        if (isset($validated['basic_salary']))
            $data['basic_salary'] = $validated['basic_salary'];
        if (isset($validated['contract_end_date']))
            $data['contract_end_date'] = $validated['contract_end_date'];
        if (isset($validated['contract_type']))
            $data['employment_status'] = $validated['contract_type'];
        if (isset($validated['employment_status']))
            $data['employment_status'] = $validated['employment_status'];
        if (isset($validated['status']))
            $data['status'] = $validated['status'];

        $extraFields = [
            'place_of_birth',
            'ktp_address',
            'current_address',
            'gender',
            'religion',
            'marital_status',
            'ptkp_status',
            'nik',
            'npwp',
            'bank_account_number',
            'bank_account_name',
            'father_name',
            'mother_name',
            'spouse_name',
            'family_contact_number',
            'education',
            'supervisor_name',
            'supervisor_position',
            'photo_path'
        ];
        foreach ($extraFields as $f) {
            if (isset($validated[$f]))
                $data[$f] = $validated[$f];
        }

        $employee->update($data);

        return response()->json($employee);
    }

    /**
     * Remove the specified employee
     */
    public function destroy(string $id)
    {
        $employee = Employee::findOrFail($id);
        $employee->delete();

        return response()->json(['message' => 'Employee deleted successfully']);
    }

    /**
     * Get employee attendances
     */
    public function attendances(string $id, Request $request)
    {
        $employee = Employee::findOrFail($id);

        $query = $employee->attendances();

        if ($request->has('month') && $request->has('year')) {
            $query->whereMonth('date', $request->month)
                ->whereYear('date', $request->year);
        }

        $attendances = $query->orderBy('date', 'desc')->paginate(31);

        return response()->json($attendances);
    }

    /**
     * Get employee payrolls
     */
    public function payrolls(string $id, Request $request)
    {
        $employee = Employee::findOrFail($id);

        $payrolls = $employee->payrolls()
            ->orderBy('period_month', 'desc')
            ->orderBy('period_year', 'desc')
            ->paginate(12);

        return response()->json($payrolls);
    }
}
