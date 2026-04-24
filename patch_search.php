<?php
$dir = '/Applications/XAMPP/xamppfiles/htdocs/sobat-hr/sobat-api/app/Http/Controllers/Api';
$files = glob($dir . '/Payroll*Controller.php');

$searchBlock = "
        // Filter by search name
        if (\$request->has('search') && !empty(\$request->search)) {
            \$query->whereHas('employee', function(\$q) use (\$request) {
                \$q->where('full_name', 'like', '%' . \$request->search . '%');
            });
        }
";

foreach ($files as $file) {
    if (strpos($file, 'Payslip') !== false) continue; // skip non-payrolls
    $content = file_get_contents($file);
    
    // Check if index method exists and search not already applied
    if (strpos($content, "Filter by status") !== false && strpos($content, "Filter by search name") === false) {
        $content = str_replace(
            "// Filter by status",
            $searchBlock . "\n        // Filter by status",
            $content
        );
        file_put_contents($file, $content);
        echo "Patched: " . basename($file) . "\n";
    }
}
