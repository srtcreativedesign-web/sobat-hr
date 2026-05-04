<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Storage;
use App\Models\Attendance;
use App\Models\Employee;
use App\Jobs\VerifyAttendanceFace;
use App\Services\GeofenceValidationService;
use Carbon\Carbon;
use Maatwebsite\Excel\Facades\Excel;
use App\Exports\AttendanceExport;

class AttendanceController extends Controller
{
    public function index(Request $request)
    {
        // --- IDOR GUARD: Non-admin users can only see their own attendance ---
        $user = auth()->user();
        $roleName = $user->role ? strtolower($user->role->name) : '';
        $isAdmin = in_array($roleName, [\App\Models\Role::ADMIN, \App\Models\Role::SUPER_ADMIN, \App\Models\Role::HR, \App\Models\Role::HRD, \App\Models\Role::ADMIN_CABANG]);

        // EAGER LOADING: employee
        $query = Attendance::with(['employee.division']);

        $isMobile = $request->header('X-Platform') === 'mobile' || 
                    !$request->hasHeader('Origin') || 
                    str_contains($request->userAgent(), 'Dart');

        // Filter for self-view only if NOT in Admin roles OR if accessed via Mobile
        if (!$isAdmin || $isMobile) {
            // Non-admin or Mobile: force filter to own employee_id only
            if (!$user->employee) {
                return response()->json(['message' => 'Employee record not found'], 404);
            }
            $query->where('employee_id', $user->employee->id);
        } elseif ($request->has('employee_id')) {
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

        // Division Filter (Matches UI 'Organizations' name against Employee 'department' string)
        if ($request->has('division_id') && $request->division_id) {
            $orgName = \App\Models\Organization::find($request->division_id)?->name;
            if ($orgName) {
                $query->whereHas('employee', function ($q) use ($orgName) {
                    $q->where('department', $orgName);
                });
            }
        }

        if ($request->has('status')) {
            $query->where('status', $request->status);
        }

        $attendances = $query->orderBy('date', 'desc')->paginate(31);

        return response()->json($attendances);
    }

    public function store(Request $request)
    {
        // --- MAINTENANCE MODE ---
        if (config('app.attendance_maintenance', false)) {
            return response()->json([
                'message' => 'Fitur absensi sedang dalam maintenance. Silakan coba beberapa saat lagi.',
            ], 503);
        }

        $validated = $request->validate([
            'employee_id' => 'required|exists:employees,id',
            'date' => 'required|date',
            'check_in' => 'required',
            'check_out' => 'nullable',
            'status' => 'required|in:present,late,absent,leave,sick,pending',
            'notes' => 'nullable|string',
            'latitude' => 'nullable|numeric|between:-90,90',
            'longitude' => 'nullable|numeric|between:-180,180',
            'photo' => 'nullable|image|mimes:jpg,jpeg,png|max:5120',
            'location_address' => 'nullable|string',
            'attendance_type' => 'nullable|in:office,field',
            'field_notes' => 'nullable|string|required_if:attendance_type,field',
            'track_type' => 'nullable|in:operational,head_office,office',
            'is_shifting' => 'nullable|boolean',
        ]);

        $employee = Employee::find($validated['employee_id']);
        $attendanceType = $validated['attendance_type'] ?? 'office';
        // ✓ ENFORCE employee's track from database, not from request
        $trackType = $employee->track ?? 'head_office';
        \Log::info("Attendance Store - Employee: {$employee->full_name}, Track: {$trackType}, Type: {$attendanceType}");

        // Geolocation Validation (Mandatory for Head Office / Office track)
        if (($trackType === 'head_office' || $trackType === 'office') && $attendanceType === 'office' && isset($validated['latitude']) && isset($validated['longitude']) && $employee) {
            $geofenceService = app(GeofenceValidationService::class);
            $geofenceResult = $geofenceService->validateAgainstAllLocations(
                $validated['latitude'],
                $validated['longitude']
            );

            if (!$geofenceResult['valid']) {
                return response()->json([
                    'message' => $geofenceResult['message'],
                    'nearest_location' => $geofenceResult['data']['nearest_location'],
                    'distance_nearest' => $geofenceResult['data']['distance_meters'] . ' meter dari ' . ($geofenceResult['data']['nearest_location'] ?? 'lokasi terdekat'),
                ], 422);
            }

            $validated['location_id'] = $geofenceResult['data']['location_id'];
            $validated['location_name'] = $geofenceResult['data']['location_name'];
        }

        // For field attendance: Auto-set status to pending (requires approval)
        if ($attendanceType === 'field') {
            $validated['status'] = 'pending';
            $validated['attendance_type'] = 'field';
        } else {
            $validated['attendance_type'] = 'office';
        }

        // Handle Photo Upload
        $needsFaceVerification = false;
        if ($request->hasFile('photo')) {
            $photo = $request->file('photo');
            $filename = uniqid() . '_' . time() . '.jpg';
            $path = 'attendance_photos/' . $filename;
            $fullPath = storage_path('app/public/' . $path);

            $this->resizeAndSaveImage($photo->getPathname(), $fullPath, 800, 80);
            $validated['photo_path'] = $path;

            // Determine if face verification is needed (head_office track only)
            if (($trackType === 'head_office' || $trackType === 'office') && $employee->face_photo_path) {
                $needsFaceVerification = true;
                $validated['face_verification_status'] = 'pending';
            } else if ($trackType === 'head_office' && !$employee->face_photo_path) {
                Storage::disk('public')->delete($path);
                return response()->json([
                    'message' => 'Anda belum mendaftarkan wajah. Silakan daftarkan wajah terlebih dahulu di menu Profil.',
                ], 403);
            }
        }

        // Late/Status calculation (skip if already pending from field attendance)
        if ($validated['status'] !== 'pending') {
            // Check if user claimed shifting
            if (isset($validated['is_shifting']) && $validated['is_shifting'] == true) {
                $validated['status'] = 'present';
                $validated['late_duration'] = 0;
            } else {
                // Get employee shift
                $shift = $employee->shift;
                $defaultStartTime = '08:00:00';
                
                if ($shift) {
                    // Use shift start time if available
                    $startTimeStr = $shift->start_time instanceof Carbon 
                        ? $shift->start_time->format('H:i:s') 
                        : Carbon::parse($shift->start_time)->format('H:i:s');
                    $workStartTime = Carbon::parse($validated['date'] . ' ' . $startTimeStr);
                } else {
                    $workStartTime = Carbon::parse($validated['date'] . ' ' . $defaultStartTime);
                }

                $clockInTime = Carbon::parse($validated['date'] . ' ' . $validated['check_in']);

                if ($clockInTime->gt($workStartTime)) {
                    $lateDuration = abs($clockInTime->diffInMinutes($workStartTime));
                    $validated['late_duration'] = $lateDuration;

                    if ($lateDuration > 5) {
                        $validated['status'] = 'pending';
                    } else {
                        $validated['status'] = 'late';
                    }
                } else {
                    $validated['status'] = 'present';
                }
            }
        }

        // Calculate work hours if check_out exists
        if (isset($validated['check_out'])) {
            $checkIn = Carbon::parse($validated['check_in']);
            $checkOut = Carbon::parse($validated['check_out']);
            $validated['work_hours'] = $checkIn->floatDiffInHours($checkOut);

            // Get employee shift for overtime
            $shift = $employee->shift;
            $defaultEndTime = '17:00:00';

            if ($shift) {
                $endTimeStr = $shift->end_time instanceof Carbon 
                    ? $shift->end_time->format('H:i:s') 
                    : Carbon::parse($shift->end_time)->format('H:i:s');
                $workEndTime = Carbon::parse($validated['date'] . ' ' . $endTimeStr);
            } else {
                $workEndTime = Carbon::parse($validated['date'] . ' ' . $defaultEndTime);
            }

            $clockOutTime = Carbon::parse($validated['date'] . ' ' . $validated['check_out']);

            if ($clockOutTime->gt($workEndTime)) {
                $validated['overtime_duration'] = $clockOutTime->diffInMinutes($workEndTime);
            }
        }

        // Verify face synchronously for immediate feedback
        if ($needsFaceVerification) {
            $verificationResult = $this->verifyFaceInline(
                $employee->id,
                $validated['photo_path']
            );

            if ($verificationResult['status'] === 'mismatch') {
                // Delete the photo as it's not valid
                Storage::disk('public')->delete($validated['photo_path']);
                
                return response()->json([
                    'message' => 'Verifikasi wajah gagal: wajah tidak cocok. Pastikan Anda melakukan absensi sendiri.',
                    'distance' => $verificationResult['distance'] ?? null
                ], 422);
            } elseif ($verificationResult['status'] === 'error') {
                // If AI service is down, we might allow it but flag it? 
                // For now, let's allow but log error, or we can be strict.
                Log::error('Face verification service error: ' . $verificationResult['message']);
                $validated['face_verification_status'] = 'failed';
            } else {
                $validated['face_verified'] = true;
                $validated['face_verification_status'] = 'verified';
            }
        }

        // Store the employee's actual track_type in the attendance record for auditing
        $validated['track_type'] = $trackType;

        // Wrap in transaction for data consistency under concurrent writes
        $attendance = DB::transaction(function () use ($validated) {
            return Attendance::create($validated);
        });

        return response()->json($attendance, 201);
    }

    /**
     * Get all configured attendance locations
     */
    public function getLocations()
    {
        return response()->json([
            'locations' => config('attendance_locations.locations'),
        ]);
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
        @imagedestroy($sourceImage);
        @imagedestroy($newImage);
    }

    public function show(string $id)
    {
        $attendance = Attendance::with('employee')->findOrFail($id);
        
        // --- IDOR GUARD ---
        $user = auth()->user();
        $roleName = $user->role ? strtolower($user->role->name) : '';
        $isAdmin = in_array($roleName, [\App\Models\Role::ADMIN, \App\Models\Role::SUPER_ADMIN, \App\Models\Role::HR]);

        if (!$isAdmin && $attendance->employee_id !== $user->employee?->id) {
            return response()->json(['message' => 'Anda tidak memiliki akses ke data absensi ini.'], 403);
        }

        return response()->json($attendance);
    }

    public function update(Request $request, string $id)
    {
        $attendance = Attendance::findOrFail($id);
        // --- MAINTENANCE MODE ---
        if (config('app.attendance_maintenance', false)) {
            return response()->json([
                'message' => 'Fitur absensi sedang dalam maintenance. Silakan coba beberapa saat lagi.',
            ], 503);
        }

        $attendance = Attendance::findOrFail($id);

        // --- IDOR GUARD ---
        $user = auth()->user();
        $roleName = $user->role ? strtolower($user->role->name) : '';
        $isAdmin = in_array($roleName, [\App\Models\Role::ADMIN, \App\Models\Role::SUPER_ADMIN, \App\Models\Role::HR]);

        if (!$isAdmin && $attendance->employee_id !== $user->employee?->id) {
            return response()->json(['message' => 'Anda tidak memiliki akses untuk mengubah data absensi ini.'], 403);
        }

        $validated = $request->validate([
            'check_in' => 'sometimes',
            'check_out' => 'nullable',
            'status' => 'sometimes|in:present,late,absent,leave,sick',
            'notes' => 'nullable|string',
            'attendance_type' => 'nullable|in:office,field',
            'field_notes' => 'nullable|string',
            'photo' => 'required_with:check_out|image|mimes:jpg,jpeg,png|max:5120',
            'track_type' => 'nullable|in:operational,head_office,office',
            'qr_code_data' => 'nullable|string', // QR code for operational checkout validation
        ]);

        \Log::info("Attendance Update/Checkout - ID: {$attendance->id}, Track (DB): {$attendance->track_type}");

        // Handle Checkout Photo Upload (with compression)
        if ($request->hasFile('photo')) {
            $photo = $request->file('photo');
            
            // Generate filename unique
            $filename = 'out_' . uniqid() . '_' . time() . '.jpg';
            $path = 'attendance_photos/' . $filename;
            $fullPath = storage_path('app/public/' . $path);

            // Cleanup: Delete old checkout photo if exists
            if ($attendance->checkout_photo_path) {
                Storage::disk('public')->delete($attendance->checkout_photo_path);
            }

            // Compress and Resize Image (Consistent with check-in)
            $this->resizeAndSaveImage($photo->getPathname(), $fullPath, 800, 80);
            
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

                // Calculate Overtime based on Shift
                $shift = $attendance->employee->shift;
                $defaultEndTime = '17:00:00';
                $dateVal = $attendance->date instanceof Carbon ? $attendance->date->format('Y-m-d') : $attendance->date;

                if ($shift) {
                    $endTimeStr = $shift->end_time instanceof Carbon 
                        ? $shift->end_time->format('H:i:s') 
                        : Carbon::parse($shift->end_time)->format('H:i:s');
                    $workEndTime = Carbon::parse($dateVal . ' ' . $endTimeStr);
                } else {
                    $workEndTime = Carbon::parse($dateVal . ' ' . $defaultEndTime);
                }

                $clockOutDateTime = Carbon::parse($dateVal . ' ' . $checkOutTime);
                
                if ($clockOutDateTime->gt($workEndTime)) {
                    $validated['overtime_duration'] = $clockOutDateTime->diffInMinutes($workEndTime);
                } else {
                    $validated['overtime_duration'] = 0;
                }
            }
        }

        DB::transaction(function () use ($attendance, $validated) {
            $attendance->update($validated);
        });

        return response()->json($attendance);
    }

