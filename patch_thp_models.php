<?php
$models = [
    '/Applications/XAMPP/xamppfiles/htdocs/sobat-hr/sobat-api/app/Models/PayrollFnb.php',
    '/Applications/XAMPP/xamppfiles/htdocs/sobat-hr/sobat-api/app/Models/PayrollMm.php',
    '/Applications/XAMPP/xamppfiles/htdocs/sobat-hr/sobat-api/app/Models/PayrollRef.php',
    '/Applications/XAMPP/xamppfiles/htdocs/sobat-hr/sobat-api/app/Models/PayrollWrapping.php',
    '/Applications/XAMPP/xamppfiles/htdocs/sobat-hr/sobat-api/app/Models/PayrollHans.php',
    '/Applications/XAMPP/xamppfiles/htdocs/sobat-hr/sobat-api/app/Models/PayrollCelluller.php',
    '/Applications/XAMPP/xamppfiles/htdocs/sobat-hr/sobat-api/app/Models/PayrollMoneyChanger.php'
];

foreach ($models as $file) {
    if (file_exists($file)) {
        $content = file_get_contents($file);
        
        // Find 'net_salary', and add 'thp', before or after it
        if (strpos($content, "'thp',") === false) {
            $content = str_replace("'net_salary',", "'net_salary',\n        'thp',", $content);
            // Money Changer uses 'net_salary' too.
            // If it doesn't have net_salary but final_payment
            if (strpos($content, "'final_payment',") !== false && strpos($content, "'net_salary',") === false) {
                $content = str_replace("'final_payment',", "'final_payment',\n        'thp',", $content);
            }
            file_put_contents($file, $content);
            echo "Patched: " . basename($file) . "\n";
        }
    }
}
