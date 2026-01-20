<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;

class NotificationController extends Controller
{
    /**
     * Get all notifications for the authenticated user
     */
    public function index(Request $request)
    {
        $notifications = $request->user()->notifications;

        return response()->json([
            'success' => true,
            'data' => $notifications
        ]);
    }

    /**
     * Mark a notification or all notifications as read
     */
    public function markAsRead(Request $request)
    {
        if ($request->has('id')) {
            $notification = $request->user()
                ->notifications()
                ->where('id', $request->id)
                ->first();
            
            if ($notification) {
                $notification->markAsRead();
            }
        } else {
            // Mark all as read
            $request->user()->unreadNotifications->markAsRead();
        }

        return response()->json([
            'success' => true,
            'message' => 'Notifikasi ditandai sudah dibaca'
        ]);
    }
}
