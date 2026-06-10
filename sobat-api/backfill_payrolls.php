<?php
use App\Models\Payroll;
use Illuminate\Support\Facades\Log;

$models = [
    \App\Models\PayrollHo::class => 'office',
    \App\Models\PayrollFnb::class => 'fnb',
    \App\Models\PayrollTungtau::class => 'tungtau',
    \App\Models\PayrollMaximum::class => 'maximum',
    \App\Models\PayrollCelluller::class => 'cellular',
    \App\Models\PayrollHans::class => 'hans',
    \App\Models\PayrollRef::class => 'ref',
    \App\Models\PayrollWrapping::class => 'wrapping',
    \App\Models\PayrollMm::class => 'minimarket',
    \App\Models\PayrollMoneyChanger::class => 'money_changer',
];

$count = 0;
foreach ($models as $modelClass => $divisionType) {
    if (!class_exists($modelClass)) continue;
    $payrolls = $modelClass::whereIn('status', ['approved', 'released', 'paid'])->get();
    foreach ($payrolls as $payroll) {
        $genericPayroll = Payroll::firstOrNew([
            'employee_id' => $payroll->employee_id,
            'period' => $payroll->period,
        ]);
        
        $allowancesTotal = 
            (float)($payroll->attendance_amount ?? $payroll->attendance_allowance ?? 0) + 
            (float)($payroll->transport_amount ?? 0) + 
            (float)($payroll->health_allowance ?? 0) + 
            (float)($payroll->position_allowance ?? 0) + 
            (float)($payroll->meal_amount ?? 0) + 
            (float)($payroll->holiday_allowance ?? 0) + 
            (float)($payroll->bonus ?? 0) + 
            (float)($payroll->adjustment ?? 0) + 
            (float)($payroll->insentif_kehadiran ?? 0) + 
            (float)($payroll->target_koli ?? 0) + 
            (float)($payroll->accessory_fee ?? 0) + 
            (float)($payroll->backup ?? 0) + 
            (float)($payroll->policy_ho ?? 0);

        $genericPayroll->basic_salary = $payroll->basic_salary ?? 0;
        $genericPayroll->allowances = $allowancesTotal;
        $genericPayroll->overtime_pay = $payroll->overtime_pay ?? $payroll->overtime_amount ?? 0;
        $genericPayroll->gross_salary = $payroll->gross_salary ?? $payroll->total_salary_2 ?? $payroll->total_salary_1 ?? 0;
        $genericPayroll->bpjs_kesehatan = $payroll->bpjs_kesehatan ?? $payroll->deduction_bpjs_ks ?? 0;
        $genericPayroll->bpjs_ketenagakerjaan = $payroll->bpjs_ketenagakerjaan ?? $payroll->deduction_bpjs_tk ?? $payroll->bpjs_tk_deduction ?? 0;
        $genericPayroll->pph21 = $payroll->pph21 ?? 0;
        $genericPayroll->other_deductions = 0;
        $genericPayroll->total_deductions = $payroll->total_deductions ?? $payroll->deduction_total ?? 0;
        $genericPayroll->net_salary = $payroll->net_salary ?? $payroll->thp ?? 0;
        $genericPayroll->status = $payroll->status;
        
        $details = $genericPayroll->details ?? [];
        $details['original_model'] = get_class($payroll);
        $details['original_id'] = $payroll->id;
        $details['division_type'] = $payroll->division_type ?? $divisionType;
        
        // Map Attendance for mobile app
        $details['days_present'] = $payroll->days_present ?? 0;
        $details['days_sick'] = $payroll->days_sick ?? 0;
        $details['days_permission'] = $payroll->days_permission ?? 0;
        $details['days_alpha'] = $payroll->days_alpha ?? 0;
        $details['days_leave'] = $payroll->days_leave ?? 0;
        
        // Map Allowances for mobile app
        $details['transport_allowance'] = $payroll->transport_amount ?? 0;
        $details['health_allowance'] = $payroll->health_allowance ?? 0;
        $details['position_allowance'] = $payroll->position_allowance ?? 0;
        $details['holiday_allowance'] = $payroll->holiday_allowance ?? 0;
        $details['attendance_allowance'] = $payroll->attendance_amount ?? $payroll->attendance_allowance ?? 0;
        $details['adjustment'] = $payroll->adjustment ?? 0;
        $details['overtime_hours'] = $payroll->overtime_hours ?? 0;
        $details['insentif_kehadiran'] = $payroll->insentif_kehadiran ?? 0;
        $details['meal_allowance'] = $payroll->meal_amount ?? 0;
        $details['bonus'] = $payroll->bonus ?? 0;
        
        // Map Deductions for mobile app
        $details['deductions'] = [
            'absent' => $payroll->deduction_absent ?? 0,
            'alfa' => $payroll->deduction_alpha ?? 0,
            'late' => $payroll->deduction_late ?? 0,
            'shortage' => $payroll->deduction_shortage ?? $payroll->deduction_so_shortage ?? 0,
            'loan' => $payroll->deduction_loan ?? 0,
            'bank_fee' => $payroll->deduction_admin_fee ?? $payroll->bank_fee ?? 0,
            'bpjs_tk' => $payroll->deduction_bpjs_tk ?? $payroll->bpjs_tk_deduction ?? 0,
        ];
        
        $genericPayroll->details = $details;
        $genericPayroll->saveQuietly();
        $count++;
    }
}
echo "Backfilled $count payrolls.";
