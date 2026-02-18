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
    Route::post('/auth/login', [App\Http\Controllers\Api\AuthController::class, 'login'])->name('login');
    Route::post('/auth/register', [App\Http\Controllers\Api\AuthController::class, 'register']);
});
Route::get('/announcements/active', [App\Http\Controllers\Api\AnnouncementController::class, 'getActive']);
Route::post('/auth/forgot-password', [App\Http\Controllers\Api\PasswordResetController::class, 'request']); // Public Forgot Password
// Route::get('/divisions', [App\Http\Controllers\Api\DivisionController::class, 'index']); // Moved to protected resources
Route::get('/organizations', [App\Http\Controllers\Api\OrganizationController::class, 'index']); // Public Organizations List
Route::get('/organizations/divisions', [App\Http\Controllers\Api\OrganizationController::class, 'divisions']); // Public Divisions List

Route::middleware(['auth:sanctum', 'role:super_admin,admin_cabang'])->group(function () {
    Route::get('/admin/password-requests', [App\Http\Controllers\Api\PasswordResetController::class, 'index']);
    Route::post('/admin/password-requests/{id}/approve', [App\Http\Controllers\Api\PasswordResetController::class, 'approve']);
    Route::post('/admin/password-requests/{id}/reject', [App\Http\Controllers\Api\PasswordResetController::class, 'reject']);
});

