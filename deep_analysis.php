<?php
require __DIR__ . '/sobat-api/vendor/autoload.php';

use PhpOffice\PhpSpreadsheet\IOFactory;

$file = 'format tabel payslip (3).xlsx';

echo "=== DEEP ANALYSIS ===\n\n";

$reader = IOFactory::createReader('Xlsx');
$reader->setReadDataOnly(false); // Try reading formulas too
$spreadsheet = $reader->load($file);
$sheet = $spreadsheet->getActiveSheet();

echo "Row 2 - ALL COLUMNS (A-AJ):\n";
foreach (range('A', 'AJ') as $col) {
    $cell = $sheet->getCell($col . '2');
    $value = $cell->getValue();
    $type = $cell->getDataType();
    
    if ($value !== null && $value !== '') {
        echo "$col: [$type] $value\n";
    }
}

echo "\nRow 2 Column B specifically:\n";
$cellB = $sheet->getCell('B2');
echo "Value: '" . $cellB->getValue() . "'\n";
echo "Formatted: '" . $cellB->getFormattedValue() . "'\n";
echo "Data Type: " . $cellB->getDataType() . "\n";

// Try with merged cell check
echo "\nMerged cells check:\n";
foreach ($sheet->getMergeCells() as $mergedRange) {
    echo "Merged: $mergedRange\n";
}

// Check if column B2 is part of merged cell
if ($sheet->getCell('B2')->isMergeRangeValueCell()) {
    echo "B2 is a merged cell!\n";
}
