<?php
$file = '/Applications/XAMPP/xamppfiles/htdocs/sobat-hr/sobat-api/app/Http/Controllers/Api/PayrollMaximumController.php';
$content = file_get_contents($file);

// Add to index
$indexSearch = "            // Add attendance data\n            \$formatted['attendance'] = [";
$indexReplace = "            // Add extra fields\n            \$formatted['ewa_amount'] = \$payroll->stafbook_loan;\n            \$formatted['thp'] = \$payroll->thp;\n            \n            // Add attendance data\n            \$formatted['attendance'] = [";
$content = str_replace($indexSearch, $indexReplace, $content);

// Add to show
$showSearch = "        // Add attendance data\n        \$formatted['attendance'] = [";
$showReplace = "        // Add extra fields\n        \$formatted['ewa_amount'] = \$payroll->stafbook_loan;\n        \$formatted['thp'] = \$payroll->thp;\n        \n        // Add attendance data\n        \$formatted['attendance'] = [";
$content = str_replace($showSearch, $showReplace, $content);

file_put_contents($file, $content);
echo "Controller patched.";
