<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Shift;
use App\Models\Employee;

class ShiftController extends Controller
{
    public function index(Request $request)
    {
        $query = Shift::query();

        if ($request->has('organization_id')) {
            $query->where('organization_id', $request->organization_id);
        }

        $shifts = $query->paginate(20);

        return response()->json($shifts);
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'organization_id' => 'required|exists:organizations,id',
            'start_time' => 'required',
            'end_time' => 'required',
            'days' => 'required|array',
            'days.*' => 'in:monday,tuesday,wednesday,thursday,friday,saturday,sunday',
        ]);

        $validated['days'] = json_encode($validated['days']);

        $shift = Shift::create($validated);

        return response()->json($shift, 201);
    }

    public function show(string $id)
    {
        $shift = Shift::findOrFail($id);
        $shift->days = json_decode($shift->days);

        return response()->json($shift);
    }

    public function update(Request $request, string $id)
    {
        $shift = Shift::findOrFail($id);

        $validated = $request->validate([
            'name' => 'sometimes|string|max:255',
            'organization_id' => 'sometimes|exists:organizations,id',
            'start_time' => 'sometimes',
            'end_time' => 'sometimes',
            'days' => 'sometimes|array',
            'days.*' => 'in:monday,tuesday,wednesday,thursday,friday,saturday,sunday',
        ]);

        if (isset($validated['days'])) {
            $validated['days'] = json_encode($validated['days']);
        }

        $shift->update($validated);

        return response()->json($shift);
    }

    public function destroy(string $id)
    {
        $shift = Shift::findOrFail($id);
        $shift->delete();

        return response()->json(['message' => 'Shift deleted successfully']);
    }

    /**
     * Assign shift to employee(s)
     */
    public function assignToEmployee(Request $request)
    {
        $validated = $request->validate([
            'shift_id' => 'required|exists:shifts,id',
            'employee_ids' => 'required|array',
            'employee_ids.*' => 'exists:employees,id',
        ]);

        foreach ($validated['employee_ids'] as $employeeId) {
            $employee = Employee::find($employeeId);
            $employee->shift_id = $validated['shift_id'];
            $employee->save();
        }

        return response()->json([
            'message' => 'Shift assigned successfully',
            'count' => count($validated['employee_ids']),
        ]);
    }
}
