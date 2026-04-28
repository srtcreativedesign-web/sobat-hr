<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class PayrollMaximum extends Model
{
    protected $table = 'payroll_maximums';

    protected $fillable = [
        // Core
        'employee_id',
        'period',
        'account_number',
        
        // Attendance
        'days_total',
        'days_off',
        'days_sick',
        'days_permission',
        'days_alpha',
        'days_leave',
        'days_present',
        
        // Basic Salary
        'basic_salary',
        
        // Allowances
        'attendance_rate',
        'attendance_amount',
        'transport_rate',
        'transport_amount',
        'health_allowance',
        'position_allowance',
        
        // Totals & Overtime
        'total_salary_1',
        'overtime_rate',
        'overtime_hours',
        'overtime_amount',
        
        // Maximum specific
        'backup',
        'insentif',
        'insentif_kehadiran',
        'holiday_allowance',
        'adjustment',
        'total_salary_2',
        
        // Policy & Deductions
        'policy_ho',
        'deduction_absent',
        'deduction_late',
        'deduction_shortage',
        'deduction_loan',
        'deduction_admin_fee',
        'deduction_bpjs_tk',
        'total_deductions',
        
        // Finals
        'grand_total',
        'thp',
        'stafbook_loan',
        'net_salary',
    ];

    public function employee()
    {
        return $this->belongsTo(Employee::class);
    }
}
