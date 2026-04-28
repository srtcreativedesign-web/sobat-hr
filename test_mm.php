<?php
$file = '/Applications/XAMPP/xamppfiles/htdocs/sobat-hr/sobat-api/app/Http/Controllers/Api/PayrollMmController.php';
$content = file_get_contents($file);
echo substr($content, strpos($content, "'ewa_amount' => \$getMappedValue('ewa_amount', \$row),"), 400);
