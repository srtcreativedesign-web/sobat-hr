<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;

use App\Models\User;
use App\Models\Employee;
use App\Models\PasswordResetRequest;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;

class PasswordResetController extends Controller
{
    /**
     * User submits request by phone
     */
    public function request(Request $request)
    {
        $request->validate([
            'phone' => 'required|string',
        ]);

        // Find employee by phone
        $employee = Employee::where('phone', $request->phone)->first();

        if (!$employee || !$employee->user) {
            return response()->json([
                'message' => 'Nomor HP tidak terdaftar.'
            ], 404);
        }

        $user = $employee->user;

        // Check pending
        $existing = PasswordResetRequest::where('user_id', $user->id)
            ->where('status', 'pending')
            ->first();

        if ($existing) {
            return response()->json([
                'message' => 'Permintaan sedang diproses. Mohon tunggu approval admin.'
            ], 400);
        }

        PasswordResetRequest::create([
            'user_id' => $user->id,
            'phone' => $request->phone,
            'status' => 'pending'
        ]);

        return response()->json([
            'message' => 'Permintaan dikirim. Silakan hubungi Admin.'
        ]);
    }

    /**
     * Admin lists pending requests
     */
    public function index()
    {
        $requests = PasswordResetRequest::with(['user.employee'])
            ->where('status', 'pending')
            ->latest()
            ->get();

        return response()->json(['data' => $requests]);
    }

    /**
     * Admin approves request
     */
    public function approve($id)
    {
        $resetRequest = PasswordResetRequest::findOrFail($id);

        if ($resetRequest->status !== 'pending') {
            return response()->json(['message' => 'Request finished'], 400);
        }

        $user = User::findOrFail($resetRequest->user_id);
        
        // Generate Temp Password (random 6 chars alphanumeric upper)
        $tempPassword = Str::upper(Str::random(6)); 
        
        $user->update([
            'password' => Hash::make($tempPassword)
        ]);

        $resetRequest->update([
            'status' => 'approved'
        ]);

        return response()->json([
            'message' => 'Password reset successful',
            'temp_password' => $tempPassword,
            'user_name' => $user->name,
            'phone' => $resetRequest->phone
        ]);
    }

    /**
     * Admin rejects request
     */
    public function reject(Request $request, $id)
    {
        $resetRequest = PasswordResetRequest::findOrFail($id);
         if ($resetRequest->status !== 'pending') {
            return response()->json(['message' => 'Request finished'], 400);
        }
        
        $resetRequest->update([
            'status' => 'rejected',
            'reject_reason' => $request->reason ?? null
        ]);

        return response()->json(['message' => 'Request rejected']);
    }
}

