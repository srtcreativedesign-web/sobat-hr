<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\OutletDevice;
use App\Models\Attendance;
use Carbon\Carbon;
use Barryvdh\DomPDF\Facade\Pdf;

class OutletHistoryController extends Controller
{
    private function authenticateDevice(Request $request)
    {
        $deviceUid = $request->header('x-device-uid');
        $secretKey = $request->header('x-secret-key');

        if (!$deviceUid || !$secretKey) {
            return null;
        }

        $device = OutletDevice::with('organization')
            ->where('device_uid', $deviceUid)
            ->where('secret_key', $secretKey)
            ->first();

        if (!$device || $device->status === 'revoked') {
            return null;
        }

        return $device;
    }

    public function history(Request $request)
    {
        $device = $this->authenticateDevice($request);

        if (!$device) {
            return response()->json(['message' => 'Unauthorized device'], 401);
        }

        $date = $request->query('date', Carbon::today()->toDateString());

        $history = Attendance::with(['employee:id,full_name,employee_code'])
            ->where('outlet_id', $device->organization_id)
            ->where('date', $date)
            ->orderBy('created_at', 'desc')
            ->get();

        return response()->json([
            'message' => 'History retrieved',
            'data' => $history
        ]);
    }

    public function downloadPdf(Request $request)
    {
        $device = $this->authenticateDevice($request);

        if (!$device) {
            return response()->json(['message' => 'Unauthorized device'], 401);
        }

        $date = $request->query('date', Carbon::today()->toDateString());
        $formattedDate = Carbon::parse($date)->translatedFormat('d F Y');

        $history = Attendance::with(['employee:id,full_name,employee_code'])
            ->where('outlet_id', $device->organization_id)
            ->where('date', $date)
            ->orderBy('created_at', 'desc')
            ->get();

        $pdf = Pdf::loadView('exports.outlet_history_pdf', [
            'history' => $history,
            'organization' => $device->organization,
            'date' => $formattedDate,
            'device_name' => $device->device_name,
        ]);

        return $pdf->download('Riwayat_Absen_' . ($device->organization->name ?? 'Outlet') . '_' . $date . '.pdf');
    }

    public function downloadExcel(Request $request)
    {
        $device = $this->authenticateDevice($request);

        if (!$device) {
            return response()->json(['message' => 'Unauthorized device'], 401);
        }

        $date = $request->query('date', Carbon::today()->toDateString());
        
        return \Maatwebsite\Excel\Facades\Excel::download(
            new \App\Exports\OutletHistoryExport($device->organization_id, $date),
            'Riwayat_Absen_' . ($device->organization->name ?? 'Outlet') . '_' . $date . '.xlsx'
        );
    }
}
