<?php

namespace App\Http\Controllers\Api\Traits;

trait PayrollThpCalculator
{
    /**
     * Calculate THP dynamically with fallback.
     * If net_salary > 0, use: net_salary + ewa_amount
     * If net_salary == 0 (import anomaly), compute from income components minus deductions.
     *
     * @param  object  $payroll       The payroll Eloquent model
     * @param  array   $incomeFields  List of income column names
     * @param  array   $deductionFields  List of deduction column names
     * @return array   ['thp' => float, 'net_salary' => float|null]
     */
    protected function calculateThp($payroll, array $incomeFields, array $deductionFields): array
    {
        $netSalary = (float)($payroll->net_salary ?? 0);
        $ewaAmount = (float)($payroll->ewa_amount ?? 0);

        // Primary: use stored values if valid
        if ($netSalary > 0 || $ewaAmount > 0) {
            return [
                'thp' => $netSalary + $ewaAmount,
                'net_salary' => null, // no override needed
            ];
        }

        // Fallback: calculate from individual components
        $totalIncome = 0;
        foreach ($incomeFields as $field) {
            $totalIncome += (float)($payroll->$field ?? 0);
        }

        $totalDeductions = 0;
        foreach ($deductionFields as $field) {
            $totalDeductions += (float)($payroll->$field ?? 0);
        }

        $thp = $totalIncome - $totalDeductions;

        return [
            'thp' => $thp,
            'net_salary' => $thp - $ewaAmount,
        ];
    }
}
