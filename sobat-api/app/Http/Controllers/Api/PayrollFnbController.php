<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\PayrollFnb;
use App\Models\Employee;
use App\Models\Role;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use PDF;
use App\Services\GroqAiService;

class PayrollFnbController extends Controller
{
    use Traits\PayrollThpCalculator;
    private function isAdmin(): bool
    {
        $user = auth()->user();
        $roleName = $user->role ? strtolower($user->role->name) : '';
        return in_array($roleName, [Role::SUPER_ADMIN, Role::ADMIN, Role::ADMIN_CABANG, Role::HR, 'admin_hr']);
    }

    /**
     * Display a listing of FnB payrolls
     */
    public function index(Request $request)
    {
        $user = auth()->user();
        $query = PayrollFnb::with('employee');

        // Check scope
        if (!$this->isAdmin()) {
            $employeeId = $user->employee ? $user->employee->id : null;
            if ($employeeId) {
                $query->where('employee_id', $employeeId);
                // Also scope status for non-admins
                $query->whereIn('status', ['approved', 'paid']);
            } else {
                return response()->json([]);
            }
        }
        
        // Filter by period
        if ($request->has('period')) {
            $query->where('period', $request->period);
        } elseif ($request->has('month') && $request->has('year') && $request->month != 0 && $request->year != 0) {
            $periodString = sprintf('%04d-%02d', $request->year, $request->month);
            $query->where('period', $periodString);
        }
        
        
        // Filter by search name
        if ($request->has('search') && !empty($request->search)) {
            $query->whereHas('employee', function($q) use ($request) {
                $q->where('full_name', 'like', '%' . $request->search . '%');
            });
        }

        // Filter by status (allow overriding if user is checking 'draft' etc, but mostly for admins)
        if ($request->has('status')) {
            $query->where('status', $request->status);
        }
        
        $payrolls = $query->orderBy('period', 'desc')
            ->orderBy('created_at', 'desc')
            ->paginate(20);
        
        // Format each payroll with grouped allowances and deductions
        $payrolls->getCollection()->transform(function ($payroll) {
            $formatted = $payroll->toArray();
            
            // Add structured allowances
            $formatted['allowances'] = [
                'Kehadiran' => [
                    'rate' => $payroll->attendance_rate,
                    'amount' => $payroll->attendance_amount,
                ],
                'Transport' => [
                    'rate' => $payroll->transport_rate,
                    'amount' => $payroll->transport_amount,
                ],
                'Tunjangan Kesehatan' => $payroll->health_allowance,
                'Tunjangan Jabatan' => $payroll->position_allowance,
                'Lembur' => [
                    'rate' => $payroll->overtime_rate,
                    'hours' => $payroll->overtime_hours,
                    'amount' => $payroll->overtime_amount,
                ],
                'Insentif Lebaran' => $payroll->holiday_allowance,
                'Adjustment' => $payroll->adjustment,
                'Kebijakan HO' => $payroll->policy_ho,
            ];
            
            // Add structured deductions
            $formatted['deductions'] = [
                'Potongan Absen' => $payroll->deduction_absent,
                'Terlambat' => $payroll->deduction_late,
                'Selisih SO' => $payroll->deduction_shortage,
                'Pinjaman' => $payroll->deduction_loan,
                'Adm Bank' => $payroll->deduction_admin_fee,
                'BPJS TK' => $payroll->deduction_bpjs_tk,
            ];
            
            // Dynamic THP calculation with fallback for import anomalies
            $thpResult = $this->calculateThp($payroll, 
                ['basic_salary', 'attendance_amount', 'transport_amount', 'health_allowance', 'position_allowance', 'overtime_amount', 'holiday_allowance', 'adjustment', 'policy_ho'],
                ['deduction_absent', 'deduction_late', 'deduction_shortage', 'deduction_loan', 'deduction_admin_fee', 'deduction_bpjs_tk']
            );
            $formatted['thp'] = $thpResult['thp'];
            if ($thpResult['net_salary'] !== null) {
                $formatted['net_salary'] = $thpResult['net_salary'];
            }
            
            // Fallback for gross salary if it's 0 or missing in DB
            $gross = (float)($payroll->total_salary_2 ?? 0);
            $formatted['total_salary_2'] = $gross > 0 ? $gross : $thpResult['total_income'];
            
            // Add attendance data
            $formatted['attendance'] = [
                'Total Hari' => $payroll->days_total,
                'Off' => $payroll->days_off,
                'Sakit' => $payroll->days_sick,
                'Ijin' => $payroll->days_permission,
                'Alfa' => $payroll->days_alpha,
                'Cuti' => $payroll->days_leave,
                'Hadir' => $payroll->days_present,
            ];
            
            return $formatted;
        });
        
        return response()->json($payrolls);
    }

