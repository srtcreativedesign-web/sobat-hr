<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Attendance;
use App\Models\Employee;
use Carbon\Carbon;
use Maatwebsite\Excel\Facades\Excel;
use App\Exports\AttendanceExport;

class AttendanceController extends Controller
{
    public function index(Request $request)
    {
        $query = Attendance::with(['employee']);

        if ($request->has('employee_id')) {
            $query->where('employee_id', $request->employee_id);
        }

        // Date Range Filter
        if ($request->has('start_date') && $request->start_date) {
            $query->whereDate('date', '>=', $request->start_date);
        }
        if ($request->has('end_date') && $request->end_date) {
            $query->whereDate('date', '<=', $request->end_date);
        }
        
        // Backward compatibility or exact date match if needed
        if (!$request->has('start_date') && $request->has('date')) {
            $query->whereDate('date', $request->date);
        }

        // Division Filter
        if ($request->has('division_id') && $request->division_id) {
            $query->whereHas('employee', function ($q) use ($request) {
                $q->where('organization_id', $request->division_id);
            });
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
            'status' => 'required|in:present,late,absent,leave,sick,pending', // Added pending
            'notes' => 'nullable|string',
            'latitude' => 'nullable|numeric',
            'longitude' => 'nullable|numeric',
            'photo' => 'nullable|image|max:5120', // Max 5MB
            'location_address' => 'nullable|string',
            'attendance_type' => 'nullable|in:office,field', // New: attendance type
            'field_notes' => 'nullable|string|required_if:attendance_type,field', // Mandatory for field
        ]);

        // DEBUG: Log raw incoming request data
        \Illuminate\Support\Facades\Log::info('ATTENDANCE RAW REQUEST:', [
            'attendance_type_raw' => $request->input('attendance_type'),
            'field_notes_raw' => $request->input('field_notes'),
            'all_inputs' => $request->except(['photo']),
        ]);

        $employee = Employee::with('organization')->find($validated['employee_id']);
        
        // Set default attendance type to 'office' if not specified
        $attendanceType = $validated['attendance_type'] ?? 'office';

        \Illuminate\Support\Facades\Log::info('ATTENDANCE TYPE RESOLVED:', [
            'validated_attendance_type' => $validated['attendance_type'] ?? 'NOT SET',
            'final_attendanceType' => $attendanceType,
        ]);

        // Geolocation Validation (Skip for field attendance)
        if ($attendanceType === 'office' && isset($validated['latitude']) && isset($validated['longitude']) && $employee && $employee->organization && $employee->organization->latitude) {
            $orgLat = $employee->organization->latitude;
            $orgLng = $employee->organization->longitude;
            $radius = $employee->organization->radius_meters ?? 50;

            $distance = $this->haversineGreatCircleDistance(
                $validated['latitude'],
                $validated['longitude'],
                $orgLat,
                $orgLng
            );

            if ($distance > $radius) {
                return response()->json([
                    'message' => 'Anda berada di luar jangkauan kantor.',
                    'distance' => round($distance, 2) . ' meter',
                    'radius' => $radius . ' meter'
                ], 422); // Unprocessable Entity
            }
        }
        
        // For field attendance: Auto-set status to pending (requires approval)
        if ($attendanceType === 'field') {
            $validated['status'] = 'pending';
            $validated['attendance_type'] = 'field';
        } else {
            $validated['attendance_type'] = 'office';
        }

