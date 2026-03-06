<?php

namespace App\Jobs;

use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Queue\Queueable;

class ProcessPayrollImport implements ShouldQueue
{
    use Queueable;

    protected $rows;
    protected $adminId;

    /**
     * Create a new job instance.
     */
    public function __construct(array $rows, int $adminId)
    {
        $this->rows = $rows;
        $this->adminId = $adminId;
    }

    /**
     * Execute the job.
     */
    public function handle(): void
    {
        \Illuminate\Support\Facades\Log::info("Processing Payroll Import Job. Rows: " . count($this->rows));
        
        foreach ($this->rows as $index => $row) {
            try {
                // Find employee by name (case insensitive)
                $employee = \App\Models\Employee::whereRaw('LOWER(full_name) = ?', [strtolower($row['employee_name'])])->first();

                if (!$employee) {
                    \Illuminate\Support\Facades\Log::warning("Employee not found during import: " . $row['employee_name']);
                    continue;
                }

                // Parse period
                $period = $row['period'] ?? date('Y-m'); 
                $periodString = $period; // Assuming it's already in YYYY-MM format from frontend

                $basicSalary = $row['basic_salary'];
                $allowances = $row['allowances'] ?? 0;
                $overtime = $row['overtime'] ?? 0;
                $totalDeductions = $row['total_deductions'] ?? 0;
                
                $grossSalary = $basicSalary + $allowances + $overtime;
                $details = $row['details'] ?? [];
                
                $deductions = $details['deductions'] ?? [];
                $bpjsTK = (float) ($deductions['bpjs_tk'] ?? 0);
                
                $knownDeductions = $bpjsTK + (float)($deductions['absent'] ?? 0) + (float)($deductions['late'] ?? 0) + (float)($deductions['shortage'] ?? 0) + (float)($deductions['loan'] ?? 0) + (float)($deductions['bank_fee'] ?? 0);
                $otherDeductions = $totalDeductions - $knownDeductions;
                if ($otherDeductions < 0) $otherDeductions = 0;

                $calculatedNetSalary = $grossSalary - $totalDeductions;

                \App\Models\Payroll::updateOrCreate(
                    [
                        'employee_id' => $employee->id,
                        'period' => $periodString,
                    ],
                    [
                        'basic_salary' => $basicSalary,
                        'allowances' => $allowances,
                        'overtime_pay' => $overtime,
                        'gross_salary' => $grossSalary,
                        'total_deductions' => $totalDeductions,
                        'net_salary' => $calculatedNetSalary,
                        'details' => $details,
                        'status' => 'draft',
                        'bpjs_kesehatan' => 0, 
                        'bpjs_ketenagakerjaan' => $bpjsTK,
                        'pph21' => 0,
                        'other_deductions' => $otherDeductions,
                        'created_by' => $this->adminId
                    ]
                );

            } catch (\Exception $e) {
                \Illuminate\Support\Facades\Log::error("Error processing row " . ($index + 1) . ": " . $e->getMessage());
            }
        }
    }
}
