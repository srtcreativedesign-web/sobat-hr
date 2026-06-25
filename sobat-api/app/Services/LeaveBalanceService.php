<?php

namespace App\Services;

use App\Models\Employee;
use App\Models\Request as RequestModel;
use Carbon\Carbon;

class LeaveBalanceService
{
    /**
     * Calculate leave balance for an employee.
     *
     * @param Employee $employee
     * @return array
     */
    public function calculateForEmployee(Employee $employee): array
    {
        if (! $employee->join_date) {
            return [
                'eligible' => false,
                'message' => 'Tanggal bergabung belum diatur',
                'quota' => 0,
                'used' => 0,
                'balance' => 0,
                'years_of_service' => 0,
            ];
        }

        $yearsOfService = $employee->join_date->diffInYears(now());

        if ($yearsOfService < 1) {
            return [
                'eligible' => false,
                'message' => 'Masa kerja belum mencapai 1 tahun',
                'quota' => 0,
                'used' => 0,
                'balance' => 0,
                'years_of_service' => $yearsOfService,
            ];
        }

        $quota = 12; // Base quota for 1+ years of service

        // Calculate used leave for the current year
        $used = RequestModel::where('employee_id', $employee->id)
            ->where('type', 'leave')
            ->where('status', 'approved')
            ->whereYear('start_date', now()->year)
            ->get()
            ->sum(function ($req) {
                if ($req->amount > 0) {
                    return $req->amount;
                }
                
                if ($req->start_date && $req->end_date) {
                    $start = Carbon::parse($req->start_date);
                    $end = Carbon::parse($req->end_date);
                    return $start->diffInDays($end) + 1;
                }

                return 0;
            });

        return [
            'eligible' => true,
            'message' => 'Eligible',
            'quota' => $quota,
            'used' => $used,
            'balance' => max(0, $quota - $used), // Prevent negative balance
            'years_of_service' => $yearsOfService,
        ];
    }
}
