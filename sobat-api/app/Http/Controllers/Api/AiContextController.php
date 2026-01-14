<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Employee;
use App\Models\Payroll;
use Illuminate\Http\Request;
use Carbon\Carbon;

use App\Models\Approval;
use App\Models\Attendance;
use App\Models\Organization;

class AiContextController extends Controller
{
    public function getContext()
    {
        // 1. Employee Data (Tenure & Basic Info)
        // Limit to 50 for performance context
        $employees = Employee::with('organization')->latest()->take(50)->get()->map(function ($emp) {
            $joinDate = $emp->join_date ? Carbon::parse($emp->join_date) : null;
            $tenure = $joinDate ? $joinDate->diffForHumans(null, true) : 'Unknown';

            return [
                'name' => $emp->name,
                'position' => $emp->job_position,
                'division' => $emp->organization ? $emp->organization->name : 'N/A',
                'join_date' => $joinDate ? $joinDate->format('Y-m-d') : null,
                'tenure' => $tenure,
                'status' => $emp->status,
            ];
        });

        // 2. Organization Stats
        $orgStats = [
            'total_organizations' => Organization::count(),
            'divisions' => Organization::where('type', 'division')->count(),
            'branches' => Organization::where('type', 'branch')->count(),
        ];

        // 3. Attendance Today
        $today = Carbon::today();
        $attendanceStats = [
            'date' => $today->toDateString(),
            'present_count' => Attendance::whereDate('created_at', $today)->count(),
            // Assuming we can check late/on-time if Logic exists, otherwise just count
        ];

        // 4. Pending Tasks (System Wide)
        $pendingApprovals = Approval::where('status', 'pending')->count();

        // 5. Payroll Data
        $recentPayrolls = Payroll::with('employee')
            ->orderBy('id', 'desc')
            ->take(20)
            ->get()
            ->map(function ($p) {
                return [
                    'period' => $p->period,
                    'employee' => $p->employee ? $p->employee->full_name : 'Unknown',
                    'net_salary' => $p->net_salary,
                    'status' => $p->status,
                ];
            });

        // 6. System Knowledge / Capabilities
        $capabilities = [
            "We can import staff via Excel (bulk invitation).",
            "We can manage Organization Hierarchy (Drag & Drop, Zoom/Pan).",
            "We have flexible Payroll generation with Tax calculation.",
        ];

        return response()->json([
            'meta' => [
                'generated_at' => Carbon::now()->toDateTimeString(),
            ],
            'system_stats' => [
                'organizations' => $orgStats,
                'attendance_today' => $attendanceStats,
                'pending_approvals_count' => $pendingApprovals,
                'total_employees' => Employee::count(),
            ],
            'recent_payrolls' => $recentPayrolls,
            'capabilities' => $capabilities,
            'employees_sample' => $employees, // Sending sample/recent employees
        ]);
    }
}
