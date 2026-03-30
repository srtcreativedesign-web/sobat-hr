<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Role;
use Illuminate\Http\Request;
use App\Models\Policy;
use Illuminate\Support\Facades\Storage;

class PolicyController extends Controller
{
    private function authorizeAdmin(): ?array
    {
        $user = auth()->user();
        $roleName = $user->role ? strtolower($user->role->name) : '';
        if (!in_array($roleName, [Role::SUPER_ADMIN, Role::ADMIN, Role::ADMIN_CABANG, Role::HR])) {
            return ['message' => 'Anda tidak memiliki akses untuk operasi ini.'];
        }
        return null;
    }

    /**
     * List policies (Admin sees all, User sees published only)
     */
    public function index(Request $request)
    {
        $query = Policy::with('creator:id,name')->latest();

        // If not admin, restrict to published
        // Ideally handled by role middleware, but simple check here:
        // Assuming /api/mobile/* routes might set a param or we check role
        if ($request->has('mobile')) {
            $query->where('is_published', true);
        }

        $policies = $query->paginate(20);

        // Append full URL for attachment if exists
        $policies->getCollection()->transform(function ($policy) {
            if ($policy->attachment_path) {
                // Should return absolute URL
                $policy->attachment_url = url('storage/' . $policy->attachment_path);
            }
            return $policy;
        });

        return response()->json($policies);
    }

    public function store(Request $request)
    {
        if ($denied = $this->authorizeAdmin()) {
            return response()->json($denied, 403);
        }

        $validated = $request->validate([
            'title' => 'required|string|max:255',
            'content' => 'required|string',
            'attachment' => 'nullable|file|mimes:pdf,doc,docx,jpg,png|max:10240', // 10MB
            'is_published' => 'boolean'
        ]);

        $data = [
            'created_by' => $request->user()->id,
            'title' => $validated['title'],
            'content' => $validated['content'],
            'is_published' => $validated['is_published'] ?? false,
            'published_at' => ($validated['is_published'] ?? false) ? now() : null,
        ];

        if ($request->hasFile('attachment')) {
            $path = $request->file('attachment')->store('policies', 'public');
            $data['attachment_path'] = $path;
        }

        $policy = Policy::create($data);

        return response()->json($policy, 201);
    }

    public function show(string $id)
    {
        $policy = Policy::with('creator:id,name')->findOrFail($id);
        if ($policy->attachment_path) {
            $policy->attachment_url = url('storage/' . $policy->attachment_path);
        }
        return response()->json($policy);
    }

    public function update(Request $request, string $id)
    {
        if ($denied = $this->authorizeAdmin()) {
            return response()->json($denied, 403);
        }

        $policy = Policy::findOrFail($id);

        $validated = $request->validate([
            'title' => 'sometimes|string|max:255',
            'content' => 'sometimes|string',
            'attachment' => 'nullable|file|mimes:pdf,doc,docx,jpg,png|max:10240',
            'is_published' => 'boolean'
        ]);

        $data = [];
        if (isset($validated['title']))
            $data['title'] = $validated['title'];
        if (isset($validated['content']))
            $data['content'] = $validated['content'];

        if (isset($validated['is_published'])) {
            $data['is_published'] = $validated['is_published'];
            if ($validated['is_published'] && !$policy->is_published) {
                $data['published_at'] = now();
            }
        }

        if ($request->hasFile('attachment')) {
            // Delete old file if exists
            if ($policy->attachment_path) {
                Storage::disk('public')->delete($policy->attachment_path);
            }
            $path = $request->file('attachment')->store('policies', 'public');
            $data['attachment_path'] = $path;
        }

        $policy->update($data);

        return response()->json($policy);
    }

    public function destroy(string $id)
    {
        if ($denied = $this->authorizeAdmin()) {
            return response()->json($denied, 403);
        }

        $policy = Policy::findOrFail($id);

        if ($policy->attachment_path) {
            Storage::disk('public')->delete($policy->attachment_path);
        }

        $policy->delete();

        return response()->json(['message' => 'Policy deleted successfully']);
    }
}
