<?php
require 'sobat-api/vendor/autoload.php';
use PhpOffice\PhpSpreadsheet\IOFactory;

try {
    $spreadsheet = IOFactory::load('payroll MM.xlsx');
    $sheet = $spreadsheet->getActiveSheet();
    echo "--- ROW 1 ---\n";
    $i = 0;
    echo "Total Rows: " . $sheet->getHighestRow() . "\n";
    foreach ($sheet->getRowIterator() as $row) {
        if ($i > 5) break; // Check Row 1-6 
        $cellIterator = $row->getCellIterator();
        $cellIterator->setIterateOnlyExistingCells(FALSE);
        $rowCells = [];
        $colIndex = 0;
        foreach ($cellIterator as $cell) {
            $val = $cell->getCalculatedValue(); // Use calculated value to see raw data
            $rowCells[] = "[$colIndex] $val";
            $colIndex++;
        }
        echo "Row " . ($i+1) . ": " . implode(" | ", $rowCells) . "\n";
        $i++;
    }
} catch (Exception $e) {
    echo "Error: " . $e->getMessage();
}
