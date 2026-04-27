<?php
require __DIR__ . '/vendor/autoload.php';

use PhpOffice\PhpSpreadsheet\IOFactory;

$filePath = '/Applications/XAMPP/xamppfiles/htdocs/sobat-hr/8. Maximum 600-2.xlsx';
if (!file_exists($filePath)) {
    die("File not found: " . $filePath . "\n");
}

$spreadsheet = IOFactory::load($filePath);
$sheet = $spreadsheet->getActiveSheet();

$highestRow = $sheet->getHighestRow();
$highestColumn = $sheet->getHighestColumn();
$highestColumnIndex = \PhpOffice\PhpSpreadsheet\Cell\Coordinate::columnIndexFromString($highestColumn);

echo "Highest Row: $highestRow, Highest Col: $highestColumn\n";

// Find header row (usually row 3 or 4)
$headerRowIndex = 4; // Assumption based on previous
for ($row = 1; $row <= 10; $row++) {
    $val = $sheet->getCell([1, $row])->getValue(); // Col A
    if ($val === 'NO') {
        $headerRowIndex = $row;
        break;
    }
}

echo "Header Row: $headerRowIndex\n";

// Get headers
$headers = [];
$currentMainHeader = '';

for ($col = 1; $col <= $highestColumnIndex; $col++) {
    $colLetter = \PhpOffice\PhpSpreadsheet\Cell\Coordinate::stringFromColumnIndex($col);
    
    $cellValue = trim($sheet->getCell([$col, $headerRowIndex])->getCalculatedValue() ?? '');
    
    if (empty($cellValue)) {
        $cellValue = $currentMainHeader; 
    } else {
        $currentMainHeader = $cellValue;
    }
    
    $subCellValue = trim($sheet->getCell([$col, $headerRowIndex + 1])->getCalculatedValue() ?? '');
    
    $fullHeader = $cellValue;
    if (!empty($subCellValue) && $subCellValue !== $cellValue) {
         $fullHeader .= ' ' . $subCellValue;
    }
    
    $headers[$colLetter] = trim($fullHeader);
}

echo "HEADERS:\n";
print_r($headers);

// Read row 7 (Agus Firman Santoso usually around here)
for ($row = $headerRowIndex + 2; $row <= $highestRow; $row++) {
    $name = trim($sheet->getCell('B' . $row)->getCalculatedValue() ?? '');
    if (stripos($name, 'Agus') !== false) {
        echo "\nDATA FOR $name (Row $row):\n";
        foreach ($headers as $col => $header) {
            $val = $sheet->getCell($col . $row)->getCalculatedValue() ?? '';
            echo "$col ($header) => $val\n";
        }
        break;
    }
}
