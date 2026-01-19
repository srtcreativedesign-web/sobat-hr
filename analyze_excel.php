<?php
require __DIR__ . '/sobat-api/vendor/autoload.php';

use PhpOffice\PhpSpreadsheet\IOFactory;

$files = [
    'format tabel payslip (1).xlsx',
    'sobat-api/storage/app/private/imports/format tabel payslip (3).xlsx',
];

foreach ($files as $file) {
    if (!file_exists($file)) {
        echo "File not found: $file\n\n";
        continue;
    }
    
    echo "\n================== ANALYZING: $file ==================\n\n";
    
    try {
        $reader = IOFactory::createReader('Xlsx');
        $reader->setReadDataOnly(true); // Read calculated values, not formulas
        $spreadsheet = $reader->load($file);
        $sheet = $spreadsheet->getActiveSheet();
        
        $highestRow = $sheet->getHighestRow();
        $highestColumn = $sheet->getHighestColumn();
        
        echo "Rows: $highestRow\n";
        echo "Columns: $highestColumn\n\n";
        
        echo "=== ROW 1 (Title/Header) ===\n";
        for ($col = 'A'; $col <= 'AH'; $col++) {
            $value = $sheet->getCell($col . '1')->getCalculatedValue();
            if ($value !== null && $value !== '') {
                echo "$col: $value\n";
            }
        }
        
        echo "\n=== ROW 2 (Column Headers) ===\n";
        for ($col = 'A'; $col <= 'AH'; $col++) {
            $value = $sheet->getCell($col . '2')->getCalculatedValue();
            if ($value !== null && $value !== '') {
                echo "$col: $value\n";
            }
        }
        
        echo "\n=== ROW 3 (Units/Types) ===\n";
        for ($col = 'A'; $col <= 'AH'; $col++) {
            $value = $sheet->getCell($col . '3')->getCalculatedValue();
            if ($value !== null && $value !== '') {
                echo "$col: $value\n";
            }
        }
        
        if ($highestRow >= 4) {
            echo "\n=== ROW 4 (First Data Row) ===\n";
            for ($col = 'A'; $col <= 'AH'; $col++) {
                $cell = $sheet->getCell($col . '4');
                $value = $cell->getCalculatedValue();
                if ($value !== null && $value !== '') {
                    echo "$col: $value\n";
                }
            }
        }
        
        // Check if cells have formulas
        echo "\n=== FORMULA DETECTION (Row 4) ===\n";
        if ($highestRow >= 4) {
            for ($col = 'A'; $col <= 'AH'; $col++) {
                $cell = $sheet->getCell($col . '4');
                if ($cell->getValue() !== null) {
                    $cellValue = $cell->getValue();
                    $isFormula = is_string($cellValue) && substr($cellValue, 0, 1) === '=';
                    if ($isFormula) {
                        $calculatedValue = $cell->getCalculatedValue();
                        echo "$col: FORMULA => Result: $calculatedValue\n";
                    }
                }
            }
        }
        
    } catch (Exception $e) {
        echo "Error: " . $e->getMessage() . "\n";
    }
}
