<?php
require __DIR__ . '/sobat-api/vendor/autoload.php';

use PhpOffice\PhpSpreadsheet\IOFactory;

$inputFileType = 'Xlsx';
$inputFileName = __DIR__ . '/format tabel payslip (1).xlsx';

try {
    $reader = IOFactory::createReader($inputFileType);
    $spreadsheet = $reader->load($inputFileName);
    $sheet = $spreadsheet->getActiveSheet();
    
    echo "--- DATA INSPECTION ---\n";
    $i = 0;
    foreach ($sheet->getRowIterator() as $row) {
        if ($i > 6) break; // Ensure we see Row 4
        
        $cellIterator = $row->getCellIterator();
        $cellIterator->setIterateOnlyExistingCells(FALSE);
        $rowCells = [];
        $colIndex = 0;
        foreach ($cellIterator as $cell) {
            $val = $cell->getCalculatedValue();
            $fmt = $cell->getFormattedValue(); 
            // Only show relevant COMPONENT columns
            if (in_array($colIndex, [13, 14, 18, 19, 20])) {
                $rowCells[] = "[$colIndex] Val:$val (Fmt:$fmt)";
            }
            $colIndex++;
        }
        echo "Row " . ($i+1) . ": " . implode(" | ", $rowCells) . "\n";
        $i++;
    }

} catch(Exception $e) {
    echo 'Error loading file: ', $e->getMessage();
}