        // Handle Photo Upload
        if ($request->hasFile('photo')) {
            $photo = $request->file('photo');
            
            // Generate filename unique
            $filename = uniqid() . '_' . time() . '.jpg';
            $path = 'attendance_photos/' . $filename;
            $fullPath = storage_path('app/public/' . $path);

            // Compress and Resize Image
            $this->resizeAndSaveImage($photo->getPathname(), $fullPath, 800, 80); // Width 800px, Quality 80
            
            $validated['photo_path'] = $path;

            // Face Verification Logic
            if ($employee->face_photo_path) {
                // Determine full paths
                $checkInPhotoPath = storage_path('app/public/' . $path);
                $referencePhotoPath = storage_path('app/public/' . $employee->face_photo_path);
                $scriptPath = base_path('python_scripts/compare_faces.py');

                // Platform-aware Python command
                if (PHP_OS_FAMILY === 'Darwin') {
                    // macOS (Development) - Use arch for Apple Silicon compatibility
                    $command = "/usr/bin/arch -arm64 /usr/bin/python3 " . escapeshellarg($scriptPath) . " " . escapeshellarg($referencePhotoPath) . " " . escapeshellarg($checkInPhotoPath) . " 2>&1";
                } else {
                    // Linux (Production) - Standard python3
                    $command = "/usr/bin/python3 " . escapeshellarg($scriptPath) . " " . escapeshellarg($referencePhotoPath) . " " . escapeshellarg($checkInPhotoPath) . " 2>&1";
                }
                
                $output = shell_exec($command);
                $result = json_decode($output, true);

                // FAIL-SECURE: If verification fails for ANY reason, BLOCK attendance
                if (!$result) {
                    \Illuminate\Support\Facades\Log::error('Face Verification Script Output Empty or Invalid', ['output' => $output]);
                    \Illuminate\Support\Facades\Storage::disk('public')->delete($path);
                    return response()->json([
                        'message' => 'Verifikasi wajah gagal: Script tidak merespons. Hubungi administrator.',
                    ], 422);
                }

                if ($result['status'] === 'error') {
                    \Illuminate\Support\Facades\Log::error('Face Verification Error: ' . $result['message']);
                    \Illuminate\Support\Facades\Storage::disk('public')->delete($path);
                    return response()->json([
                        'message' => 'Verifikasi wajah gagal: ' . $result['message'],
                    ], 422);
                }

                if ($result['status'] === 'success' && !$result['match']) {
                    \Illuminate\Support\Facades\Storage::disk('public')->delete($path);
                    return response()->json([
                        'message' => 'Verifikasi Wajah Gagal. Wajah tidak cocok dengan data pendaftaran.',
                        'distance' => $result['distance']
                    ], 422);
                }

                // Success: Face matched
                $validated['face_verified'] = true;
                \Illuminate\Support\Facades\Log::info('Face Verified Successfully', ['distance' => $result['distance']]);
            } else {
                // Employee has no registered face - BLOCK attendance
                \Illuminate\Support\Facades\Storage::disk('public')->delete($path);
                return response()->json([
                    'message' => 'Anda belum mendaftarkan wajah. Silakan daftarkan wajah terlebih dahulu di menu Profil.',
                ], 403);
            }
        }

        // Check for Late (after 08:00) - Skip if already pending (field attendance)
        if ($validated['status'] !== 'pending') {
            $workStartTime = Carbon::parse($validated['date'] . ' 08:00:00');
            $clockInTime = Carbon::parse($validated['date'] . ' ' . $validated['check_in']);
            
            \Illuminate\Support\Facades\Log::info('Attendance Logic:', [
                'date' => $validated['date'],
                'check_in_input' => $validated['check_in'],
                'work_start' => $workStartTime->toDateTimeString(),
                'clock_in_parsed' => $clockInTime->toDateTimeString(),
                'is_gt' => $clockInTime->gt($workStartTime) ? 'YES' : 'NO'
            ]);

            // Late Logic
            // Late Logic
            if ($clockInTime->gt($workStartTime)) {
                // Use abs() because diffInMinutes is returning negative values on this environment
                $lateDuration = abs($clockInTime->diffInMinutes($workStartTime));
                $validated['late_duration'] = $lateDuration;
                
                \Illuminate\Support\Facades\Log::info('Late Duration Check (Fixed):', ['duration' => $lateDuration]);

                // If late more than 5 minutes (> 08:05), need approval
                if ($lateDuration > 5) {
                    $validated['status'] = 'pending';
                    \Illuminate\Support\Facades\Log::info('Status set to pending');
                } else {
                    $validated['status'] = 'late';
                    \Illuminate\Support\Facades\Log::info('Status set to late');
                }
            } else {
                 // On time
                 $validated['status'] = 'present';
                 \Illuminate\Support\Facades\Log::info('Status set to present');
            }
        }

