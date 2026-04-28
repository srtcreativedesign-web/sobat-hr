<?php
$file = '/Applications/XAMPP/xamppfiles/htdocs/sobat-hr/sobat-api/app/Http/Controllers/Api/PayrollHansController.php';
$content = file_get_contents($file);
echo substr($content, strpos($content, "'pinjaman ewa' => 'ewa_amount',"), 200);
