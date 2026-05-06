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

        // Always calculate from individual components
        $totalIncome = 0;
        foreach ($incomeFields as $field) {
            $totalIncome += (float)($payroll->$field ?? 0);
        }

        $totalDeductions = 0;
        foreach ($deductionFields as $field) {
            $totalDeductions += (float)($payroll->$field ?? 0);
        }

        $thpCalculated = $totalIncome - $totalDeductions;
        $dbThp = $netSalary + $ewaAmount;

        // If DB has 0 or if there is a significant miscalculation in the uploaded Excel (> Rp 100 difference),
        // we forcefully override it with the correct mathematical calculation from the components.
        // Users should use 'adjustment' for manual tweaks, not overwrite the net_salary cell directly.
        if ($netSalary <= 0 || abs($thpCalculated - $dbThp) > 100) {
            return [
                'thp' => $thpCalculated,
                'net_salary' => $thpCalculated - $ewaAmount,
                'total_income' => $totalIncome,
                'total_deductions' => $totalDeductions,
            ];
        }

        // If the DB value is correct (matches calculation), no need to override net_salary
        return [
            'thp' => $dbThp,
            'net_salary' => null,
            'total_income' => $totalIncome,
            'total_deductions' => $totalDeductions,
        ];
    }
}
