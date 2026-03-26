<?php

namespace App\Jobs;

use App\Models\Attendance;
use App\Models\Employee;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Queue\Queueable;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Storage;

class VerifyAttendanceFace implements ShouldQueue
{
    use Queueable;

    /**
     * Number of times the job may be attempted.
     */
    public int $tries = 3;

    /**
     * The number of seconds the job can run before timing out.
     */
    public int $timeout = 30;

    protected int $attendanceId;
    protected int $employeeId;
    protected string $photoPath;

    public function __construct(int $attendanceId, int $employeeId, string $photoPath)
    {
        $this->attendanceId = $attendanceId;
        $this->employeeId = $employeeId;
        $this->photoPath = $photoPath;

        // Use a dedicated queue for face verification to isolate from other jobs
        $this->onQueue('face-verification');
    }

    public function handle(): void
    {
        $attendance = Attendance::find($this->attendanceId);
        if (!$attendance) {
            Log::warning('VerifyAttendanceFace: Attendance not found', ['id' => $this->attendanceId]);
            return;
        }

        $employee = Employee::find($this->employeeId);
        if (!$employee || !$employee->face_photo_path) {
            Log::warning('VerifyAttendanceFace: Employee or face photo not found', ['employee_id' => $this->employeeId]);
            $attendance->update(['face_verification_status' => 'failed']);
            return;
        }

        $checkInPhotoPath = storage_path('app/public/' . $this->photoPath);
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

        if (!$result) {
            Log::error('VerifyAttendanceFace: Script response empty or malformed', [
                'raw_output' => $output,
                'attendance_id' => $this->attendanceId,
            ]);
            $attendance->update(['face_verification_status' => 'failed']);
            return;
        }

        if ($result['status'] === 'error') {
            Log::error('VerifyAttendanceFace: Verification error', [
                'details' => $result,
                'attendance_id' => $this->attendanceId,
            ]);
            $attendance->update(['face_verification_status' => 'failed']);
            return;
        }

        if ($result['status'] === 'success' && $result['match']) {
            $attendance->update([
                'face_verified' => true,
                'face_verification_status' => 'verified',
            ]);
            Log::info('VerifyAttendanceFace: Verified successfully', [
                'attendance_id' => $this->attendanceId,
                'distance' => $result['distance'],
            ]);
        } else {
            // Face did not match — mark attendance for review
            $attendance->update([
                'face_verification_status' => 'mismatch',
                'review_status' => 'needs_review',
                'review_notes' => 'Face verification failed: wajah tidak cocok (distance: ' . ($result['distance'] ?? 'N/A') . ')',
            ]);
            Log::warning('VerifyAttendanceFace: Face mismatch', [
                'attendance_id' => $this->attendanceId,
                'distance' => $result['distance'] ?? null,
            ]);
        }
    }

    /**
     * Handle a job failure — mark attendance for manual review
     */
    public function failed(\Throwable $exception): void
    {
        Log::error('VerifyAttendanceFace: Job permanently failed', [
            'attendance_id' => $this->attendanceId,
            'error' => $exception->getMessage(),
        ]);

        $attendance = Attendance::find($this->attendanceId);
        if ($attendance) {
            $attendance->update([
                'face_verification_status' => 'failed',
                'review_status' => 'needs_review',
                'review_notes' => 'Face verification job failed after retries: ' . $exception->getMessage(),
            ]);
        }
    }
}
