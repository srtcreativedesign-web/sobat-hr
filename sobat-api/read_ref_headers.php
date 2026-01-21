<?php
require __DIR__ . '/vendor/autoload.php';

use PhpOffice\PhpSpreadsheet\IOFactory;

try {
    $inputFileName = __DIR__ . '/../payslip REF.xlsx';
    $spreadsheet = IOFactory::load($inputFileName);
    $worksheet = $spreadsheet->getActiveSheet();
    
    // Read the first 5 rows to find headers
    $rows = [];
    foreach ($worksheet->getRowIterator() as $row) {
        $cellIterator = $row->getCellIterator();
        $cellIterator->setIterateOnlyExistingCells(FALSE);
        $rowData = [];
        foreach ($cellIterator as $cell) {
            $rowData[] = $cell->getValue();
        }
        $rows[] = $rowData;
        if (count($rows) >= 5) break; 
    }
    
    echo json_encode($rows, JSON_PRETTY_PRINT);

} catch (Exception $e) {
    echo 'Error: ' . $e->getMessage();
}
