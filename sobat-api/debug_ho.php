<?php

require __DIR__ . '/vendor/autoload.php';

use PhpOffice\PhpSpreadsheet\IOFactory;

$filePath = dirname(__DIR__) . '/payslip HO.xlsx';

if (!file_exists($filePath)) {
    echo "File not found: $filePath\n";
    exit(1);
}

echo "Loading file: $filePath\n";

try {
    $spreadsheet = IOFactory::load($filePath);
    $sheet = $spreadsheet->getActiveSheet();
    $highestRow = $sheet->getHighestRow();
    $highestColumn = $sheet->getHighestColumn();
    
    echo "Highest Row: $highestRow\n";
    
    // Header Detection
    $headerRowIndex = -1;
    for ($r = 1; $r <= min(20, $highestRow); $r++) {
        $rowCells = $sheet->getRowIterator($r)->current()->getCellIterator();
        $rowCells->setIterateOnlyExistingCells(false);
        
        foreach ($rowCells as $cell) {
            $val = $cell->getValue();
            if ($val instanceof \PhpOffice\PhpSpreadsheet\RichText\RichText) {
                $val = $val->getPlainText();
            }
            $val = trim((string)$val);
            
            if (preg_match('/(nama karyawan|nama pegawai|employee name|nama)/i', $val)) {
                $headerRowIndex = $r;
                echo "Header found at Row $r, Col " . $cell->getColumn() . " ($val)\n";
                break 2;
            }
        }
    }
    
    if ($headerRowIndex === -1) {
        echo "Header NOT found!\n";
        exit;
    }

    // Map Headers
    $columnMapping = [];
    $headerIterator = $sheet->getRowIterator($headerRowIndex)->current()->getCellIterator();
    $headerIterator->setIterateOnlyExistingCells(true);
    foreach ($headerIterator as $cell) {
        $val = trim((string)$cell->getValue());
        if ($val) $columnMapping[strtolower($val)] = $cell->getColumn();
    }
    
    // Build Mapping with Combined Keys
    $finalMapping = [];
    $normalize = function($str) {
        return strtolower(trim(preg_replace('/\s+/', ' ', $str)));
    };
    
    // Row 1 (Parents)
    $parentMap = [];
    $iter1 = $sheet->getRowIterator($headerRowIndex)->current()->getCellIterator();
    $iter1->setIterateOnlyExistingCells(true);
    foreach ($iter1 as $cell) {
        $val = trim((string)$cell->getValue());
        if ($val) {
            $col = $cell->getColumn();
            $parentMap[$col] = $val;
            $finalMapping[$normalize($val)] = $col; // Add parent key
        }
    }
    
    // Row 2 (Subheaders)
    $subHeaderRow = $headerRowIndex + 1;
    if ($subHeaderRow <= $highestRow) {
        $iter2 = $sheet->getRowIterator($subHeaderRow)->current()->getCellIterator();
        $iter2->setIterateOnlyExistingCells(true);
        foreach ($iter2 as $cell) {
             $val = trim((string)$cell->getValue());
             $col = $cell->getColumn();
             
             if ($val) {
                 // Add Subheader key (careful of collisions)
                 // $finalMapping[$normalize($val)] = $col; 
                 // We skip raw subheader to avoid 'total' clobbering.
                 // Only add specific ones like 'Kasbon'? 
                 // Let's add ONLY if it looks unique or we rely on it.
                 $finalMapping[$normalize($val)] = $col; 
                 
                 // Add Combined key
                 if (isset($parentMap[$col])) {
                     $parent = $parentMap[$col];
                     $combined = $parent . ' ' . $val;
                     $finalMapping[$normalize($combined)] = $col;
                     
                     // Also try Parent + " " + Sub but parent might be from merged cell (previous col)
                     // If Col I has parent 'uang lembur', Col J might be empty in Row 1.
                     // Merged cell logic: accessing Col J in Row 1 should return 'uang lembur' if merged?
                     // PhpSpreadsheet's getValue() returns null for merged cells except top-left.
                     // So we need to handle Merge!
                 } else {
                     // Try to find parent from previous columns (Merge simulation)
                     // Simple heuristic: walk backwards
                     $cIndex = \PhpOffice\PhpSpreadsheet\Cell\Coordinate::columnIndexFromString($col);
                     for ($search = $cIndex - 1; $search >= 1; $search--) {
                         $searchCol = \PhpOffice\PhpSpreadsheet\Cell\Coordinate::stringFromColumnIndex($search);
                         if (isset($parentMap[$searchCol])) {
                             $parent = $parentMap[$searchCol];
                             // Verify if it's actually merged? 
                             // For now assume emptiness implies merge continuation or just use immediate left.
                             // Actually, simpler: if parent is empty, look left.
                             $combined = $parent . ' ' . $val;
                             $finalMapping[$normalize($combined)] = $col;
                             break;
                         }
                     }
                 }
             }
        }
    }
    
    // Fix merge parent lookup more robustly
    foreach ($sheet->getMergeCells() as $range) {
        $cells = \PhpOffice\PhpSpreadsheet\Cell\Coordinate::extractAllCellReferencesInRange($range);
        $topLeft = $cells[0]; // e.g. "I1"
        $val = $sheet->getCell($topLeft)->getValue();
        if ($val) {
            // Assign this parent value to all columns in range
             // We only care about columns in Header Row
             foreach ($cells as $cellRef) {
                 // Check if cell is in Header Row
                 if (strpos($cellRef, (string)$headerRowIndex) !== false) {
                     // It's in header row.
                     // Get column letter.
                     $col = preg_replace('/[0-9]+/', '', $cellRef);
                     $parentMap[$col] = $val;
                     // Also add parent key for this column
                     $finalMapping[$normalize($val)] = $col;
                 }
             }
        }
    }
    
    // Re-run subheader loop to use correct parents from merge
    if ($subHeaderRow <= $highestRow) {
        $iter2 = $sheet->getRowIterator($subHeaderRow)->current()->getCellIterator();
        $iter2->setIterateOnlyExistingCells(true);
        foreach ($iter2 as $cell) {
             $val = trim((string)$cell->getValue());
             $col = $cell->getColumn();
             if ($val) {
                 if (isset($parentMap[$col])) {
                     $parent = $parentMap[$col];
                     $combined = $parent . ' ' . $val;
                     $finalMapping[$normalize($combined)] = $col;
                 }
             }
        }
    }

    echo "Final Keys: " . json_encode(array_keys($finalMapping)) . "\n";
    
    // Helper
    $findCol = function($patterns, $default = null) use ($finalMapping, $normalize) {
        foreach ((array)$patterns as $pat) {
            $nPat = $normalize($pat);
            if (isset($finalMapping[$nPat])) return $finalMapping[$nPat];
        }
        return $default;
    };
    
    // Updated Columns Patterns
    $cols = [
        'account' => $findCol(['no rekening', 'account number', 'rekening', 'nomor rekening'], 'C'),
        'present' => $findCol(['jml hr masuk', 'hadir', 'jml hr masuk'], 'E'),
        'basic' => $findCol(['gaji pokok'], null),
        'transport_amt' => $findCol(['transport total', 'uang kehadiran'], null),
        'transport_rate' => $findCol(['transport @hari'], null),
        'attend_amt' => $findCol(['uang kehadiran total', 'uang kehadiran'], null), // Uang Kehadiran Total
        'attend_rate' => $findCol(['uang kehadiran @hari'], null),
        'health' => $findCol(['tunjangan'], null), // Tunjangan (Row 1 L)
        'position' => $findCol(['tunjangan jabatan'], null),
        'overtime_hr' => $findCol(['jam lbr', 'jam lembur'], null),
        'overtime_amt' => $findCol(['uang lembur total'], null),
        'overtime_rate' => $findCol(['uang lembur @hari', 'uang lembur @ jam'], null), 
        'loan' => $findCol(['potongan kasbon', 'kasbon'], null), 
        'alfa' => $findCol(['potongan alfa', 'alfa'], null),
        'pot_ewa' => $findCol(['potongan ewa'], null),
        'payroll' => $findCol(['net salary', 'gaji diterima'], null),
    ];
    
    echo "Mapped Cols: " . json_encode($cols) . "\n";

    
    // Parse First Row
    $startRow = $headerRowIndex + 2;
    // If subheaders exist, maybe allow data to start later?
    // But usually Row 1: Header, Row 2: Subheader. Data Row 3.
    $row = $startRow; 
    
    $getCellValue = function($col, $row) use ($sheet) {
        if (!$col) return 0;
        $val = $sheet->getCell($col . $row)->getCalculatedValue(); 
        return is_numeric($val) ? $val : 0;
    };
    
    $safeGet = function($colKey) use ($cols, $getCellValue, $row) {
        if (empty($cols[$colKey])) return 0;
        return $getCellValue($cols[$colKey], $row);
    };

    $name = $sheet->getCell('B' . $row)->getValue();
    echo "Parsing Row $row (Name: $name):\n";
    
    $parsed = [
        'basic_salary' => $safeGet('basic'),
        'transport_amt' => $safeGet('transport_amt'),
        'attend_amt' => $safeGet('attend_amt'),
        'overtime_hours' => $safeGet('overtime_hr'),
        'overtime_rate' => $safeGet('overtime_rate'),
        'overtime_amount' => $safeGet('overtime_amt'),
        'loan' => $safeGet('loan'),
        'alfa' => $safeGet('alfa'),
        'pot_ewa' => $safeGet('pot_ewa'),
    ];
    
    // Calc logic
    if ($parsed['overtime_amount'] == 0 && $parsed['overtime_hours'] > 0) {
         $rate = $safeGet('overtime_rate');
         if ($rate > 0) {
             $parsed['overtime_amount_calculated'] = $parsed['overtime_hours'] * $rate;
         }
    }
    
    print_r($parsed);

} catch (Exception $e) {
    echo "Error: " . $e->getMessage() . "\n";
}
