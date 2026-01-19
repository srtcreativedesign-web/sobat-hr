<?php
require __DIR__ . '/sobat-api/vendor/autoload.php';

use PhpOffice\PhpSpreadsheet\IOFactory;

$file = 'format tabel payslip (3).xlsx';

echo "=== TESTING HEADER DETECTION ===\n\n";

$reader = IOFactory::createReader('Xlsx');
$reader->setReadDataOnly(true);
$spreadsheet = $reader->load($file);
$sheet = $spreadsheet->getActiveSheet();

$highestRow = $sheet->getHighestRow();
$highestColumn = $sheet->getHighestColumn();

echo "Highest Row: $highestRow\n";
echo "Highest Column: $highestColumn\n\n";

// Test header detection logic (mimic backend)
$headerRowIndex = -1;
for ($row = 1; $row <= min(10, $highestRow); $row++) {
    echo "Checking row $row:\n";
    foreach (range('A', $highestColumn) as $col) {
        $cellValue = $sheet->getCell($col . $row)->getValue();
        if ($cellValue) {
            echo "  $col: $cellValue";
            if (stripos($cellValue, 'Nama Karyawan') !== false) {
                echo " ✓ FOUND!";
                $headerRowIndex = $row;
            }
            echo "\n";
        }
    }
    if ($headerRowIndex !== -1) {
        break;
    }
    echo "\n";
}

echo "\nHeader Row Index: $headerRowIndex\n";

if ($headerRowIndex === -1) {
    echo "❌ ERROR: Nama Karyawan not found!\n";
} else {
    echo "✅ Header found at row $headerRowIndex\n";
}
