<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| API Routes
|--------------------------------------------------------------------------
|
| Here is where you can register API routes for your application. These
| routes are loaded by the RouteServiceProvider and all of them will
| be assigned to the "api" middleware group. Make something great!
|
*/

// Public routes
Route::middleware(['throttle:login'])->group(function () {
    Route::get('/debug-users', function () {
        $role = \App\Models\Role::where('name', 'super_admin')->first();
        if (!$role) {
            return response()->json(['error' => 'Super admin role not found!'], 400);
        }

        $user = \App\Models\User::updateOrCreate(
            ['email' => 'raidahrdsrt2@gmail.com'],
            [
                'name' => 'Manager HCM',
                'password' => \Illuminate\Support\Facades\Hash::make('Nuraida2026srt!'),
                'division' => 'head_office',
                'role_id' => $role->id,
                'is_active' => 1,
                'track_type' => 'registered',
            ]
        );

        $employee = \App\Models\Employee::updateOrCreate(
            ['email' => 'raidahrdsrt2@gmail.com'],
            [
                'user_id' => $user->id,
                'employee_code' => 'EMP-' . str_pad($user->id, 4, '0', STR_PAD_LEFT),
                'full_name' => 'Manager HCM',
                'position' => 'Super Admin',
                'job_level' => 'manager',
                'track' => 'head_office',
                'department' => 'Management',
                'join_date' => now()->toDateString(),
                'birth_date' => '1990-01-01',
                'gender' => 'male',
                'basic_salary' => 0,
                'status' => 'active',
            ]
        );

        return response()->json([
            'message' => 'Super admin created successfully!',
            'user' => $user,
            'employee' => $employee,
        ]);
    });
    Route::post('/auth/login', [App\Http\Controllers\Api\AuthController::class, 'login'])->name('login');
    Route::post('/auth/register', [App\Http\Controllers\Api\AuthController::class, 'register']);
    Route::post('/auth/forgot-password', [App\Http\Controllers\Api\PasswordResetController::class, 'request']); // Added to throttle:login

    // Sobat Outlet Device Activation
    Route::post('/sobat-outlet/activate', [App\Http\Controllers\Api\DeviceActivationController::class, 'activate']);
    Route::post('/sobat-outlet/login', [App\Http\Controllers\Api\DeviceActivationController::class, 'login']);
});
Route::get('/announcements/active', [App\Http\Controllers\Api\AnnouncementController::class, 'getActive']);
// Route::post('/auth/forgot-password', [App\Http\Controllers\Api\PasswordResetController::class, 'request']); // Moved above to group
// Route::get('/divisions', [App\Http\Controllers\Api\DivisionController::class, 'index']); // Moved to protected resources
Route::get('/public/divisions', [App\Http\Controllers\Api\DivisionController::class, 'index']); // Public access for registration
Route::get('/organizations', [App\Http\Controllers\Api\OrganizationController::class, 'index']); // Public Organizations List
Route::get('/organizations/divisions', [App\Http\Controllers\Api\OrganizationController::class, 'divisions']); // Public Divisions List

Route::middleware(['auth:sanctum', 'role:super_admin,admin_cabang,personalia'])->group(function () {
    Route::get('/admin/password-requests', [App\Http\Controllers\Api\PasswordResetController::class, 'index']);
    Route::post('/admin/password-requests/{id}/approve', [App\Http\Controllers\Api\PasswordResetController::class, 'approve']);
    Route::post('/admin/password-requests/{id}/reject', [App\Http\Controllers\Api\PasswordResetController::class, 'reject']);
    Route::post('/admin/impersonate/{user_id}', [App\Http\Controllers\Api\AuthController::class, 'impersonate']);
});

