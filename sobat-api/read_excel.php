<?php
require __DIR__.'/vendor/autoload.php';
$inputFileName = '/Applications/XAMPP/xamppfiles/htdocs/sobat-hr/debug/excel/format payslip retail (1).xlsx';
$spreadsheet = \PhpOffice\PhpSpreadsheet\IOFactory::load($inputFileName);
$worksheet = $spreadsheet->getActiveSheet();
$rows = [];
foreach ($worksheet->getRowIterator() as $row) {
    $cellIterator = $row->getCellIterator();
    $cellIterator->setIterateOnlyExistingCells(false); 
    $cells = [];
    foreach ($cellIterator as $cell) {
        $cells[] = $cell->getCalculatedValue();
    }
    $rows[] = implode(" | ", $cells);
    if ($row->getRowIndex() > 15) break; // Read first 15 rows
}
echo implode("\n", $rows);
