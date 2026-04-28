<?php
require 'vendor/autoload.php';

use PhpOffice\PhpSpreadsheet\IOFactory;

$files = [
    'fnb' => '/Applications/XAMPP/xamppfiles/htdocs/sobat-hr/04. Gaji Bekal.xlsx',
    'mm' => '/Applications/XAMPP/xamppfiles/htdocs/sobat-hr/payroll MM.xlsx',
    'ref' => '/Applications/XAMPP/xamppfiles/htdocs/sobat-hr/17. Gaji Reflexy G14.xlsx',
    'wrapping' => '/Applications/XAMPP/xamppfiles/htdocs/sobat-hr/wrapping t3 payslip.xlsx',
    'hans' => '/Applications/XAMPP/xamppfiles/htdocs/sobat-hr/payslip hans.xlsx',
    'money_changer' => '/Applications/XAMPP/xamppfiles/htdocs/sobat-hr/36. Money Changer.xlsx'
];

foreach ($files as $div => $file) {
    echo "--- $div ---\n";
    if (!file_exists($file)) {
        continue;
    }
    $spreadsheet = IOFactory::load($file);
    $worksheet = $spreadsheet->getActiveSheet();
    
    // Look at row 4 and 5
    for ($r = 4; $r <= 5; $r++) {
        echo "Row $r: ";
        foreach (range('A', 'Z') as $col) {
            $val = trim($worksheet->getCell($col.$r)->getCalculatedValue() ?? '');
            if ($val !== '') echo "[$col]=$val | ";
        }
        foreach (['AA','AB','AC','AD','AE','AF','AG','AH','AI','AJ','AK','AL','AM','AN','AO','AP'] as $col) {
            $val = trim($worksheet->getCell($col.$r)->getCalculatedValue() ?? '');
            if ($val !== '') echo "[$col]=$val | ";
        }
        echo "\n";
    }
}
