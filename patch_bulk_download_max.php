<?php
$file = '/Applications/XAMPP/xamppfiles/htdocs/sobat-hr/sobat-api/app/Http/Controllers/Api/PayrollController.php';
$content = file_get_contents($file);

// Add maximum to bulkDownload validation
$bulkDownloadValidationSearch = "'division' => 'required|string', // all, office, hans, fnb, mm, ref, wrapping";
$bulkDownloadValidationReplace = "'division' => 'required|string', // all, office, hans, fnb, maximum, mm, ref, wrapping, tungtau";
$content = str_replace($bulkDownloadValidationSearch, $bulkDownloadValidationReplace, $content);

// Add maximum and tungtau to processDivision switch
$switchSearch = <<<EOT
            // Switch Divisions
            if (\$division === 'all' || \$division === 'hans') {
EOT;
$switchReplace = <<<EOT
            // Switch Divisions
            if (\$division === 'all' || \$division === 'maximum') {
                \$processDivision(\App\Models\PayrollMaximum::class, 'payslips.maximum', 'Maximum600');
            }
            if (\$division === 'all' || \$division === 'tungtau') {
                \$processDivision(\App\Models\PayrollTungtau::class, 'payslips.tungtau', 'Tungtau');
            }
            if (\$division === 'all' || \$division === 'hans') {
EOT;

$content = str_replace($switchSearch, $switchReplace, $content);

file_put_contents($file, $content);
echo "bulkDownload patched for maximum and tungtau.";
