<?php
require __DIR__ . '/sobat-api/vendor/autoload.php';

use PhpOffice\PhpSpreadsheet\IOFactory;

$file = 'test_payroll_excel.xlsx';

if (!file_exists($file)) {
    die("File not found: $file\n");
}

echo "Testing Excel import logic...\n\n";

// Simulate the import() method logic
$reader = IOFactory::createReader('Xlsx');
$reader->setReadDataOnly(true); // READ CALCULATED VALUES, NOT FORMULAS
$spreadsheet = $reader->load($file);
$sheet = $spreadsheet->getActiveSheet();

$highestRow = $sheet->getHighestRow();

// Helper function to get calculated value from cell
$getCellValue = function($col, $row) use ($sheet) {
    $cell = $sheet->getCell($col . $row);
    $value = $cell->getCalculatedValue();
    
    // Clean numeric values
    if (is_numeric($value)) {
        return (float) $value;
    }
    
    // Clean string numeric values (remove currency symbols, etc)
    if (is_string($value)) {
        $cleaned = preg_replace('/[^0-9\.\,\-]/', '', $value);
        if ($cleaned !== '' && is_numeric($cleaned)) {
            return (float) $cleaned;
        }
        return $value; // Return as string if not numeric
    }
    
    return $value ?? 0;
};

// Detect header row
$headerRowIndex = -1;
for ($row = 1; $row <= min(10, $highestRow); $row++) {
    $cellValue = $sheet->getCell('B' . $row)->getValue();
    if (stripos($cellValue, 'Nama Karyawan') !== false) {
        $headerRowIndex = $row;
        break;
    }
}

echo "Header row found at: Row $headerRowIndex\n";
echo "Highest row: $highestRow\n\n";

// Test data row (row 4)
$row = 4;

echo "=== TESTING ROW $row ===\n\n";

$employeeName = $getCellValue('B', $row);
$basicSalary = $getCellValue('K', $row);

$kehadiranAllowance = $getCellValue('M', $row);
$transportAllowance = $getCellValue('O', $row);
$healthAllowance = $getCellValue('Q', $row);
$positionAllowance = $getCellValue('R', $row);

$overtimeHours = $getCellValue('U', $row);
$overtimePay = $getCellValue('V', $row);

$holidayAllowance = $getCellValue('W', $row);
$adjustment = $getCellValue('X', $row);

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

echo "Employee Name: $employeeName\n";
echo "Basic Salary: " . number_format($basicSalary, 0, ',', '.') . "\n\n";

echo "Allowances:\n";
echo "  - Kehadiran: " . number_format($kehadiranAllowance, 0, ',', '.') . "\n";
echo "  - Transport: " . number_format($transportAllowance, 0, ',', '.') . "\n";
echo "  - Health: " . number_format($healthAllowance, 0, ',', '.') . "\n";
echo "  - Position: " . number_format($positionAllowance, 0, ',', '.') . "\n";
echo "  Total Allowances: " . number_format($kehadiranAllowance + $transportAllowance + $healthAllowance + $positionAllowance, 0, ',', '.') . "\n\n";

echo "Overtime:\n";
echo "  - Hours: $overtimeHours\n";
echo "  - Pay: " . number_format($overtimePay, 0, ',', '.') . "\n\n";

echo "Other Income:\n";
echo "  - Holiday Allowance: " . number_format($holidayAllowance, 0, ',', '.') . "\n";
echo "  - Adjustment: " . number_format($adjustment, 0, ',', '.') . "\n\n";

echo "FORMULA RESULTS:\n";
echo "  ✓ Total Gaji (Y): " . number_format($totalGaji, 0, ',', '.') . " (EXPECTED: 5.750.000)\n\n";

echo "Deductions:\n";
echo "  - Absen: " . number_format($absen, 0, ',', '.') . "\n";
echo "  - Terlambat: " . number_format($terlambat, 0, ',', '.') . "\n";
echo "  - Selisih SO: " . number_format($selisihSO, 0, ',', '.') . "\n";
echo "  - Pinjaman (EWA): " . number_format($pinjaman, 0, ',', '.') . "\n";
echo "  - Adm Bank (EWA): " . number_format($admBank, 0, ',', '.') . "\n";
echo "  - BPJS TK: " . number_format($bpjsTK, 0, ',', '.') . "\n";
echo "  ✓ Total Deductions (AG): " . number_format($totalDeductions, 0, ',', '.') . " (EXPECTED: 509.500)\n\n";

echo "FINAL CALCULATIONS:\n";
echo "  ✓ Grand Total (AH): " . number_format($grandTotal, 0, ',', '.') . " (EXPECTED: 5.240.500)\n";
echo "  - EWA (AI): " . number_format($ewa, 0, ',', '.') . "\n";
echo "  ✓ PAYROLL / NET SALARY (AJ): " . number_format($netSalary, 0, ',', '.') . " (EXPECTED: 4.723.000)\n\n";

// Verify
$allCorrect = true;
if ($totalGaji != 5750000) {
    echo "❌ ERROR: Total Gaji mismatch! Expected 5750000, got $totalGaji\n";
    $allCorrect = false;
}
if ($totalDeductions != 509500) {
    echo "❌ ERROR: Total Deductions mismatch! Expected 509500, got $totalDeductions\n";
    $allCorrect = false;
}
if ($grandTotal != 5240500) {
    echo "❌ ERROR: Grand Total mismatch! Expected 5240500, got $grandTotal\n";
    $allCorrect = false;
}
if ($netSalary != 4723000) {
    echo "❌ ERROR: Net Salary mismatch! Expected 4723000, got $netSalary\n";
    $allCorrect = false;
}

if ($allCorrect) {
    echo "✅ ALL FORMULA COLUMNS READ CORRECTLY!\n";
    echo "✅ Import logic is working as expected.\n";
} else {
    echo "\n⚠️  Some values don't match. Please review the logic.\n";
}
