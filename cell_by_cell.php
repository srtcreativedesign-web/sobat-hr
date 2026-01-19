<?php
require __DIR__ . '/sobat-api/vendor/autoload.php';

use PhpOffice\PhpSpreadsheet\IOFactory;

$file = 'format tabel payslip (3).xlsx';

echo "=== CELL BY CELL CHECK ===\n\n";

$reader = IOFactory::createReader('Xlsx');
$reader->setReadDataOnly(true);
$spreadsheet = $reader->load($file);
$sheet = $spreadsheet->getActiveSheet();

// Check specific cells row 2
$cols = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K'];

echo "Row 2 cells:\n";
foreach ($cols as $col) {
    $cell = $sheet->getCell($col . '2');
    $value = $cell->getValue();
    $realValue = '';
    
    // Try different methods to get value
    try {
        $realValue = $cell->getCalculatedValue();
    } catch (Exception $e) {
        $realValue = $value;
    }
    
    echo sprintf("  %s: value='%s' real='%s' isMerged=%s\n", 
        $col, 
        $value ?: '(empty)',
        $realValue ?: '(empty)',
        $cell->isMergeRangeValueCell() ? 'YES' : 'NO'
    );
}

// Try iterating with column iterator
echo "\nUsing Column Iterator:\n";
$highestColumn = $sheet->getHighestColumn();
$columnIterator = $sheet->getRowIterator(2, 2)->current()->getCellIterator('A', $highestColumn);
$columnIterator->setIterateOnlyExistingCells(false);

foreach ($columnIterator as $cell) {
    $value = $cell->getValue();
    if ($value) {
        echo $cell->getColumn() . ": " . $value . "\n";
    }
}
