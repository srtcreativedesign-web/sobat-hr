<?php

namespace App\Repositories;

use App\Models\Payroll;
use App\Models\Employee;
use Carbon\Carbon;

class PayrollRepository
{
    protected $model;

    public function __construct(Payroll $payroll)
    {
        $this->model = $payroll;
    }

    /**
     * Get all payrolls with filters
     */
    public function getAll(array $filters = [])
    {
        $query = $this->model->with('employee');

        if (isset($filters['employee_id'])) {
            $query->where('employee_id', $filters['employee_id']);
        }

        if (isset($filters['month']) && isset($filters['year'])) {
            $query->where('period_month', $filters['month'])
                  ->where('period_year', $filters['year']);
        }

        return $query->orderBy('period_year', 'desc')
            ->orderBy('period_month', 'desc')
            ->paginate(20);
    }

    /**
     * Find payroll by ID
     */
    public function findById(int $id)
    {
        return $this->model->with('employee')->findOrFail($id);
    }

    /**
     * Create payroll
     */
    public function create(array $data)
    {
        return $this->model->create($data);
    }

    /**
     * Update payroll
     */
    public function update(int $id, array $data)
    {
        $payroll = $this->findById($id);
        $payroll->update($data);
        return $payroll;
    }

    /**
     * Delete payroll
     */
    public function delete(int $id): bool
    {
        $payroll = $this->findById($id);
        return $payroll->delete();
    }

    /**
     * Calculate payroll for employee
     */
    public function calculateForEmployee(int $employeeId, int $month, int $year)
    {
        $employee = Employee::with('attendances')->findOrFail($employeeId);

        // Get attendance data
        $attendances = $employee->attendances()
            ->whereMonth('date', $month)
            ->whereYear('date', $year)
            ->get();

        $totalWorkDays = $attendances->where('status', 'present')->count();
        $totalWorkHours = $attendances->sum('work_hours');
        $totalOvertimeHours = 0; // TODO: Calculate from overtime requests

        // Calculate components
        $baseSalary = $employee->base_salary;
        $allowances = 0;
        $overtimePay = $totalOvertimeHours * ($baseSalary / 173);
        
        // BPJS calculations
        $bpjsHealth = $baseSalary * 0.01;
        $bpjsEmployment = $baseSalary * 0.02;
        
        // Tax calculation
        $grossSalary = $baseSalary + $allowances + $overtimePay;
        $taxableIncome = $grossSalary - $bpjsHealth - $bpjsEmployment;
        $taxPph21 = $this->calculatePph21($taxableIncome);

        $deductions = 0;
        $totalDeductions = $deductions + $bpjsHealth + $bpjsEmployment + $taxPph21;
        $netSalary = $grossSalary - $totalDeductions;

        return $this->create([
            'employee_id' => $employeeId,
            'period_month' => $month,
            'period_year' => $year,
            'base_salary' => $baseSalary,
            'allowances' => $allowances,
            'overtime_pay' => $overtimePay,
            'deductions' => $deductions,
            'bpjs_health' => $bpjsHealth,
            'bpjs_employment' => $bpjsEmployment,
            'tax_pph21' => $taxPph21,
            'net_salary' => $netSalary,
            'status' => 'draft',
        ]);
    }

    /**
     * Get payrolls for specific period
     */
    public function getByPeriod(int $month, int $year)
    {
        return $this->model->with('employee')
            ->where('period_month', $month)
            ->where('period_year', $year)
            ->get();
    }

    /**
     * Calculate PPh21 tax
     */
    private function calculatePph21($taxableIncome)
    {
        $yearlyIncome = $taxableIncome * 12;
        $ptkp = 54000000;

        if ($yearlyIncome <= $ptkp) {
            return 0;
        }

        $taxable = $yearlyIncome - $ptkp;
        
        if ($taxable <= 60000000) {
            $yearlyTax = $taxable * 0.05;
        } elseif ($taxable <= 250000000) {
            $yearlyTax = 3000000 + ($taxable - 60000000) * 0.15;
        } else {
            $yearlyTax = 31500000 + ($taxable - 250000000) * 0.25;
        }

        return $yearlyTax / 12;
    }
}
