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

        if (!$isAdmin) {
            // Non-admin: force filter to own employee_id only
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
            'track_type' => 'nullable|in:operational,head_office',
        ]);

        $employee = Employee::find($validated['employee_id']);
        $attendanceType = $validated['attendance_type'] ?? 'office';
        // ✓ ENFORCE employee's track from database, not from request
        $trackType = $employee->track_type ?? 'head_office';
        $isOperational = $trackType === 'operational';

        // Geolocation Validation (Skip for field attendance and operational track)
        if ($trackType !== 'operational' && $attendanceType === 'office' && isset($validated['latitude']) && isset($validated['longitude']) && $employee) {
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
            if (!$isOperational && $employee->face_photo_path) {
                $needsFaceVerification = true;
                $validated['face_verification_status'] = 'pending';
            } else if (!$isOperational && !$employee->face_photo_path) {
                Storage::disk('public')->delete($path);
                return response()->json([
                    'message' => 'Anda belum mendaftarkan wajah. Silakan daftarkan wajah terlebih dahulu di menu Profil.',
                ], 403);
            }
        }

        // Late/Status calculation (skip if already pending from field attendance)
        if ($validated['status'] !== 'pending') {
            $workStartTime = Carbon::parse($validated['date'] . ' 08:00:00');
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

        // Calculate work hours if check_out exists
        if (isset($validated['check_out'])) {
            $checkIn = Carbon::parse($validated['check_in']);
            $checkOut = Carbon::parse($validated['check_out']);
            $validated['work_hours'] = $checkIn->floatDiffInHours($checkOut);

            $workEndTime = Carbon::parse($validated['date'] . ' 17:00:00');
            $clockOutTime = Carbon::parse($validated['date'] . ' ' . $validated['check_out']);

            if ($clockOutTime->gt($workEndTime)) {
                $validated['overtime_duration'] = $clockOutTime->diffInMinutes($workEndTime);
            }
        }

        // Store the employee's actual track_type in the attendance record for auditing
        $validated['track_type'] = $trackType;

        // Wrap in transaction for data consistency under concurrent writes
        $attendance = DB::transaction(function () use ($validated) {
            return Attendance::create($validated);
        });

        // Dispatch face verification as background job (non-blocking)
        if ($needsFaceVerification) {
            VerifyAttendanceFace::dispatch(
                $attendance->id,
                $employee->id,
                $validated['photo_path']
            );
        }

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
        imagedestroy($sourceImage);
        imagedestroy($newImage);
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
            'photo' => 'required_with:check_out|image|mimes:jpg,jpeg,png|max:5120', // ADDED MIMES VALIDATION
            'qr_code_data' => 'nullable|string', // QR code for operational checkout validation
        ]);

        // Operational track: validate checkout QR matches check-in location
        if ($attendance->track_type === 'operational' && isset($validated['check_out'])) {
            if (empty($validated['qr_code_data'])) {
                return response()->json([
                    'message' => 'Scan QR Code diperlukan untuk checkout di outlet. Silakan scan QR Code yang sama dengan saat check-in.',
                ], 422);
            }

            // Match against check-in QR code or outlet
            $checkInQr = $attendance->qr_code_data;
            $checkInOutletId = $attendance->outlet_id;
            $checkoutQr = $validated['qr_code_data'];

            // Validate checkout QR exists and is active
            $checkoutQrLocation = \App\Models\QrCodeLocation::where('qr_code', $checkoutQr)
                ->where('is_active', true)
                ->first();

            if (!$checkoutQrLocation) {
                return response()->json([
                    'message' => 'QR Code checkout tidak valid atau sudah tidak aktif.',
                ], 422);
            }

            // Compare: checkout outlet must match check-in outlet
            $isSameLocation = false;

            if ($checkInQr && $checkInQr === $checkoutQr) {
                $isSameLocation = true;
            } elseif ($checkInOutletId && $checkoutQrLocation->organization_id == $checkInOutletId) {
                // Same outlet even if QR code string differs (e.g. regenerated QR)
                $isSameLocation = true;
            }

            if (!$isSameLocation) {
                return response()->json([
                    'message' => 'Lokasi checkout tidak sesuai dengan lokasi check-in. Anda harus checkout di outlet yang sama.',
                ], 422);
            }
        }

        // Handle Checkout Photo Upload (with compression)
        if ($request->hasFile('photo')) {
            $photo = $request->file('photo');
            
            // Generate filename unique
            $filename = 'out_' . uniqid() . '_' . time() . '.jpg';
            $path = 'attendance_photos/' . $filename;
            $fullPath = storage_path('app/public/' . $path);

            // Cleanup: Delete old checkout photo if exists
            if ($attendance->checkout_photo_path) {
                \Illuminate\Support\Facades\Storage::disk('public')->delete($attendance->checkout_photo_path);
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
            \Illuminate\Support\Facades\Storage::disk('public')->delete($attendance->photo_path);
        }
        if ($attendance->checkout_photo_path) {
            \Illuminate\Support\Facades\Storage::disk('public')->delete($attendance->checkout_photo_path);
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
