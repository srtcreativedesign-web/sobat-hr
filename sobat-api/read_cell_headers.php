<?php
require 'vendor/autoload.php';

use PhpOffice\PhpSpreadsheet\IOFactory;

$inputFile = '/Applications/XAMPP/xamppfiles/htdocs/sobat-hr/payslip cell.xlsx'; 
$reader = IOFactory::createReaderForFile($inputFile);
$reader->setReadDataOnly(true);
$spreadsheet = $reader->load($inputFile);
$sheet = $spreadsheet->getActiveSheet();

echo "Highest Row: " . $sheet->getHighestRow() . "\n";
echo "Highest Column: " . $sheet->getHighestColumn() . "\n\n";

// Read first 10 rows to find header
$limit = min(10, $sheet->getHighestRow());
for ($row = 1; $row <= $limit; $row++) {
    echo "Row $row: ";
    $cellIterator = $sheet->getRowIterator($row)->current()->getCellIterator();
    $cellIterator->setIterateOnlyExistingCells(false);
    foreach ($cellIterator as $cell) {
        echo "[" . $cell->getColumn() . "]" . $cell->getValue() . " | ";
    }
    echo "\n";
}
