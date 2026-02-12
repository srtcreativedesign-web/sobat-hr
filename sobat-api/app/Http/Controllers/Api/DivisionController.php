<?php

namespace App\Http\Controllers\Api;


use App\Http\Controllers\Controller;
use App\Models\Division;
use Illuminate\Http\Request;

class DivisionController extends Controller
{
    /**
     * Display a listing of the resource.
     */
    public function index(Request $request)
    {
        $query = Division::with('department');

        if ($request->has('search')) {
            $search = $request->search;
            $query->where(function($q) use ($search) {
                $q->where('name', 'like', "%{$search}%")
                  ->orWhere('code', 'like', "%{$search}%");
            });
        }
        
        if ($request->has('department_id')) {
            $query->where('department_id', $request->department_id);
        }

        return response()->json($query->orderBy('name')->get());
    }

    /**
     * Store a newly created resource in storage.
     */
    public function store(Request $request)
    {
        $validated = $request->validate([
            'name' => 'required|string|max:255|unique:divisions,name',
            'code' => 'nullable|string|max:50|unique:divisions,code',
            'description' => 'nullable|string',
            'department_id' => 'nullable|exists:departments,id',
        ]);

        $division = Division::create($validated);

        return response()->json($division, 201);
    }

    /**
     * Display the specified resource.
     */
    public function show($id)
    {
        $division = Division::findOrFail($id);
        return response()->json($division);
    }

    /**
     * Update the specified resource in storage.
     */
    public function update(Request $request, $id)
    {
        $division = Division::findOrFail($id);

        $validated = $request->validate([
            'name' => 'required|string|max:255|unique:divisions,name,' . $division->id,
            'code' => 'nullable|string|max:50|unique:divisions,code,' . $division->id,
            'description' => 'nullable|string',
        ]);

        $division->update($validated);

        return response()->json($division);
    }

    /**
     * Remove the specified resource from storage.
     */
    public function destroy($id)
    {
        $division = Division::findOrFail($id);
        // Optional: Check if used in other tables before delete
        $division->delete();

        return response()->json(['message' => 'Division deleted successfully']);
    }
}