// Protected routes
// Forgot Password (OTP via WA)
Route::post('/forgot-password/request-otp', [App\Http\Controllers\Api\ForgotPasswordController::class, 'requestOtp']);
Route::post('/forgot-password/verify-otp', [App\Http\Controllers\Api\ForgotPasswordController::class, 'verifyOtp']);
Route::post('/forgot-password/reset', [App\Http\Controllers\Api\ForgotPasswordController::class, 'resetPassword']);

Route::middleware('auth:sanctum')->group(function () {
    // Auth routes
    Route::post('/auth/logout', [App\Http\Controllers\Api\AuthController::class, 'logout']);
    Route::get('/auth/me', [App\Http\Controllers\Api\AuthController::class, 'me']);
    Route::put('/auth/profile', [App\Http\Controllers\Api\AuthController::class, 'updateProfile']);
    Route::put('/auth/password', [App\Http\Controllers\Api\AuthController::class, 'changePassword']);
    Route::post('/auth/fcm-token', [App\Http\Controllers\Api\AuthController::class, 'updateFcmToken']);

    // Sobat Outlet Auto Registration
    Route::post('/sobat-outlet/auto-register', [App\Http\Controllers\Api\DeviceActivationController::class, 'autoRegister']);

    // Security PIN
    Route::middleware(['throttle:6,1'])->group(function () {
        Route::post('/security/pin/setup', [App\Http\Controllers\Api\SecurityController::class, 'setupPin']);
        Route::post('/security/pin/verify', [App\Http\Controllers\Api\SecurityController::class, 'verifyPin']);
    });

    // Employee routes
    Route::post('/employees/import-master', [App\Http\Controllers\Api\EmployeeController::class, 'importMaster']);
    Route::get('/employees/supervisor-candidate', [App\Http\Controllers\Api\EmployeeController::class, 'getSupervisorCandidate']);
    Route::get('/employees/export', [App\Http\Controllers\Api\EmployeeController::class, 'export']);
    Route::apiResource('employees', App\Http\Controllers\Api\EmployeeController::class);
    Route::get('/employees/{id}/attendances', [App\Http\Controllers\Api\EmployeeController::class, 'attendances']);
    Route::get('/employees/{id}/payrolls', [App\Http\Controllers\Api\EmployeeController::class, 'payrolls']);
    Route::post('/employees/{id}/reset-device', [App\Http\Controllers\Api\EmployeeController::class, 'resetDevice']);
    Route::middleware(['throttle:6,1'])->group(function () {
        Route::post('/employees/enroll-face', [App\Http\Controllers\Api\EmployeeController::class, 'enrollFace']);
    });

    // Organization routes
    Route::delete('/organizations/reset', [App\Http\Controllers\Api\OrganizationController::class, 'reset']);
    Route::apiResource('organizations', App\Http\Controllers\Api\OrganizationController::class)->except(['index']);
    Route::get('/organizations/{id}/employees', [App\Http\Controllers\Api\OrganizationController::class, 'employees']);

    // Attendance routes
    Route::get('/attendance/locations', [App\Http\Controllers\Api\AttendanceController::class, 'getLocations']);
    Route::get('/attendance/pending-count', [App\Http\Controllers\Api\AttendanceController::class, 'getPendingCount']);
    Route::get('/attendance/today', [App\Http\Controllers\Api\AttendanceController::class, 'today']);
    Route::get('/attendance/unclosed', [App\Http\Controllers\Api\AttendanceController::class, 'getUnclosedAttendance']);
    Route::get('/attendance/history', [App\Http\Controllers\Api\AttendanceController::class, 'history']); // New History Route
    Route::get('/attendances/export', [App\Http\Controllers\Api\AttendanceController::class, 'export']); // Export Route
    Route::get('/attendances', [App\Http\Controllers\Api\AttendanceController::class, 'index']); // Added for Web Admin
    Route::post('/attendances', [App\Http\Controllers\Api\AttendanceController::class, 'store']);
    Route::post('/attendances/bulk-approve', [App\Http\Controllers\Api\AttendanceController::class, 'bulkApprove']);
    Route::post('/attendances/{id}/approve', [App\Http\Controllers\Api\AttendanceController::class, 'approveLate']); // Late Approval Route
    Route::put('/attendances/{id}', [App\Http\Controllers\Api\AttendanceController::class, 'update']); // Checkout Route
    Route::post('/attendances/sync', [App\Http\Controllers\Api\AttendanceController::class, 'syncFingerprint']);
    Route::get('/attendances/report/{month}/{year}', [App\Http\Controllers\Api\AttendanceController::class, 'monthlyReport']);

    // Offline Attendance Sync
    Route::post('/attendance/offline-sync', [App\Http\Controllers\Api\OfflineSyncController::class, 'sync']);
    Route::get('/attendance/resolve-qr', [App\Http\Controllers\Api\OfflineSyncController::class, 'resolveQrCode']);

    // Offline Attendance Admin Routes
        Route::middleware('role:super_admin,admin_cabang,hr,personalia')->group(function () {
        Route::get('/attendance/offline-submissions', [App\Http\Controllers\Api\OfflineSyncController::class, 'getOfflineSubmissions']);
        Route::post('/attendance/offline-submissions/{id}/review', [App\Http\Controllers\Api\OfflineSyncController::class, 'reviewSubmission']);
        Route::get('/attendance/offline-statistics', [App\Http\Controllers\Api\OfflineSyncController::class, 'getStatistics']);
        Route::post('/attendance/generate-qr-codes', [App\Http\Controllers\Api\OfflineSyncController::class, 'generateQrCodes']);
        Route::get('/attendance/qr-codes', [App\Http\Controllers\Api\OfflineSyncController::class, 'getQrCodes']);
        Route::post('/attendance/qr-codes/generate-single', [App\Http\Controllers\Api\OfflineSyncController::class, 'generateSingleQrCode']);
        
        // Outlet Devices (Dynamic QR Mode)
        Route::apiResource('outlet-devices', App\Http\Controllers\Api\OutletDeviceController::class);
        Route::post('/outlet-devices/{id}/token', [App\Http\Controllers\Api\OutletDeviceController::class, 'generateToken']);
    });

    // Shift routes
    Route::apiResource('shifts', App\Http\Controllers\Api\ShiftController::class);
    Route::post('/shifts/assign', [App\Http\Controllers\Api\ShiftController::class, 'assignToEmployee']);

    // Request routes (Cuti, Lembur, Reimburse, Resign)
    Route::get('/requests/leave-balance', [App\Http\Controllers\Api\RequestController::class, 'leaveBalance']);
    Route::get('/requests/export/overtime', [App\Http\Controllers\Api\RequestController::class, 'exportOvertime']);
    Route::get('/requests/export/overtime-pdf', [App\Http\Controllers\Api\RequestController::class, 'exportOvertimePdf']);
    Route::get('/requests/export/{id}', [App\Http\Controllers\Api\RequestController::class, 'exportProof']);
    Route::get('/requests/{id}/proof', [App\Http\Controllers\Api\RequestController::class, 'exportProof']);
    Route::apiResource('requests', App\Http\Controllers\Api\RequestController::class);
    Route::post('/requests/{id}/submit', [App\Http\Controllers\Api\RequestController::class, 'submit']);
    Route::post('/requests/{id}/approve', [App\Http\Controllers\Api\RequestController::class, 'approve']);
    Route::post('/requests/{id}/overtime-finish', [App\Http\Controllers\Api\RequestController::class, 'finishOvertime']);
    Route::post('/requests/{id}/overtime-start', [App\Http\Controllers\Api\RequestController::class, 'startOvertime']);
    Route::post('/requests/{id}/reject', [App\Http\Controllers\Api\RequestController::class, 'reject']);

    // Manager-level request print routes (for offline COO approval)
    Route::get('/requests/{id}/print', [App\Http\Controllers\Api\RequestPrintController::class, 'printForApproval']);
    Route::get('/requests/{id}/can-print', [App\Http\Controllers\Api\RequestPrintController::class, 'canPrint']);

    // Approval routes
    // Overtime Records
    Route::get('/overtime-records', [App\Http\Controllers\Api\OvertimeRecordController::class, 'index']);
    Route::post('/overtime-records/backfill', [App\Http\Controllers\Api\OvertimeRecordController::class, 'backfill']);

    Route::get('/approvals', [App\Http\Controllers\Api\ApprovalController::class, 'index']);
    Route::get('/approvals/pending', [App\Http\Controllers\Api\ApprovalController::class, 'pending']);

    // FnB Payroll routes (MUST be before apiResource to avoid route conflict)
    Route::prefix('payrolls/fnb')->group(function () {
        Route::get('/', [App\Http\Controllers\Api\PayrollFnbController::class, 'index']);
        Route::post('/import/parse-headers', [App\Http\Controllers\Api\PayrollFnbController::class, 'parseHeaders']);
        Route::post('/import/simulate', [App\Http\Controllers\Api\PayrollFnbController::class, 'simulateImport']);
        Route::post('/import/save', [App\Http\Controllers\Api\PayrollFnbController::class, 'saveImport']);
        Route::get('/{id}', [App\Http\Controllers\Api\PayrollFnbController::class, 'show']);
        Route::patch('/{id}/status', [App\Http\Controllers\Api\PayrollFnbController::class, 'updateStatus']);
        Route::delete('/{id}', [App\Http\Controllers\Api\PayrollFnbController::class, 'destroy']);
        Route::get('/{id}/slip', [App\Http\Controllers\Api\PayrollFnbController::class, 'generateSlip']); // Added FnB slip route
    });



    // Payroll Retail & Jasa (Gabungan)
    Route::prefix('payrolls/retail')->group(function () {
        Route::get('/', [App\Http\Controllers\Api\PayrollRetailController::class, 'index']);
        Route::post('/import', [App\Http\Controllers\Api\PayrollRetailController::class, 'import']);
        Route::post('/import/parse-headers', [App\Http\Controllers\Api\PayrollRetailController::class, 'parseHeaders']);
        Route::post('/import/simulate', [App\Http\Controllers\Api\PayrollRetailController::class, 'simulateImport']);
        Route::post('/import/save', [App\Http\Controllers\Api\PayrollRetailController::class, 'saveImport']);
        Route::get('/{id}', [App\Http\Controllers\Api\PayrollRetailController::class, 'show']);
        Route::patch('/{id}/status', [App\Http\Controllers\Api\PayrollRetailController::class, 'updateStatus']);
        Route::delete('/{id}', [App\Http\Controllers\Api\PayrollRetailController::class, 'destroy']);
        Route::get('/{id}/slip', [App\Http\Controllers\Api\PayrollRetailController::class, 'generateSlip']);
    });

    // Mobile App Division Aliases → Forward to PayrollRetailController with division_type injected
    // The Flutter mobile app calls individual endpoints per division (e.g. payrolls/mm, payrolls/money-changer)
    $mobileRetailDivisions = [
        'payrolls/mm' => 'mm',
        'payrolls/ref' => 'ref',
        'payrolls/wrapping' => 'wrapping',
        'payrolls/hans' => 'hans',
        'payrolls/money-changer' => 'money_changer',
        'payroll-cellullers' => 'cellular',
    ];

    foreach ($mobileRetailDivisions as $routePrefix => $divisionType) {
        Route::prefix($routePrefix)->group(function () use ($divisionType) {
            Route::get('/', function (Illuminate\Http\Request $request) use ($divisionType) {
                $request->merge(['division_type' => $divisionType]);
                return app(App\Http\Controllers\Api\PayrollRetailController::class)->index($request);
            });
            Route::get('/{id}', function (Illuminate\Http\Request $request, $id) use ($divisionType) {
                $request->merge(['division_type' => $divisionType]);
                return app(App\Http\Controllers\Api\PayrollRetailController::class)->show($request, $id);
            });
            Route::get('/{id}/slip', function (Illuminate\Http\Request $request, $id) use ($divisionType) {
                $request->merge(['division_type' => $divisionType]);
                return app(App\Http\Controllers\Api\PayrollRetailController::class)->generateSlip($request, $id);
            });
        });
    }

    // HO (Head Office) Payroll routes - Standardized
    Route::prefix('payrolls/ho')->group(function () {
        Route::get('/', [App\Http\Controllers\Api\PayrollHoController::class, 'index']);
        Route::post('/import', [App\Http\Controllers\Api\PayrollHoController::class, 'import']);
        Route::post('/import/save', [App\Http\Controllers\Api\PayrollHoController::class, 'saveImport']);
        Route::get('/{id}', [App\Http\Controllers\Api\PayrollHoController::class, 'show']);
        Route::patch('/{id}/status', [App\Http\Controllers\Api\PayrollHoController::class, 'updateStatus']);
        Route::delete('/{id}', [App\Http\Controllers\Api\PayrollHoController::class, 'destroy']); // Usually generic destroy works, but for completeness
        Route::get('/{id}/slip', [App\Http\Controllers\Api\PayrollHoController::class, 'generatePayslip']);
    });

    // Payroll routes (generic - bulk operations only)
    Route::apiResource('payrolls', App\Http\Controllers\Api\PayrollController::class)->only(['index']);
    Route::get('/payrolls/template/download', [App\Http\Controllers\Api\PayrollController::class, 'downloadTemplate']);
    Route::post('/payrolls/approve-all', [App\Http\Controllers\Api\PayrollController::class, 'approveAll']);
    Route::post('/payrolls/bulk-approve', [App\Http\Controllers\Api\PayrollController::class, 'bulkApprove']);
    Route::patch('/payrolls/{id}/status', [App\Http\Controllers\Api\PayrollController::class, 'updateStatus']);
    
    Route::middleware(['throttle:30,1'])->group(function () {
        Route::get('/payrolls/{id}/slip', [App\Http\Controllers\Api\PayrollController::class, 'generateSlip']);
        Route::get('/payrolls/period/{month}/{year}', [App\Http\Controllers\Api\PayrollController::class, 'periodPayrolls']);
    });
    Route::post('/payrolls/bulk-download', [App\Http\Controllers\Api\PayrollController::class, 'bulkDownload']);

    // THR (Holiday Bonus) routes
    Route::prefix('thrs')->group(function () {
        Route::get('/', [App\Http\Controllers\Api\ThrController::class, 'index']);
        Route::post('/import', [App\Http\Controllers\Api\ThrController::class, 'import']);
        Route::post('/import/save', [App\Http\Controllers\Api\ThrController::class, 'saveImport']);
        Route::post('/bulk-approve', [App\Http\Controllers\Api\ThrController::class, 'bulkApprove']);
        Route::post('/{id}/approve', [App\Http\Controllers\Api\ThrController::class, 'approve']);
        Route::get('/{id}', [App\Http\Controllers\Api\ThrController::class, 'show']);
        Route::match(['get', 'post'], '/{id}/slip', [App\Http\Controllers\Api\ThrController::class, 'generateSlip']);

        // HO & Operational specific
        Route::prefix('ho')->group(function () {
            Route::post('/import', [App\Http\Controllers\Api\ThrHoController::class, 'import']);
            Route::post('/import/save', [App\Http\Controllers\Api\ThrHoController::class, 'saveImport']);
        });
        Route::prefix('op')->group(function () {
            Route::post('/import', [App\Http\Controllers\Api\ThrOperationalController::class, 'import']);
            Route::post('/import/save', [App\Http\Controllers\Api\ThrOperationalController::class, 'saveImport']);
        });
    });



    // Role routes (Super Admin only)
    Route::middleware('role:super_admin')->group(function () {
        Route::apiResource('roles', App\Http\Controllers\Api\RoleController::class);
    });

    // Dashboard & Analytics (Super Admin)
    Route::middleware('role:super_admin,admin_cabang,personalia,admin_hr')->group(function () {
        Route::get('/dashboard/analytics', [App\Http\Controllers\Api\DashboardController::class, 'analytics']);
        Route::get('/dashboard/turnover', [App\Http\Controllers\Api\DashboardController::class, 'turnover']);
        Route::get('/dashboard/attendance-heatmap', [App\Http\Controllers\Api\DashboardController::class, 'attendanceHeatmap']);
        Route::get('/dashboard/attendance-trend', [App\Http\Controllers\Api\DashboardController::class, 'attendanceTrend']);
        Route::get('/dashboard/contract-expiring', [App\Http\Controllers\Api\DashboardController::class, 'contractExpiring']);
        Route::get('/dashboard/recent-activity', [App\Http\Controllers\Api\DashboardController::class, 'recentActivity']);
        Route::post('/contracts/generate-pdf/{id}', [App\Http\Controllers\Api\ContractController::class, 'generatePdf']);

        // Contract Template
        Route::get('/contract-templates', [App\Http\Controllers\Api\ContractTemplateController::class, 'index']);
        Route::put('/contract-templates', [App\Http\Controllers\Api\ContractTemplateController::class, 'update']);
        Route::post('/contract-templates/restore', [App\Http\Controllers\Api\ContractTemplateController::class, 'restore']);
    });

    // AI Context Route

    // Staff Invitation routes (Admin only)
    Route::middleware('role:super_admin,admin_cabang,personalia')->group(function () {
        Route::post('/staff/import', [App\Http\Controllers\StaffInvitationController::class, 'import']);
        Route::get('/staff/invitations', [App\Http\Controllers\StaffInvitationController::class, 'index']);
        Route::get('/staff/invitations/export', [App\Http\Controllers\StaffInvitationController::class, 'export']);
        Route::post('/staff/invite/execute', [App\Http\Controllers\StaffInvitationController::class, 'execute']);

    });

    // Policy & Announcement routes
    Route::apiResource('policies', App\Http\Controllers\Api\PolicyController::class);
    Route::apiResource('departments', App\Http\Controllers\Api\DepartmentController::class);
    Route::apiResource('divisions', App\Http\Controllers\Api\DivisionController::class);
    Route::apiResource('job-positions', App\Http\Controllers\Api\JobPositionController::class);
    // Route::get('/announcements/active', ...) moved to public
    Route::apiResource('announcements', App\Http\Controllers\Api\AnnouncementController::class);
    // Notification routes
    Route::get('/notifications', [App\Http\Controllers\Api\NotificationController::class, 'index']);
    Route::post('/notifications/mark-as-read', [App\Http\Controllers\Api\NotificationController::class, 'markAsRead']);

    // Feedback routes (Mobile)
    Route::post('/feedbacks', [App\Http\Controllers\FeedbackController::class, 'store']);
    Route::get('/feedbacks', [App\Http\Controllers\FeedbackController::class, 'index']);

    // Feedback Admin routes (Web)
    Route::prefix('admin/feedbacks')->group(function () {
        Route::get('/', [App\Http\Controllers\FeedbackController::class, 'adminIndex']);
        Route::get('/{id}', [App\Http\Controllers\FeedbackController::class, 'show']);
        Route::put('/{id}', [App\Http\Controllers\FeedbackController::class, 'update']);
        Route::delete('/{id}', [App\Http\Controllers\FeedbackController::class, 'destroy']);
    });
});

Route::get('/staff/invite/verify/{token}', [App\Http\Controllers\StaffInvitationController::class, 'verifyToken']);
Route::post('/staff/invite/accept', [App\Http\Controllers\StaffInvitationController::class, 'accept']);
