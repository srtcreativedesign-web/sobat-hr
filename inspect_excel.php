<?php

require 'sobat-api/vendor/autoload.php';

use PhpOffice\PhpSpreadsheet\IOFactory;

$filePath = 'payslip hans.xlsx';

if (!file_exists($filePath)) {
    die("File not found: $filePath\n");
}

try {
    $reader = IOFactory::createReader('Xlsx');
    $reader->setReadDataOnly(true);
    $spreadsheet = $reader->load($filePath);
    $sheet = $spreadsheet->getActiveSheet();
    
    echo "Inspecting $filePath\n";
    
    // Check first 10 rows for header
    $highestRow = min(10, $sheet->getHighestRow());
    $highestColumn = $sheet->getHighestColumn();
    
    echo "Scanning first $highestRow rows for header...\n";
    
    $headerRowIndex = -1;
    
    for ($row = 1; $row <= $highestRow; $row++) {
        echo "Row $row: ";
        $rowData = [];
        $cellIterator = $sheet->getRowIterator($row, $row)->current()->getCellIterator('AA', 'AZ'); // Scan AA-AZ
        $cellIterator->setIterateOnlyExistingCells(false);
        
        foreach ($cellIterator as $cell) {
             $val = $cell->getValue();
             if ($val) $rowData[] = $val;
             echo "[" . $cell->getColumn() . "]: $val | ";
             
             if ($val && (stripos($val, 'Nama') !== false || stripos($val, 'No') !== false)) {
                 if ($headerRowIndex === -1) $headerRowIndex = $row;
             }
        }
        echo "\n";
    }
    
    if ($headerRowIndex !== -1) {
        echo "\nFound Header candidate at Row $headerRowIndex\n";
        // Detailed column listing
        $cellIterator = $sheet->getRowIterator($headerRowIndex, $headerRowIndex)->current()->getCellIterator('A', 'AZ');
        $cellIterator->setIterateOnlyExistingCells(false);
        
        foreach ($cellIterator as $cell) {
            echo "Col " . $cell->getColumn() . ": " . $cell->getValue() . "\n";
        }
    }

} catch (Exception $e) {
    echo "Error: " . $e->getMessage() . "\n";
}
