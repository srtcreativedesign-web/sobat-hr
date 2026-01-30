<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Announcement;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Validator;

class AnnouncementController extends Controller
{
    public function index(Request $request)
    {
        $query = Announcement::latest();

        if ($request->has('category')) {
            $query->where('category', $request->category);
        }

        $announcements = $query->get();
        return response()->json([
            'success' => true,
            'data' => $announcements
        ]);
    }

    public function store(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'title' => 'required|string|max:255',
            'image' => 'nullable|image|max:5120', // Made nullable if just creating text announcement? Plan said image_path still for banner image. 
            // Let's keep image required IF it's a banner? Or just nullable in general? Plan said specific banner image.
            // Let's make image nullable for standard announcements, but maybe required for banner? 
            // For now, let's make it nullable to be flexible as per "modify existing" which implies general announcements might not need it.
            // User requirement: "popup everytime login" -> likely needs image.
            // But let's stick to nullable to be safe for "News" without image.
            'category' => 'in:news,policy',
            'description' => 'nullable|string',
            'attachment' => 'nullable|file|mimes:pdf,doc,docx,jpg,jpeg,png|max:10240', // 10MB
            'is_active' => 'boolean',
            'is_banner' => 'boolean',
            'start_date' => 'nullable|date',
            'end_date' => 'nullable|date',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation Error',
                'errors' => $validator->errors()
            ], 422);
        }

        $imagePath = null;
        if ($request->hasFile('image')) {
            $imagePath = $request->file('image')->store('announcements', 'public');
        }

        $attachmentUrl = null;
        if ($request->hasFile('attachment')) {
            $attachmentUrl = $request->file('attachment')->store('attachments', 'public');
        }

        $announcement = Announcement::create([
            'title' => $request->title,
            'description' => $request->description,
            'image_path' => $imagePath,
            'category' => $request->category ?? 'news',
            'attachment_url' => $attachmentUrl,
            'is_active' => $request->boolean('is_active', true),
            'is_banner' => $request->boolean('is_banner', false),
            'start_date' => $request->start_date,
            'end_date' => $request->end_date,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Announcement created successfully',
            'data' => $announcement
        ], 201);
    }

    public function update(Request $request, $id)
    {
        $announcement = Announcement::find($id);
        if (!$announcement) {
            return response()->json(['success' => false, 'message' => 'Not found'], 404);
        }

        $validator = Validator::make($request->all(), [
            'title' => 'sometimes|string|max:255',
            'image' => 'nullable|image|max:5120',
            'description' => 'nullable|string',
            'category' => 'sometimes|in:news,policy',
            'attachment' => 'nullable|file|mimes:pdf,doc,docx,jpg,jpeg,png|max:10240',
            'is_active' => 'sometimes|boolean',
            'is_banner' => 'sometimes|boolean',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors()
            ], 422);
        }

        if ($request->hasFile('image')) {
            // Delete old image
            if ($announcement->image_path) {
                Storage::disk('public')->delete($announcement->image_path);
            }
            $announcement->image_path = $request->file('image')->store('announcements', 'public');
        }

        if ($request->hasFile('attachment')) {
            // Delete old attachment
            if ($announcement->attachment_url) {
                Storage::disk('public')->delete($announcement->attachment_url);
            }
            $announcement->attachment_url = $request->file('attachment')->store('attachments', 'public');
        }

        $announcement->update($request->except(['image', 'attachment']));

        return response()->json([
            'success' => true,
            'message' => 'Announcement updated',
            'data' => $announcement
        ]);
    }

    public function destroy($id)
    {
        $announcement = Announcement::find($id);
        if (!$announcement) {
            return response()->json(['success' => false, 'message' => 'Not found'], 404);
        }

        if ($announcement->image_path) {
            Storage::disk('public')->delete($announcement->image_path);
        }

        $announcement->delete();

        return response()->json([
            'success' => true,
            'message' => 'Announcement deleted'
        ]);
    }

    public function getActive()
    {
        $now = now()->toDateString();
        // Only fetch items where is_banner is true
        $announcement = Announcement::where('is_active', true)
            ->where('is_banner', true)
            ->where(function ($query) use ($now) {
                $query->whereNull('start_date')
                      ->orWhere('start_date', '<=', $now);
            })
            ->where(function ($query) use ($now) {
                $query->whereNull('end_date')
                      ->orWhere('end_date', '>=', $now);
            })
            ->latest()
            ->first();

        return response()->json([
            'success' => true,
            'data' => $announcement
        ]);
    }
}