    /**
     * Parse Excel headers for FnB
     */
    public function parseHeaders(Request $request)
    {
        $request->validate([
            'file' => 'required|file|mimes:xlsx,xls',
        ]);

        $file = $request->file('file');

        try {
            $reader = \PhpOffice\PhpSpreadsheet\IOFactory::createReader('Xlsx');
            $reader->setReadDataOnly(true);
            $spreadsheet = $reader->load($file->getRealPath());
            $sheet = $spreadsheet->getSheet(0);
            
            $highestRow = $sheet->getHighestRow();
            $highestColumn = $sheet->getHighestColumn();
            
            // Detect header row
            $headerRowIndex = -1;
            for ($row = 1; $row <= min(10, $highestRow); $row++) {
                $rowIterator = $sheet->getRowIterator($row, $row)->current();
                $cellIterator = $rowIterator->getCellIterator('A', $highestColumn);
                $cellIterator->setIterateOnlyExistingCells(false);
                
                foreach ($cellIterator as $cell) {
                    $cellValue = $cell->getValue();
                    if ($cellValue && (stripos((string)$cellValue, 'Nama Karyawan') !== false || stripos((string)$cellValue, 'Nama Pegawai') !== false)) {
                        $headerRowIndex = $row;
                        break 2;
                    }
                }
            }
            
            if ($headerRowIndex === -1) {
                return response()->json(['message' => 'Format Excel tidak dikenali. Pastikan ada kolom "Nama Karyawan".'], 422);
            }
            
            // Build header lookup
            $allHeaders = [];
            $allSubs = [];
            $colOrder = [];
            $uiHeaders = [];
            
            $headerRow = $sheet->getRowIterator($headerRowIndex, $headerRowIndex)->current();
            $cellIterator = $headerRow->getCellIterator('A', $highestColumn);
            $cellIterator->setIterateOnlyExistingCells(false);
            
            foreach ($cellIterator as $cell) {
                $col = $cell->getColumn();
                $colOrder[] = $col;
                
                $headerValue = trim((string)$cell->getValue());
                $subValue = trim((string)$sheet->getCell($col . ($headerRowIndex + 1))->getValue());
                
                $allHeaders[$col] = $headerValue;
                $allSubs[$col] = $subValue;
                
                // Create a meaningful display title for the UI
                $displayTitle = $headerValue;
                if (empty($displayTitle)) {
                    for ($i = count($colOrder) - 1; $i >= 0; $i--) {
                        if (!empty($allHeaders[$colOrder[$i]])) {
                            $displayTitle = $allHeaders[$colOrder[$i]];
                            break;
                        }
                    }
                }
                
                if (!empty($subValue)) {
                    $displayTitle .= empty($displayTitle) ? $subValue : ' - ' . $subValue;
                }
                
                $uiHeaders[$col] = trim($displayTitle);
            }
            
            // BUILD COLUMN MAPPING dynamically
            $headerPatterns = [
                'employee_name' => ['Nama Karyawan', 'Nama Pegawai'],
                'account_number' => ['No Rekening', 'Rekening'],
                'days_total' => [['Jumlah', 'Hari']],
                'days_off' => ['Off'],
                'days_sick' => ['Sakit'],
                'days_permission' => ['Ijin'],
                'days_alpha' => ['Alfa', 'ALFA', 'Alpa'],
                'days_leave' => ['Cuti'],
                'days_present' => ['Ada', 'Hadir'],
                'basic_salary' => ['Gaji Pokok', 'Gapok', 'Basic Salary'],
                'attendance_rate' => [['Kehadiran', '/ Hari']],
                'attendance_allowance' => [['Kehadiran', 'Jumlah']],
                'transport_rate' => [['Transport', '/ Hari']],
                'transport_amount' => [['Transport', 'Jumlah']],
                'health_allowance' => ['Tunj. Kesehatan'],
                'position_allowance' => ['Tunj. Jabatan'],
                'total_salary_1' => ['Total Gaji            ( Rp )', 'Total Gaji'],
                'overtime_rate' => [['Lembur', '/ Jam']],
                'overtime_hours' => [['Lembur', 'Jam']],
                'overtime_amount' => [['Lembur', 'Jumlah']],
                'backup' => ['Backup'],
                'insentif_kehadiran' => ['Insentif Kehadrian', 'Insentif Kehadiran'],
                'bonus' => ['Insentif Lebaran'],
                'insentif' => ['Insentif '], // Added for Max 600
                'total_salary_gross' => ['Total Gaji    (Rp)', 'Total Gaji & Bonus'],
                'policy_ho' => ['Kebijakan'],
                'deduction_absent' => ['Absen 1X', 'Absen 1x'],
                'terlambat_menit' => ['terlambat (menit)'],
                'deduction_late' => ['Terlambat'],
                'shortage_deduction' => ['Selisih SO', 'Selisih'],
                'deduction_loan' => ['Pinjaman'],
                'deduction_admin_fee' => ['Adm Bank', 'Admin Bank'],
                'deduction_bpjs_tk' => ['BPJS TK', 'BPJS Ketenagakerjaan'],
                'total_deduction' => [['Potongan', 'Jumlah'], 'Total Potongan'],
                'thp' => ['Grand Total'],
                'ewa_amount' => ['EWA', 'Pinjaman ke Stafbook', 'Pinjaman stafbook'],
                'potongan_ewa' => ['Potongan EWA'],
                'net_salary' => ['Total Gaji Ditransfer', 'Payroll', 'THP'],
                'adjustment' => ['Adj', 'Penyesuaian', 'Kekurangan Gaji'],
            ];
            
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
                            $unitsMatch = $unitsValue && stripos((string)$unitsValue, $pattern[1]) !== false;
                            if ($pattern[1] === 'Jam' && $unitsMatch && stripos((string)$unitsValue, '/ Jam') !== false) {
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
                            $matchedSub = $unitsValue && stripos((string)$unitsValue, $pattern) !== false;
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
            
            // Store file temporarily
            $filename = time() . '_' . $file->getClientOriginalName();
            $path = $file->storeAs('temp/payrolls', $filename, 'local');
            
            return response()->json([
                'requiresMapping' => true,
                'headers' => $uiHeaders,
                'default_mapping' => $columnMapping,
                'headerRowIndex' => $headerRowIndex,
            ]);

        } catch (\Exception $e) {
            Log::error('FnB Payroll Parse Headers Error: ' . $e->getMessage());
            return response()->json(['message' => 'Error: ' . $e->getMessage()], 500);
        }
    }

    /**
     * Simulate FnB payroll import using mapped columns
     */
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
            $reader = \PhpOffice\PhpSpreadsheet\IOFactory::createReader('Xlsx');
            $reader->setReadDataOnly(true);
            $spreadsheet = $reader->load($file->getRealPath());
            $sheet = $spreadsheet->getSheet(0);
            
            $highestRow = $sheet->getHighestRow();
            
            $getCellValue = function($col, $row) use ($sheet) {
                if (!$col) return 0;
                try {
                    $cell = $sheet->getCell($col . $row);
                    $value = $cell->getCalculatedValue();
                    if (is_numeric($value)) return (float) $value;
                    if (is_string($value)) {
                        $cleaned = preg_replace('/[^0-9\.\,\-]/', '', $value);
                        if ($cleaned !== '' && is_numeric($cleaned)) return (float) $cleaned;
                        return $value;
                    }
                    return $value ?? 0;
                } catch (\Exception $e) {
                    return 0;
                }
            };
            
            $firstCell = $sheet->getCell('A1')->getValue();
            $outletName = 'FnB';
            if ($firstCell && stripos($firstCell, 'Tung Tau') !== false) {
                $outletName = 'Tung Tau';
            } elseif ($firstCell && stripos($firstCell, 'GD 600') !== false) {
                $outletName = 'GD 600';
            }
            
            $dataRows = [];
            $startDataRow = $headerRowIndex + 2; 
            
            for ($row = $startDataRow; $row <= $highestRow; $row++) {
                $employeeName = $getCellValue($columnMapping['employee_name'] ?? null, $row);
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
                
                $basicSalary = (float) $getCellValue($columnMapping['basic_salary'] ?? null, $row);
                $attendanceRate = (float) $getCellValue($columnMapping['attendance_rate'] ?? null, $row);
                $attendanceAmount = (float) $getCellValue($columnMapping['attendance_allowance'] ?? null, $row);
                $transportRate = (float) $getCellValue($columnMapping['transport_rate'] ?? null, $row);
                $transportAmount = (float) $getCellValue($columnMapping['transport_amount'] ?? null, $row);
                $healthAllowance = (float) $getCellValue($columnMapping['health_allowance'] ?? null, $row);
                $positionAllowance = (float) $getCellValue($columnMapping['position_allowance'] ?? null, $row);
                $totalSalary1 = (float) $getCellValue($columnMapping['total_salary_1'] ?? null, $row);
                
                $overtimeRate = (float) $getCellValue($columnMapping['overtime_rate'] ?? null, $row);
                $overtimeHours = (float) $getCellValue($columnMapping['overtime_hours'] ?? null, $row);
                $overtimeAmount = (float) $getCellValue($columnMapping['overtime_amount'] ?? null, $row);
                
                $backup = (float) $getCellValue($columnMapping['backup'] ?? null, $row);
                $insentif = (float) $getCellValue($columnMapping['insentif'] ?? null, $row);
                $insentifKehadiran = (float) $getCellValue($columnMapping['insentif_kehadiran'] ?? null, $row);
                $holidayAllowance = (float) $getCellValue($columnMapping['bonus'] ?? null, $row);
                $adjustment = (float) $getCellValue($columnMapping['adjustment'] ?? null, $row);
                $totalSalary2 = (float) $getCellValue($columnMapping['total_salary_gross'] ?? null, $row);
                $policyHo = (float) $getCellValue($columnMapping['policy_ho'] ?? null, $row);
                
                $deductionAbsent = (float) $getCellValue($columnMapping['deduction_absent'] ?? null, $row);
                $deductionLate = (float) $getCellValue($columnMapping['deduction_late'] ?? null, $row);
                $deductionShortage = (float) $getCellValue($columnMapping['shortage_deduction'] ?? null, $row);
                $deductionLoan = (float) $getCellValue($columnMapping['deduction_loan'] ?? null, $row);
                $deductionAdminFee = (float) $getCellValue($columnMapping['deduction_admin_fee'] ?? null, $row);
                $deductionBpjsTk = (float) $getCellValue($columnMapping['deduction_bpjs_tk'] ?? null, $row);
                $totalDeductions = (float) $getCellValue($columnMapping['total_deduction'] ?? null, $row);
                
                if ($totalDeductions <= 0) {
                    $totalDeductions = abs($deductionAbsent) + abs($deductionLate) + abs($deductionShortage) + abs($deductionLoan) + abs($deductionAdminFee) + abs($deductionBpjsTk);
                }
                
                $grandTotal = (float) $getCellValue($columnMapping['thp'] ?? null, $row);
                $ewa = (float) $getCellValue($columnMapping['ewa_amount'] ?? null, $row);
                $netSalary = (float) $getCellValue($columnMapping['net_salary'] ?? null, $row);
                
                if ($netSalary <= 0 && $grandTotal > 0) {
                    $netSalary = $grandTotal;
                }
                
                if ($totalSalary2 > 0) {
                    $grossSalary = $totalSalary2;
                } elseif ($totalSalary1 > 0) {
                    $grossSalary = $totalSalary1;
                } else {
                    $grossSalary = $basicSalary + $attendanceAmount + $transportAmount + $healthAllowance + $positionAllowance + $overtimeAmount + $holidayAllowance + $adjustment + $backup + $insentifKehadiran + $insentif;
                }
                
                $parsed = [
                    'employee_name' => $employeeName,
                    'period' => $request->period ?? date('Y-m'),
                    'account_number' => $getCellValue($columnMapping['account_number'] ?? null, $row),
                    'outlet_name' => $outletName,
                    
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
                
                $dataRows[] = $parsed;
            }

            return response()->json([
                'message' => 'Simulasi berhasil',
                'rows' => $dataRows,
            ]);

        } catch (\Exception $e) {
            Log::error('FnB Payroll Simulate Error: ' . $e->getMessage());
            return response()->json(['message' => 'Error: ' . $e->getMessage()], 500);
        }
    }


