<?php

require 'vendor/autoload.php';

use PhpOffice\PhpSpreadsheet\IOFactory;

// Adjust path as needed
$inputFileName = dirname(__DIR__) . '/Payroll Wrapping.xlsx';

try {
    $spreadsheet = IOFactory::load($inputFileName);
    $sheet = $spreadsheet->getActiveSheet();
    
    echo "Reading first 10 rows to find headers...\n\n";
    
    for ($row = 1; $row <= 10; $row++) {
        $cellIterator = $sheet->getRowIterator($row)->current()->getCellIterator();
        $cellIterator->setIterateOnlyExistingCells(false);
        
        $data = [];
        foreach ($cellIterator as $cell) {
            $data[] = $cell->getValue();
        }
        
        echo "Row $row: " . implode(" | ", array_filter($data, function($x) { return !empty($x); })) . "\n";
    }
    
    // Also try to identify column letters for key fields
    echo "\n\nColumn Mapping Preview (Row with 'Nama'):\n";
    foreach ($sheet->getRowIterator() as $row) {
        $cellIterator = $row->getCellIterator();
        $cellIterator->setIterateOnlyExistingCells(false);
        
        $found = false;
        foreach ($cellIterator as $cell) {
            if (stripos($cell->getValue(), 'Nama') !== false) {
                $found = true;
                break;
            }
        }
        
        if ($found) {
            foreach ($cellIterator as $cell) {
                if (!empty($cell->getValue())) {
                    echo $cell->getColumn() . ": " . $cell->getValue() . "\n";
                }
            }
            break; 
        }
    }

} catch (Exception $e) {
    echo 'Error loading file: ', $e->getMessage();
}
