<?php
require __DIR__ . '/sobat-api/vendor/autoload.php';

use PhpOffice\PhpSpreadsheet\IOFactory;

$file = 'format tabel payslip (3).xlsx';

echo "=== TESTING FIXED HEADER DETECTION ===\n\n";

$reader = IOFactory::createReader('Xlsx');
$reader->setReadDataOnly(true);
$spreadsheet = $reader->load($file);
$sheet = $spreadsheet->getActiveSheet();

$highestRow = $sheet->getHighestRow();
$highestColumn = $sheet->getHighestColumn();

// NEW FIXED LOGIC
$headerRowIndex = -1;
for ($row = 1; $row <= min(10, $highestRow); $row++) {
    foreach (range('A', $highestColumn) as $col) {
        $cell = $sheet->getCell($col . $row);
        $cellValue = $cell->getValue();  // This should work with merged cells
        
        if ($cellValue && stripos($cellValue, 'Nama Karyawan') !== false) {
            $headerRowIndex = $row;
            echo "✅ FOUND at row $row, column $col: '$cellValue'\n";
            break 2;
        }
    }
}

if ($headerRowIndex === -1) {
    echo "❌ NOT FOUND\n";
} else {
    echo "\n✅ Header Row Index: $headerRowIndex\n";
}
