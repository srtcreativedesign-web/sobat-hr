<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Organization;

class OrganizationController extends Controller
{
    public function index()
    {
        $organizations = Organization::with('parentOrganization')->get();
        return response()->json($organizations);
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'code' => 'required|string|unique:organizations',
            'type' => 'required|in:headquarters,branch,department',
            'parent_id' => 'nullable|exists:organizations,id',
            'address' => 'nullable|string',
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
            'type' => 'sometimes|in:headquarters,branch,department',
            'parent_id' => 'nullable|exists:organizations,id',
            'address' => 'nullable|string',
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
}
