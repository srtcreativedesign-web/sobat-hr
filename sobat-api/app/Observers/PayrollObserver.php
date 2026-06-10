<?php

namespace App\Observers;

use App\Services\FcmService;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Facades\Log;

class PayrollObserver
{
    public function saved(Model $payroll): void
    {
        Log::info('PayrollObserver saved fired', [
            'model' => get_class($payroll),
            'id' => $payroll->id,
            'status' => $payroll->status,
            'wasChanged_status' => $payroll->wasChanged('status'),
            'original_status' => $payroll->getOriginal('status'),
        ]);

        if (! $payroll->wasChanged('status') || $payroll->status !== 'approved') {
            return;
        }

        if (! $payroll->relationLoaded('employee')) {
            $payroll->load('employee.user');
        }

        $employee = $payroll->employee;
        if (! $employee) {
            Log::warning('PayrollObserver: No employee linked to payroll', ['payroll_id' => $payroll->id, 'employee_id' => $payroll->employee_id]);

            return;
        }

        if (! $employee->user) {
            Log::warning('PayrollObserver: Employee has no user', ['employee_id' => $employee->id]);

            return;
        }

        if (! $employee->user->fcm_token) {
            Log::warning('PayrollObserver: User has no FCM token', ['user_id' => $employee->user->id, 'email' => $employee->user->email]);

            return;
        }

        try {
            $period = $payroll->period ?? '';
            $fcmService = app(FcmService::class);
            $fcmService->sendToUser(
                $employee->user,
                'Slip Gaji Tersedia',
                "Slip gaji periode {$period} sudah tersedia. Silakan cek di aplikasi.",
            );
        } catch (\Exception $e) {
            Log::error("PayrollObserver FCM error: {$e->getMessage()}");
        }
        
        // Feature removed as per user request: Stop duplicating retail records to generic payrolls table
    }
}
