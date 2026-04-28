<?php
$files = [
    '/Applications/XAMPP/xamppfiles/htdocs/sobat-hr/sobat-api/app/Http/Controllers/Api/PayrollHansController.php',
    '/Applications/XAMPP/xamppfiles/htdocs/sobat-hr/sobat-api/app/Http/Controllers/Api/PayrollMmController.php'
];

foreach ($files as $file) {
    $content = file_get_contents($file);

    // Look for where we extract ewa_amount
    $impSearch = <<<EOT
                    'ewa_amount' => \$getMappedValue('ewa_amount', \$row),
                    'thp' => (float)\$getMappedValue('net_salary', \$row) + (float)\$getMappedValue('ewa_amount', \$row),
EOT;
    $impReplace = <<<EOT
                    'ewa_amount' => \$getMappedValue('ewa_amount', \$row) ?: \$getMappedValue('deduction_loan', \$row),
                    'thp' => (float)\$getMappedValue('net_salary', \$row) + ((float)\$getMappedValue('ewa_amount', \$row) ?: (float)\$getMappedValue('deduction_loan', \$row)),
EOT;
    $content = str_replace($impSearch, $impReplace, $content);

    // Also need to clear deduction_loan so it doesn't show up twice (in EWA and in standard deductions)
    // Wait, if we clear it, total deductions won't match. But we removed EWA from total deductions in frontend?
    // Actually in frontend we don't recalculate total deductions, we just print the number from backend.
    // If backend sends deduction_total = 742500, and EWA = 500000, the user will see Potongan=742500 and EWA=500000.
    // But THP = Net Salary + EWA. 
    // Net Salary = Total Pemasukan - 742500.
    // THP = Total Pemasukan - 742500 + 500000 = Total Pemasukan - 242500.
    // This is mathematically PERFECT.
    // But in the "Potongan" list, the user will still see "Pinjaman: 500000" in the generic list AND EWA: 500000 at the bottom.
    // We already removed EWA from generic list if key contains "ewa", "stafbook", "pinjaman"!
    // Let me check my page.tsx patch... did I remove it?
    
    file_put_contents($file, $content);
    echo "Patched EWA logic in " . basename($file) . "\n";
}
