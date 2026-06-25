<?php

namespace App\Services;

use Illuminate\Support\Facades\Log;

class PayrollImportService
{
    /**
     * Process Excel file and extract payroll data
     */
    public function processImport($file, $period)
    {
        $storedPath = $file->storeAs('imports', $file->getClientOriginalName());

        try {
            // Use PhpSpreadsheet directly to read calculated values
            $reader = \PhpOffice\PhpSpreadsheet\IOFactory::createReader('Xlsx');
            $reader->setReadDataOnly(true); // READ CALCULATED VALUES, NOT FORMULAS
            $spreadsheet = $reader->load($file->getRealPath());
            $sheet = $spreadsheet->getSheet(0);

            $highestRow = $sheet->getHighestRow();
            $highestColumn = $sheet->getHighestColumn();

            // Helper function to get calculated value from cell
            $getCellValue = function ($col, $row) use ($sheet) {
                if (! $col) {
                    return 0;
                } // Return 0 if column mapping not found

                try {
                    $cell = $sheet->getCell($col.$row);
                    $value = $cell->getCalculatedValue();

                    // Clean numeric values
                    if (is_numeric($value)) {
                        return (float) $value;
                    }

                    // Clean string numeric values (remove currency symbols, etc)
                    if (is_string($value)) {
                        $cleaned = preg_replace('/[^0-9\.\,\-]/', '', $value);
                        if ($cleaned !== '' && is_numeric($cleaned)) {
                            return (float) $cleaned;
                        }

                        return $value; // Return as string if not numeric
                    }

                    return $value ?? 0;
                } catch (\Exception $e) {
                    return 0;
                }
            };

            // Detect header row (look for "Nama Karyawan" or "NAMA")
            $headerRowIndex = -1;
            for ($row = 1; $row <= min(10, $highestRow); $row++) {
                $rowIterator = $sheet->getRowIterator($row, $row)->current();
                $cellIterator = $rowIterator->getCellIterator('A', $highestColumn);
                $cellIterator->setIterateOnlyExistingCells(false);

                foreach ($cellIterator as $cell) {
                    $cellValue = $cell->getValue();

                    if ($cellValue && (stripos($cellValue, 'Nama Karyawan') !== false || strtoupper(trim($cellValue)) === 'NAMA')) {
                        $headerRowIndex = $row;
                        Log::info("Header found at row $row, col ".$cell->getColumn());
                        break 2;
                    }
                }
            }

            if ($headerRowIndex === -1) {
                throw new \Exception('Format tidak dikenali. Pastikan ada kolom "Nama Karyawan" atau "NAMA".');
            }

            // BUILD COLUMN MAPPING based on header names
            $columnMapping = [];
            $headerPatterns = [
                'periode' => ['Periode'],
                'nama_karyawan' => ['Nama Karyawan', 'Nama Pegawai', 'NAMA'],
                'no_rekening' => ['No Rekening', 'Rekening'],
                'gaji_pokok' => ['Gaji Pokok', 'Gapok', 'Basic Salary'],
                'kehadiran_jumlah' => [['Kehadiran', 'Jumlah']],
                'kehadiran_rate' => [['Kehadiran', '/ Hari']],
                'transport_jumlah' => [['Transport', 'Jumlah']],
                'transport_rate' => [['Transport', '/ Hari']],
                'kesehatan_jumlah' => ['Tunj. Kesehatan'],
                'tunj_jabatan' => ['Tunj. Jabatan'],
                'total_gaji' => [['Total Gaji', '( Rp )']],
                'total_gaji_bonus' => ['Total Gaji & Bonus'],
                'lembur_rate' => [['Lembur', '/ Jam']],
                'lembur_jam' => [['Lembur', 'Jam']],
                'lembur_jumlah' => [['Lembur', 'Jumlah']],
                'insentif' => ['Insentif Kehadrian'],
                'insentif_luar_kota' => ['Luar Kota', 'Insentif Luar Kota'],
                'insentif_kehadiran' => ['Insentif Kehadiran'],
                'insentif_lebaran' => ['Insentif Lebaran'],
                'backup' => ['Backup'],
                'adjustment' => ['Adj', 'Penyesuaian', 'Kebijakan'],
                'piket_um_sabtu' => ['Piket', 'Piket UM'],
                'absen' => ['Absen 1x', 'Absen 1X'],
                'alfa' => ['ALFA', 'Alpa'],
                'terlambat' => ['Terlambat'],
                'selisih' => ['Selisih SO', 'Selisih'],
                'pinjaman' => ['Pinjaman'],
                'kasbon' => ['Kasbon'],
                'adm_bank' => ['Adm Bank', 'Admin Bank'],
                'bpjs_tk' => ['BPJS TK', 'BPJS Ketenagakerjaan'],
                'jumlah_potongan' => [['Potongan', 'Jumlah'], 'Total Potongan'],
                'grand_total' => ['Grand Total'],
                'ewa' => ['EWA', 'Pinjaman ke Stafbook', 'Pinjaman stafbook'],
                'potongan_ewa' => ['Potongan EWA'],
                'payroll' => ['Payroll', 'THP', 'NOMINAL'],
                'jml_hr_masuk' => ['JML HR', 'Jumlah Hari'],
            ];

            // Use cell iterator to support columns beyond Z (AA, AB, etc.)
            // ALSO build a lookup of all header values for merged cell detection
            $allHeaders = []; // col => headerValue
            $allSubs = [];    // col => subValue
            $colOrder = [];   // ordered list of column letters

            $headerRow = $sheet->getRowIterator($headerRowIndex, $headerRowIndex)->current();
            $cellIterator = $headerRow->getCellIterator('A', $highestColumn);
            $cellIterator->setIterateOnlyExistingCells(false);

            foreach ($cellIterator as $cell) {
                $col = $cell->getColumn();
                $colOrder[] = $col;
                $allHeaders[$col] = $cell->getValue();
                $allSubs[$col] = $sheet->getCell($col.($headerRowIndex + 1))->getValue();
            }

            // Now iterate and map
            foreach ($colOrder as $idx => $col) {
                $headerValue = $allHeaders[$col];
                $unitsValue = $allSubs[$col];

                // For merged cell support: if header is empty, inherit from previous column
                $effectiveHeader = $headerValue;
                if (empty($effectiveHeader) && $idx > 0) {
                    $prevCol = $colOrder[$idx - 1];
                    $effectiveHeader = $allHeaders[$prevCol];
                }

                foreach ($headerPatterns as $key => $patterns) {
                    // Skip if already mapped
                    if (isset($columnMapping[$key])) {
                        continue;
                    }

                    $alternativePatterns = is_array($patterns) ? $patterns : [$patterns];

                    foreach ($alternativePatterns as $pattern) {
                        if (is_array($pattern)) {
                            // Multi-row header check: use effectiveHeader (merged cell aware)
                            $headerMatch = $effectiveHeader && stripos($effectiveHeader, $pattern[0]) !== false;
                            $unitsMatch = $unitsValue && stripos($unitsValue, $pattern[1]) !== false;

                            if ($headerMatch && $unitsMatch) {
                                $columnMapping[$key] = $col;
                                break;
                            }
                        } else {
                            // Single check: header row OR sub-header row
                            $matchedHeader = $headerValue && stripos($headerValue, $pattern) !== false;
                            $matchedSub = $unitsValue && stripos($unitsValue, $pattern) !== false;

                            if ($matchedHeader || $matchedSub) {
                                $columnMapping[$key] = $col;
                                break;
                            }
                        }
                    }
                }
            }

            Log::info('Column Mapping Detected', $columnMapping);

            // Detect Outlet Name and Type
            $firstCell = $sheet->getCell('A1')->getValue();
            $outletName = null;
            $type = 'fnb'; // Default

            if (stripos($firstCell, 'Tung Tau') !== false) {
                $outletName = 'Tung Tau';
                $type = 'fnb';
            } elseif (stripos($storedPath, 'Maximum 600') !== false || stripos($firstCell, 'GD 600') !== false) {
                $outletName = 'GD 600';
                $type = 'fnb';
            } elseif (stripos($firstCell, 'HO') !== false || stripos($storedPath, 'HO') !== false) {
                $outletName = 'Head Office';
                $type = 'ho';
            }

            $dataRows = [];
            $startDataRow = $headerRowIndex + 2;

            for ($row = $startDataRow; $row <= $highestRow; $row++) {
                // Get employee name
                $namaCol = $columnMapping['nama_karyawan'] ?? null;
                if (! $namaCol) {
                    continue;
                }

                $employeeName = $getCellValue($namaCol, $row);

                // Skip if no employee name
                if (empty($employeeName) || ! is_string($employeeName)) {
                    continue;
                }

                $periode = $getCellValue($columnMapping['periode'] ?? null, $row);
                $accountNumber = $getCellValue($columnMapping['no_rekening'] ?? null, $row);

                // Fix for cellular format where first column of Nama Karyawan is just a "+"
                if ($employeeName === '+') {
                    $namaColLetter = $columnMapping['nama_karyawan'];
                    $nextColLetter = ++$namaColLetter;
                    $employeeName = $getCellValue($nextColLetter, $row);
                }

                if (empty($employeeName) || ! is_string($employeeName)) {
                    continue;
                }

                $basicSalary = $getCellValue($columnMapping['gaji_pokok'] ?? null, $row);
                $daysPresent = $getCellValue($columnMapping['jml_hr_masuk'] ?? null, $row);

                // Allowances
                $kehadiranAllowance = $getCellValue($columnMapping['kehadiran_jumlah'] ?? null, $row);
                $kehadiranRate = $getCellValue($columnMapping['kehadiran_rate'] ?? null, $row);
                $transportAllowance = $getCellValue($columnMapping['transport_jumlah'] ?? null, $row);
                $transportRate = $getCellValue($columnMapping['transport_rate'] ?? null, $row);
                $healthAllowance = $getCellValue($columnMapping['kesehatan_jumlah'] ?? null, $row);
                $positionAllowance = $getCellValue($columnMapping['tunj_jabatan'] ?? null, $row);

                // Overtime
                $overtimeHours = $getCellValue($columnMapping['lembur_jam'] ?? null, $row);
                $overtimePay = $getCellValue($columnMapping['lembur_jumlah'] ?? null, $row);
                $overtimeRate = $getCellValue($columnMapping['lembur_rate'] ?? null, $row);

                // Other Income
                $holidayAllowance = $getCellValue($columnMapping['insentif'] ?? null, $row);
                $insentifLuarKota = $getCellValue($columnMapping['insentif_luar_kota'] ?? null, $row);
                $insentifKehadiran = $getCellValue($columnMapping['insentif_kehadiran'] ?? null, $row);
                $insentifLebaran = $getCellValue($columnMapping['insentif_lebaran'] ?? null, $row);
                $backup = $getCellValue($columnMapping['backup'] ?? null, $row);
                $adjustment = $getCellValue($columnMapping['adjustment'] ?? null, $row);
                $piketUmSabtu = $getCellValue($columnMapping['piket_um_sabtu'] ?? null, $row);

                // Totals
                $totalGaji = $getCellValue($columnMapping['total_gaji'] ?? null, $row);
                $totalGajiBonus = $getCellValue($columnMapping['total_gaji_bonus'] ?? null, $row);

                // Deductions Breakdown
                $absen = $getCellValue($columnMapping['absen'] ?? null, $row);
                $alfa = $getCellValue($columnMapping['alfa'] ?? null, $row);
                $terlambat = $getCellValue($columnMapping['terlambat'] ?? null, $row);
                $selisihSO = $getCellValue($columnMapping['selisih'] ?? null, $row);
                $pinjaman = $getCellValue($columnMapping['pinjaman'] ?? null, $row);
                $kasbon = $getCellValue($columnMapping['kasbon'] ?? null, $row);
                $admBank = $getCellValue($columnMapping['adm_bank'] ?? null, $row);
                $bpjsTK = $getCellValue($columnMapping['bpjs_tk'] ?? null, $row);
                $totalDeductions = $getCellValue($columnMapping['jumlah_potongan'] ?? null, $row);

                // Grand Total and Final Net Salary
                $grandTotal = $getCellValue($columnMapping['grand_total'] ?? null, $row);
                $ewa = $getCellValue($columnMapping['ewa'] ?? null, $row);
                $potEwa = $getCellValue($columnMapping['potongan_ewa'] ?? null, $row);
                $netSalary = $getCellValue($columnMapping['payroll'] ?? null, $row);

                if ($netSalary <= 0 && $grandTotal > 0) {
                    $netSalary = $grandTotal;
                }

                $allowancesTotal = $kehadiranAllowance + $transportAllowance + $healthAllowance + $positionAllowance;

                if ($totalGajiBonus > 0) {
                    $grossSalary = $totalGajiBonus;
                } elseif ($totalGaji > 0) {
                    $grossSalary = $totalGaji;
                } else {
                    $grossSalary = $basicSalary + $allowancesTotal + $overtimePay + $holidayAllowance + $adjustment + $insentifLebaran + $backup;
                }

                $details = [
                    'account_number' => $accountNumber,
                    'days_present' => $daysPresent,
                    'transport_allowance' => $transportAllowance,
                    'transport_rate' => $transportRate,
                    'health_allowance' => $healthAllowance,
                    'position_allowance' => $positionAllowance,
                    'holiday_allowance' => $holidayAllowance,
                    'attendance_allowance' => $kehadiranAllowance,
                    'attendance_rate' => $kehadiranRate,
                    'insentif_lebaran' => $insentifLebaran,
                    'backup' => $backup,
                    'adjustment' => $adjustment,
                    'overtime_hours' => $overtimeHours,
                    'overtime_rate' => $overtimeRate,
                    'insentif_luar_kota' => $insentifLuarKota,
                    'insentif_kehadiran' => $insentifKehadiran,
                    'piket_um_sabtu' => $piketUmSabtu,
                    'total_gaji' => $totalGaji,
                    'deductions' => [
                        'absent' => $absen,
                        'alfa' => $alfa,
                        'late' => $terlambat,
                        'shortage' => $selisihSO,
                        'loan' => $pinjaman > 0 ? $pinjaman : $kasbon,
                        'bank_fee' => $admBank,
                        'bpjs_tk' => $bpjsTK,
                    ],
                    'ewa' => $potEwa > 0 ? $potEwa : $ewa,
                    'grand_total' => $grandTotal,
                ];

                $parsed = [
                    'employee_name' => $employeeName,
                    'period' => $period ?? date('Y-m'),
                    'type' => $type,
                    'outlet_name' => $outletName,
                    'basic_salary' => $basicSalary,
                    'allowances' => $allowancesTotal,
                    'overtime' => $overtimePay,
                    'total_deductions' => $totalDeductions,
                    'net_salary' => $netSalary,
                    'gross_salary' => $grossSalary,
                    'details' => $details,
                ];

                $dataRows[] = $parsed;
            }

            return [
                'success' => true,
                'file_name' => $file->getClientOriginalName(),
                'rows_count' => count($dataRows),
                'rows' => $dataRows,
            ];

        } catch (\Exception $e) {
            return [
                'success' => false,
                'message' => $e->getMessage(),
            ];
        }
    }
}
