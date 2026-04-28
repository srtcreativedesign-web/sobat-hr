<?php
$file = '/Applications/XAMPP/xamppfiles/htdocs/sobat-hr/sobat-api/app/Http/Controllers/Api/PayrollFnbController.php';
$content = file_get_contents($file);

// 1. import()
$importSearch = <<<EOT
                'grand_total' => \$grandTotal,
                'ewa_amount' => \$ewaAmount,
                'net_salary' => \$netSalary,
EOT;
$importReplace = <<<EOT
                'grand_total' => \$grandTotal,
                'thp' => \$grandTotal,
                'ewa_amount' => \$ewaAmount,
                'net_salary' => \$netSalary,
EOT;
$content = str_replace($importSearch, $importReplace, $content);

// 2. index() & show() responses
$respSearch = <<<EOT
            // Add attendance data
            \$formatted['attendance'] = [
EOT;
$respReplace = <<<EOT
            // Add extra fields
            \$formatted['thp'] = \$payroll->thp;
            
            // Add attendance data
            \$formatted['attendance'] = [
EOT;
$content = str_replace($respSearch, $respReplace, $content);

// show() specifically
$showSearch = <<<EOT
        // Add attendance data
        \$formatted['attendance'] = [
EOT;
$showReplace = <<<EOT
        // Add extra fields
        \$formatted['thp'] = \$payroll->thp;
        
        // Add attendance data
        \$formatted['attendance'] = [
EOT;
$content = str_replace($showSearch, $showReplace, $content);

file_put_contents($file, $content);
echo "PayrollFnbController patched.\n";