    /**
     * Save imported FnB payroll data
     */
    public function saveImport(Request $request)
    {
        $request->validate([
            'rows' => 'required|array',
            'rows.*.employee_name' => 'required|string',
        ]);

        try {
            $saved = 0;
            $errors = [];
            
            foreach ($request->rows as $index => $row) {
                // Find employee by full_name (not 'name')
                $employee = Employee::where('full_name', $row['employee_name'])->first();
                
                if (!$employee) {
                    $errors[] = "Row " . ($index + 1) . ": Employee '{$row['employee_name']}' not found";
                    continue;
                }
                
                // Check if payroll already exists for this period
                $existing = PayrollFnb::where('employee_id', $employee->id)
                    ->where('period', $row['period'])
                    ->first();
                
                
                $payrollData = array_merge($row, [
                    'employee_id' => $employee->id,
                    'status' => 'draft'
                ]);
                
                if ($existing) {
                    $existing->update($payrollData);
                } else {
                
                // Debug log the data being saved
                Log::info('FnB Payroll Save Data', [
                    'employee_id' => $employee->id,
                    'employee_name' => $row['employee_name'],
                    'data_keys' => array_keys($row),
                ]);
                
                // Create payroll
                PayrollFnb::create($payrollData);
                }
                
                $saved++;
            }
            
            return response()->json([
                'message' => "Successfully saved $saved payroll records",
                'saved' => $saved,
                'errors' => $errors,
            ]);

        } catch (\Exception $e) {
            Log::error('FnB Payroll Save Error: ' . $e->getMessage());
            return response()->json(['message' => 'Error: ' . $e->getMessage()], 500);
        }
    }

