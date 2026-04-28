<?php
require __DIR__ . '/sobat-api/vendor/autoload.php';

use PhpOffice\PhpSpreadsheet\IOFactory;

$file = '/Applications/XAMPP/xamppfiles/htdocs/sobat-hr/4._Tung_Tau.xlsx';
$reader = IOFactory::createReader('Xlsx');
$reader->setReadDataOnly(true);
$spreadsheet = $reader->load($file);

$sheetNames = $spreadsheet->getSheetNames();
echo "Available sheets: " . implode(', ', $sheetNames) . "\n";

$sheet = $spreadsheet->getSheet(0);

$highestRow = min(15, $sheet->getHighestRow());
$highestColumn = $sheet->getHighestColumn();
$highestColIndex = \PhpOffice\PhpSpreadsheet\Cell\Coordinate::columnIndexFromString($highestColumn);

echo "--- First 15 rows ---\n";
for ($row = 1; $row <= $highestRow; $row++) {
    $rowData = [];
    for ($col = 1; $col <= min(40, $highestColIndex); $col++) {
        $colLetter = \PhpOffice\PhpSpreadsheet\Cell\Coordinate::stringFromColumnIndex($col);
        $val = $sheet->getCell($colLetter . $row)->getValue();
        if ($val !== null && $val !== '') {
            $rowData[] = "[$colLetter] => $val";
        }
    }
    if (!empty($rowData)) {
        echo "Row $row: " . implode(' | ', $rowData) . "\n";
    }
}
