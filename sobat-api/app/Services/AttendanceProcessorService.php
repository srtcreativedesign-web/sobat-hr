<?php

namespace App\Services;

use Carbon\Carbon;
use App\Models\Employee;

class AttendanceProcessorService
{
    /**
     * Process check-in time and determine lateness and status.
     *
     * @param Employee $employee
     * @param array $validatedData Reference to validated request data
     * @param string $trackType
     * @return void
     */
    public function processCheckIn(Employee $employee, array &$validatedData, string $trackType): void
    {
        // Skip if already pending from field attendance
        if (isset($validatedData['status']) && $validatedData['status'] === 'pending') {
            return;
        }

        $clockInTime = Carbon::parse($validatedData['date'] . ' ' . $validatedData['check_in']);

        // Operational track with shift schedule: use shift_start_time for late calc
        if ($trackType === 'operational' && !empty($validatedData['shift_start_time'])) {
            $workStartTime = Carbon::parse($validatedData['date'] . ' ' . $validatedData['shift_start_time']);
            $this->calculateLateness($clockInTime, $workStartTime, $validatedData);
        } else {
            // Check if user claimed shifting (head_office only)
            if (isset($validatedData['is_shifting']) && $validatedData['is_shifting'] == true) {
                $validatedData['status'] = 'present';
                $validatedData['late_duration'] = 0;
            } else {
                // Get employee shift
                $shift = $employee->shift;
                $defaultStartTime = '08:00:00';

                if ($shift) {
                    $startTimeStr = $shift->start_time instanceof Carbon
                        ? $shift->start_time->format('H:i:s')
                        : Carbon::parse($shift->start_time)->format('H:i:s');
                    $workStartTime = Carbon::parse($validatedData['date'] . ' ' . $startTimeStr);
                } else {
                    $workStartTime = Carbon::parse($validatedData['date'] . ' ' . $defaultStartTime);
                }

                $this->calculateLateness($clockInTime, $workStartTime, $validatedData);
            }
        }
    }

    /**
     * Helper to calculate lateness against a start time.
     */
    private function calculateLateness(Carbon $clockInTime, Carbon $workStartTime, array &$validatedData): void
    {
        $toleranceTime = $workStartTime->copy()->addSeconds(59);

        if ($clockInTime->gt($toleranceTime)) {
            $lateDuration = abs($clockInTime->diffInMinutes($workStartTime));
            $validatedData['late_duration'] = $lateDuration;

            if ($lateDuration > 5) {
                $validatedData['status'] = 'pending';
            } else {
                $validatedData['status'] = 'late';
            }
        } else {
            $validatedData['status'] = 'present';
        }
    }

    /**
     * Process check-out time and calculate work hours and overtime.
     *
     * @param Employee $employee
     * @param array $validatedData Reference to validated request data
     * @return void
     */
    public function processCheckOut(Employee $employee, array &$validatedData): void
    {
        if (!isset($validatedData['check_out'])) {
            return;
        }

        $dateStr = $validatedData['date'] ?? now()->toDateString();
        
        // Use provided check_in if available, otherwise assume it's calculated elsewhere
        if (isset($validatedData['check_in'])) {
            $checkIn = Carbon::parse($validatedData['check_in']);
            $checkOut = Carbon::parse($validatedData['check_out']);
            $validatedData['work_hours'] = $checkIn->floatDiffInHours($checkOut);
        }

        // Get employee shift for overtime
        $shift = $employee->shift;
        $defaultEndTime = '17:00:00';

        if ($shift) {
            $endTimeStr = $shift->end_time instanceof Carbon
                ? $shift->end_time->format('H:i:s')
                : Carbon::parse($shift->end_time)->format('H:i:s');
            $workEndTime = Carbon::parse($dateStr . ' ' . $endTimeStr);
        } else {
            $workEndTime = Carbon::parse($dateStr . ' ' . $defaultEndTime);
        }

        $clockOutTime = Carbon::parse($dateStr . ' ' . $validatedData['check_out']);

        if ($clockOutTime->gt($workEndTime)) {
            $validatedData['overtime_duration'] = $clockOutTime->diffInMinutes($workEndTime);
        }
    }
}
