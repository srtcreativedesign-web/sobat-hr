<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Attendance;
use App\Models\Employee;
use Carbon\Carbon;

class AttendanceController extends Controller
{
    public function index(Request $request)
    {
        $query = Attendance::with(['employee']);

        if ($request->has('employee_id')) {
            $query->where('employee_id', $request->employee_id);
        }

        if ($request->has('date')) {
            $query->whereDate('date', $request->date);
        }

        if ($request->has('status')) {
            $query->where('status', $request->status);
        }

        $attendances = $query->orderBy('date', 'desc')->paginate(31);

        return response()->json($attendances);
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'employee_id' => 'required|exists:employees,id',
            'date' => 'required|date',
            'check_in' => 'required',
            'check_out' => 'nullable',
            'status' => 'required|in:present,late,absent,leave,sick',
            'notes' => 'nullable|string',
        ]);

        // Calculate work hours if check_out exists
        if (isset($validated['check_out'])) {
            $checkIn = Carbon::parse($validated['check_in']);
            $checkOut = Carbon::parse($validated['check_out']);
            $validated['work_hours'] = $checkOut->diffInHours($checkIn, false);
        }

        $attendance = Attendance::create($validated);

        return response()->json($attendance, 201);
    }

    public function show(string $id)
    {
        $attendance = Attendance::with('employee')->findOrFail($id);
        return response()->json($attendance);
    }

    public function update(Request $request, string $id)
    {
        $attendance = Attendance::findOrFail($id);

        $validated = $request->validate([
            'check_in' => 'sometimes',
            'check_out' => 'nullable',
            'status' => 'sometimes|in:present,late,absent,leave,sick',
            'notes' => 'nullable|string',
        ]);

        // Recalculate work hours if check_in or check_out changes
        if (isset($validated['check_in']) || isset($validated['check_out'])) {
            $checkIn = Carbon::parse($validated['check_in'] ?? $attendance->check_in);
            $checkOut = Carbon::parse($validated['check_out'] ?? $attendance->check_out);
            if ($checkOut) {
                $validated['work_hours'] = $checkOut->diffInHours($checkIn, false);
            }
        }

        $attendance->update($validated);

        return response()->json($attendance);
    }

    public function destroy(string $id)
    {
        $attendance = Attendance::findOrFail($id);
        $attendance->delete();

        return response()->json(['message' => 'Attendance deleted successfully']);
    }

    /**
     * Sync attendance from fingerprint device
     */
    public function syncFingerprint(Request $request)
    {
        $validated = $request->validate([
            'device_ip' => 'required|ip',
            'date' => 'nullable|date',
        ]);

        // TODO: Implement actual fingerprint sync logic
        // This will be handled by a Job/Queue in production
        
        return response()->json([
            'message' => 'Fingerprint sync queued successfully',
            'job_id' => 'sync_' . time(),
        ]);
    }

    /**
     * Get monthly attendance report
     */
    public function monthlyReport(int $month, int $year)
    {
        $attendances = Attendance::with('employee')
            ->whereMonth('date', $month)
            ->whereYear('date', $year)
            ->get()
            ->groupBy('employee_id');

        $report = [];
        foreach ($attendances as $employeeId => $records) {
            $report[] = [
                'employee' => $records->first()->employee,
                'total_days' => $records->count(),
                'present' => $records->where('status', 'present')->count(),
                'late' => $records->where('status', 'late')->count(),
                'absent' => $records->where('status', 'absent')->count(),
                'leave' => $records->where('status', 'leave')->count(),
                'sick' => $records->where('status', 'sick')->count(),
                'total_hours' => $records->sum('work_hours'),
            ];
        }

        return response()->json($report);
    }
}