    /**
     * Display single payroll with formatted details
     */
    public function show($id)
    {
        $payroll = PayrollFnb::with('employee')->findOrFail($id);

        if (!$this->isAdmin()) {
            $user = auth()->user();
            if (!$user->employee || $user->employee->id !== $payroll->employee_id) {
                return response()->json(['message' => 'Unauthorized'], 403);
            }
        }

        $formatted = $payroll->toArray();
        
        // Add structured allowances
        $formatted['allowances'] = [
            'Kehadiran' => [
                'rate' => $payroll->attendance_rate,
                'amount' => $payroll->attendance_amount,
            ],
            'Transport' => [
                'rate' => $payroll->transport_rate,
                'amount' => $payroll->transport_amount,
            ],
            'Tunjangan Kesehatan' => $payroll->health_allowance,
            'Tunjangan Jabatan' => $payroll->position_allowance,
            'Lembur' => [
                'rate' => $payroll->overtime_rate,
                'hours' => $payroll->overtime_hours,
                'amount' => $payroll->overtime_amount,
            ],
            'Insentif Lebaran' => $payroll->holiday_allowance,
            'Adjustment' => $payroll->adjustment,
            'Kebijakan HO' => $payroll->policy_ho,
        ];
        
        // Add structured deductions
        $formatted['deductions'] = [
            'Potongan Absen' => $payroll->deduction_absent,
            'Terlambat' => $payroll->deduction_late,
            'Selisih SO' => $payroll->deduction_shortage,
            'Pinjaman' => $payroll->deduction_loan,
            'Adm Bank' => $payroll->deduction_admin_fee,
            'BPJS TK' => $payroll->deduction_bpjs_tk,
        ];
        
        // Dynamic THP calculation with fallback for import anomalies
        $thpResult = $this->calculateThp($payroll, 
            ['basic_salary', 'attendance_amount', 'transport_amount', 'health_allowance', 'position_allowance', 'overtime_amount', 'holiday_allowance', 'adjustment', 'policy_ho'],
            ['deduction_absent', 'deduction_late', 'deduction_shortage', 'deduction_loan', 'deduction_admin_fee', 'deduction_bpjs_tk']
        );
        $formatted['thp'] = $thpResult['thp'];
        if ($thpResult['net_salary'] !== null) {
            $formatted['net_salary'] = $thpResult['net_salary'];
        }
        
        // Fallback for gross salary if it's 0 or missing in DB
        $gross = (float)($payroll->total_salary_2 ?? 0);
        $formatted['total_salary_2'] = $gross > 0 ? $gross : $thpResult['total_income'];
        
        // Add attendance data
        $formatted['attendance'] = [
            'Total Hari' => $payroll->days_total,
            'Off' => $payroll->days_off,
            'Sakit' => $payroll->days_sick,
            'Ijin' => $payroll->days_permission,
            'Alfa' => $payroll->days_alpha,
            'Cuti' => $payroll->days_leave,
            'Hadir' => $payroll->days_present,
        ];
        
        return response()->json($formatted);
    }

