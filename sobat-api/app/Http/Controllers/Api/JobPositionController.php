<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\JobPosition;
use Illuminate\Http\Request;

class JobPositionController extends Controller
{
    /**
     * Display a listing of the resource.
     */
    public function index(Request $request)
    {
        $query = JobPosition::with(['division.department', 'parentPosition']);

        if ($request->has('division_id')) {
            $query->where('division_id', $request->division_id);
        }

        if ($request->has('search')) {
            $search = $request->search;
            $query->where(function($q) use ($search) {
                $q->where('name', 'like', "%{$search}%")
                  ->orWhere('code', 'like', "%{$search}%");
            });
        }

        return response()->json($query->orderBy('level')->orderBy('name')->get());
    }

    /**
     * Store a newly created resource in storage.
     */
    public function store(Request $request)
    {
        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'code' => 'nullable|string|max:50|unique:job_positions,code',
            'division_id' => 'nullable|exists:divisions,id',
            'level' => 'required|integer|min:0',
            'track' => 'required|in:office,operational',
            'parent_position_id' => 'nullable|exists:job_positions,id',
        ]);

        $jobPosition = JobPosition::create($validated);

        return response()->json($jobPosition, 201);
    }

    /**
     * Display the specified resource.
     */
    public function show($id)
    {
        $jobPosition = JobPosition::with(['division', 'parentPosition', 'childPositions'])->findOrFail($id);

        // --- SECURITY GUARD ---
        $user = auth()->user();
        $roleName = $user->role ? strtolower($user->role->name) : '';
        $isAdmin = in_array($roleName, [\App\Models\Role::ADMIN, \App\Models\Role::SUPER_ADMIN, \App\Models\Role::HR, \App\Models\Role::ADMIN_CABANG]);

        // Non-admin check (simplified: only allow self-position or if they are supervisor)
        if (!$isAdmin && $jobPosition->id !== $user->employee?->job_position_id) {
            // We could add more complex logic for supervisors here later
            return response()->json(['message' => 'Anda tidak memiliki akses ke data jabatan ini.'], 403);
        }

        return response()->json($jobPosition);
    }

    /**
     * Update the specified resource in storage.
     */
    public function update(Request $request, $id)
    {
        $jobPosition = JobPosition::findOrFail($id);

        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'code' => 'nullable|string|max:50|unique:job_positions,code,' . $jobPosition->id,
            'division_id' => 'nullable|exists:divisions,id',
            'level' => 'required|integer|min:0',
            'track' => 'required|in:office,operational',
            'parent_position_id' => 'nullable|exists:job_positions,id',
        ]);

        $jobPosition->update($validated);

        return response()->json($jobPosition);
    }

    /**
     * Remove the specified resource from storage.
     */
    public function destroy($id)
    {
        $jobPosition = JobPosition::findOrFail($id);
        // Optional: Check usage in employees table
        $jobPosition->delete();

        return response()->json(['message' => 'Job Position deleted successfully']);
    }
}
