<?php
require 'vendor/autoload.php';

use PhpOffice\PhpSpreadsheet\IOFactory;

$files = [
    'fnb' => '/Applications/XAMPP/xamppfiles/htdocs/sobat-hr/04. Gaji Bekal.xlsx',
    'mm' => '/Applications/XAMPP/xamppfiles/htdocs/sobat-hr/payroll MM.xlsx',
    'ref' => '/Applications/XAMPP/xamppfiles/htdocs/sobat-hr/17. Gaji Reflexy G14.xlsx',
    'wrapping' => '/Applications/XAMPP/xamppfiles/htdocs/sobat-hr/wrapping t3 payslip.xlsx',
    'hans' => '/Applications/XAMPP/xamppfiles/htdocs/sobat-hr/payslip hans.xlsx',
    'cellular' => '/Applications/XAMPP/xamppfiles/htdocs/sobat-hr/37. Premium Fast track.xlsx',
    'money_changer' => '/Applications/XAMPP/xamppfiles/htdocs/sobat-hr/36. Money Changer.xlsx'
];

foreach ($files as $div => $file) {
    echo "--- $div ---\n";
    if (!file_exists($file)) {
        echo "File not found\n";
        continue;
    }
    try {
        $spreadsheet = IOFactory::load($file);
        $worksheet = $spreadsheet->getActiveSheet();
        
        $rowIter = $worksheet->getRowIterator(1, 5);
        foreach ($rowIter as $row) {
            $cellIter = $row->getCellIterator();
            $cellIter->setIterateOnlyExistingCells(false);
            $values = [];
            foreach ($cellIter as $cell) {
                $val = trim($cell->getCalculatedValue() ?? '');
                if ($val !== '') {
                    $values[$cell->getColumn()] = $val;
                }
            }
            if (!empty($values)) {
                // Just print the last 15 columns
                $keys = array_keys($values);
                sort($keys);
                $lastKeys = array_slice($keys, -15);
                echo "Row " . $row->getRowIndex() . ": ";
                foreach ($lastKeys as $k) {
                    echo "[$k]=" . $values[$k] . " | ";
                }
                echo "\n";
            }
        }
    } catch (Exception $e) {
        echo "Error: " . $e->getMessage() . "\n";
    }
    echo "\n";
}
