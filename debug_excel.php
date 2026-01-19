<?php
require __DIR__ . '/sobat-api/vendor/autoload.php';

use PhpOffice\PhpSpreadsheet\IOFactory;

// Test with actual uploaded file
$testFiles = [
    'test_payroll_excel.xlsx',
    'sobat-api/storage/app/private/imports/format tabel payslip (3).xlsx',
];

foreach ($testFiles as $file) {
    if (!file_exists($file)) {
        continue;
    }
    
    echo "\n=== DEBUGGING: $file ===\n\n";
    
    $reader = IOFactory::createReader('Xlsx');
    $reader->setReadDataOnly(true);
    $spreadsheet = $reader->load($file);
    $sheet = $spreadsheet->getActiveSheet();
    
    $highestRow = $sheet->getHighestRow();
    $highestColumn = $sheet->getHighestColumn();
    
    echo "Highest Row: $highestRow\n";
    echo "Highest Column: $highestColumn\n\n";
    
    // Find header row
    $headerRowIndex = -1;
    for ($row = 1; $row <= min(10, $highestRow); $row++) {
        $cellValue = $sheet->getCell('B' . $row)->getValue();
        if (stripos($cellValue, 'Nama Karyawan') !== false) {
            $headerRowIndex = $row;
            break;
        }
    }
    
    echo "Header Row: $headerRowIndex\n\n";
    
    // Show headers
    echo "=== COLUMN HEADERS (Row $headerRowIndex) ===\n";
    foreach (range('A', 'AJ') as $col) {
        $value = $sheet->getCell($col . $headerRowIndex)->getValue();
        if ($value) {
            echo "$col: $value\n";
        }
    }
    
    echo "\n=== UNITS (Row " . ($headerRowIndex + 1) . ") ===\n";
    foreach (range('A', 'AJ') as $col) {
        $value = $sheet->getCell($col . ($headerRowIndex + 1))->getValue();
        if ($value) {
            echo "$col: $value\n";
        }
    }
    
    // Show first data row
    $dataRow = $headerRowIndex + 2;
    if ($dataRow <= $highestRow) {
        echo "\n=== DATA ROW $dataRow (with CALCULATED VALUES) ===\n";
        
        $getCellValue = function($col, $row) use ($sheet) {
            $cell = $sheet->getCell($col . $row);
            $value = $cell->getCalculatedValue();
            
            if (is_numeric($value)) {
                return (float) $value;
            }
            
            if (is_string($value)) {
                $cleaned = preg_replace('/[^0-9\.\,\-]/', '', $value);
                if ($cleaned !== '' && is_numeric($cleaned)) {
                    return (float) $cleaned;
                }
                return $value;
            }
            
            return $value ?? 0;
        };
        
        $cols = ['A', 'B', 'C', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z', 'AA', 'AB', 'AC', 'AD', 'AE', 'AF', 'AG', 'AH', 'AI', 'AJ'];
        
        foreach ($cols as $col) {
            $value = $getCellValue($col, $dataRow);
            if ($value !== 0 && $value !== '' && $value !== null) {
                echo sprintf("%-3s: %s\n", $col, is_numeric($value) ? number_format($value, 0, ',', '.') : $value);
            }
        }
        
        // CALCULATIONS CHECK
        echo "\n=== CALCULATIONS CHECK ===\n";
        $basicSalary = $getCellValue('K', $dataRow);
        $kehadiran = $getCellValue('M', $dataRow);
        $transport = $getCellValue('O', $dataRow);
        $healthAllowance = $getCellValue('Q', $dataRow);
        $positionAllowance = $getCellValue('R', $dataRow);
        $totalGaji_S = $getCellValue('S', $dataRow);
        $overtime = $getCellValue('V', $dataRow);
        $insentif = $getCellValue('W', $dataRow);
        $totalGaji_Y = $getCellValue('Y', $dataRow);
        
        $totalDeductions = $getCellValue('AG', $dataRow);
        $grandTotal = $getCellValue('AH', $dataRow);
        $ewa = $getCellValue('AI', $dataRow);
        $payroll = $getCellValue('AJ', $dataRow);
        
        echo "Basic Salary (K): " . number_format($basicSalary, 0, ',', '.') . "\n";
        echo "Kehadiran (M): " . number_format($kehadiran, 0, ',', '.') . "\n";
        echo "Transport (O): " . number_format($transport, 0, ',', '.') . "\n";
        echo "Health (Q): " . number_format($healthAllowance, 0, ',', '.') . "\n";
        echo "Position (R): " . number_format($positionAllowance, 0, ',', '.') . "\n";
        echo "Total Allowances Sum: " . number_format($kehadiran + $transport + $healthAllowance + $positionAllowance, 0, ',', '.') . "\n";
        echo "\nTotal Gaji S (FORMULA): " . number_format($totalGaji_S, 0, ',', '.') . "\n";
        echo "Overtime (V): " . number_format($overtime, 0, ',', '.') . "\n";
        echo "Insentif (W): " . number_format($insentif, 0, ',', '.') . "\n";
        echo "Total Gaji Y (FORMULA): " . number_format($totalGaji_Y, 0, ',', '.') . "\n";
        
        echo "\nTotal Deductions (AG - FORMULA): " . number_format($totalDeductions, 0, ',', '.') . "\n";
        echo "Grand Total (AH - FORMULA): " . number_format($grandTotal, 0, ',', '.') . "\n";
        echo "EWA (AI): " . number_format($ewa, 0, ',', '.') . "\n";
        echo "Payroll/Net (AJ - FORMULA): " . number_format($payroll, 0, ',', '.') . "\n";
        
        // Manual calculation
        $manualGross = $basicSalary + $kehadiran + $transport + $healthAllowance + $positionAllowance + $overtime + $insentif;
        echo "\n[MANUAL] Gross should be: " . number_format($manualGross, 0, ',', '.') . "\n";
        echo "[EXCEL Y] Total Gaji is: " . number_format($totalGaji_Y, 0, ',', '.') . "\n";
        
        if ($manualGross != $totalGaji_Y) {
            echo "⚠️  MISMATCH! Manual calculation differs from Excel Y column\n";
        }
    }
    
    break; // Only test first found file
}