    public function destroy(string $id)
    {
        $attendance = Attendance::findOrFail($id);

        // --- IDOR GUARD ---
        $user = auth()->user();
        $roleName = $user->role ? strtolower($user->role->name) : '';
        $isAdmin = in_array($roleName, [\App\Models\Role::ADMIN, \App\Models\Role::SUPER_ADMIN, \App\Models\Role::HR]);

        if (!$isAdmin) {
             return response()->json(['message' => 'Hanya Admin/HR yang dapat menghapus data absensi.'], 403);
        }

        // Cleanup: Delete associated photos from storage before deleting the record
        if ($attendance->photo_path) {
            Storage::disk('public')->delete($attendance->photo_path);
        }
        if ($attendance->checkout_photo_path) {
            Storage::disk('public')->delete($attendance->checkout_photo_path);
        }

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
            ->where('date', Carbon::today()->toDateString())
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

    /**
     * Bulk approve attendance records
     */
    public function bulkApprove(Request $request)
    {
        // --- IDOR GUARD ---
        $user = auth()->user();
        $roleName = $user->role ? strtolower($user->role->name) : '';
        $isAdmin = in_array($roleName, [\App\Models\Role::ADMIN, \App\Models\Role::SUPER_ADMIN, \App\Models\Role::HR]);

        if (!$isAdmin) {
            return response()->json(['message' => 'Hanya Admin/HR yang dapat melakukan bulk approval.'], 403);
        }

        $validated = $request->validate([
            'ids' => 'required|array',
            'ids.*' => 'exists:attendances,id',
            'status' => 'required|in:present,late,absent',
            'admin_note' => 'nullable|string'
        ]);

        $count = DB::transaction(function () use ($validated) {
            $updated = 0;
            $attendances = Attendance::whereIn('id', $validated['ids'])
                ->where('status', 'pending')
                ->get();

            foreach ($attendances as $attendance) {
                /** @var \App\Models\Attendance $attendance */
                $attendance->status = $validated['status'];
                if (!empty($validated['admin_note'])) {
                    $existingNotes = $attendance->notes ? $attendance->notes . "\n" : "";
                    $attendance->notes = $existingNotes . "[Bulk Approved]: " . $validated['admin_note'];
                }
                $attendance->save();
                $updated++;
            }
            return $updated;
        });

        return response()->json([
            'message' => "Berhasil memproses $count data absensi.",
            'updated_count' => $count
        ]);
    }

    /**
     * Verify face inline (synchronous)
     */
    private function verifyFaceInline(int $employeeId, string $checkInPhoto)
    {
        $employee = Employee::find($employeeId);
        if (!$employee || !$employee->face_photo_path) {
            return ['status' => 'error', 'message' => 'Employee face data not found'];
        }

        $checkInPhotoPath = storage_path('app/public/' . $checkInPhoto);
        $referencePhotoPath = storage_path('app/public/' . $employee->face_photo_path);
        $scriptPath = base_path('python_scripts/compare_faces.py');

        // Platform-aware Python command
        if (PHP_OS_FAMILY === 'Darwin') {
            $command = "/usr/bin/arch -arm64 /usr/bin/python3 " . escapeshellarg($scriptPath) . " " . escapeshellarg($referencePhotoPath) . " " . escapeshellarg($checkInPhotoPath) . " 2>&1";
        } else {
            $command = "/usr/bin/python3 " . escapeshellarg($scriptPath) . " " . escapeshellarg($referencePhotoPath) . " " . escapeshellarg($checkInPhotoPath) . " 2>&1";
        }

        $output = shell_exec($command);
        $result = json_decode($output, true);

        if (!$result || !isset($result['status'])) {
            return ['status' => 'error', 'message' => 'AI Service error', 'raw' => $output];
        }

        if ($result['status'] === 'success' && $result['match']) {
            return ['status' => 'success', 'match' => true, 'distance' => $result['distance']];
        }

        return [
            'status' => 'mismatch', 
            'match' => false, 
            'distance' => $result['distance'] ?? null,
            'message' => $result['message'] ?? 'Face mismatch'
        ];
    }
}
