<?php
$file = '/Applications/XAMPP/xamppfiles/htdocs/sobat-hr/sobat-api/app/Http/Controllers/Api/PayrollCellullerController.php';
$content = file_get_contents($file);

$impSearch = <<<EOT
                    'net_salary' => \$getMappedValue('net_salary', \$row),
                    'final_payment' => \$getMappedValue('final_payment', \$row),
                    'ewa_amount' => \$getMappedValue('ewa_amount', \$row),
EOT;
$impReplace = <<<EOT
                    'net_salary' => \$getMappedValue('net_salary', \$row),
                    'final_payment' => \$getMappedValue('final_payment', \$row),
                    'ewa_amount' => \$getMappedValue('ewa_amount', \$row),
                    'thp' => (float)\$getMappedValue('final_payment', \$row) + (float)\$getMappedValue('ewa_amount', \$row),
EOT;
$content = str_replace($impSearch, $impReplace, $content);

$respSearch = <<<EOT
            // Add attendance data
            \$formatted['attendance'] = [
EOT;
$respReplace = <<<EOT
            // Add extra fields
            \$formatted['thp'] = \$payroll->thp;
            \$formatted['ewa_amount'] = \$payroll->ewa_amount; // Just in case it's missing
            
            // Add attendance data
            \$formatted['attendance'] = [
EOT;
$content = str_replace($respSearch, $respReplace, $content);

$showSearch = <<<EOT
        // Add attendance data
        \$formatted['attendance'] = [
EOT;
$showReplace = <<<EOT
        // Add extra fields
        \$formatted['thp'] = \$payroll->thp;
        \$formatted['ewa_amount'] = \$payroll->ewa_amount;
        
        // Add attendance data
        \$formatted['attendance'] = [
EOT;
$content = str_replace($showSearch, $showReplace, $content);

file_put_contents($file, $content);
echo "PayrollCellullerController patched.\n";
