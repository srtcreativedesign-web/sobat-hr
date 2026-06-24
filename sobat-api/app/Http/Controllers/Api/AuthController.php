<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Models\UserDevice;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;

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

            $user = User::with(['role', 'employee'])->where('email', $request->email)->first();

            if (! $user || ! Hash::check($request->password, $user->password)) {
                return response()->json([
                    'success' => false,
                    'message' => 'Email atau password salah',
                ], 401);
            }

            // Delete old tokens
            $user->tokens()->delete();

            // Load relationships for UserResource
            $user->load(['role', 'employee.division', 'employee.jobPosition', 'employee.shift']);

            // DEVICE BINDING LOGIC
            // Hanya berlaku untuk user dengan role 'employee'
            if ($user->role && $user->role->name === \App\Models\Role::EMPLOYEE) {
                if ($request->has('device_id') && ! empty($request->device_id)) {
                    if (is_null($user->device_id)) {
                        // Bind to this new device
                        $user->device_id = $request->device_id;
                        if ($request->has('device_name')) {
                            $user->device_name = $request->device_name;
                        }
                        $user->save();
                    } elseif ($user->device_id !== $request->device_id) {
                        // Device mismatch
                        return response()->json([
                            'success' => false,
                            'message' => 'Akun Anda telah terkait dengan perangkat lain ('.($user->device_name ?? 'Unknown Device').'). Hubungi Admin HR untuk melakukan Reset Device.',
                        ], 403);
                    }
                }
            }

            // Create new token
            $token = $user->createToken('auth_token')->plainTextToken;

            return response()->json([
                'success' => true,
                'message' => 'Login successful',
                'data' => [
                    'access_token' => $token,
                    'token_type' => 'Bearer',
                    'user' => new \App\Http\Resources\UserResource($user),
                ],
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Terjadi kesalahan: '.$e->getMessage(),
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

        if (! $employeeRole) {
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
            'message' => 'Successfully logged out',
        ]);
    }

    /**
     * Get authenticated user
     */
    public function me(Request $request)
    {
        $user = $request->user();
        $user->load(['role', 'employee.division', 'employee.jobPosition', 'employee.shift']);

        return response()->json([
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
            'email' => 'required|email|max:255|unique:users,email,'.$user->id,
            'supervisor_name' => 'nullable|string',
        ]);

        $user->update([
            'name' => $validated['name'],
            'email' => $validated['email'],
        ]);

        // Self-service supervisor mapping
        if ($request->has('supervisor_name') && !empty($request->supervisor_name)) {
            $supervisor = \App\Models\Employee::where('full_name', $request->supervisor_name)->first();
            
            if (!$supervisor) {
                return response()->json([
                    'message' => 'Atasan dengan nama tersebut tidak ditemukan di sistem. Harap periksa ejaan namanya.',
                ], 422);
            }
            
            if ($user->employee) {
                $user->employee->update(['supervisor_id' => $supervisor->id]);
            }
        }

        return response()->json([
            'message' => 'Profile updated successfully',
            'user' => $user->load('employee'),
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

        if (! Hash::check($request->current_password, $user->password)) {
            return response()->json([
                'message' => 'Password saat ini salah',
            ], 422);
        }

        $user->update([
            'password' => Hash::make($request->new_password),
        ]);

        return response()->json([
            'message' => 'Password berhasil diubah',
        ]);
    }

    /**
     * Update user FCM token
     */
    public function updateFcmToken(Request $request)
    {
        $request->validate([
            'fcm_token' => 'required|string',
            'device_name' => 'nullable|string',
            'device_id' => 'nullable|string',
        ]);

        $user = $request->user();

        // Keep legacy single-token column for backward compatibility
        $user->update(['fcm_token' => $request->fcm_token]);

        // Register device for multi-device support
        UserDevice::updateOrCreate(
            [
                'user_id' => $user->id,
                'device_id' => $request->device_id ?? $request->fcm_token,
            ],
            [
                'fcm_token' => $request->fcm_token,
                'device_name' => $request->device_name ?? $request->header('User-Agent'),
                'last_active_at' => now(),
            ]
        );

        return response()->json([
            'success' => true,
            'message' => 'FCM token updated successfully',
        ]);
    }

    /**
     * Impersonate a user (Admin only)
     */
    public function impersonate($user_id)
    {
        try {
            $adminUser = auth()->user();
            
            // Allow admin roles
            $allowedRoles = [\App\Models\Role::SUPER_ADMIN, 'admin_cabang', 'personalia', 'hr'];
            if (!$adminUser->role || !in_array($adminUser->role->name, $allowedRoles)) {
                return response()->json([
                    'success' => false,
                    'message' => 'Unauthorized. Only admins can impersonate users.',
                ], 403);
            }

            $targetUser = User::with(['role', 'employee.division', 'employee.jobPosition', 'employee.shift'])->find($user_id);

            if (!$targetUser) {
                return response()->json([
                    'success' => false,
                    'message' => 'User not found.',
                ], 404);
            }

            // Create new token for target user (without affecting device_id binding logic since this is from web)
            $token = $targetUser->createToken('impersonate_token')->plainTextToken;

            return response()->json([
                'success' => true,
                'message' => 'Impersonating ' . $targetUser->name,
                'data' => [
                    'access_token' => $token,
                    'token_type' => 'Bearer',
                    'user' => new \App\Http\Resources\UserResource($targetUser),
                ],
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Terjadi kesalahan: ' . $e->getMessage(),
            ], 500);
        }
    }
}
