<?php
$dir = '/Applications/XAMPP/xamppfiles/htdocs/sobat-hr/sobat-api/app/Http/Controllers/Api/';
$files = glob($dir . 'Payroll*.php');

foreach ($files as $file) {
    if (strpos($file, 'ThpCalculator') !== false) continue;
    $content = file_get_contents($file);
    
    // Pattern to match the "if ($existing) { ... return error ... } else create"
    // We can replace the if ($existing) block.
    
    // A regex to match:
    // if ($existing) {
    //    ... already exists ...
    //    continue;
    // }
    $content = preg_replace('/if\s*\(\$existing\)\s*\{\s*\$errors\[\].*?already exists.*?continue;\s*\}/s', '
                $payrollData = array_merge($row, [
                    \'employee_id\' => $employee->id,
                    \'status\' => \'draft\'
                ]);
                
                if ($existing) {
                    $existing->update($payrollData);
                } else {', $content);
                
    // And now we need to close the else block after the create() statement.
    // PayrollWrapping::create(...)
    // Let's replace the Model::create(...) with Model::create($payrollData); }
    $content = preg_replace('/([A-Za-z0-9]+)::create\(\s*array_merge\(\$row.*?employee_id.*?\]\)\s*\);/s', '$1::create($payrollData);
                }', $content);
                
    file_put_contents($file, $content);
    echo "Updated $file\n";
}
