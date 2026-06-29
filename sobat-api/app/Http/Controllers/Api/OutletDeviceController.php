<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;

class OutletDeviceController extends Controller
{
    public function index(Request $request)
    {
        $query = \App\Models\OutletDevice::with('organization');
        
        if ($request->has('organization_id')) {
            $query->where('organization_id', $request->organization_id);
        }

        $devices = $query->latest()->paginate($request->input('per_page', 15));
        
        return response()->json($devices);
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'organization_id' => 'required|exists:organizations,id',
            'device_name' => 'required|string|max:255',
            'pin' => 'required|string|min:6|max:6',
        ]);

        $device = \App\Models\OutletDevice::create($validated);
        $device->generateActivationToken();

        return response()->json([
            'message' => 'Device created successfully',
            'data' => $device
        ], 201);
    }

    public function update(Request $request, $id)
    {
        $device = \App\Models\OutletDevice::findOrFail($id);

        $validated = $request->validate([
            'device_name' => 'sometimes|required|string|max:255',
            'status' => 'sometimes|required|in:pending,active,revoked',
        ]);

        $device->update($validated);

        return response()->json([
            'message' => 'Device updated successfully',
            'data' => $device
        ]);
    }

    public function destroy($id)
    {
        $device = \App\Models\OutletDevice::findOrFail($id);
        $device->delete();

        return response()->json(['message' => 'Device deleted successfully']);
    }

    public function generateToken($id)
    {
        $device = \App\Models\OutletDevice::findOrFail($id);
        $device->generateActivationToken();

        return response()->json([
            'message' => 'Activation token regenerated successfully',
            'data' => $device
        ]);
    }
}
