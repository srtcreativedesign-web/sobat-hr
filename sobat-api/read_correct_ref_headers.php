<?php
require 'vendor/autoload.php';

use PhpOffice\PhpSpreadsheet\IOFactory;

$inputFileName = __DIR__ . '/../payroll reflexy.xlsx';
$spreadsheet = IOFactory::load($inputFileName);
$sheet = $spreadsheet->getActiveSheet();

echo "Highest Row: " . $sheet->getHighestRow() . "\n";
echo "Highest Column: " . $sheet->getHighestColumn() . "\n\n";

// Read first 10 rows to find headers
for ($row = 1; $row <= 10; $row++) {
    $rowData = [];
    // Read cols A to AL (index 1 to 38)
    for ($colIdx = 1; $colIdx <= \PhpOffice\PhpSpreadsheet\Cell\Coordinate::columnIndexFromString('AL'); $colIdx++) {
        $col = \PhpOffice\PhpSpreadsheet\Cell\Coordinate::stringFromColumnIndex($colIdx);
        $cell = $sheet->getCell($col . $row);
        $val = $cell->getValue();
        if (!empty($val)) {
            $rowData[$col] = $val;
        }
    }
    echo "Row $row: " . json_encode($rowData) . "\n";
}
