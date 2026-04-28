<?php
$file = '/Applications/XAMPP/xamppfiles/htdocs/sobat-hr/sobat-api/app/Http/Controllers/Api/PayrollTungtauController.php';
$content = file_get_contents($file);
$content = str_replace("'Pinjaman' => \$payroll->deduction_loan,", "'Potongan Stafbook' => \$payroll->deduction_loan,", $content);
file_put_contents($file, $content);
echo "Patched Stafbook";