        // Calculate work hours if check_out exists (e.g., manual full day input)
        if (isset($validated['check_out'])) {
            $checkIn = Carbon::parse($validated['check_in']);
            $checkOut = Carbon::parse($validated['check_out']);
            $validated['work_hours'] = $checkIn->floatDiffInHours($checkOut);

            // Check for Overtime (after 17:00)
            $workEndTime = Carbon::parse($validated['date'] . ' 17:00:00');
            $clockOutTime = Carbon::parse($validated['date'] . ' ' . $validated['check_out']);
            
            if ($clockOutTime->gt($workEndTime)) {
                $validated['overtime_duration'] = $clockOutTime->diffInMinutes($workEndTime);
                 // Note: Status might remain 'present' or 'late', overtime is an attribute. 
                 // If we want status to be 'overtime', we can change it, but usually 'overtime' is just extra hours on top of present.
                 // The enum has 'overtime', but usually that means "Full Overtime Day" or similar. 
                 // Let's keep status as calculated (late or present) and just store duration.
            }
        }

        $attendance = Attendance::create($validated);

        return response()->json($attendance, 201);
    }

    /**
     * Calculate distance between two points in meters using Haversine formula
     */
    private function haversineGreatCircleDistance($latitudeFrom, $longitudeFrom, $latitudeTo, $longitudeTo, $earthRadius = 6371000)
    {
        $latFrom = deg2rad($latitudeFrom);
        $lonFrom = deg2rad($longitudeFrom);
        $latTo = deg2rad($latitudeTo);
        $lonTo = deg2rad($longitudeTo);

        $latDelta = $latTo - $latFrom;
        $lonDelta = $lonTo - $lonFrom;

        $angle = 2 * asin(sqrt(pow(sin($latDelta / 2), 2) +
            cos($latFrom) * cos($latTo) * pow(sin($lonDelta / 2), 2)));
        
        return $angle * $earthRadius;
    }

    /**
     * Resize and save image using GD
     */
    private function resizeAndSaveImage($sourcePath, $destinationPath, $maxWidth, $quality)
    {
        list($width, $height, $type) = getimagesize($sourcePath);
        
        // Load image based on type
        switch ($type) {
            case IMAGETYPE_JPEG:
                $sourceImage = imagecreatefromjpeg($sourcePath);
                break;
            case IMAGETYPE_PNG:
                $sourceImage = imagecreatefrompng($sourcePath);
                break;
            default:
                // If not JPG/PNG, just copy original
                copy($sourcePath, $destinationPath);
                return;
        }

        // Calculate new dimensions
        if ($width > $maxWidth) {
            $newWidth = $maxWidth;
            $newHeight = ($height / $width) * $newWidth;
        } else {
            $newWidth = $width;
            $newHeight = $height;
        }

        $newImage = imagecreatetruecolor($newWidth, $newHeight);

        // Preserve transparency for PNG
        if ($type == IMAGETYPE_PNG) {
            imagealphablending($newImage, false);
            imagesavealpha($newImage, true);
        }

        // Resize
        imagecopyresampled($newImage, $sourceImage, 0, 0, 0, 0, $newWidth, $newHeight, $width, $height);

        // Save as JPEG (convert everything to jpg for uniformity and compression)
        // Ensure directory exists
        $directory = dirname($destinationPath);
        if (!file_exists($directory)) {
            mkdir($directory, 0755, true);
        }

        imagejpeg($newImage, $destinationPath, $quality);

        // Free memory
        imagedestroy($sourceImage);
        imagedestroy($newImage);
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
            'photo' => 'nullable|image|max:5120', // Add validation for checkout photo
        ]);

        // Handle Checkout Photo Upload
        if ($request->hasFile('photo')) {
            $path = $request->file('photo')->store('attendance_photos', 'public');
            $validated['checkout_photo_path'] = $path;
        }

        // Recalculate work hours if check_in or check_out changes
        if (isset($validated['check_in']) || isset($validated['check_out'])) {
            $checkInTime = isset($validated['check_in']) ? $validated['check_in'] : $attendance->check_in;
            $checkOutTime = isset($validated['check_out']) ? $validated['check_out'] : $attendance->check_out;

            $checkIn = Carbon::parse($checkInTime);
            $checkOut = Carbon::parse($checkOutTime);
            
            if ($checkOutTime) {
                // Calculate Work Hours
            $validated['work_hours'] = $checkIn->floatDiffInHours($checkOut);

                // Calculate Overtime (after 17:00)
                // Use date from attendance record
                $dateStr = $attendance->date; // Assuming date is YYYY-MM-DD string or Carbon
                // If $attendance->date is Carbon (casted), format it. If string, use directly.
                // Model usually casts 'date' => 'date'.
                $dateVal = $attendance->date instanceof Carbon ? $attendance->date->format('Y-m-d') : $attendance->date;
                
                $workEndTime = Carbon::parse($dateVal . ' 17:00:00');
                // Check Out Date/Time 
                // Note: If check out is next day, this logic needs adjustment. Assuming same day for now.
                $clockOutDateTime = Carbon::parse($dateVal . ' ' . $checkOutTime);
                
                if ($clockOutDateTime->gt($workEndTime)) {
                    $validated['overtime_duration'] = $clockOutDateTime->diffInMinutes($workEndTime);
                } else {
                    $validated['overtime_duration'] = 0;
                }
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
    /**
     * Get today's attendance for the authenticated user
     */
    public function today(Request $request)
    {
        $user = $request->user();
        if (!$user->employee) {
            return response()->json(['message' => 'Employee record not found'], 404);
        }

        $attendance = Attendance::where('employee_id', $user->employee->id)
            ->whereDate('date', Carbon::today())
            ->first();

        return response()->json($attendance);
    }
    /**
     * Get attendance history for the authenticated user
     */
    public function history(Request $request)
    {
        $user = $request->user();
        if (!$user->employee) {
            return response()->json(['message' => 'Employee record not found'], 404);
        }

        $query = Attendance::where('employee_id', $user->employee->id);

        if ($request->has('month') && $request->has('year')) {
            $query->whereMonth('date', $request->month)
                  ->whereYear('date', $request->year);
        }

        $history = $query->orderBy('date', 'desc')->get();

        return response()->json($history);
    }

    /**
     * Approve late attendance
     */
    public function approveLate(Request $request, $id)
    {
        $attendance = Attendance::findOrFail($id);

        if ($attendance->status !== 'pending') {
            return response()->json(['message' => 'Attendance is not pending approval'], 400);
        }

        $validated = $request->validate([
            'status' => 'required|in:late,present,absent', // Admin decides final status
            'admin_note' => 'nullable|string'
        ]);

        $attendance->status = $validated['status'];
        if (!empty($validated['admin_note'])) {
            // Append note if existing, or set new
            $existingNotes = $attendance->notes ? $attendance->notes . "\n" : "";
            $attendance->notes = $existingNotes . "[Admin Verification]: " . $validated['admin_note'];
        }

        $attendance->save();

        return response()->json($attendance);
    }
    /**
     * Export attendance to Excel
     */
    public function export(Request $request)
    {
        return Excel::download(new AttendanceExport($request), 'attendance_' . date('Y-m-d_H-i-s') . '.xlsx');
    }
    /**
     * Get count of pending attendance approvals
     */
    public function getPendingCount()
    {
        $count = Attendance::where('status', 'pending')->count();
        return response()->json(['count' => $count]);
    }
}
