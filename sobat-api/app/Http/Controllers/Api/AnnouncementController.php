<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Announcement;
use Illuminate\Support\Facades\Storage;

class AnnouncementController extends Controller
{
    /**
     * Display a listing of the resource.
     */
    public function index(Request $request)
    {
        $query = Announcement::query();

        // Filter by category if provided
        if ($request->has('category')) {
            $query->where('category', $request->category);
        }

        // Filter by published status (default to published only for non-admin, but here we just list all)
        // Usually, mobile app should only fetch published ones.
        if ($request->has('published')) {
            $query->where('is_published', filter_var($request->published, FILTER_VALIDATE_BOOLEAN));
        }

        // Sort by newest
        $query->orderBy('created_at', 'desc');

        return response()->json($query->get());
    }

    /**
     * Store a newly created resource in storage.
     */
    public function store(Request $request)
    {
        $validated = $request->validate([
            'title' => 'required|string|max:255',
            'content' => 'required|string',
            'category' => 'required|in:news,policy',
            'attachment' => 'nullable|file|mimes:pdf,jpg,jpeg,png|max:10240', // Max 10MB
            'is_published' => 'boolean',
        ]);

        $announcement = new Announcement();
        $announcement->title = $validated['title'];
        $announcement->content = $validated['content'];
        $announcement->category = $validated['category'];
        $announcement->is_published = $request->input('is_published', false);

        if ($request->hasFile('attachment')) {
            $path = $request->file('attachment')->store('announcements', 'public');
            $announcement->attachment_url = Storage::url($path);
        }

        $announcement->save();

        return response()->json($announcement, 201);
    }

    /**
     * Display the specified resource.
     */
    public function show(string $id)
    {
        $announcement = Announcement::findOrFail($id);
        return response()->json($announcement);
    }

    /**
     * Update the specified resource in storage.
     */
    public function update(Request $request, string $id)
    {
        $announcement = Announcement::findOrFail($id);

        $validated = $request->validate([
            'title' => 'sometimes|string|max:255',
            'content' => 'sometimes|string',
            'category' => 'sometimes|in:news,policy',
            'attachment' => 'nullable|file|mimes:pdf,jpg,jpeg,png|max:10240',
            'is_published' => 'boolean',
        ]);

        if (isset($validated['title'])) $announcement->title = $validated['title'];
        if (isset($validated['content'])) $announcement->content = $validated['content'];
        if (isset($validated['category'])) $announcement->category = $validated['category'];
        if ($request->has('is_published')) $announcement->is_published = $request->input('is_published');

        if ($request->hasFile('attachment')) {
            // Delete old file if needed? For now, just overwrite ref
            $path = $request->file('attachment')->store('announcements', 'public');
            $announcement->attachment_url = Storage::url($path);
        }

        $announcement->save();

        return response()->json($announcement);
    }

    /**
     * Remove the specified resource from storage.
     */
    public function destroy(string $id)
    {
        $announcement = Announcement::findOrFail($id);
        // Optionally delete file from storage
        $announcement->delete();

        return response()->json(['message' => 'Announcement deleted successfully']);
    }
}
