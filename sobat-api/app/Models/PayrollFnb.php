<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class PayrollFnb extends Model
{
    use HasFactory;

    protected $table = 'payroll_fnb';

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
        
        // Final
        'grand_total',
        'ewa_amount',
        'net_salary',
        
        // Metadata
        'status',
        'details',
        'notes',
    ];

    protected $casts = [
        'details' => 'array',
        'basic_salary' => 'decimal:2',
        'attendance_rate' => 'decimal:2',
        'attendance_amount' => 'decimal:2',
        'transport_rate' => 'decimal:2',
        'transport_amount' => 'decimal:2',
        'health_allowance' => 'decimal:2',
        'position_allowance' => 'decimal:2',
        'total_salary_1' => 'decimal:2',
        'overtime_rate' => 'decimal:2',
        'overtime_hours' => 'decimal:2',
        'overtime_amount' => 'decimal:2',
        'holiday_allowance' => 'decimal:2',
        'adjustment' => 'decimal:2',
        'total_salary_2' => 'decimal:2',
        'policy_ho' => 'decimal:2',
        'deduction_absent' => 'decimal:2',
        'deduction_late' => 'decimal:2',
        'deduction_shortage' => 'decimal:2',
        'deduction_loan' => 'decimal:2',
        'deduction_admin_fee' => 'decimal:2',
        'deduction_bpjs_tk' => 'decimal:2',
        'total_deductions' => 'decimal:2',
        'grand_total' => 'decimal:2',
        'ewa_amount' => 'decimal:2',
        'net_salary' => 'decimal:2',
    ];

    // Relationships
    public function employee()
    {
        return $this->belongsTo(Employee::class);
    }
}
