<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\ValidationException;
use App\Models\User;

class AuthController extends Controller
{
    /**
     * Login user and create token
     */
    public function login(Request $request)
    {
        try {
            $request->validate([
                'email' => 'required|email',
                'password' => 'required',
            ]);

            $user = User::where('email', $request->email)->first();

            if (!$user || !Hash::check($request->password, $user->password)) {
                return response()->json([
                    'success' => false,
                    'message' => 'Email atau password salah',
                ], 401);
            }

            // Delete old tokens
            $user->tokens()->delete();

            // Load relationships for UserResource
            $user->load(['role', 'employee.organization', 'employee.jobPosition']);

            // Create new token
            $token = $user->createToken('auth_token')->plainTextToken;

            return response()->json([
                'success' => true,
                'message' => 'Login successful',
                'data' => [
                    'access_token' => $token,
                    'token_type' => 'Bearer',
                    'user' => new \App\Http\Resources\UserResource($user),
                ]
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Terjadi kesalahan: ' . $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Register new user (Strict Employee Only)
     */
    public function register(Request $request)
    {
        $request->validate([
            'name' => 'required|string|max:255',
            'email' => 'required|string|email|max:255|unique:users',
            'password' => 'required|string|min:8|confirmed',
        ]);

        // Solve 1: Hardcode role to 'employee' to prevent role escalation
        $employeeRole = \App\Models\Role::where('name', \App\Models\Role::EMPLOYEE)->first();
        
        if (!$employeeRole) {
            return response()->json(['message' => 'System configuration error: Employee role not found.'], 500);
        }

        $user = User::create([
            'name' => $request->name,
            'email' => $request->email,
            'password' => Hash::make($request->password),
            'role_id' => $employeeRole->id, // FORCE EMPLOYEE ROLE
        ]);

        $token = $user->createToken('auth_token')->plainTextToken;

        return response()->json([
            'success' => true,
            'access_token' => $token,
            'token_type' => 'Bearer',
            'user' => new \App\Http\Resources\UserResource($user),
        ], 201);
    }

    /**
     * Logout user (Revoke token)
     */
    public function logout(Request $request)
    {
        $request->user()->currentAccessToken()->delete();

        return response()->json([
            'message' => 'Successfully logged out'
        ]);
    }

    /**
     * Get authenticated user
     */
    public function me(Request $request)
    {
        $user = $request->user();
        $user->load(['role', 'employee.organization', 'employee.jobPosition']);

        return response()->json([
            'success' => true,
            'message' => 'User profile fetched successfully',
            'success' => true,
            'message' => 'User profile fetched successfully',
            'data' => new \App\Http\Resources\UserResource($user),
        ]);
    }
    /**
     * Update user profile (Name & Email)
     */
    public function updateProfile(Request $request)
    {
        $user = $request->user();

        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'email' => 'required|email|max:255|unique:users,email,' . $user->id,
        ]);

        $user->update([
            'name' => $validated['name'],
            'email' => $validated['email'],
        ]);

        return response()->json([
            'message' => 'Profile updated successfully',
            'user' => $user
        ]);
    }

    /**
     * Change password
     */
    public function changePassword(Request $request)
    {
        $request->validate([
            'current_password' => 'required',
            'new_password' => 'required|min:8|confirmed',
        ]);

        $user = $request->user();

        if (!Hash::check($request->current_password, $user->password)) {
            return response()->json([
                'message' => 'Password saat ini salah'
            ], 422);
        }

        $user->update([
            'password' => Hash::make($request->new_password)
        ]);

        return response()->json([
            'message' => 'Password berhasil diubah'
        ]);
    }

    /**
     * Update user FCM token
     */
    public function updateFcmToken(Request $request)
    {
        $request->validate([
            'fcm_token' => 'required|string',
        ]);

        $request->user()->update([
            'fcm_token' => $request->fcm_token,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'FCM token updated successfully',
        ]);
    }
}
