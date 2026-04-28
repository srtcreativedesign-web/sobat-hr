<?php
require __DIR__ . '/sobat-api/vendor/autoload.php';
$file = '/Applications/XAMPP/xamppfiles/htdocs/sobat-hr/8. Maximum 600-2.xlsx';
$reader = \PhpOffice\PhpSpreadsheet\IOFactory::createReader('Xlsx');
$reader->setReadDataOnly(true);
$spreadsheet = $reader->load($file);
$sheet = $spreadsheet->getActiveSheet();

$headerRowIndex = 5;
$highestColumn = $sheet->getHighestColumn();
$headerRow = $sheet->getRowIterator($headerRowIndex, $headerRowIndex)->current();
$cellIterator = $headerRow->getCellIterator('A', $highestColumn);
$cellIterator->setIterateOnlyExistingCells(false);

$allHeaders = [];
$allSubs = [];
$colOrder = [];

foreach ($cellIterator as $cell) {
    $col = $cell->getColumn();
    $colOrder[] = $col;
    $allHeaders[$col] = $cell->getValue();
    $allSubs[$col] = $sheet->getCell($col . ($headerRowIndex + 1))->getValue();
}

$headerPatterns = [
    'nama_karyawan' => ['Nama Karyawan', 'Nama Pegawai'],
    'no_rekening' => ['No Rekening', 'Rekening'],
    'days_total' => [['Jumlah', 'Hari']],
    'days_off' => ['Off'],
    'days_sick' => ['Sakit'],
    'days_permission' => ['Ijin'],
    'days_alpha' => ['Alfa', 'ALFA', 'Alpa'],
    'days_leave' => ['Cuti'],
    'days_present' => ['Ada', 'Hadir'],
    'gaji_pokok' => ['Gaji Pokok', 'Gapok', 'Basic Salary'],
    'kehadiran_rate' => [['Kehadiran', '/ Hari']],
    'kehadiran_jumlah' => [['Kehadiran', 'Jumlah']],
    'transport_rate' => [['Transport', '/ Hari']],
    'transport_jumlah' => [['Transport', 'Jumlah']],
    'kesehatan' => ['Tunj. Kesehatan'],
    'jabatan' => ['Tunj. Jabatan'],
    'total_gaji' => ['Total Gaji            ( Rp )', 'Total Gaji'],
    'lembur_rate' => [['Lembur', '/ Jam']],
    'lembur_jam' => [['Lembur', 'Jam']],
    'lembur_jumlah' => [['Lembur', 'Jumlah']],
    'backup' => ['Backup'],
    'insentif_kehadiran' => ['Insentif Kehadrian', 'Insentif Kehadiran'],
    'insentif_lebaran' => ['Insentif Lebaran'],
    'insentif' => ['Insentif '], // For column Y in max 600
    'total_gaji_bonus' => ['Total Gaji    (Rp)', 'Total Gaji & Bonus'],
    'kebijakan_ho' => ['Kebijakan'],
    'absen_count' => ['Absen 1x'],
    'absen' => ['Absen 1X'],
    'terlambat_menit' => ['terlambat (menit)'],
    'terlambat' => ['Terlambat'],
    'selisih' => ['Selisih SO', 'Selisih'],
    'pinjaman' => ['Pinjaman'],
    'adm_bank' => ['Adm Bank', 'Admin Bank'],
    'bpjs_tk' => ['BPJS TK', 'BPJS Ketenagakerjaan'],
    'jumlah_potongan' => [['Potongan', 'Jumlah'], 'Total Potongan'],
    'grand_total' => ['Grand Total'],
    'ewa' => ['EWA', 'Pinjaman ke Stafbook', 'Pinjaman stafbook'],
    'potongan_ewa' => ['Potongan EWA'],
    'payroll' => ['Total Gaji Ditransfer', 'Payroll', 'THP'],
    'adjustment' => ['Adj', 'Penyesuaian'],
];

$columnMapping = [];
$lastHeader = ''; // Track the last effective header

foreach ($colOrder as $idx => $col) {
    $headerValue = $allHeaders[$col];
    $unitsValue = $allSubs[$col];
    
    // Proper merged cell resolution
    if (!empty($headerValue)) {
        $lastHeader = $headerValue;
        $effectiveHeader = $headerValue;
    } else {
        $effectiveHeader = $lastHeader;
    }
    
    foreach ($headerPatterns as $key => $patterns) {
        if (isset($columnMapping[$key])) continue;
        
        $alternativePatterns = is_array($patterns) ? $patterns : [$patterns];
        
        foreach ($alternativePatterns as $pattern) {
            if (is_array($pattern)) {
                $headerMatch = $effectiveHeader && stripos($effectiveHeader, $pattern[0]) !== false;
                $unitsMatch = $unitsValue && stripos($unitsValue, $pattern[1]) !== false;
                if ($headerMatch && $unitsMatch) {
                    $columnMapping[$key] = $col;
                    break;
                }
            } else {
                // If it's single string, check either header or subheader
                $matchedHeader = $effectiveHeader && stripos($effectiveHeader, $pattern) !== false;
                $matchedSub = $unitsValue && stripos($unitsValue, $pattern) !== false;
                if ($matchedHeader || $matchedSub) {
                    $columnMapping[$key] = $col;
                    break;
                }
            }
        }
    }
}
print_r($columnMapping);
