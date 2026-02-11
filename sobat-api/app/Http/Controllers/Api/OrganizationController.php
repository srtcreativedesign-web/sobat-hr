<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Organization;

class OrganizationController extends Controller
{
    public function index(Request $request)
    {
        $query = Organization::with('parentOrganization');
        
        // Filter by specific division sub-tree
        if ($request->has('division_id')) {
            $divisionId = $request->division_id;
            // Get the division and all its descendants recursively
            $ids = $this->getDescendantIds($divisionId);
            $ids[] = (int) $divisionId;
            $query->whereIn('id', $ids);
        } elseif ($request->has('type')) {
            $query->where('type', $request->type);
        } else {
             $query->whereNotIn('type', ['Board Of Directors', 'Holdings']);
        }

        return response()->json($query->get());
    }

    /**
     * Get list of divisions (organizations whose parent is a Holdings type)
     */
    public function divisions()
    {
        $holdingIds = Organization::where('type', 'Holdings')->pluck('id');
        $divisions = Organization::whereIn('parent_id', $holdingIds)
            ->orderBy('name')
            ->get(['id', 'name', 'code', 'type']);

        return response()->json($divisions);
    }

    /**
     * Get all descendant IDs recursively
     */
    private function getDescendantIds(int $parentId): array
    {
        $childIds = Organization::where('parent_id', $parentId)->pluck('id')->toArray();
        $allIds = $childIds;
        foreach ($childIds as $childId) {
            $allIds = array_merge($allIds, $this->getDescendantIds($childId));
        }
        return $allIds;
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'code' => 'required|string|unique:organizations',
            'type' => 'required|string|max:50',
            'line_style' => 'nullable|in:solid,dashed,dotted',
            'parent_id' => 'nullable|exists:organizations,id',
            'address' => 'nullable|string',
            'description' => 'nullable|string',
            'phone' => 'nullable|string',
            'email' => 'nullable|email',
        ]);

        $organization = Organization::create($validated);

        return response()->json($organization, 201);
    }

    public function show(string $id)
    {
        $organization = Organization::with(['parentOrganization', 'childOrganizations', 'employees'])
            ->findOrFail($id);

        return response()->json($organization);
    }

    public function update(Request $request, string $id)
    {
        $organization = Organization::findOrFail($id);

        $validated = $request->validate([
            'name' => 'sometimes|string|max:255',
            'code' => 'sometimes|string|unique:organizations,code,' . $id,
            'type' => 'sometimes|string|max:50',
            'line_style' => 'nullable|in:solid,dashed,dotted',
            'parent_id' => 'nullable|exists:organizations,id',
            'address' => 'nullable|string',
            'description' => 'nullable|string',
            'phone' => 'nullable|string',
            'email' => 'nullable|email',
        ]);

        $organization->update($validated);

        return response()->json($organization);
    }

    public function destroy(string $id)
    {
        $organization = Organization::findOrFail($id);
        $organization->delete();

        return response()->json(['message' => 'Organization deleted successfully']);
    }

    public function employees(string $id)
    {
        $organization = Organization::findOrFail($id);
        $employees = $organization->employees()->with(['user', 'role'])->paginate(20);

        return response()->json($employees);
    }

    public function reset()
    {
        Organization::query()->delete();
        return response()->json(['message' => 'All organizations reset successfully']);
    }
}
