<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Employee;
use App\Models\Attendance;
use App\Models\RequestModel;
use Carbon\Carbon;
use Illuminate\Support\Facades\DB;

class DashboardController extends Controller
{
    /**
     * Get dashboard analytics
     */
    public function analytics(Request $request)
    {
        $now = Carbon::now();
        $currentMonth = $now->month;
        $currentYear = $now->year;

        // Total employees by status
        $employeeStats = [
            'total' => Employee::count(),
            'active' => Employee::where('status', 'active')->count(),
            'inactive' => Employee::where('status', 'inactive')->count(),
            'resigned' => Employee::where('status', 'resigned')->count(),
        ];

        // Attendance stats for current month
        $attendanceStats = Attendance::whereMonth('date', $currentMonth)
            ->whereYear('date', $currentYear)
            ->select('status', DB::raw('count(*) as count'))
            ->groupBy('status')
            ->pluck('count', 'status')
            ->toArray();

        // Request stats
        $requestStats = [
            'pending' => RequestModel::where('status', 'pending')->count(),
            'approved' => RequestModel::where('status', 'approved')->count(),
            'rejected' => RequestModel::where('status', 'rejected')->count(),
        ];

        // Contract expiring soon (within 3 months)
        $contractExpiringSoon = Employee::where('status', 'active')
            ->where('contract_type', 'contract')
            ->whereNotNull('contract_end_date')
            ->whereDate('contract_end_date', '<=', $now->copy()->addMonths(3))
            ->whereDate('contract_end_date', '>=', $now)
            ->count();

        return response()->json([
            'employees' => $employeeStats,
            'attendance' => $attendanceStats,
            'requests' => $requestStats,
            'contract_expiring_soon' => $contractExpiringSoon,
            'period' => [
                'month' => $currentMonth,
                'year' => $currentYear,
            ],
        ]);
    }

    /**
     * Get turnover rate
     */
    public function turnover(Request $request)
    {
        $year = $request->get('year', Carbon::now()->year);

        $monthlyData = [];
        
        for ($month = 1; $month <= 12; $month++) {
            $startOfMonth = Carbon::create($year, $month, 1)->startOfMonth();
            $endOfMonth = Carbon::create($year, $month, 1)->endOfMonth();

            $activeStart = Employee::where('status', 'active')
                ->where('join_date', '<=', $endOfMonth)
                ->count();

            $resigned = Employee::where('status', 'resigned')
                ->whereMonth('updated_at', $month)
                ->whereYear('updated_at', $year)
                ->count();

            $turnoverRate = $activeStart > 0 ? ($resigned / $activeStart) * 100 : 0;

            $monthlyData[] = [
                'month' => $month,
                'month_name' => Carbon::create()->month($month)->format('F'),
                'active_employees' => $activeStart,
                'resigned' => $resigned,
                'turnover_rate' => round($turnoverRate, 2),
            ];
        }

        return response()->json([
            'year' => $year,
            'data' => $monthlyData,
        ]);
    }

    /**
     * Get attendance heatmap
     */
    public function attendanceHeatmap(Request $request)
    {
        $month = $request->get('month', Carbon::now()->month);
        $year = $request->get('year', Carbon::now()->year);

        $attendances = Attendance::whereMonth('date', $month)
            ->whereYear('date', $year)
            ->with('employee')
            ->get();

        $heatmapData = [];
        
        foreach ($attendances->groupBy('date') as $date => $records) {
            $heatmapData[] = [
                'date' => $date,
                'total' => $records->count(),
                'present' => $records->where('status', 'present')->count(),
                'late' => $records->where('status', 'late')->count(),
                'absent' => $records->where('status', 'absent')->count(),
                'leave' => $records->where('status', 'leave')->count(),
                'sick' => $records->where('status', 'sick')->count(),
            ];
        }

        return response()->json([
            'month' => $month,
            'year' => $year,
            'data' => $heatmapData,
        ]);
    }

    /**
     * Get employees with contracts expiring within 30 days
     */
    public function contractExpiring(Request $request)
    {
        $days = (int) $request->get('days', 30);
        $now = Carbon::now();

        $employees = Employee::where('status', 'active')
            ->where('employment_status', 'contract')
            ->whereNotNull('contract_end_date')
            ->whereDate('contract_end_date', '<=', $now->copy()->addDays($days))
            ->whereDate('contract_end_date', '>=', $now)
            ->with(['user', 'organization'])
            ->orderBy('contract_end_date', 'asc')
            ->get()
            ->map(function ($employee) use ($now) {
                $daysRemaining = Carbon::parse($employee->contract_end_date)->diffInDays($now);
                return [
                    'id' => $employee->id,
                    'employee_code' => $employee->employee_code,
                    'user' => [
                        'name' => $employee->full_name,
                        'email' => $employee->email,
                    ],
                    'position' => $employee->position,
                    'organization' => [
                        'name' => $employee->organization->name ?? 'N/A',
                    ],
                    'contract_end_date' => $employee->contract_end_date,
                    'days_remaining' => $daysRemaining,
                ];
            });

        return response()->json([
            'total' => $employees->count(),
            'data' => [
                'employees' => $employees,
            ],
        ]);
    }
}
