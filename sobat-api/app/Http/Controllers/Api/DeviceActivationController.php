<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;

class DeviceActivationController extends Controller
{
    public function activate(Request $request)
    {
        $validated = $request->validate([
            'activation_token' => 'required|string',
            'device_uid' => 'required|string|max:255',
        ]);

        $device = \App\Models\OutletDevice::with('organization')->where('activation_token', $validated['activation_token'])->first();

        if (!$device) {
            return response()->json([
                'message' => 'Token aktivasi tidak valid atau sudah kedaluwarsa.',
            ], 400);
        }

        if ($device->status === 'revoked') {
            return response()->json([
                'message' => 'Akses perangkat ini telah diblokir oleh sistem.',
            ], 403);
        }

        $device->activateWithDeviceUid($validated['device_uid']);

        return response()->json([
            'message' => 'Perangkat berhasil diaktivasi.',
            'data' => [
                'device_id' => $device->id,
                'device_name' => $device->device_name,
                'organization' => $device->organization,
                'secret_key' => $device->secret_key,
            ]
        ]);
    }
    public function autoRegister(Request $request)
    {
        $validated = $request->validate([
            'organization_id' => 'required|exists:organizations,id',
            'device_uid' => 'required|string|max:255',
            'device_name' => 'required|string|max:255',
            'latitude' => 'nullable|numeric',
            'longitude' => 'nullable|numeric',
        ]);

        $organization = \App\Models\Organization::find($validated['organization_id']);

        // Update organization coordinates if provided
        if (isset($validated['latitude']) && isset($validated['longitude'])) {
            $organization->update([
                'latitude' => $validated['latitude'],
                'longitude' => $validated['longitude'],
            ]);
        }

        // Create the device directly
        $device = \App\Models\OutletDevice::create([
            'organization_id' => $organization->id,
            'device_name' => $validated['device_name'],
            'device_uid' => $validated['device_uid'],
            'status' => 'active',
            'last_active_at' => now(),
        ]);

        // Generate secret key (similar to what activateWithDeviceUid does)
        $secretKey = hash('sha256', $device->id . $validated['device_uid'] . config('app.key') . time());
        $device->update(['secret_key' => $secretKey]);

        return response()->json([
            'message' => 'Perangkat berhasil diregistrasi.',
            'data' => [
                'device_id' => $device->id,
                'device_name' => $device->device_name,
                'organization' => $device->organization,
                'secret_key' => $secretKey,
            ]
        ]);
    }

    public function login(Request $request)
    {
        $validated = $request->validate([
            'device_code' => 'required|string',
            'pin' => 'required|string',
            'device_uid' => 'required|string',
        ]);

        $device = \App\Models\OutletDevice::with('organization')
            ->where('device_code', $validated['device_code'])
            ->first();

        if (!$device) {
            return response()->json([
                'message' => 'ID Perangkat tidak ditemukan.',
            ], 404);
        }

        if ($device->pin !== $validated['pin']) {
            return response()->json([
                'message' => 'PIN salah.',
            ], 401);
        }

        if ($device->status === 'revoked') {
            return response()->json([
                'message' => 'Akses perangkat ini telah diblokir oleh sistem.',
            ], 403);
        }

        // Bind new device uid and set active
        $device->activateWithDeviceUid($validated['device_uid']);

        return response()->json([
            'message' => 'Login Sobat Outlet berhasil.',
            'data' => [
                'device_id' => $device->id,
                'device_name' => $device->device_name,
                'organization' => $device->organization,
                'secret_key' => $device->secret_key,
            ]
        ]);
    }
}