    /**
     * Update payroll status
     */
    /**
     * Update payroll status
     */
    public function updateStatus(Request $request, $id)
    {
        if (!$this->isAdmin()) {
            return response()->json(['message' => 'Anda tidak memiliki akses untuk operasi ini.'], 403);
        }

        $request->validate([
            'status' => 'required|in:draft,approved,paid',
            'approval_signature' => 'nullable|string',
            'notes' => 'nullable|string', // Base64 string
                    ]);

        $payroll = PayrollFnb::findOrFail($id);
        
        $data = ['status' => $request->status];
        
        if ($request->status === 'approved' && $request->has('approval_signature')) {
            $data['approval_signature'] = $request->approval_signature;
            $data['signer_name'] = $request->signer_name;
            $data['notes'] = $request->notes;
            $data['approved_by'] = auth()->id();
        }

        $payroll->update($data);

        return response()->json([
            'message' => 'Status updated successfully',
            'payroll' => $payroll,
        ]);
    }

    /**
     * Delete payroll
     */
    public function destroy($id)
    {
        if (!$this->isAdmin()) {
            return response()->json(['message' => 'Anda tidak memiliki akses untuk operasi ini.'], 403);
        }

        $payroll = PayrollFnb::findOrFail($id);
        $payroll->delete();

        return response()->json(['message' => 'Payroll deleted successfully']);
    }

