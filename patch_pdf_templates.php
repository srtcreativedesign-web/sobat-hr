<?php
$files = [
    '/Applications/XAMPP/xamppfiles/htdocs/sobat-hr/sobat-api/resources/views/payslips/fnb.blade.php',
    '/Applications/XAMPP/xamppfiles/htdocs/sobat-hr/sobat-api/resources/views/payslips/mm.blade.php',
    '/Applications/XAMPP/xamppfiles/htdocs/sobat-hr/sobat-api/resources/views/payslips/ref.blade.php',
    '/Applications/XAMPP/xamppfiles/htdocs/sobat-hr/sobat-api/resources/views/payslips/wrapping.blade.php',
    '/Applications/XAMPP/xamppfiles/htdocs/sobat-hr/sobat-api/resources/views/payslips/hans.blade.php',
    '/Applications/XAMPP/xamppfiles/htdocs/sobat-hr/sobat-api/resources/views/payslips/celluller.blade.php',
    '/Applications/XAMPP/xamppfiles/htdocs/sobat-hr/sobat-api/resources/views/payslips/money_changer.blade.php'
];

foreach ($files as $file) {
    if (!file_exists($file)) continue;
    $content = file_get_contents($file);

    // 1. Remove EWA from Potongan list
    $content = preg_replace('/@if\(\$payroll->ewa_amount\s*>\s*0\).*?EWA \(Kasbon\).*?@endif/is', '', $content);
    $content = preg_replace('/@if\(\$payroll->ewa_amount\s*>\s*0\).*?Pinjaman EWA.*?@endif/is', '', $content);

    // 2. Fix Total Potongan Math (remove + $payroll->ewa_amount)
    $content = str_replace('+ $payroll->ewa_amount', '', $content);
    $content = str_replace('+$payroll->ewa_amount', '', $content);

    // 3. Replace the entire total-section
    $totalSectionPattern = '/<div class="total-section">.*?<\/div>/is';
    
    $newTotalSection = <<<EOT
    <div class="total-section">
        <table style="width: 100%;">
            <tr>
                <td style="font-size: 12px; font-weight: bold; color: #333;">TOTAL PENDAPATAN (THP)</td>
                <td style="font-size: 14px; font-weight: bold; text-align: right;">Rp {{ number_format(\$payroll->thp, 0, ',', '.') }}</td>
            </tr>
            @if(\$payroll->ewa_amount > 0)
            <tr>
                <td style="font-size: 12px; font-weight: bold; color: #d32f2f;">POTONGAN STAFBOOK (EWA)</td>
                <td style="font-size: 14px; font-weight: bold; color: #d32f2f; text-align: right;">-Rp {{ number_format(\$payroll->ewa_amount, 0, ',', '.') }}</td>
            </tr>
            @endif
            <tr>
                <td style="font-size: 14px; font-weight: bold; padding-top: 5px;">TOTAL DITRANSFER</td>
                <td style="font-size: 16px; font-weight: bold; text-align: right; padding-top: 5px;">Rp {{ number_format(isset(\$payroll->final_payment) ? \$payroll->final_payment : \$payroll->net_salary, 0, ',', '.') }}</td>
            </tr>
        </table>
    </div>
EOT;

    $content = preg_replace($totalSectionPattern, $newTotalSection, $content);
    
    file_put_contents($file, $content);
    echo "Patched: " . basename($file) . "\n";
}
