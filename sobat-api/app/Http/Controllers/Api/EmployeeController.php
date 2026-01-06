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
            $query->where(function($q) use ($search) {
                $q->where('full_name', 'like', "%{$search}%")
                  ->orWhere('employee_number', 'like', "%{$search}%");
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
        $validated = $request->validate([
            'user_id' => 'nullable|exists:users,id',
            'organization_id' => 'required|exists:organizations,id',
            'role_id' => 'required|exists:roles,id',
            'employee_number' => 'required|string|unique:employees',
            'full_name' => 'required|string|max:255',
            'email' => 'required|email|unique:employees',
            'phone' => 'required|string',
            'address' => 'nullable|string',
            'date_of_birth' => 'required|date',
            'join_date' => 'required|date',
            'position' => 'required|string',
            'department' => 'required|string',
            'base_salary' => 'required|numeric|min:0',
            'status' => 'required|in:active,inactive,resigned',
            'contract_type' => 'required|in:permanent,contract,probation',
            'contract_end_date' => 'nullable|date',
        ]);

        $employee = Employee::create($validated);

        return response()->json($employee, 201);
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
            'full_name' => 'sometimes|string|max:255',
            'email' => 'sometimes|email|unique:employees,email,' . $id,
            'phone' => 'sometimes|string',
            'address' => 'nullable|string',
            'position' => 'sometimes|string',
            'department' => 'sometimes|string',
            'base_salary' => 'sometimes|numeric|min:0',
            'status' => 'sometimes|in:active,inactive,resigned',
            'contract_type' => 'sometimes|in:permanent,contract,probation',
            'contract_end_date' => 'nullable|date',
        ]);

        $employee->update($validated);

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
