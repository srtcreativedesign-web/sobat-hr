<?php
require __DIR__ . '/sobat-api/vendor/autoload.php';

use PhpOffice\PhpSpreadsheet\IOFactory;

$file = 'format tabel payslip (3).xlsx';

echo "=== COMPLETE FnB PAYROLL STRUCTURE ANALYSIS ===\n\n";

$reader = IOFactory::createReader('Xlsx');
$reader->setReadDataOnly(true);
$spreadsheet = $reader->load($file);
$sheet = $spreadsheet->getActiveSheet();

// Get all column headers
echo "COLUMN MAPPING (Row 2 & 3):\n";
echo str_repeat("=", 80) . "\n";

$headerRow = $sheet->getRowIterator(2, 2)->current();
$cellIterator = $headerRow->getCellIterator('A');
$cellIterator->setIterateOnlyExistingCells(false);

$columns = [];
foreach ($cellIterator as $cell) {
    $col = $cell->getColumn();
    $header = $cell->getValue();
    $units = $sheet->getCell($col . '3')->getValue();
    
    if ($header || $units) {
        $columns[$col] = [
            'header' => $header ?: '',
            'units' => $units ?: '',
        ];
        
        $display = sprintf("%-3s | %-30s | %s", $col, $header, $units);
        echo $display . "\n";
    }
    
    // Stop at empty columns for a while
    if ($col > 'AJ' && !$header && !$units) {
        break;
    }
}

echo "\n" . str_repeat("=", 80) . "\n";
echo "\n=== DATA SAMPLE (Row 4) ===\n";

$getCellValue = function($col, $row) use ($sheet) {
    $cell = $sheet->getCell($col . $row);
    $value = $cell->getCalculatedValue();
    
    if (is_numeric($value)) {
        return (float) $value;
    }
    
    return $value ?? '';
};

foreach ($columns as $col => $info) {
    $value = $getCellValue($col, 4);
    if ($value !== '' && $value !== 0) {
        if (is_numeric($value)) {
            echo sprintf("%-3s | %-30s | %s\n", $col, $info['header'], number_format($value, 0, ',', '.'));
        } else {
            echo sprintf("%-3s | %-30s | %s\n", $col, $info['header'], $value);
        }
    }
}
