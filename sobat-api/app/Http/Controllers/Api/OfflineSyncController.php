<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Attendance;
use App\Models\Employee;
use App\Models\QrCodeLocation;
use App\Services\QrCodeValidationService;
use App\Services\GeofenceValidationService;
use App\Services\TimestampTamperingDetectionService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Storage;
use Carbon\Carbon;

class OfflineSyncController extends Controller
{
    protected QrCodeValidationService $qrValidationService;
    protected GeofenceValidationService $geofenceService;
    protected TimestampTamperingDetectionService $tamperingService;

    public function __construct(
        QrCodeValidationService $qrValidationService,
        GeofenceValidationService $geofenceService,
        TimestampTamperingDetectionService $tamperingService
    ) {
        $this->qrValidationService = $qrValidationService;
        $this->geofenceService = $geofenceService;
        $this->tamperingService = $tamperingService;
    }

    /**
     * Sync offline attendance submission
     * 
     * Expected payload:
     * {
     *   "employee_id": 123,
     *   "track_type": "operational" | "head_office",
     *   "validation_method": "qr_code" | "gps",
     *   "qr_code_data": "OUTLET-xxx-LT1-...", (if operational)
     *   "gps_coordinates": {"latitude": -6.123, "longitude": 106.456}, (if head_office)
     *   "photo_base64": "data:image/jpeg;base64,/9j/...",
     *   "device_timestamp": "2026-03-16 08:00:00",
     *   "device_id": "abc123xyz",
     *   "device_uptime_seconds": 3600,
     *   "attendance_type": "office" | "field",
     *   "field_notes": "..." (optional)
     * }
     */
    public function sync(Request $request)
    {
        DB::beginTransaction();

        try {
            // Validate required fields
            $validated = $request->validate([
                'employee_id' => 'required|exists:employees,id',
                'track_type' => 'required|in:head_office,operational',
                'validation_method' => 'required|in:qr_code,gps',
                'photo_base64' => 'required|string',
                'device_timestamp' => 'required|date',
                'device_id' => 'required|string',
                'device_uptime_seconds' => 'nullable|integer',
                'attendance_type' => 'nullable|in:office,field',
                'field_notes' => 'nullable|string',
            ]);

            $employee = Employee::with('user')->findOrFail($validated['employee_id']);

            // 1. Device ID Lock Validation
            $deviceLockResult = $this->validateDeviceLock($employee, $validated['device_id']);
            if (!$deviceLockResult['valid']) {
                DB::rollBack();
                return response()->json([
                    'success' => false,
                    'message' => $deviceLockResult['message'],
                ], 403);
            }

            // 2. Validate based on track type
            $locationValidation = null;
            if ($validated['track_type'] === 'operational') {
                // QR Code validation for operational track
                if (!$request->has('qr_code_data')) {
                    DB::rollBack();
                    return response()->json([
                        'success' => false,
                        'message' => 'QR code data is required for operational track',
                    ], 422);
                }

                $locationValidation = $this->qrValidationService->validate($request->qr_code_data);
                
                if (!$locationValidation['valid']) {
                    DB::rollBack();
                    return response()->json([
                        'success' => false,
                        'message' => $locationValidation['message'],
                    ], 422);
                }
            } else {
                // GPS validation for head_office track
                if (!$request->has('gps_coordinates')) {
                    DB::rollBack();
                    return response()->json([
                        'success' => false,
                        'message' => 'GPS coordinates are required for head office track',
                    ], 422);
                }

                $gpsCoords = $request->gps_coordinates;
                
                if (!isset($gpsCoords['latitude']) || !isset($gpsCoords['longitude'])) {
                    DB::rollBack();
                    return response()->json([
                        'success' => false,
                        'message' => 'Invalid GPS coordinates format',
                    ], 422);
                }

                // Get office coordinates (from employee's organization or default)
                $officeCoords = $this->getOfficeCoordinates($employee);
                
                $locationValidation = $this->geofenceService->validate(
                    $gpsCoords['latitude'],
                    $gpsCoords['longitude'],
                    $officeCoords['latitude'],
                    $officeCoords['longitude'],
                    $officeCoords['radius_meters']
                );

                if (!$locationValidation['valid']) {
                    DB::rollBack();
                    return response()->json([
                        'success' => false,
                        'message' => $locationValidation['message'],
                        'distance' => $locationValidation['data']['distance_meters'] ?? null,
                    ], 422);
                }
            }

            // 3. Timestamp tampering detection
            $serverTimestamp = now()->toDateTimeString();
            $tamperingResult = $this->tamperingService->detectTampering(
                $validated['device_timestamp'],
                $serverTimestamp,
                $validated['device_uptime_seconds'] ?? null
            );

            // 4. Process and save photo
            $photoPath = $this->processPhoto($validated['photo_base64'], $employee->id);

            // 5. Determine attendance status
            $attendanceStatus = $this->determineAttendanceStatus(
                $validated['device_timestamp'],
                $validated['attendance_type'] ?? 'office'
            );

            // 6. Create attendance record
            $attendanceData = [
                'employee_id' => $validated['employee_id'],
                'date' => Carbon::parse($validated['device_timestamp'])->format('Y-m-d'),
                'check_in' => Carbon::parse($validated['device_timestamp'])->format('H:i:s'),
                'status' => $attendanceStatus,
                'track_type' => $validated['track_type'],
                'validation_method' => $validated['validation_method'],
                'is_offline' => true,
                'device_timestamp' => $validated['device_timestamp'],
                'server_timestamp' => $serverTimestamp,
                'time_discrepancy_seconds' => $tamperingResult['discrepancy_seconds'],
                'device_id' => $validated['device_id'],
                'device_uptime_seconds' => $validated['device_uptime_seconds'] ?? null,
                'review_status' => $this->tamperingService->getReviewStatus($tamperingResult['discrepancy_seconds']),
                'photo_path' => $photoPath,
                'attendance_type' => $validated['attendance_type'] ?? 'office',
                'field_notes' => $validated['field_notes'] ?? null,
            ];

            // Add location-specific data
            if ($validated['track_type'] === 'operational' && $locationValidation['data']) {
                $attendanceData['qr_code_data'] = $locationValidation['data']['qr_code'];
                $attendanceData['outlet_id'] = $locationValidation['data']['organization_id'];
                $attendanceData['floor_number'] = $locationValidation['data']['floor_number'];
                $attendanceData['latitude'] = null; // QR doesn't provide GPS
                $attendanceData['longitude'] = null;
            } else {
                $attendanceData['latitude'] = $gpsCoords['latitude'];
                $attendanceData['longitude'] = $gpsCoords['longitude'];
            }

            $attendance = Attendance::create($attendanceData);

            DB::commit();

            // Log successful sync
            Log::info('Offline Attendance Synced Successfully', [
                'attendance_id' => $attendance->id,
                'employee_id' => $employee->id,
                'track_type' => $validated['track_type'],
                'review_status' => $attendance->review_status,
                'time_discrepancy' => $tamperingResult['discrepancy_seconds'],
            ]);

            return response()->json([
                'success' => true,
                'message' => 'Attendance synced successfully',
                'data' => [
                    'attendance_id' => $attendance->id,
                    'review_status' => $attendance->review_status,
                    'requires_review' => $attendance->review_status === 'pending',
                ],
            ], 201);

        } catch (\Exception $e) {
            DB::rollBack();
            
            Log::error('Offline Sync Failed', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString(),
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Failed to sync attendance: ' . $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Validate device ID lock (prevent account sharing)
     */
    protected function validateDeviceLock(Employee $employee, string $deviceId): array
    {
        // Check if this employee has a registered device
        $lastAttendance = Attendance::where('employee_id', $employee->id)
            ->whereNotNull('device_id')
            ->orderBy('created_at', 'desc')
            ->first();

        if ($lastAttendance && $lastAttendance->device_id !== $deviceId) {
            Log::warning('Device ID Mismatch', [
                'employee_id' => $employee->id,
                'registered_device' => $lastAttendance->device_id,
                'current_device' => $deviceId,
            ]);

            return [
                'valid' => false,
                'message' => 'Akun ini sudah terdaftar di perangkat lain. Hubungi HRD untuk registrasi perangkat baru.',
            ];
        }

        return ['valid' => true, 'message' => 'Device validated'];
    }

    /**
     * Process base64 photo and save to storage
     */
    protected function processPhoto(string $photoBase64, int $employeeId): string
    {
        // Remove data:image prefix if present
        if (preg_match('/^data:image\/(\w+);base64,/', $photoBase64, $type)) {
            $photoBase64 = substr($photoBase64, strlen($type[0]));
        }

        // Decode
        $photoData = base64_decode($photoBase64);

        if ($photoData === false) {
            throw new \Exception('Invalid base64 photo data');
        }

        // Generate filename
        $filename = 'offline_' . $employeeId . '_' . time() . '_' . uniqid() . '.jpg';
        $path = 'attendance_photos/offline/' . $filename;

        // Save to storage
        Storage::disk('public')->put($path, $photoData);

        return $path;
    }

    /**
     * Determine attendance status based on check-in time
     */
    protected function determineAttendanceStatus(string $checkInTime, string $attendanceType): string
    {
        // Field attendance is always pending (requires approval)
        if ($attendanceType === 'field') {
            return 'pending';
        }

        $checkIn = Carbon::parse($checkInTime);
        $workStart = Carbon::parse($checkInTime->format('Y-m-d') . ' 08:00:00');

        if ($checkIn->gt($workStart)) {
            $lateMinutes = abs($checkIn->diffInMinutes($workStart));
            
            if ($lateMinutes > 5) {
                return 'pending'; // Late more than 5 minutes, needs approval
            }
            
            return 'late'; // Late but within 5 minutes
        }

        return 'present';
    }

    /**
     * Get office coordinates for GPS validation
     */
    protected function getOfficeCoordinates(Employee $employee): array
    {
        // Try to get from employee's organization/division
        $organization = $employee->division; // Assuming division has geolocation
        
        if ($organization && $organization->latitude) {
            return [
                'latitude' => (float) $organization->latitude,
                'longitude' => (float) $organization->longitude,
                'radius_meters' => (int) ($organization->radius_meters ?? 100),
            ];
        }

        // Fallback to default head office
        return $this->geofenceService->getDefaultHeadOffice();
    }

    /**
     * Get offline submissions for admin review (Web Admin)
     */
    public function getOfflineSubmissions(Request $request)
    {
        $query = Attendance::with(['employee.user', 'employee.division', 'outlet'])
            ->where('is_offline', true);

        // Filter by review status
        if ($request->has('review_status')) {
            $query->where('review_status', $request->review_status);
        }

        // Filter by date range
        if ($request->has('start_date')) {
            $query->whereDate('device_timestamp', '>=', $request->start_date);
        }
        if ($request->has('end_date')) {
            $query->whereDate('device_timestamp', '<=', $request->end_date);
        }

        // Filter by track type
        if ($request->has('track_type')) {
            $query->where('track_type', $request->track_type);
        }

        // Filter by validation method
        if ($request->has('validation_method')) {
            $query->where('validation_method', $request->validation_method);
        }

        // Filter by employee
        if ($request->has('employee_id')) {
            $query->where('employee_id', $request->employee_id);
        }

        // Sort by device timestamp (when employee actually clocked in)
        $sortBy = $request->get('sort_by', 'device_timestamp');
        $sortDir = $request->get('sort_dir', 'desc');
        $query->orderBy($sortBy, $sortDir);

        $submissions = $query->paginate(50);

        return response()->json($submissions);
    }

    /**
     * Admin approve/reject offline submission
     */
    public function reviewSubmission(Request $request, int $id)
    {
        $attendance = Attendance::with('employee')->findOrFail($id);

        $validated = $request->validate([
            'review_status' => 'required|in:approved,rejected',
            'review_notes' => 'nullable|string|max:1000',
        ]);

        $attendance->review_status = $validated['review_status'];
        
        if (isset($validated['review_notes'])) {
            $existingNotes = $attendance->review_notes ? $attendance->review_notes . "\n" : "";
            $attendance->review_notes = $existingNotes . "[Admin Review]: " . $validated['review_notes'];
        }

        // If approved, ensure status is valid
        if ($validated['review_status'] === 'approved' && $attendance->status === 'pending') {
            $attendance->status = 'present'; // Default to present when approved
        }

        $attendance->save();

        Log::info('Offline Attendance Reviewed', [
            'attendance_id' => $attendance->id,
            'review_status' => $attendance->review_status,
            'admin_id' => auth()->id(),
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Submission reviewed successfully',
            'data' => $attendance,
        ]);
    }

    /**
     * Get statistics for offline submissions
     */
    public function getStatistics(Request $request)
    {
        $baseQuery = Attendance::where('is_offline', true);

        // Date range filter
        if ($request->has('start_date')) {
            $baseQuery->whereDate('device_timestamp', '>=', $request->start_date);
        }
        if ($request->has('end_date')) {
            $baseQuery->whereDate('device_timestamp', '<=', $request->end_date);
        }

        $total = $baseQuery->count();
        $pending = (clone $baseQuery)->where('review_status', 'pending')->count();
        $approved = (clone $baseQuery)->where('review_status', 'approved')->count();
        $rejected = (clone $baseQuery)->where('review_status', 'rejected')->count();

        // Group by track type
        $byTrack = (clone $baseQuery)
            ->select('track_type', DB::raw('count(*) as count'))
            ->groupBy('track_type')
            ->get()
            ->pluck('count', 'track_type');

        // Group by validation method
        $byValidation = (clone $baseQuery)
            ->select('validation_method', DB::raw('count(*) as count'))
            ->groupBy('validation_method')
            ->get()
            ->pluck('count', 'validation_method');

        // Time discrepancy stats
        $avgDiscrepancy = (clone $baseQuery)
            ->whereNotNull('time_discrepancy_seconds')
            ->avg('time_discrepancy_seconds');

        $highDiscrepancy = (clone $baseQuery)
            ->where('time_discrepancy_seconds', '>', 300)
            ->count();

        return response()->json([
            'total' => $total,
            'pending' => $pending,
            'approved' => $approved,
            'rejected' => $rejected,
            'by_track_type' => [
                'head_office' => $byTrack['head_office'] ?? 0,
                'operational' => $byTrack['operational'] ?? 0,
            ],
            'by_validation_method' => [
                'qr_code' => $byValidation['qr_code'] ?? 0,
                'gps' => $byValidation['gps'] ?? 0,
            ],
            'average_time_discrepancy_seconds' => round($avgDiscrepancy ?? 0, 2),
            'high_discrepancy_count' => $highDiscrepancy,
        ]);
    }

    /**
     * Generate QR codes for all outlets (Admin utility)
     */
    public function generateQrCodes(Request $request)
    {
        $qrService = new QrCodeValidationService();
        
        try {
            $generated = $qrService->batchGenerateForOutlets();

            return response()->json([
                'success' => true,
                'message' => 'QR codes generated successfully',
                'data' => $generated,
            ]);
        } catch (\Exception $e) {
            Log::error('QR Code Generation Failed', [
                'error' => $e->getMessage(),
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Failed to generate QR codes: ' . $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Generate or Update a single QR code for a specific outlet/floor
     */
    public function generateSingleQrCode(Request $request)
    {
        $validated = $request->validate([
            'organization_id' => 'required|exists:organizations,id',
            'floor_number' => 'nullable|integer|min:1',
            'location_name' => 'nullable|string|max:255',
            'notes' => 'nullable|string|max:1000',
        ]);

        try {
            $qrService = new QrCodeValidationService();
            $qrLocation = $qrService->createQrCodeLocation(
                $validated['organization_id'],
                $validated['floor_number'] ?? 1,
                $validated['location_name'] ?? '',
                $validated['notes'] ?? null
            );

            return response()->json([
                'success' => true,
                'message' => 'QR code generated/updated successfully',
                'data' => $qrLocation->load('organization'),
            ]);
        } catch (\Exception $e) {
            Log::error('Single QR Code Generation Failed', [
                'error' => $e->getMessage(),
                'organization_id' => $validated['organization_id'],
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Failed to generate QR code: ' . $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Get QR codes for admin management
     */
    public function getQrCodes(Request $request)
    {
        $query = QrCodeLocation::with('organization');

        if ($request->has('organization_id')) {
            $query->where('organization_id', $request->organization_id);
        }

        if ($request->has('is_active')) {
            $query->where('is_active', $request->is_active);
        }

        $qrCodes = $query->orderBy('organization_id')->orderBy('floor_number')->get();

        return response()->json($qrCodes);
    }
}
