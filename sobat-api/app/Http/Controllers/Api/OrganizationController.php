<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Organization;
use App\Models\Employee;

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
             $query->whereNotIn('type', ['Board Of Directors', 'Holdings', 'branch']);
        }

        return response()->json($query->get());
    }

    /**
     * Get list of divisions (organizations whose parent is a Holdings type)
     */
    public function divisions()
    {
        $divisions = Organization::whereRaw('LOWER(type) = ?', ['division'])
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
        // --- Authorization: Only admins can create organizations ---
        $user = auth()->user();
        $roleName = $user->role ? strtolower($user->role->name) : '';
        if (!in_array($roleName, [\App\Models\Role::SUPER_ADMIN, \App\Models\Role::ADMIN, \App\Models\Role::ADMIN_CABANG])) {
            return response()->json(['message' => 'Anda tidak memiliki akses untuk membuat organisasi.'], 403);
        }

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
        $organization = Organization::with(['parentOrganization', 'childOrganizations'])
            ->findOrFail($id);
        
        // --- IDOR GUARD ---
        $user = auth()->user();
        $roleName = $user->role ? strtolower($user->role->name) : '';
        $isAdmin = in_array($roleName, [\App\Models\Role::ADMIN, \App\Models\Role::SUPER_ADMIN, \App\Models\Role::HR, \App\Models\Role::ADMIN_CABANG]);

        // Non-admin can only see their own division data if linked,
        // but since organizations are now separate from employees, 
        // we might allow viewing for now or add division check.
        // For simplicity and since user said organization_id is gone:
        if (!$isAdmin && $user->employee && $organization->id !== $user->employee->division_id) {
            return response()->json(['message' => 'Anda tidak memiliki akses ke data organisasi ini.'], 403);
        }

        return response()->json($organization);
    }

    public function update(Request $request, string $id)
    {
        // --- Authorization: Only admins can update organizations ---
        $user = auth()->user();
        $roleName = $user->role ? strtolower($user->role->name) : '';
        if (!in_array($roleName, [\App\Models\Role::SUPER_ADMIN, \App\Models\Role::ADMIN, \App\Models\Role::ADMIN_CABANG])) {
            return response()->json(['message' => 'Anda tidak memiliki akses untuk mengubah organisasi.'], 403);
        }

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
        // --- Authorization: Only super_admin can delete organizations ---
        $user = auth()->user();
        $roleName = $user->role ? strtolower($user->role->name) : '';
        if (!in_array($roleName, [\App\Models\Role::SUPER_ADMIN, \App\Models\Role::ADMIN])) {
            return response()->json(['message' => 'Anda tidak memiliki akses untuk menghapus organisasi.'], 403);
        }

        $organization = Organization::findOrFail($id);
        $organization->delete();

        return response()->json(['message' => 'Organization deleted successfully']);
    }

    public function employees(string $id)
    {
        // This endpoint is now obsolete as employees don't have organization_id.
        // We should instead filter employees by department name equal to organization name if needed.
        $organization = Organization::findOrFail($id);
        $employees = Employee::where('department', $organization->name)
            ->with(['user', 'role'])
            ->paginate(20);

        return response()->json($employees);
    }

    public function reset()
    {
        // --- Authorization: Only super_admin can reset all organizations ---
        $user = auth()->user();
        $roleName = $user->role ? strtolower($user->role->name) : '';
        if ($roleName !== \App\Models\Role::SUPER_ADMIN) {
            return response()->json(['message' => 'Hanya Super Admin yang dapat mereset seluruh organisasi.'], 403);
        }

        Organization::query()->delete();
        return response()->json(['message' => 'All organizations reset successfully']);
    }
}
