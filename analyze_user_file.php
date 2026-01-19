<?php
require __DIR__ . '/sobat-api/vendor/autoload.php';

use PhpOffice\PhpSpreadsheet\IOFactory;

$file = 'format tabel payslip (3).xlsx';

echo "=== DETAILED ANALYSIS: $file ===\n\n";

$reader = IOFactory::createReader('Xlsx');
$reader->setReadDataOnly(true);
$spreadsheet = $reader->load($file);
$sheet = $spreadsheet->getActiveSheet();

$getCellValue = function($col, $row) use ($sheet) {
    $cell = $sheet->getCell($col . $row);
    $value = $cell->getCalculatedValue();
    
    if (is_numeric($value)) {
        return (float) $value;
    }
    
    if (is_string($value)) {
        $cleaned = preg_replace('/[^0-9\.\,\-]/', '', $value);
        if ($cleaned !== '' && is_numeric($cleaned)) {
            return (float) $cleaned;
        }
        return $value;
    }
    
    return $value ?? 0;
};

// Row 2 - Headers
echo "=== ROW 2 (HEADERS) ===\n";
$allCols = range('A', 'AJ');
foreach ($allCols as $col) {
    $value = $sheet->getCell($col . '2')->getValue();
    if ($value) {
        echo "$col: $value\n";
    }
}

echo "\n=== ROW 3 (UNITS) ===\n";
foreach ($allCols as $col) {
    $value = $sheet->getCell($col . '3')->getValue();
    if ($value) {
        echo "$col: $value\n";
    }
}

echo "\n=== ROW 4 (DATA - ALL COLUMNS) ===\n";
foreach ($allCols as $col) {
    $value = $getCellValue($col, 4);
    if ($value !== 0 && $value !== '' && $value !== null) {
        if (is_numeric($value)) {
            echo sprintf("%-3s: %15s", $col, number_format($value, 0, ',', '.'));
            
            // Show column name
            $header = $sheet->getCell($col . '2')->getValue();
            if ($header) {
                echo "  ($header)";
            }
            echo "\n";
        } else {
            echo sprintf("%-3s: %s\n", $col, $value);
        }
    }
}

// Test mapping with current logic
echo "\n=== TESTING CURRENT MAPPING ===\n";
$row = 4;

$employeeName = $getCellValue('B', $row);
$basicSalary = $getCellValue('K', $row);
$kehadiranAllowance = $getCellValue('M', $row);
$transportAllowance = $getCellValue('O', $row);
$healthAllowance = $getCellValue('Q', $row);
$positionAllowance = $getCellValue('R', $row);
$overtimePay = $getCellValue('V', $row);
$holidayAllowance = $getCellValue('W', $row);
$totalGaji = $getCellValue('Y', $row);

$absen = $getCellValue('AA', $row);
$terlambat = $getCellValue('AB', $row);
$selisihSO = $getCellValue('AC', $row);
$pinjaman = $getCellValue('AD', $row);
$admBank = $getCellValue('AE', $row);
$bpjsTK = $getCellValue('AF', $row);

$totalDeductions = $getCellValue('AG', $row);
$grandTotal = $getCellValue('AH', $row);
$ewa = $getCellValue('AI', $row);
$netSalary = $getCellValue('AJ', $row);

echo "Employee: $employeeName\n";
echo "Basic Salary (K): " . number_format($basicSalary, 0, ',', '.') . "\n";
echo "Kehadiran (M): " . number_format($kehadiranAllowance, 0, ',', '.') . "\n";
echo "Transport (O): " . number_format($transportAllowance, 0, ',', '.') . "\n";
echo "Health (Q): " . number_format($healthAllowance, 0, ',', '.') . "\n";
echo "Position (R): " . number_format($positionAllowance, 0, ',', '.') . "\n";
echo "Overtime (V): " . number_format($overtimePay, 0, ',', '.') . "\n";
echo "Holiday (W): " . number_format($holidayAllowance, 0, ',', '.') . "\n";
echo "\n";
echo "Total Gaji (Y): " . number_format($totalGaji, 0, ',', '.') . "\n";
echo "\n";
echo "Deductions:\n";
echo "  Absen (AA): " . number_format($absen, 0, ',', '.') . "\n";
echo "  Terlambat (AB): " . number_format($terlambat, 0, ',', '.') . "\n";
echo "  Selisih SO (AC): " . number_format($selisihSO, 0, ',', '.') . "\n";
echo "  Pinjaman (AD): " . number_format($pinjaman, 0, ',', '.') . "\n";
echo "  Adm Bank (AE): " . number_format($admBank, 0, ',', '.') . "\n";
echo "  BPJS TK (AF): " . number_format($bpjsTK, 0, ',', '.') . "\n";
echo "\n";
echo "Total Deductions (AG): " . number_format($totalDeductions, 0, ',', '.') . "\n";
echo "Grand Total (AH): " . number_format($grandTotal, 0, ',', '.') . "\n";
echo "EWA (AI): " . number_format($ewa, 0, ',', '.') . "\n";
echo "Net Salary / Payroll (AJ): " . number_format($netSalary, 0, ',', '.') . "\n";

$allowancesTotal = $kehadiranAllowance + $transportAllowance + $healthAllowance + $positionAllowance;
echo "\n=== CALCULATED VALUES ===\n";
echo "Allowances Sum: " . number_format($allowancesTotal, 0, ',', '.') . "\n";
echo "Gross (Manual): " . number_format($basicSalary + $allowancesTotal + $overtimePay + $holidayAllowance, 0, ',', '.') . "\n";
echo "Gross (Excel Y): " . number_format($totalGaji, 0, ',', '.') . "\n";
