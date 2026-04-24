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
        $user = $request->user();
        $isMobile = $request->header('X-Platform') === 'mobile' || 
                    !$request->hasHeader('Origin') || 
                    str_contains($request->userAgent(), 'Dart');
        $roleName = $user->role ? strtolower($user->role->name) : '';
        $isAdmin = in_array($roleName, [\App\Models\Role::ADMIN, \App\Models\Role::SUPER_ADMIN, \App\Models\Role::HR]);

        $now = Carbon::now();
        $currentMonth = $now->month;
        $currentYear = $now->year;

        // If on mobile, return personalized small-set of data
        if ($isMobile) {
            $employeeId = $user->employee ? $user->employee->id : null;
            
            $myRequests = [
                'pending' => RequestModel::where('employee_id', $employeeId)->where('status', 'pending')->count(),
                'approved' => RequestModel::where('employee_id', $employeeId)->where('status', 'approved')->count(),
                'rejected' => RequestModel::where('employee_id', $employeeId)->where('status', 'rejected')->count(),
            ];

            $myAttendance = Attendance::where('employee_id', $employeeId)
                ->whereMonth('date', $currentMonth)
                ->whereYear('date', $currentYear)
                ->select('status', DB::raw('count(*) as count'))
                ->groupBy('status')
                ->pluck('count', 'status')
                ->toArray();

            return response()->json([
                'is_mobile' => true,
                'requests' => $myRequests,
                'attendance_monthly' => $myAttendance,
                'employee' => $user->employee,
            ]);
        }

        // --- WEB ADMIN GLOBAL VIEW ---
        // Total employees by status
        $employeeStats = [
            'total' => Employee::count(),
            'active' => Employee::where('status', 'active')->count(),
            'inactive' => Employee::where('status', 'inactive')->count(),
            'resigned' => Employee::where('status', 'resigned')->count(),
        ];

        // Attendance stats for TODAY
        $attendanceStats = Attendance::where('date', $now->toDateString())
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
        $threeMonthsFromNow = $now->copy()->addMonths(3)->toDateString();
        $todayStr = $now->toDateString();
        
        $contractExpiringSoon = Employee::where('status', 'active')
            ->where('employment_status', 'contract')
            ->whereNotNull('contract_end_date')
            ->whereBetween('contract_end_date', [$todayStr, $threeMonthsFromNow])
            ->count();

        // Payroll Stats (Current Month)
        try {
            $periodString = sprintf('%04d-%02d', $currentYear, $currentMonth);
            $payrollTotal = \App\Models\Payroll::where('period', $periodString)
                ->sum('net_salary');
        } catch (\Exception $e) {
            \Illuminate\Support\Facades\Log::error('Dashboard Payroll Stat Error: ' . $e->getMessage());
            $payrollTotal = 0;
        }

        // Leaderboards (Top Late & Top On-Time)
        $startOfMonth = $now->copy()->startOfMonth()->toDateString();
        $endOfMonth = $now->copy()->endOfMonth()->toDateString();

        $topLate = \App\Models\Attendance::whereBetween('date', [$startOfMonth, $endOfMonth])
            ->where('status', 'late')
            ->select('employee_id', DB::raw('count(*) as total'))
            ->groupBy('employee_id')
            ->orderByDesc('total')
            ->limit(5)
            ->with(['employee' => function($q) { $q->select('id', 'user_id', 'employee_code')->with('user:id,name'); }])
            ->get();

        $topOnTime = \App\Models\Attendance::whereBetween('date', [$startOfMonth, $endOfMonth])
            ->where('status', 'present')
            ->select('employee_id', DB::raw('count(*) as total'))
            ->groupBy('employee_id')
            ->orderByDesc('total')
            ->limit(5)
            ->with(['employee' => function($q) { $q->select('id', 'user_id', 'employee_code')->with('user:id,name'); }])
            ->get();

        return response()->json([
            'employees' => $employeeStats,
            'attendance' => $attendanceStats,
            'requests' => $requestStats,
            'payroll' => [
                'total' => $payrollTotal,
                'period_month' => $currentMonth,
                'period_year' => $currentYear,
            ],
            'contract_expiring_soon' => $contractExpiringSoon,
            'period' => [
                'month' => $currentMonth,
                'year' => $currentYear,
            ],
            'leaderboards' => [
                'top_late' => $topLate,
                'top_on_time' => $topOnTime,
            ],
        ]);
    }

    /**
     * Get turnover rate
     */
    public function turnover(Request $request)
    {
        $year = $request->get('year', Carbon::now()->year);

        // OPTIMIZATION: Get all resigned counts in one query instead of a loop (Resolves N+1)
        $resignedData = Employee::where('status', 'resigned')
            ->whereYear('updated_at', $year)
            ->select(DB::raw('MONTH(updated_at) as month'), DB::raw('count(*) as total'))
            ->groupBy('month')
            ->pluck('total', 'month');

        // OPTIMIZATION: Get base active count before the year starts
        $baseActiveCount = Employee::where('status', 'active')
            ->where('join_date', '<', Carbon::create($year, 1, 1))
            ->count();

        // OPTIMIZATION: Get all join counts for the target year in one query
        $joinedData = Employee::where('status', 'active')
            ->whereYear('join_date', $year)
            ->select(DB::raw('MONTH(join_date) as month'), DB::raw('count(*) as total'))
            ->groupBy('month')
            ->pluck('total', 'month');

        $monthlyData = [];
        $runningActiveTotal = $baseActiveCount;
        
        for ($month = 1; $month <= 12; $month++) {
            // Count active for this month (previous month's total + this month's joins)
            $newJoins = $joinedData->get($month, 0);
            $runningActiveTotal += $newJoins;

            $resigned = $resignedData->get($month, 0);

            $turnoverRate = $runningActiveTotal > 0 ? ($resigned / $runningActiveTotal) * 100 : 0;

            $monthlyData[] = [
                'month' => $month,
                'month_name' => Carbon::create()->month($month)->format('F'),
                'active_employees' => $runningActiveTotal,
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
            ->whereIn('employment_status', ['contract', 'probation'])
            ->whereNotNull('contract_end_date')
            ->whereBetween('contract_end_date', [$now->toDateString(), $now->copy()->addDays($days)->toDateString()])
            ->with(['user', 'division'])
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
                        'name' => $employee->division->name ?? 'N/A',
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
    /**
     * Get attendance trend (Lateness % for last 6 months)
     */
    public function attendanceTrend(Request $request)
    {
        $months = 6;
        $data = [];
        
        $sixMonthsAgo = Carbon::now()->subMonths($months - 1)->startOfMonth();
        
        // Single optimized query for 6 months of data
        $trends = Attendance::where('date', '>=', $sixMonthsAgo->toDateString())
            ->select(
                DB::raw("DATE_FORMAT(date, '%b') as month_name"),
                DB::raw("YEAR(date) as year"),
                DB::raw("DATE_FORMAT(date, '%Y-%m') as period"),
                DB::raw('count(*) as total'),
                DB::raw("SUM(CASE WHEN status = 'late' THEN 1 ELSE 0 END) as late_count")
            )
            ->groupBy('period', 'month_name', 'year')
            ->orderBy('period', 'asc')
            ->get();

        foreach ($trends as $trend) {
            $lateRate = $trend->total > 0 ? ($trend->late_count / $trend->total) * 100 : 0;
            $data[] = [
                'month' => $trend->month_name,
                'year' => (int)$trend->year,
                'total' => (int)$trend->total,
                'late' => (int)$trend->late_count,
                'rate' => round($lateRate, 1)
            ];
        }

        return response()->json([
            'data' => $data
        ]);
    }
    /**
     * Get recent activity (Employees & Requests)
     */
    public function recentActivity(Request $request)
    {
        $user = $request->user();
        $isMobile = $request->header('X-Platform') === 'mobile' || 
                    !$request->hasHeader('Origin') || 
                    str_contains($request->userAgent(), 'Dart');

        // 1. Recent Employees (HIDE ON MOBILE for non-HR)
        $recentEmployees = collect();
        if (!$isMobile) {
            $recentEmployees = Employee::select('id', 'full_name', 'created_at')
                ->orderBy('created_at', 'desc')
                ->limit(5)
                ->get()
                ->map(function ($employee) {
                    return [
                        'id' => 'emp_' . $employee->id,
                        'type' => 'employee_onboarding',
                        'message' => "New employee {$employee->full_name} onboarded.",
                        'timestamp' => $employee->created_at,
                        'user' => $employee->full_name,
                        'status' => 'active'
                    ];
                });
        }

        // 2. Recent Requests
        $requestQuery = RequestModel::with('employee')
            ->select('id', 'employee_id', 'type', 'status', 'created_at', 'updated_at');

        // IF MOBILE: Filter to OWN requests ONLY
        if ($isMobile) {
            $requestQuery->where('employee_id', $user->employee?->id);
        }

        $recentRequests = $requestQuery->orderBy('updated_at', 'desc')
            ->limit(5)
            ->get()
            ->map(function ($req) {
                 $typeStr = ucfirst($req->type);
                 $statusStr = $req->status;
                 $userName = $req->employee->full_name ?? 'Unknown Employee';

                return [
                    'id' => 'req_' . $req->id,
                    'type' => 'submission',
                    'message' => "{$typeStr} request by {$userName} is {$statusStr}.",
                    'timestamp' => $req->updated_at,
                    'user' => $userName,
                    'status' => $req->status
                ];
            });

        // Merge and Sort
        $activities = $recentEmployees->concat($recentRequests)
            ->sortByDesc('timestamp')
            ->take(5)
            ->values();

        return response()->json([
            'data' => $activities
        ]);
    }
}
