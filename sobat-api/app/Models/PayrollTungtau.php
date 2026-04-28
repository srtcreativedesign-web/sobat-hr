<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class PayrollTungtau extends Model
{
    protected $table = 'payroll_tungtau';

    protected $fillable = [
        // Core
        'employee_id',
        'period',
        'account_number',
        
        // Status & Approval
        'status',
        'approval_signature',
        'signer_name',
        'approved_by',
        'notes',
        
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
        
        // Allowances & Incomes
        'attendance_rate',
        'attendance_amount',
        'transport_rate',
        'transport_amount',
        'health_allowance',
        'position_allowance',
        'total_salary_1',
        'overtime_rate',
        'overtime_hours',
        'overtime_amount',
        'backup_allowance',
        'attendance_incentive',
        'holiday_allowance',
        'total_salary_2',
        'policy_ho',
        'adjustment',
        
        // Deductions
        'deduction_absent',
        'deduction_late',
        'deduction_shortage',
        'deduction_loan',
        'deduction_admin_fee',
        'deduction_bpjs_tk',
        'total_deductions',
        
        // Totals
        'grand_total',
        'ewa_amount',
        'net_salary',
    ];

    /**
     * Get the employee that owns the payroll.
     */
    public function employee()
    {
        return $this->belongsTo(Employee::class);
    }
}