// Protected routes
Route::middleware('auth:sanctum')->group(function () {
    // Auth routes
    Route::post('/auth/logout', [App\Http\Controllers\Api\AuthController::class, 'logout']);
    Route::get('/auth/me', [App\Http\Controllers\Api\AuthController::class, 'me']);
    Route::put('/auth/profile', [App\Http\Controllers\Api\AuthController::class, 'updateProfile']);
    Route::put('/auth/password', [App\Http\Controllers\Api\AuthController::class, 'changePassword']);

    // Security PIN
    Route::middleware(['throttle:pin'])->group(function () {
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
    Route::post('/employees/enroll-face', [App\Http\Controllers\Api\EmployeeController::class, 'enrollFace']);

    // Organization routes
    Route::delete('/organizations/reset', [App\Http\Controllers\Api\OrganizationController::class, 'reset']);
    Route::apiResource('organizations', App\Http\Controllers\Api\OrganizationController::class)->except(['index']);
    Route::get('/organizations/{id}/employees', [App\Http\Controllers\Api\OrganizationController::class, 'employees']);

    // Attendance routes
    Route::get('/attendance/pending-count', [App\Http\Controllers\Api\AttendanceController::class, 'getPendingCount']);
    Route::get('/attendance/today', [App\Http\Controllers\Api\AttendanceController::class, 'today']);
    Route::get('/attendance/history', [App\Http\Controllers\Api\AttendanceController::class, 'history']); // New History Route
    Route::get('/attendances/export', [App\Http\Controllers\Api\AttendanceController::class, 'export']); // Export Route
    Route::get('/attendances', [App\Http\Controllers\Api\AttendanceController::class, 'index']); // Added for Web Admin
    Route::post('/attendances', [App\Http\Controllers\Api\AttendanceController::class, 'store']);
    Route::post('/attendances/{id}/approve', [App\Http\Controllers\Api\AttendanceController::class, 'approveLate']); // Late Approval Route
    Route::put('/attendances/{id}', [App\Http\Controllers\Api\AttendanceController::class, 'update']); // Checkout Route
    Route::post('/attendances/sync', [App\Http\Controllers\Api\AttendanceController::class, 'syncFingerprint']);
    Route::get('/attendances/report/{month}/{year}', [App\Http\Controllers\Api\AttendanceController::class, 'monthlyReport']);

    // Shift routes
    Route::apiResource('shifts', App\Http\Controllers\Api\ShiftController::class);
    Route::post('/shifts/assign', [App\Http\Controllers\Api\ShiftController::class, 'assignToEmployee']);

    // Request routes (Cuti, Lembur, Reimburse, Resign)
    Route::get('/requests/leave-balance', [App\Http\Controllers\Api\RequestController::class, 'leaveBalance']);
    Route::get('/requests/{id}/proof', [App\Http\Controllers\Api\RequestController::class, 'exportProof']);
    Route::apiResource('requests', App\Http\Controllers\Api\RequestController::class);
    Route::post('/requests/{id}/submit', [App\Http\Controllers\Api\RequestController::class, 'submit']);
    Route::post('/requests/{id}/approve', [App\Http\Controllers\Api\RequestController::class, 'approve']);
    Route::post('/requests/{id}/reject', [App\Http\Controllers\Api\RequestController::class, 'reject']);
    
    // Manager-level request print routes (for offline COO approval)
    Route::get('/requests/{id}/print', [App\Http\Controllers\Api\RequestPrintController::class, 'printForApproval']);
    Route::get('/requests/{id}/can-print', [App\Http\Controllers\Api\RequestPrintController::class, 'canPrint']);

    // Approval routes
    // Overtime Records
    Route::get('/overtime-records', [App\Http\Controllers\Api\OvertimeRecordController::class, 'index']);
    Route::post('/overtime-records/backfill', [App\Http\Controllers\Api\OvertimeRecordController::class, 'backfill']);

    Route::get('/requests/export/overtime', [App\Http\Controllers\Api\RequestController::class, 'exportOvertime']);
    Route::get('/approvals', [App\Http\Controllers\Api\ApprovalController::class, 'index']);
    Route::get('/approvals/pending', [App\Http\Controllers\Api\ApprovalController::class, 'pending']);

    // FnB Payroll routes (MUST be before apiResource to avoid route conflict)
    Route::prefix('payrolls/fnb')->group(function () {
        Route::get('/', [App\Http\Controllers\Api\PayrollFnbController::class, 'index']);
        Route::post('/import', [App\Http\Controllers\Api\PayrollFnbController::class, 'import']);
        Route::post('/import/save', [App\Http\Controllers\Api\PayrollFnbController::class, 'saveImport']);
        Route::get('/{id}', [App\Http\Controllers\Api\PayrollFnbController::class, 'show']);
        Route::patch('/{id}/status', [App\Http\Controllers\Api\PayrollFnbController::class, 'updateStatus']);
        Route::delete('/{id}', [App\Http\Controllers\Api\PayrollFnbController::class, 'destroy']);
        Route::get('/{id}/slip', [App\Http\Controllers\Api\PayrollFnbController::class, 'generateSlip']); // Added FnB slip route
    });

    // Minimarket Payroll routes
    Route::prefix('payrolls/mm')->group(function () {
        Route::get('/', [App\Http\Controllers\Api\PayrollMmController::class, 'index']);
        Route::post('/import', [App\Http\Controllers\Api\PayrollMmController::class, 'import']);
        Route::post('/import/save', [App\Http\Controllers\Api\PayrollMmController::class, 'saveImport']);
        Route::get('/{id}', [App\Http\Controllers\Api\PayrollMmController::class, 'show']);
        Route::patch('/{id}/status', [App\Http\Controllers\Api\PayrollMmController::class, 'updateStatus']);
        Route::delete('/{id}', [App\Http\Controllers\Api\PayrollMmController::class, 'destroy']);
        Route::get('/{id}/slip', [App\Http\Controllers\Api\PayrollMmController::class, 'generateSlip']);
    });

    // Reflexiology Payroll routes
    Route::prefix('payrolls/ref')->group(function () {
        Route::get('/', [App\Http\Controllers\Api\PayrollRefController::class, 'index']);
        Route::post('/import', [App\Http\Controllers\Api\PayrollRefController::class, 'import']);
        Route::post('/import/save', [App\Http\Controllers\Api\PayrollRefController::class, 'saveImport']);
        Route::get('/{id}', [App\Http\Controllers\Api\PayrollRefController::class, 'show']);
        Route::patch('/{id}/status', [App\Http\Controllers\Api\PayrollRefController::class, 'updateStatus']);
        Route::delete('/{id}', [App\Http\Controllers\Api\PayrollRefController::class, 'destroy']);
        Route::get('/{id}/slip', [App\Http\Controllers\Api\PayrollRefController::class, 'generateSlip']);
    });

    // Wrapping Payroll routes
    Route::prefix('payrolls/wrapping')->group(function () {
        Route::get('/', [App\Http\Controllers\Api\PayrollWrappingController::class, 'index']);
        Route::post('/import', [App\Http\Controllers\Api\PayrollWrappingController::class, 'import']);
        Route::post('/import/save', [App\Http\Controllers\Api\PayrollWrappingController::class, 'saveImport']);
        Route::get('/{id}', [App\Http\Controllers\Api\PayrollWrappingController::class, 'show']);
        Route::patch('/{id}/status', [App\Http\Controllers\Api\PayrollWrappingController::class, 'updateStatus']);
        Route::delete('/{id}', [App\Http\Controllers\Api\PayrollWrappingController::class, 'destroy']);
        Route::get('/{id}/slip', [App\Http\Controllers\Api\PayrollWrappingController::class, 'generateSlip']);
    });

    // Hans Payroll routes
    Route::prefix('payrolls/hans')->group(function () {
        Route::get('/', [App\Http\Controllers\Api\PayrollHansController::class, 'index']);
        Route::post('/import', [App\Http\Controllers\Api\PayrollHansController::class, 'import']);
        Route::post('/import/save', [App\Http\Controllers\Api\PayrollHansController::class, 'saveImport']);
        Route::get('/{id}', [App\Http\Controllers\Api\PayrollHansController::class, 'show']);
        Route::patch('/{id}/status', [App\Http\Controllers\Api\PayrollHansController::class, 'updateStatus']);
        Route::delete('/{id}', [App\Http\Controllers\Api\PayrollHansController::class, 'destroy']);
        Route::get('/{id}/slip', [App\Http\Controllers\Api\PayrollHansController::class, 'generateSlip']);
    });

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

    // Payroll routes (generic)
    Route::apiResource('payrolls', App\Http\Controllers\Api\PayrollController::class);
    Route::get('/payrolls/template/download', [App\Http\Controllers\Api\PayrollController::class, 'downloadTemplate']);
    Route::post('/payrolls/approve-all', [App\Http\Controllers\Api\PayrollController::class, 'approveAll']);
    Route::post('/payrolls/bulk-approve', [App\Http\Controllers\Api\PayrollController::class, 'bulkApprove']);
    Route::post('/payrolls/import', [App\Http\Controllers\Api\PayrollController::class, 'import']);
    Route::post('/payrolls/import/save', [App\Http\Controllers\Api\PayrollController::class, 'saveImport']);
    Route::post('/payrolls/calculate', [App\Http\Controllers\Api\PayrollController::class, 'calculate']);
    Route::patch('/payrolls/{id}/status', [App\Http\Controllers\Api\PayrollController::class, 'updateStatus']);
    Route::get('/payrolls/{id}/payslip', [App\Http\Controllers\Api\PayrollController::class, 'generatePayslip']);
    Route::get('/payrolls/{id}/slip', [App\Http\Controllers\Api\PayrollController::class, 'generateSlip']);
    Route::get('/payrolls/period/{month}/{year}', [App\Http\Controllers\Api\PayrollController::class, 'periodPayrolls']);
    Route::post('/payrolls/bulk-download', [App\Http\Controllers\Api\PayrollController::class, 'bulkDownload']);

    // Payroll Celluller (NEW)
    Route::apiResource('payroll-cellullers', App\Http\Controllers\Api\PayrollCellullerController::class);
    Route::post('payroll-cellullers/import', [App\Http\Controllers\Api\PayrollCellullerController::class, 'import']);
    Route::post('payroll-cellullers/import/save', [App\Http\Controllers\Api\PayrollCellullerController::class, 'saveImport']);
    Route::patch('payroll-cellullers/{id}/status', [App\Http\Controllers\Api\PayrollCellullerController::class, 'updateStatus']);
    Route::get('payroll-cellullers/{id}/slip', [App\Http\Controllers\Api\PayrollCellullerController::class, 'generateSlip']);

    // Role routes (Super Admin only)
    Route::middleware('role:super_admin')->group(function () {
        Route::apiResource('roles', App\Http\Controllers\Api\RoleController::class);
    });

    // Dashboard & Analytics (Super Admin)
    Route::middleware('role:super_admin,admin_cabang')->group(function () {
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
    Route::middleware('role:super_admin,admin_cabang')->group(function () {
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
    Route::post('/notifications/read', [App\Http\Controllers\Api\NotificationController::class, 'markAsRead']);

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
