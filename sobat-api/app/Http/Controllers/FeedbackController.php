<?php

namespace App\Http\Controllers;

use App\Models\Feedback;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Validator;

class FeedbackController extends Controller
{
    /**
     * Submit new feedback (Mobile - User)
     */
    public function store(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'subject' => 'required|string|max:255',
            'category' => 'required|in:bug,feature_request,complaint,question,other',
            'description' => 'required|string',
            'screenshot' => 'nullable|image|max:5120', // 5MB max
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors()
            ], 422);
        }

        $data = $validator->validated();
        $data['user_id'] = auth()->id();

        // Handle screenshot upload
        if ($request->hasFile('screenshot')) {
            $path = $request->file('screenshot')->store('feedbacks', 'public');
            $data['screenshot_path'] = $path;
        }

        $feedback = Feedback::create($data);

        return response()->json([
            'success' => true,
            'message' => 'Feedback submitted successfully',
            'data' => $feedback->load('user')
        ], 201);
    }

    /**
     * Get user's own feedbacks (Mobile - User)
     */
    public function index(Request $request)
    {
        $feedbacks = Feedback::where('user_id', auth()->id())
            ->orderBy('created_at', 'desc')
            ->get();

        return response()->json([
            'success' => true,
            'data' => $feedbacks
        ]);
    }

    /**
     * Get all feedbacks (Web - Admin)
     */
    public function adminIndex(Request $request)
    {
        $query = Feedback::with('user');

        // Filter by status
        if ($request->has('status')) {
            $query->where('status', $request->status);
        }

        // Filter by category
        if ($request->has('category')) {
            $query->where('category', $request->category);
        }

        // Search by subject or user name
        if ($request->has('search')) {
            $search = $request->search;
            $query->where(function($q) use ($search) {
                $q->where('subject', 'like', "%{$search}%")
                  ->orWhereHas('user', function($userQuery) use ($search) {
                      $userQuery->where('name', 'like', "%{$search}%");
                  });
            });
        }

        $feedbacks = $query->orderBy('created_at', 'desc')->paginate(20);

        return response()->json([
            'success' => true,
            'data' => $feedbacks
        ]);
    }

    /**
     * Get feedback detail (Web - Admin)
     */
    public function show($id)
    {
        $feedback = Feedback::with('user')->findOrFail($id);

        return response()->json([
            'success' => true,
            'data' => $feedback
        ]);
    }

    /**
     * Update feedback status/response (Web - Admin)
     */
    public function update(Request $request, $id)
    {
        $feedback = Feedback::findOrFail($id);

        $validator = Validator::make($request->all(), [
            'status' => 'nullable|in:pending,in_progress,resolved,closed',
            'admin_response' => 'nullable|string',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors()
            ], 422);
        }

        $feedback->update($validator->validated());

        return response()->json([
            'success' => true,
            'message' => 'Feedback updated successfully',
            'data' => $feedback->load('user')
        ]);
    }

    /**
     * Delete feedback (Web - Admin)
     */
    public function destroy($id)
    {
        $feedback = Feedback::findOrFail($id);

        // Delete screenshot if exists
        if ($feedback->screenshot_path) {
            Storage::disk('public')->delete($feedback->screenshot_path);
        }

        $feedback->delete();

        return response()->json([
            'success' => true,
            'message' => 'Feedback deleted successfully'
        ]);
    }
}
