<?php
$file = '/Applications/XAMPP/xamppfiles/htdocs/sobat-hr/sobat-api/app/Http/Controllers/Api/PayrollRefController.php';
$content = file_get_contents($file);

$impSearch = <<<EOT
                    'net_salary' => \$getMappedValue('net_salary', \$row),
EOT;
$impReplace = <<<EOT
                    'net_salary' => \$getMappedValue('net_salary', \$row),
                    'thp' => (float)\$getMappedValue('net_salary', \$row) + (float)\$getMappedValue('ewa_amount', \$row),
EOT;
$content = str_replace($impSearch, $impReplace, $content);

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
echo "PayrollRefController patched.\n";
