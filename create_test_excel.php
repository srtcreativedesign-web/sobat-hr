<?php
require __DIR__ . '/sobat-api/vendor/autoload.php';

use PhpOffice\PhpSpreadsheet\Spreadsheet;
use PhpOffice\PhpSpreadsheet\Writer\Xlsx;
use PhpOffice\PhpSpreadsheet\Style\NumberFormat;

$spreadsheet = new Spreadsheet();
$sheet = $spreadsheet->getActiveSheet();

// Row 1: Empty/Title row
$sheet->setCellValue('A1', '');

// Row 2: Column Headers
$headers = [
    'A2' => 'Periode',
    'B2' => 'Nama Karyawan',
    'C2' => 'No Rekening',
    'D2' => 'Jumlah',
    'K2' => 'Gaji Pokok (Rp)',
    'L2' => 'Kehadiran',
    'M2' => '',
    'N2' => 'Transport (Rp)',
    'O2' => '',
    'P2' => 'Tunj. Kesehatan ( Rp )',
    'Q2' => '',
    'R2' => 'Tunj. Jabatan ( Rp )',
    'S2' => 'Total Gaji ( Rp )',
    'T2' => 'Lembur ( Rp )',
    'U2' => '',
    'V2' => '',
    'W2' => 'Insentif Lebaran',
    'X2' => 'Adj Kekurangan Gaji',
    'Y2' => 'Total Gaji (Rp)',
    'Z2' => 'Kebijakan HO',
    'AA2' => 'Potongan (Rp)',
    'AG2' => '', // Jumlah
    'AH2' => 'Grand Total (Rp)',
    'AI2' => 'EWA',
    'AJ2' => 'Payroll',
];

foreach ($headers as $cell => $value) {
    $sheet->setCellValue($cell, $value);
}

// Row 3: Units
$units = [
    'D3' => 'Hari',
    'E3' => 'Off',
    'F3' => 'Sakit',
    'G3' => 'Ijin',
    'H3' => 'Alfa',
    'I3' => 'Cuti',
    'J3' => 'Ada',
    'L3' => '/ Hari',
    'M3' => 'Jumlah',
    'N3' => '/ Hari',
    'O3' => 'Jumlah',
    'P3' => '/ Hari',
    'Q3' => 'Jumlah',
    'T3' => '/ Jam',
    'U3' => 'Jam',
    'V3' => 'Jumlah',
    'AA3' => 'Absen 1X',
    'AB3' => 'Terlambat',
    'AC3' => 'Selisih SO',
    'AD3' => 'Pinjaman',
    'AE3' => 'Adm Bank',
    'AF3' => 'BPJS TK',
    'AG3' => 'Jumlah',
];

foreach ($units as $cell => $value) {
    $sheet->setCellValue($cell, $value);
}

// Row 4: Sample Data with FORMULAS (matching user's actual data)
$data = [
    'A4' => 46023, // Excel date serial
    'B4' => 'Maya Estianty',
    'C4' => '7295554665',
    'D4' => 31,
    'E4' => 8,
    'F4' => 2,
    'G4' => 1,
    'H4' => '',
    'I4' => 1,
    'J4' => 20,
    'K4' => 5000000,  // Gaji Pokok
    'L4' => 10000,    // Kehadiran / Hari
    'M4' => 200000,   // Kehadiran Jumlah
    'N4' => 10000,    // Transport / Hari  
    'O4' => 200000,   // Transport Jumlah
    'P4' => 100000,   // Tunj. Kesehatan / Hari (but seems to be total based on data)
    'Q4' => 100000,   // Tunj. Kesehatan Jumlah
    'R4' => 100000,   // Tunj. Jabatan (fixed from 5600000)
    'S4' => '=K4+M4+O4+Q4+R4', // Total Gaji FORMULA = 5000000+200000+200000+100000+100000 = 5600000
    'T4' => 10000,    // Lembur / Jam
    'U4' => 5,        // Lembur Jam
    'V4' => 50000,    // Lembur Jumlah
    'W4' => 100000,   // Insentif Lebaran
    'X4' => '',       // Adj Kekurangan Gaji
    'Y4' => '=S4+V4+W4', // Total Gaji (Rp) FORMULA = 5600000+50000+100000 = 5750000
    'Z4' => '',       // Kebijakan HO
    'AA4' => 20000,   // Absen 1X
    'AB4' => 20000,   // Terlambat
    'AC4' => 50000,   // Selisih SO
    'AD4' => 200000,  // Pinjaman (EWA Principal)
    'AE4' => 2500,    // Adm Bank (EWA Fee)
    'AF4' => 217000,  // BPJS TK
    'AG4' => '=AA4+AB4+AC4+AD4+AE4+AF4', // Jumlah Potongan FORMULA = 20000+20000+50000+200000+2500+217000 = 509500
    'AH4' => '=Y4-AG4', // Grand Total FORMULA = 5750000-509500 = 5240500
    'AI4' => 517500,  // EWA
    'AJ4' => '=AH4-AI4', // Payroll FORMULA (Final Net Salary) = 5240500-517500 = 4723000
];


foreach ($data as $cell => $value) {
    $sheet->setCellValue($cell, $value);
}

// Format numbers as currency
$currencyFormat = '_-"Rp"* #,##0_-;-"Rp"* #,##0_-;_-"Rp"* "-"_-;_-@_-';
$currencyCells = ['K4', 'M4', 'O4', 'Q4', 'R4', 'S4', 'V4', 'W4', 'Y4', 'AA4', 'AB4', 'AC4', 'AD4', 'AE4', 'AF4', 'AG4', 'AH4', 'AI4', 'AJ4'];
foreach ($currencyCells as $cellAddress) {
    $sheet->getStyle($cellAddress)->getNumberFormat()->setFormatCode($currencyFormat);
}

// Save file
$writer = new Xlsx($spreadsheet);
$filename = 'test_payroll_excel.xlsx';
$writer->save($filename);

echo "Excel file created: $filename\n";
echo "Formulas included in columns S, Y, AG, AH, AJ\n";
echo "\nExpected values:\n";
echo "- Total Gaji (S4): " . $sheet->getCell('S4')->getCalculatedValue() . "\n";
echo "- Total Gaji Rp (Y4): " . $sheet->getCell('Y4')->getCalculatedValue() . "\n";
echo "- Jumlah Potongan (AG4): " . $sheet->getCell('AG4')->getCalculatedValue() . "\n";
echo "- Grand Total (AH4): " . $sheet->getCell('AH4')->getCalculatedValue() . "\n";
echo "- Payroll/Net Salary (AJ4): " . $sheet->getCell('AJ4')->getCalculatedValue() . "\n";
