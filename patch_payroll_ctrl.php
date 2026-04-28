<?php
$file = '/Applications/XAMPP/xamppfiles/htdocs/sobat-hr/sobat-api/app/Http/Controllers/Api/PayrollController.php';
$content = file_get_contents($file);

// Add 'maximum' to validation
$content = str_replace("'division' => 'required|in:fnb,tungtau,mm,ref,wrapping,hans,cellular,money_changer',", "'division' => 'required|in:fnb,tungtau,maximum,mm,ref,wrapping,hans,cellular,money_changer',", $content);

// Add model mapping
$mappingSearch = <<<EOT
            'tungtau' => \App\Models\PayrollTungtau::class,
            'mm' => \App\Models\PayrollMm::class,
EOT;
$mappingReplace = <<<EOT
            'tungtau' => \App\Models\PayrollTungtau::class,
            'maximum' => \App\Models\PayrollMaximum::class,
            'mm' => \App\Models\PayrollMm::class,
EOT;
$content = str_replace($mappingSearch, $mappingReplace, $content);

file_put_contents($file, $content);
echo "PayrollController patched.";
