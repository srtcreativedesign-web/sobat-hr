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
