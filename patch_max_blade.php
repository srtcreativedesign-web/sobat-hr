<?php
$file = '/Applications/XAMPP/xamppfiles/htdocs/sobat-hr/sobat-api/resources/views/payslips/maximum.blade.php';
$content = file_get_contents($file);

// Replace title & company info
$content = str_replace('Slip Gaji - Tungtau', 'Slip Gaji - Maximum 600', $content);
$content = str_replace('TUNG TAU RESTAURANT', 'MAKSIMUM KOPI GD 600', $content);
$content = str_replace('Kawasan Wisata Tung Tau', 'Soekarno - Hatta', $content);
$content = str_replace('Divisi Tungtau', 'Divisi Maximum 600', $content);

// Add Insentif field after Insentif Lebaran
$insentifSearch = <<<EOT
        @if($payroll->holiday_allowance > 0)
        <tr>
            <td>Insentif Lebaran</td>
            <td class="amount">Rp {{ number_format($payroll->holiday_allowance, 0, ',', '.') }}</td>
        </tr>
        @endif
EOT;
$insentifReplace = <<<EOT
        @if($payroll->holiday_allowance > 0)
        <tr>
            <td>Insentif Lebaran</td>
            <td class="amount">Rp {{ number_format($payroll->holiday_allowance, 0, ',', '.') }}</td>
        </tr>
        @endif
        @if(isset(\$payroll->insentif) && \$payroll->insentif > 0)
        <tr>
            <td>Insentif</td>
            <td class="amount">Rp {{ number_format(\$payroll->insentif, 0, ',', '.') }}</td>
        </tr>
        @endif
EOT;
$content = str_replace($insentifSearch, $insentifReplace, $content);

// Fix the Total Section layout to include THP, Pinjaman Stafbook, and Net Salary
$totalSearch = <<<EOT
        <tr class="total-row grand-total">
            <td>TOTAL GAJI DITERIMA</td>
            <td class="amount">Rp {{ number_format(\$payroll->net_salary, 0, ',', '.') }}</td>
        </tr>
EOT;
$totalReplace = <<<EOT
        <tr class="total-row">
            <td>TOTAL GAJI & BONUS (THP)</td>
            <td class="amount">Rp {{ number_format(\$payroll->thp, 0, ',', '.') }}</td>
        </tr>
        @if(isset(\$payroll->stafbook_loan) && \$payroll->stafbook_loan > 0)
        <tr class="total-row text-red">
            <td>POTONGAN PINJAMAN STAFBOOK</td>
            <td class="amount">-Rp {{ number_format(\$payroll->stafbook_loan, 0, ',', '.') }}</td>
        </tr>
        @endif
        <tr class="total-row grand-total">
            <td>TOTAL GAJI DITRANSFER</td>
            <td class="amount">Rp {{ number_format(\$payroll->net_salary, 0, ',', '.') }}</td>
        </tr>
EOT;
$content = str_replace($totalSearch, $totalReplace, $content);

file_put_contents($file, $content);
echo "Blade template updated.";