    /**
     * Generate payslip PDF
     */
    public function generateSlip($id)
    {
        try {
            $payroll = PayrollFnb::with('employee')->findOrFail($id);

            if (!$this->isAdmin()) {
                $user = auth()->user();
                if (!$user->employee || $user->employee->id !== $payroll->employee_id) {
                    return response()->json(['message' => 'Unauthorized'], 403);
                }
            }

            // Inject structured data for the view (same as show method)
            $payroll->allowances = [
                'Kehadiran' => [
                    'rate' => $payroll->attendance_rate,
                    'amount' => $payroll->attendance_amount,
                ],
                'Transport' => [
                    'rate' => $payroll->transport_rate,
                    'amount' => $payroll->transport_amount,
                ],
                'Tunjangan Kesehatan' => $payroll->health_allowance,
                'Tunjangan Jabatan' => $payroll->position_allowance,
                'Lembur' => [
                    'rate' => $payroll->overtime_rate,
                    'hours' => $payroll->overtime_hours,
                    'amount' => $payroll->overtime_amount,
                ],
                'Insentif Lebaran' => $payroll->holiday_allowance,
                'Adjustment' => $payroll->adjustment,
                'Kebijakan HO' => $payroll->policy_ho,
            ];
            
            $payroll->deductions = [
                'Potongan Absen' => $payroll->deduction_absent,
                'Terlambat' => $payroll->deduction_late,
                'Selisih SO' => $payroll->deduction_shortage,
                'Pinjaman' => $payroll->deduction_loan,
                'Adm Bank' => $payroll->deduction_admin_fee,
                'BPJS TK' => $payroll->deduction_bpjs_tk,
            ];
            
            $payroll->attendance = [
                'Total Hari' => $payroll->days_total,
                'Off' => $payroll->days_off,
                'Sakit' => $payroll->days_sick,
                'Ijin' => $payroll->days_permission,
                'Alfa' => $payroll->days_alpha,
                'Cuti' => $payroll->days_leave,
                'Hadir' => $payroll->days_present,
            ];
            
            // Dynamic THP calculation with fallback
            $thpResult = $this->calculateThp($payroll, 
                ['basic_salary', 'attendance_amount', 'transport_amount', 'health_allowance', 'position_allowance', 'overtime_amount', 'holiday_allowance', 'adjustment', 'policy_ho'],
                ['deduction_absent', 'deduction_late', 'deduction_shortage', 'deduction_loan', 'deduction_admin_fee', 'deduction_bpjs_tk']
            );
            $payroll->thp = $thpResult['thp'];
            if ($thpResult['net_salary'] !== null) {
                $payroll->net_salary = $thpResult['net_salary'];
                $payroll->final_payment = $thpResult['net_salary'];
            }
            $gross = (float)($payroll->total_salary_2 ?? 0);
            if ($gross <= 0) {
                $payroll->total_salary_2 = $thpResult['total_income'];
            }
            
            // Generate AI-powered personalized message
            $aiMessage = null;
            try {
                $groqService = new GroqAiService();
                $aiMessage = $groqService->generatePayslipMessage([
                    'employee_name' => $payroll->employee->full_name,
                    'period' => date('F Y', strtotime($payroll->period . '-01')),
                    'basic_salary' => $payroll->basic_salary,
                    'overtime' => $payroll->overtime_amount,
                    'net_salary' => $payroll->net_salary,
                    'join_date' => $payroll->employee->join_date,
                ]);
            } catch (\Exception $e) {
                // Ignore AI error
            }

            $pdf = PDF::loadView('payslips.fnb', [
                'payroll' => $payroll,
                'aiMessage' => $aiMessage
            ]);
            
            $filename = 'payslip_' . str_replace(' ', '_', $payroll->employee->full_name) . '_' . $payroll->period . '.pdf';
            
            return $pdf->download($filename);
        } catch (\Exception $e) {
            \Log::error('Error generating FnB payslip: ' . $e->getMessage());
            return response()->json([
                'message' => 'Failed to generate payslip',
                'error' => $e->getMessage()
            ], 500);
        }
    }
}
