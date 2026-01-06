<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Payroll extends Model
{
    use HasFactory;

    protected $fillable = [
        'employee_id',
        'period_month',
        'period_year',
        'base_salary',
        'allowances',
        'overtime_pay',
        'deductions',
        'bpjs_health',
        'bpjs_employment',
        'tax_pph21',
        'net_salary',
        'status',
        'paid_at',
    ];

    protected $casts = [
        'period_month' => 'integer',
        'period_year' => 'integer',
        'base_salary' => 'decimal:2',
        'allowances' => 'decimal:2',
        'overtime_pay' => 'decimal:2',
        'deductions' => 'decimal:2',
        'bpjs_health' => 'decimal:2',
        'bpjs_employment' => 'decimal:2',
        'tax_pph21' => 'decimal:2',
        'net_salary' => 'decimal:2',
        'paid_at' => 'datetime',
    ];

    /**
     * Relationships
     */
    public function employee()
    {
        return $this->belongsTo(Employee::class);
    }
}
