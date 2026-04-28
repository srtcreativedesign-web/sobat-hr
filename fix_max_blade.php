<?php
$file = '/Applications/XAMPP/xamppfiles/htdocs/sobat-hr/sobat-api/resources/views/payslips/maximum.blade.php';
$content = file_get_contents($file);

// Remove the incorrect insertion
$badBlock = <<<EOT
    <div class="section-title">PENDAPATAN (INCOME)</div>
    <table class="details-table">
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
$content = str_replace($badBlock, "    <div class=\"section-title\">PENDAPATAN (INCOME)</div>\n    <table class=\"details-table\">", $content);

// Apply correctly at the end
$correctSearch = <<<EOT
        <tr class="total-row grand-total">
            <td>TOTAL GAJI DITERIMA</td>
            <td class="amount">Rp {{ number_format(\$payroll->net_salary, 0, ',', '.') }}</td>
        </tr>
    </table>
EOT;

$correctReplace = <<<EOT
        <tr class="total-row">
            <td>TOTAL GAJI & BONUS (THP)</td>
            <td class="amount">Rp {{ number_format(\$payroll->thp, 0, ',', '.') }}</td>
        </tr>
        @if(isset(\$payroll->stafbook_loan) && \$payroll->stafbook_loan > 0)
        <tr class="total-row text-red" style="color: #e53e3e;">
            <td>POTONGAN PINJAMAN STAFBOOK</td>
            <td class="amount">-Rp {{ number_format(\$payroll->stafbook_loan, 0, ',', '.') }}</td>
        </tr>
        @endif
        <tr class="total-row grand-total">
            <td>TOTAL GAJI DITRANSFER</td>
            <td class="amount">Rp {{ number_format(\$payroll->net_salary, 0, ',', '.') }}</td>
        </tr>
    </table>
EOT;

$content = str_replace($correctSearch, $correctReplace, $content);
file_put_contents($file, $content);
echo "Fixed!";
