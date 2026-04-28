<?php
$file = '/Applications/XAMPP/xamppfiles/htdocs/sobat-hr/sobat-api/app/Http/Controllers/Api/PayrollTungtauController.php';
$content = file_get_contents($file);

// Replace class names and models
$content = str_replace('PayrollFnbController', 'PayrollTungtauController', $content);
$content = str_replace('PayrollFnb::', 'PayrollTungtau::', $content);
$content = str_replace('App\Models\PayrollFnb', 'App\Models\PayrollTungtau', $content);
$content = str_replace('payslips.fnb', 'payslips.tungtau', $content);
$content = str_replace('payslip_', 'payslip_tungtau_', $content);
$content = str_replace("FnB Payroll", "Tungtau Payroll", $content);

// In the formatPayroll method, add the extra fields
$formatPayrollPattern = '/\$formatted\[\'allowances\'\] = \[(.*?)\];/s';
$formatPayrollReplacement = <<<'REPLACEMENT'
$formatted['allowances'] = [
             'Kehadiran' => [
                 'rate' => $payroll->attendance_rate,
                 'amount' => $payroll->attendance_amount,
             ],
             'Transport' => [
                 'rate' => $payroll->transport_rate,
                 'amount' => $payroll->transport_amount,
             ],
             'Tunjangan Kesehatan' => $payroll->health_allowance,
             'Tunjangan Jabatan' => $payroll->position_allowance,
             'Lembur' => [
                 'rate' => $payroll->overtime_rate,
                 'hours' => $payroll->overtime_hours,
                 'amount' => $payroll->overtime_amount,
             ],
             'Insentif Kehadiran' => $payroll->attendance_incentive,
             'Backup' => $payroll->backup_allowance,
             'Insentif Lebaran' => $payroll->holiday_allowance,
             'Adjustment' => $payroll->adjustment,
             'Kebijakan HO' => $payroll->policy_ho,
        ];
REPLACEMENT;
$content = preg_replace($formatPayrollPattern, $formatPayrollReplacement, $content);

// For generateSlip, update the $payroll->allowances injection
$generateSlipPattern = '/\$payroll->allowances = \[(.*?)\];/s';
$generateSlipReplacement = <<<'REPLACEMENT'
$payroll->allowances = [
                'Kehadiran' => [
                    'rate' => $payroll->attendance_rate,
                    'amount' => $payroll->attendance_amount,
                ],
                'Transport' => [
                    'rate' => $payroll->transport_rate,
                    'amount' => $payroll->transport_amount,
                ],
                'Tunjangan Kesehatan' => $payroll->health_allowance,
                'Tunjangan Jabatan' => $payroll->position_allowance,
                'Lembur' => [
                    'rate' => $payroll->overtime_rate,
                    'hours' => $payroll->overtime_hours,
                    'amount' => $payroll->overtime_amount,
                ],
                'Insentif Kehadiran' => $payroll->attendance_incentive,
                'Backup' => $payroll->backup_allowance,
                'Insentif Lebaran' => $payroll->holiday_allowance,
                'Adjustment' => $payroll->adjustment,
                'Kebijakan HO' => $payroll->policy_ho,
            ];
REPLACEMENT;
$content = preg_replace($generateSlipPattern, $generateSlipReplacement, $content);

// Update column map array inside import()
// From inspection: Backup -> backup_allowance, Insentif Kehadrian -> attendance_incentive, Insentif Lebaran -> holiday_allowance
$headerLabelsPattern = '/\$headerLabels = \[(.*?)\];/s';
$headerLabelsReplacement = <<<'REPLACEMENT'
$headerLabels = [
                'nama karyawan' => 'employee_name',
                'no rekening' => 'account_number',
                'gaji pokok' => 'basic_salary',
                'tunj. kehadiran' => 'attendance_allowance_header',
                'tunj kehadiran' => 'attendance_allowance_header',
                'kehadiran' => 'attendance_allowance_header', // mapped later
                'transport' => 'transport_rate_header',
                'tunj. kesehatan' => 'health_allowance',
                'tunj kesehatan' => 'health_allowance',
                'tunj. jabatan' => 'position_allowance',
                'tunj jabatan' => 'position_allowance',
                'total gaji & bonus' => 'total_salary_2',
                'total gaji' => 'total_salary_1',
                'lembur' => 'overtime_rate_header',
                'insentif lebaran' => 'holiday_allowance',
                'thr' => 'holiday_allowance',
                'insentif kehadrian' => 'attendance_incentive',
                'insentif kehadiran' => 'attendance_incentive',
                'backup' => 'backup_allowance',
                'kebijakan ho' => 'policy_ho',
                'kebijakan' => 'policy_ho',
                'adj' => 'adjustment',
                'potongan' => 'deductions_header',
                'grand total' => 'grand_total',
                'pinjaman ewa' => 'ewa_amount',
                'ewa' => 'ewa_amount',
                'payroll' => 'net_salary',
                'thp' => 'net_salary', // because Tungtau uses THP as net salary
            ];
REPLACEMENT;
$content = preg_replace($headerLabelsPattern, $headerLabelsReplacement, $content);

// In the dataRows loop, add the new mapped fields
$parsedPattern = '/\'holiday_allowance\' => \$getMappedValue\(\'holiday_allowance\', \$row\),.*?\'total_salary_2\'/s';
$parsedReplacement = <<<'REPLACEMENT'
'attendance_incentive' => $getMappedValue('attendance_incentive', $row),
                    'backup_allowance' => $getMappedValue('backup_allowance', $row),
                    'holiday_allowance' => $getMappedValue('holiday_allowance', $row),
                    'total_salary_2'
REPLACEMENT;
$content = preg_replace($parsedPattern, $parsedReplacement, $content);

// Replace "ewa_amount" fallback. Tungtau doesn't have EWA in the file, we can map ewa_amount to 0 if not found, but we already have fallback
// "THP (kolom yang harus rirubah jika ada perubahan gaji)" maps to THP. Since we mapped 'thp' => 'net_salary', it will capture it.
// Pinjaman -> AH -> deduction_loan.

file_put_contents($file, $content);
echo "Patched PayrollTungtauController\n";
