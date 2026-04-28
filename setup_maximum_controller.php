<?php
$file = '/Applications/XAMPP/xamppfiles/htdocs/sobat-hr/sobat-api/app/Http/Controllers/Api/PayrollMaximumController.php';
$content = file_get_contents($file);

// 1. Class and Model Name
$content = str_replace('class PayrollFnbController extends Controller', 'class PayrollMaximumController extends Controller', $content);
$content = str_replace('use App\Models\PayrollFnb;', "use App\Models\PayrollMaximum;\nuse App\Models\Employee;", $content);
$content = str_replace('PayrollFnb::', 'PayrollMaximum::', $content);

// 2. Adjust json response for list/show
// We need to return the correct calculation values to frontend.
// The frontend still expects `net_salary`, `total_salary_2`, `ewa_amount`, etc.
$content = preg_replace("/'Insentif Lebaran' => \\\$payroll->holiday_allowance,/", "'Insentif Lebaran' => \$payroll->holiday_allowance,\n                'Insentif ' => \$payroll->insentif,", $content);

// 3. Fix the parsed array mappings
$oldParsed = <<<EOT
                    'grand_total' => \$grandTotal,
                    'ewa_amount' => \$ewa,
                    'net_salary' => \$netSalary,
EOT;

// In Maximum 600:
// grand_total is AJ (which we can leave as grand_total)
// thp is AK
// ewa is AL
// net_salary is AM
$newParsed = <<<EOT
                    'grand_total' => \$grandTotal,
                    'thp' => \$netSalary, // AK is read as 'payroll', but it's actually THP in Maximum
                    'stafbook_loan' => \$ewa, // AL
                    'net_salary' => \$getCellValue(\$columnMapping['net_salary_am'] ?? null, \$row), // AM
EOT;
// Wait, my patterns need `net_salary_am` mapped to `AM`.
$content = str_replace($oldParsed, $newParsed, $content);

// Also we need to add `net_salary_am` to patterns.
$content = str_replace("'payroll' => ['Total Gaji Ditransfer', 'Payroll', 'THP'],", "'payroll' => ['THP', 'Payroll'],\n                'net_salary_am' => ['Total Gaji Ditransfer'],", $content);

// Fix the calculation to match user request: ewa is stafbook_loan. We need to pass it back via API as `ewa_amount` for UI compatibility.
// In index & show:
$content = str_replace("'net_salary' => \$payroll->net_salary,", "'net_salary' => \$payroll->net_salary,\n                'ewa_amount' => \$payroll->stafbook_loan,\n                'thp' => \$payroll->thp,", $content);

file_put_contents($file, $content);
echo "Controller setup done.";
