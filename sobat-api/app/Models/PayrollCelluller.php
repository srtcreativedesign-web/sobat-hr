<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class PayrollCelluller extends Model
{
    protected $fillable = [
        'employee_id',
        'period',
        'account_number',
        'days_total',
        'days_off',
        'days_sick',
        'days_permission',
        'days_alpha',
        'days_leave',
        'days_present',
        'basic_salary',
        'position_allowance',
        'meal_rate',
        'meal_amount',
        'transport_rate',
        'transport_amount',
        'mandatory_overtime_rate',
        'mandatory_overtime_amount',
        'attendance_allowance',
        'health_allowance',
        'subtotal_1',
        'overtime_rate',
        'overtime_hours',
        'overtime_amount',
        'bonus',
        'holiday_allowance',
        'adjustment',
        'gross_salary',
        'policy_ho',
        'deduction_absent',
        'deduction_late',
        'deduction_so_shortage',
        'deduction_loan',
        'deduction_admin_fee',
        'deduction_bpjs_tk',
        'total_deduction',
        'net_salary',
        'ewa_amount',
        'final_payment',
        'years_of_service',
        'notes',
        'status',
        'signer_name',
        'approval_signature',
        'approved_by',
    ];

    public function employee()
    {
        return $this->belongsTo(Employee::class);
    }
}
