const fs = require('fs');
const path = './sobat-api/app/Http/Controllers/Api/PayrollRetailController.php';
let content = fs.readFileSync(path, 'utf8');

// I need to rename public function import(Request $request) to public function parseHeaders(Request $request)
// AND then return headers instead of processing the rest.
// Wait, actually I can just copy the import function and make it parseHeaders.

const parseHeadersCode = `
    public function parseHeaders(Request $request)
    {
        $request->validate([
            'file' => 'required|file|mimes:xlsx,xls',
            'division_type' => 'required|string',
        ]);

        $file = $request->file('file');

        try {
            $reader = \\PhpOffice\\PhpSpreadsheet\\IOFactory::createReader('Xlsx');
            $reader->setReadDataOnly(true); 
            $spreadsheet = $reader->load($file->getRealPath());
            
            $sheet = $spreadsheet->getSheetByName('gabungan');
            if (!$sheet) {
                $sheet = $spreadsheet->getActiveSheet();
            }
            
            $highestRow = $sheet->getHighestRow();
            $highestColumn = $sheet->getHighestColumn();
            
            $headerRowIndex = -1;
            for ($row = 1; $row <= min(15, $highestRow); $row++) {
                $rowIterator = $sheet->getRowIterator($row, $row)->current();
                $cellIterator = $rowIterator->getCellIterator('A', $highestColumn);
                $cellIterator->setIterateOnlyExistingCells(false);
                
                foreach ($cellIterator as $cell) {
                    $cellValue = $cell->getValue();
                    if ($cellValue && stripos($cellValue, 'Nama Karyawan') !== false) {
                        $headerRowIndex = $row;
                        break 2;
                    }
                }
            }
            
            if ($headerRowIndex === -1) {
                return response()->json(['message' => 'Format Excel tidak dikenali. Pastikan ada kolom "Nama Karyawan".'], 422);
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
                'target_koli' => ['Target Koli', 'Koli'],
                'accessory_fee' => ['Aksesoris', 'Fee Aksesoris', 'Accessory'],
                'backup' => ['Backup'],
                'insentif_kehadiran' => ['Insentif Kehadrian', 'Insentif Kehadiran'],
                'insentif_lebaran' => ['Insentif Lebaran'],
                'total_gaji_bonus' => ['Total Gaji    (Rp)', 'Total Gaji & Bonus'],
                'kebijakan_ho' => ['Kebijakan'],
                'absen' => ['Absen 1X', 'Absen 1x'],
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
                'adjustment' => ['Adj', 'Penyesuaian', 'Kekurangan Gaji'],
            ];
            
            $allHeaders = [];
            $allSubs = [];
            $colOrder = [];
            
            $headerRow = $sheet->getRowIterator($headerRowIndex, $headerRowIndex)->current();
            $cellIterator = $headerRow->getCellIterator('A', $highestColumn);
            $cellIterator->setIterateOnlyExistingCells(false);
            
            foreach ($cellIterator as $cell) {
                $col = $cell->getColumn();
                $colOrder[] = $col;
                $allHeaders[$col] = $cell->getValue();
                $allSubs[$col] = $sheet->getCell($col . ($headerRowIndex + 1))->getValue();
            }
            
            $columnMapping = [];
            $usedColumns = []; 
            
            foreach ($headerPatterns as $key => $patterns) {
                $alternativePatterns = is_array($patterns) ? $patterns : [$patterns];
                
                foreach ($alternativePatterns as $pattern) {
                    $matched = false;
                    foreach ($colOrder as $col) {
                        if (in_array($col, $usedColumns)) continue;
                        
                        $headerValue = $allHeaders[$col];
                        $unitsValue = $allSubs[$col];
                        
                        $effectiveHeader = '';
                        if (!empty($headerValue)) {
                            $effectiveHeader = $headerValue;
                        } else {
                            foreach ($colOrder as $c) {
                                if (!empty($allHeaders[$c])) $effectiveHeader = $allHeaders[$c];
                                if ($c === $col) break;
                            }
                        }
                        
                        if (is_array($pattern)) {
                            $headerMatch = $effectiveHeader && stripos($effectiveHeader, $pattern[0]) !== false;
                            $unitsMatch = $unitsValue && stripos($unitsValue, $pattern[1]) !== false;
                            
                            if ($pattern[1] === 'Jam' && $unitsMatch && stripos($unitsValue, '/ Jam') !== false) {
                                $unitsMatch = false; 
                            }
                            
                            if ($headerMatch && $unitsMatch) {
                                $columnMapping[$key] = $col;
                                $usedColumns[] = $col;
                                $matched = true;
                                break;
                            }
                        } else {
                            $matchedHeader = $effectiveHeader && stripos($effectiveHeader, $pattern) !== false;
                            $matchedSub = $unitsValue && stripos($unitsValue, $pattern) !== false;
                            
                            if ($matchedHeader || $matchedSub) {
                                $columnMapping[$key] = $col;
                                $usedColumns[] = $col;
                                $matched = true;
                                break;
                            }
                        }
                    }
                    if ($matched) break;
                }
            }
            
            Log::info('Retail Column Mapping Detected', $columnMapping);
            
            return response()->json([
                'requiresMapping' => true,
                'headers' => $allHeaders,
                'default_mapping' => $columnMapping,
                'headerRowIndex' => $headerRowIndex,
            ]);

        } catch (\\Exception $e) {
            Log::error('Retail Payroll Parse Error: ' . $e->getMessage());
            return response()->json(['message' => 'Error: ' . $e->getMessage()], 500);
        }
    }

    public function simulateImport(Request $request)
    {
        $request->validate([
            'file' => 'required|file|mimes:xlsx,xls',
            'mapping' => 'required|string',
            'headerRowIndex' => 'required|numeric',
        ]);

        $file = $request->file('file');
        $columnMapping = json_decode($request->mapping, true);
        $headerRowIndex = (int) $request->headerRowIndex;

        try {
            $reader = \\PhpOffice\\PhpSpreadsheet\\IOFactory::createReader('Xlsx');
            $reader->setReadDataOnly(true); 
            $spreadsheet = $reader->load($file->getRealPath());
            
            $sheet = $spreadsheet->getSheetByName('gabungan');
            if (!$sheet) {
                $sheet = $spreadsheet->getActiveSheet();
            }
            
            $highestRow = $sheet->getHighestRow();
            $getCellValue = function($col, $row) use ($sheet) {
                if (!$col) return 0;
                try {
                    $cell = $sheet->getCell($col . $row);
                    $value = $cell->getCalculatedValue();
                    
                    if (is_numeric($value)) return (float) $value;
                    
                    if (is_string($value)) {
                        $cleaned = preg_replace('/[^0-9\\.\\,\\-]/', '', $value);
                        if ($cleaned !== '' && is_numeric($cleaned)) {
                            return (float) $cleaned;
                        }
                        return $value;
                    }
                    
                    return $value ?? 0;
                } catch (\\Exception $e) {
                    return 0;
                }
            };

            $dataRows = [];
            $startDataRow = $headerRowIndex + 2; 
            
            for ($row = $startDataRow; $row <= $highestRow; $row++) {
                $employeeName = $getCellValue($columnMapping['nama_karyawan'] ?? null, $row);
                if (empty($employeeName) || !is_string($employeeName)) continue;
                
                $daysTotal = (int) $getCellValue($columnMapping['days_total'] ?? null, $row);
                $daysOff = (int) $getCellValue($columnMapping['days_off'] ?? null, $row);
                $daysSick = (int) $getCellValue($columnMapping['days_sick'] ?? null, $row);
                $daysPermission = (int) $getCellValue($columnMapping['days_permission'] ?? null, $row);
                $daysAlpha = (int) $getCellValue($columnMapping['days_alpha'] ?? null, $row);
                $daysLeave = (int) $getCellValue($columnMapping['days_leave'] ?? null, $row);
                $daysPresent = (int) $getCellValue($columnMapping['days_present'] ?? null, $row);
                
                if ($daysPresent <= 0 && $daysTotal > 0) {
                    $daysPresent = $daysTotal - $daysOff - $daysSick - $daysPermission - $daysAlpha - $daysLeave;
                    if ($daysPresent < 0) $daysPresent = 0;
                }
                
                $basicSalary = $getCellValue($columnMapping['gaji_pokok'] ?? null, $row);
                $attendanceRate = $getCellValue($columnMapping['kehadiran_rate'] ?? null, $row);
                $attendanceAmount = $getCellValue($columnMapping['kehadiran_jumlah'] ?? null, $row);
                $transportRate = $getCellValue($columnMapping['transport_rate'] ?? null, $row);
                $transportAmount = $getCellValue($columnMapping['transport_jumlah'] ?? null, $row);
                $healthAllowance = $getCellValue($columnMapping['kesehatan'] ?? null, $row);
                $positionAllowance = $getCellValue($columnMapping['jabatan'] ?? null, $row);
                $totalSalary1 = $getCellValue($columnMapping['total_gaji'] ?? null, $row);
                $overtimeRate = $getCellValue($columnMapping['lembur_rate'] ?? null, $row);
                $overtimeHours = $getCellValue($columnMapping['lembur_jam'] ?? null, $row);
                $overtimeAmount = $getCellValue($columnMapping['lembur_jumlah'] ?? null, $row);
                $targetKoli = $getCellValue($columnMapping['target_koli'] ?? null, $row);
                $accessoryFee = $getCellValue($columnMapping['accessory_fee'] ?? null, $row);
                $backup = $getCellValue($columnMapping['backup'] ?? null, $row);
                $insentifKehadiran = $getCellValue($columnMapping['insentif_kehadiran'] ?? null, $row);
                $holidayAllowance = $getCellValue($columnMapping['insentif_lebaran'] ?? null, $row);
                $adjustment = $getCellValue($columnMapping['adjustment'] ?? null, $row);
                $totalSalary2 = $getCellValue($columnMapping['total_gaji_bonus'] ?? null, $row);
                $policyHo = $getCellValue($columnMapping['kebijakan_ho'] ?? null, $row);
                $deductionAbsent = $getCellValue($columnMapping['absen'] ?? null, $row);
                $deductionLate = $getCellValue($columnMapping['terlambat'] ?? null, $row);
                $deductionShortage = $getCellValue($columnMapping['selisih'] ?? null, $row);
                $deductionLoan = $getCellValue($columnMapping['pinjaman'] ?? null, $row);
                $deductionAdminFee = $getCellValue($columnMapping['adm_bank'] ?? null, $row);
                $deductionBpjsTk = $getCellValue($columnMapping['bpjs_tk'] ?? null, $row);
                $totalDeductions = $getCellValue($columnMapping['jumlah_potongan'] ?? null, $row);
                
                if ($totalDeductions <= 0) {
                    $totalDeductions = abs($deductionAbsent) + abs($deductionLate) + abs($deductionShortage) + abs($deductionLoan) + abs($deductionAdminFee) + abs($deductionBpjsTk);
                }
                
                $grandTotal = $getCellValue($columnMapping['grand_total'] ?? null, $row);
                $ewa = $getCellValue($columnMapping['ewa'] ?? null, $row);
                $netSalary = $getCellValue($columnMapping['payroll'] ?? null, $row);
                
                if ($netSalary <= 0 && $grandTotal > 0) {
                    $netSalary = $grandTotal;
                }
                
                if ($totalSalary2 > 0) {
                    $grossSalary = $totalSalary2;
                } elseif ($totalSalary1 > 0) {
                    $grossSalary = $totalSalary1;
                } else {
                    $grossSalary = $basicSalary + $attendanceAmount + $transportAmount + $healthAllowance + $positionAllowance + $overtimeAmount + $holidayAllowance + $adjustment + $backup + $insentifKehadiran + $targetKoli + $accessoryFee;
                }
                
                $dataRows[] = [
                    'employee_name' => $employeeName,
                    'period' => $request->period ?? date('Y-m'),
                    'account_number' => $getCellValue($columnMapping['no_rekening'] ?? null, $row),
                    
                    'days_total' => $daysTotal,
                    'days_off' => $daysOff,
                    'days_sick' => $daysSick,
                    'days_permission' => $daysPermission,
                    'days_alpha' => $daysAlpha,
                    'days_leave' => $daysLeave,
                    'days_present' => $daysPresent,
                    
                    'basic_salary' => $basicSalary,
                    'attendance_rate' => $attendanceRate,
                    'attendance_amount' => $attendanceAmount,
                    'transport_rate' => $transportRate,
                    'transport_amount' => $transportAmount,
                    'health_allowance' => $healthAllowance,
                    'position_allowance' => $positionAllowance,
                    'total_salary_1' => $totalSalary1,
                    
                    'overtime_rate' => $overtimeRate,
                    'overtime_hours' => $overtimeHours,
                    'overtime_amount' => $overtimeAmount,
                    'target_koli' => $targetKoli,
                    'accessory_fee' => $accessoryFee,
                    
                    'backup' => $backup,
                    'insentif_kehadiran' => $insentifKehadiran,
                    'holiday_allowance' => $holidayAllowance,
                    'adjustment' => $adjustment,
                    'total_salary_2' => $grossSalary, 
                    'policy_ho' => $policyHo,
                    
                    'deduction_absent' => $deductionAbsent,
                    'deduction_late' => $deductionLate,
                    'deduction_shortage' => $deductionShortage,
                    'deduction_loan' => $deductionLoan,
                    'deduction_admin_fee' => $deductionAdminFee,
                    'deduction_bpjs_tk' => $deductionBpjsTk,
                    'total_deductions' => $totalDeductions,
                    
                    'grand_total' => $grandTotal,
                    'ewa_amount' => $ewa,
                    'net_salary' => $netSalary,
                ];
            }

            return response()->json([
                'message' => 'File parsed successfully',
                'file_name' => $file->getClientOriginalName(),
                'rows_count' => count($dataRows),
                'rows' => $dataRows,
            ]);

        } catch (\\Exception $e) {
            Log::error('Retail Payroll Simulate Error: ' . $e->getMessage());
            return response()->json(['message' => 'Error: ' . $e->getMessage()], 500);
        }
    }
`;

content = content.replace(
  `    public function saveImport(Request $request)`,
  parseHeadersCode + `\n    public function saveImport(Request $request)`
);

fs.writeFileSync(path, content);
console.log('Backend mapping endpoints added!');
