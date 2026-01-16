<?php
require 'sobat-api/vendor/autoload.php';
use PhpOffice\PhpSpreadsheet\IOFactory;

try {
    $spreadsheet = IOFactory::load('format tabel payslip (1).xlsx');
    $sheet = $spreadsheet->getActiveSheet();
    echo "--- ROW 1 ---\n";
    $i = 0;
    foreach ($sheet->getRowIterator() as $row) {
        if ($i > 5) break; 
        $cellIterator = $row->getCellIterator();
        $cellIterator->setIterateOnlyExistingCells(FALSE);
        $rowCells = [];
        foreach ($cellIterator as $cell) {
            $val = $cell->getValue();
            if ($val) $rowCells[] = $val;
        }
        if (!empty($rowCells)) {
            echo "Row " . ($i+1) . ": " . implode(" | ", $rowCells) . "\n";
        }
        $i++;
    }
} catch (Exception $e) {
    echo "Error: " . $e->getMessage();
}
