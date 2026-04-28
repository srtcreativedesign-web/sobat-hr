<?php
$file = '/Applications/XAMPP/xamppfiles/htdocs/sobat-hr/sobat-api/app/Http/Controllers/Api/PayrollWrappingController.php';
$content = file_get_contents($file);

// 1. Mapping
$mapSearch = <<<EOT
                'potongan' => 'deductions_header',
                'grand total' => 'net_salary',
                'pinjaman ewa' => 'ewa_amount',
                'payroll' => 'payroll_final',
EOT;
$mapReplace = <<<EOT
                'potongan' => 'deductions_header',
                'grand total' => 'thp',
                'pinjaman ewa' => 'ewa_amount',
                'payroll' => 'net_salary',
EOT;
$content = str_replace($mapSearch, $mapReplace, $content);

// 2. Import array
$impSearch = <<<EOT
                    // Finals
                    'net_salary' => \$getMappedValue('net_salary', \$row),
                    'ewa_amount' => \$getMappedValue('ewa_amount', \$row),
EOT;
$impReplace = <<<EOT
                    // Finals
                    'thp' => \$getMappedValue('thp', \$row),
                    'net_salary' => \$getMappedValue('net_salary', \$row),
                    'ewa_amount' => \$getMappedValue('ewa_amount', \$row),
EOT;
$content = str_replace($impSearch, $impReplace, $content);

// 3. Response logic
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
echo "PayrollWrappingController patched.\n";
