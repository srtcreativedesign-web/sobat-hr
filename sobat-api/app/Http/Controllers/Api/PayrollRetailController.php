<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;



use App\Models\Employee;
use App\Models\Role;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Schema;
use Barryvdh\DomPDF\Facade\Pdf;
use App\Services\GroqAiService;

class PayrollRetailController extends Controller
{
    use Traits\PayrollThpCalculator;

    private function isAdmin(): bool
    {
        $user = auth()->user();
        $roleName = $user->role ? strtolower($user->role->name) : '';
        return in_array($roleName, [Role::SUPER_ADMIN, Role::ADMIN, Role::ADMIN_CABANG, Role::HR]);
    }

    private function getModel($divisionType)
    {
        $models = [
            'cellular' => \App\Models\PayrollCelluller::class,
            'hans' => \App\Models\PayrollHans::class,
            'ref' => \App\Models\PayrollRef::class,
            'wrapping' => \App\Models\PayrollWrapping::class,
            'mm' => \App\Models\PayrollMm::class,
            'money_changer' => \App\Models\PayrollMoneyChanger::class,
        ];

        if (!isset($models[$divisionType])) {
            abort(400, "Invalid division_type: {$divisionType}");
        }

        return new $models[$divisionType];
    }

    /**
     * Display a listing of Hans payrolls
     */
    public function index(Request $request)
    {
        $request->validate(['division_type' => 'required']);

        $user = auth()->user();
        // EAGER LOADING: employee
        $query = $this->getModel($request->division_type)->with('employee');
        
        // SECURITY CHECK: Scope query to authenticated user
        $roleName = $user->role ? strtolower($user->role->name) : '';
        if (!in_array($roleName, [Role::ADMIN, Role::SUPER_ADMIN, Role::HR])) {
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
        }

        // Filter by month and year (if period not explicitly provided)
        if (!$request->has('period') && $request->has('month') && $request->has('year') && $request->month != 0 && $request->year != 0) {
            $period = $request->year . '-' . str_pad($request->month, 2, '0', STR_PAD_LEFT);
            $query->where('period', $period);
        }
        // Filter by year only (used by Mobile App Riwayat Gaji)
        elseif (!$request->has('period') && $request->has('year') && !empty($request->year)) {
            $query->where('period', 'like', $request->year . '-%');
        }
        
        
        // Filter by search name
        if ($request->has('search') && !empty($request->search)) {
            $query->whereHas('employee', function($q) use ($request) {
                $q->where('full_name', 'like', '%' . $request->search . '%');
            });
        }

        // Filter by status (override for admins)
        if ($request->has('status')) {
            $query->where('status', $request->status);
        }
        
        $payrolls = $query->orderBy('period', 'desc')
            ->orderBy('created_at', 'desc')
            ->paginate(20);
        
        // Transform data structurally for the frontend
        $payrolls->getCollection()->transform(function ($payroll) {
            return $this->formatPayrollData($payroll);
        });
        
        return response()->json($payrolls);
    }
    
    /**
     * Import Hans payroll from Excel
     */
    
    private function findDataSheet($spreadsheet, &$headerRowIndex)
    {
        $headerRowIndex = -1;
        
        // Prioritize known data sheet names
        $priorityNames = ['gabungan', 'Gaji', 'payroll', 'Sheet1'];
        foreach ($priorityNames as $name) {
            $sheet = $spreadsheet->getSheetByName($name);
            if ($sheet) {
                $highestRow = $sheet->getHighestRow();
                for ($row = 1; $row <= min(30, $highestRow); $row++) {
                    $cellIterator = $sheet->getRowIterator($row)->current()->getCellIterator();
                    $cellIterator->setIterateOnlyExistingCells(false);
                    foreach ($cellIterator as $cell) {
                        $cellValue = (string) $cell->getValue();
                        if ($cellValue && (stripos($cellValue, 'Nama Karyawan') !== false || stripos($cellValue, 'Nama Pegawai') !== false)) {
                            $headerRowIndex = $row;
                            return $sheet;
                        }
                    }
                }
            }
        }
        
        // Fallback: scan all sheets
        foreach ($spreadsheet->getAllSheets() as $testSheet) {
            $highestRow = $testSheet->getHighestRow();
            $highestColumn = $testSheet->getHighestColumn();
            for ($row = 1; $row <= min(30, $highestRow); $row++) {
                $rowIterator = $testSheet->getRowIterator($row, $row)->current();
                $cellIterator = $rowIterator->getCellIterator('A', $highestColumn);
                $cellIterator->setIterateOnlyExistingCells(false);
                foreach ($cellIterator as $cell) {
                    $cellValue = (string) $cell->getValue();
                    if ($cellValue && (stripos($cellValue, 'Nama Karyawan') !== false || stripos($cellValue, 'Nama Pegawai') !== false)) {
                        $headerRowIndex = $row;
                        return $testSheet;
                    }
                }
            }
        }
        
        return null;
    }

    public function import(Request $request)
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
            
            // Helper to get calculated cell value
            $getCellValue = function($col, $row) use ($sheet) {
                $cell = $sheet->getCell($col . $row);
                $value = $cell->getCalculatedValue();
                
                if (is_numeric($value)) return (float) $value;
                if (is_string($value)) {
                    $cleaned = preg_replace('/[^0-9\.\,\-]/', '', $value);
                    if ($cleaned !== '' && is_numeric($cleaned)) return (float) $cleaned;
                    return $value;
                }
                return $value ?? 0;
            };
            $sheet = $spreadsheet->getSheetByName('gabungan');
            $headerRowIndex = -1;
if ($headerRowIndex === -1) {
                Log::warning("Hans Import - Header not found. Defaulting to Row 5.");
                $headerRowIndex = 5;
            }
            
            Log::info("Hans Import - Header at Row {$headerRowIndex}");
            
            // --- DYNAMIC COLUMN MAPPING ---
            $columnMap = [];
            $headerLabels = [
                'nama karyawan' => 'employee_name',
                'no rekening' => 'account_number',
                'gaji pokok' => 'basic_salary',
                'uang makan' => 'meal_rate_header',
                'transport' => 'transport_rate_header',
                'tunj. kehadiran' => 'attendance_allowance_header',
                'tunj kehadiran' => 'attendance_allowance_header',
                'tunj. kesehatan' => 'health_allowance',
                'tunj kesehatan' => 'health_allowance',
                'tunj. jabatan' => 'position_allowance',
                'tunj jabatan' => 'position_allowance',
                'tunjangan jabatan' => 'position_allowance',
                'total gaji & bonus' => 'total_salary_2',
                'total gaji' => 'total_salary_1',
                'lembur wajib' => 'mandatory_overtime_header',
                'lembur' => 'overtime_rate_header',
                'insentif lebaran' => 'holiday_allowance',
                'thr' => 'holiday_allowance',
                'insentif' => 'incentive',
                'bonus' => 'bonus',
                'bonus/thr' => 'bonus',
                'thr/bonus' => 'bonus',
                'bonus / thr' => 'bonus',
                'thr / bonus' => 'bonus',
                'kebijakan' => 'policy_ho',
                'adj' => 'adjustment',
                'potongan' => 'deductions_header',
                'grand total' => 'grand_total',
                'pinjaman ewa' => 'ewa_amount',
                'ewa' => 'ewa_amount',
                'payroll' => 'net_salary',
                'masa kerja' => 'years_of_service',
                'ket ' => 'notes',
                'ket' => 'notes',
            ];
            
            $subHeaderLabels = [
                'hari' => 'days_total',
                'off' => 'days_off',
                'sakit' => 'days_sick',
                'ijin' => 'days_permission',
                'alfa' => 'days_alpha',
                'cuti' => 'days_leave',
                'ada' => 'days_present',
                '/ hari' => null, 
                'jumlah' => null, 
                '/ jam' => 'overtime_rate',
                'jam' => 'overtime_hours',
                'absen 1x' => 'deduction_absent',
                'terlambat' => 'deduction_late', 
                'selisih so' => 'deduction_so_shortage',
                'pinjaman' => 'deduction_loan',
                'kasbon' => 'deduction_loan',
                'adm bank' => 'deduction_admin_fee',
                'bpjs tk' => 'deduction_bpjs_tk',
            ];
            
            $highestColIndex = \PhpOffice\PhpSpreadsheet\Cell\Coordinate::columnIndexFromString($highestColumn);
            
            // Scan header row
            for ($colIndex = 1; $colIndex <= min(50, $highestColIndex); $colIndex++) {
                $col = \PhpOffice\PhpSpreadsheet\Cell\Coordinate::stringFromColumnIndex($colIndex);
                $headerVal = strtolower(trim((string)$sheet->getCell($col . $headerRowIndex)->getValue()));
                $subHeaderVal = strtolower(trim((string)$sheet->getCell($col . ($headerRowIndex + 1))->getValue()));
                
                foreach ($headerLabels as $key => $field) {
                    if ($headerVal && stripos($headerVal, $key) !== false && !isset($columnMap[$field])) {
                        $columnMap[$field] = $col;
                        break;
                    }
                }
                
                foreach ($subHeaderLabels as $key => $field) {
                    if ($field && $subHeaderVal === $key && !isset($columnMap[$field])) {
                        $columnMap[$field] = $col;
                        break;
                    }
                }
                
                if ($subHeaderVal === 'jumlah') {
                    if (stripos($headerVal, 'makan') !== false) $columnMap['meal_amount'] = $col;
                    elseif (stripos($headerVal, 'transport') !== false) $columnMap['transport_amount'] = $col;
                    elseif (stripos($headerVal, 'kehadiran') !== false) $columnMap['attendance_amount'] = $col;
                    elseif (stripos($headerVal, 'lembur wajib') !== false) $columnMap['mandatory_overtime_amount'] = $col;
                    elseif (stripos($headerVal, 'lembur') !== false) $columnMap['overtime_amount'] = $col;
                    elseif (stripos($headerVal, 'potongan') !== false || !empty($columnMap['deduction_bpjs_tk'])) $columnMap['deduction_total'] = $col;
                    
                    if (!isset($columnMap['meal_amount']) && isset($columnMap['meal_rate_header']) && $colIndex === (\PhpOffice\PhpSpreadsheet\Cell\Coordinate::columnIndexFromString($columnMap['meal_rate_header']) + 1)) {
                        $columnMap['meal_amount'] = $col;
                    }
                    if (!isset($columnMap['transport_amount']) && isset($columnMap['transport_rate_header']) && $colIndex === (\PhpOffice\PhpSpreadsheet\Cell\Coordinate::columnIndexFromString($columnMap['transport_rate_header']) + 1)) {
                        $columnMap['transport_amount'] = $col;
                    }
                }
                
                if ($subHeaderVal === '/ hari') {
                    if (stripos($headerVal, 'makan') !== false) $columnMap['meal_rate'] = $col;
                    elseif (stripos($headerVal, 'transport') !== false) $columnMap['transport_rate'] = $col;
                    elseif (stripos($headerVal, 'kehadiran') !== false) $columnMap['attendance_rate'] = $col;
                    elseif (stripos($headerVal, 'lembur wajib') !== false) $columnMap['mandatory_overtime_rate'] = $col;
                }
            }
            
            Log::info("Hans Import - Column Map: " . json_encode($columnMap));
            
            // --- EXTRACT PERIOD ---
            $detectedPeriod = $request->input('period');
            if (!$detectedPeriod) {
                $monthMap = [
                    'januari' => '01', 'februari' => '02', 'maret' => '03', 'april' => '04',
                    'mei' => '05', 'juni' => '06', 'juli' => '07', 'agustus' => '08',
                    'september' => '09', 'oktober' => '10', 'november' => '11', 'desember' => '12',
                ];
                
                for ($row = 1; $row < $headerRowIndex; $row++) {
                    for ($c = 1; $c <= 5; $c++) {
                        $col = \PhpOffice\PhpSpreadsheet\Cell\Coordinate::stringFromColumnIndex($c);
                        $cellText = strtolower(trim((string)$sheet->getCell($col . $row)->getValue()));
                        
                        foreach ($monthMap as $monthName => $monthNum) {
                            if (stripos($cellText, $monthName) !== false && preg_match('/(\d{4})/', $cellText, $yearMatch)) {
                                $detectedPeriod = $yearMatch[1] . '-' . $monthNum;
                                Log::info("Hans Import - Detected period from cell {$col}{$row}: {$detectedPeriod}");
                                break 3;
                            }
                        }
                    }
                }
            }
            if (!$detectedPeriod) {
                $detectedPeriod = date('Y-m'); 
                Log::warning("Hans Import - Could not detect period. Using current: {$detectedPeriod}");
            }
            
            $dataRows = [];
            $consecutiveEmptyRows = 0;
            $startDataRow = $headerRowIndex + 2;
            
            $getCol = function($field) use ($columnMap) {
                return $columnMap[$field] ?? null;
            };
            
            $getMappedValue = function($field, $row) use ($getCellValue, $getCol) {
                $col = $getCol($field);
                return $col ? $getCellValue($col, $row) : 0;
            };
            
            for ($row = $startDataRow; $row <= $highestRow; $row++) {
                $employeeName = $sheet->getCell('B' . $row)->getValue();
                
                if (empty($employeeName) || !is_string($employeeName)) {
                    $consecutiveEmptyRows++;
                    if ($consecutiveEmptyRows >= 5) {
                        break;
                    }
                    continue; 
                }
                
                $consecutiveEmptyRows = 0;
                
                $accountCol = $getCol('account_number') ?? 'D';
                if ($accountCol === 'D' && !isset($columnMap['account_number'])) {
                     $accountCol = 'C'; 
                }
                
                $parsed = [
                    'employee_name' => $employeeName,
                    'period' => $detectedPeriod,
                    'account_number' => $sheet->getCell($accountCol . $row)->getValue(),
                    
                    'days_total' => (int) $getMappedValue('days_total', $row),
                    'days_off' => (int) $getMappedValue('days_off', $row),
                    'days_sick' => (int) $getMappedValue('days_sick', $row),
                    'days_permission' => (int) $getMappedValue('days_permission', $row),
                    'days_alpha' => (int) $getMappedValue('days_alpha', $row),
                    'days_leave' => (int) $getMappedValue('days_leave', $row),
                    'days_long_shift' => 0,
                    'days_present' => (int) $getMappedValue('days_present', $row),
                    
                    'basic_salary' => $getMappedValue('basic_salary', $row),
                    
                    'meal_rate' => $getMappedValue('meal_rate', $row),
                    'meal_amount' => $getMappedValue('meal_amount', $row),
                    
                    'transport_rate' => $getMappedValue('transport_rate', $row),
                    'transport_amount' => $getMappedValue('transport_amount', $row),
                    
                    'attendance_rate' => $getMappedValue('attendance_rate', $row),
                    'attendance_amount' => $getMappedValue('attendance_amount', $row),
                    
                    'position_allowance' => $getMappedValue('position_allowance', $row),
                    'health_allowance' => $getMappedValue('health_allowance', $row),
                    
                    'total_salary_1' => $getMappedValue('total_salary_1', $row),
                    
                    'overtime_rate' => $getMappedValue('overtime_rate', $row),
                    'overtime_hours' => $getMappedValue('overtime_hours', $row),
                    'overtime_amount' => $getMappedValue('overtime_amount', $row) + $getMappedValue('mandatory_overtime_amount', $row), 
                    
                    'bonus' => $getMappedValue('bonus', $row),
                    'holiday_allowance' => $getMappedValue('holiday_allowance', $row),
                    'adjustment' => $getMappedValue('adjustment', $row),
                    'incentive' => $getMappedValue('incentive', $row),
                    
                    'total_salary_2' => $getMappedValue('total_salary_2', $row),
                    'policy_ho' => $getMappedValue('policy_ho', $row),
                    
                    'deduction_absent' => $getMappedValue('deduction_absent', $row), 
                    'deduction_late' => $getMappedValue('deduction_late', $row), 
                    'deduction_so_shortage' => $getMappedValue('deduction_so_shortage', $row),
                    'deduction_alpha' => $getMappedValue('days_alpha', $row) > 0 ? $getMappedValue('deduction_absent', $row) : 0, 
                    'deduction_loan' => $getMappedValue('deduction_loan', $row),
                    'deduction_admin_fee' => $getMappedValue('deduction_admin_fee', $row),
                    'deduction_bpjs_tk' => $getMappedValue('deduction_bpjs_tk', $row),
                    
                    'deduction_total' => $getMappedValue('deduction_total', $row),
                    
                    'grand_total' => $getMappedValue('grand_total', $row),
                    'ewa_amount' => $getMappedValue('ewa_amount', $row),
                    'net_salary' => $getMappedValue('net_salary', $row),
                    'thp' => (float)$getMappedValue('net_salary', $row) + (float)$getMappedValue('ewa_amount', $row),
                    
                    'years_of_service' => $getMappedValue('years_of_service', $row) ?: ($getCol('years_of_service') ? $sheet->getCell($getCol('years_of_service') . $row)->getValue() : null),
                    'notes' => $getMappedValue('notes', $row) ?: ($getCol('notes') ? $sheet->getCell($getCol('notes') . $row)->getValue() : null),
                ];
                
                if (!$parsed['deduction_total']) {
                    $parsed['deduction_total'] = $parsed['deduction_absent'] + $parsed['deduction_late'] + $parsed['deduction_so_shortage'] + $parsed['deduction_alpha'] + $parsed['deduction_loan'] + $parsed['deduction_admin_fee'] + $parsed['deduction_bpjs_tk'];
                }
                
                if (!$parsed['attendance_amount'] && $parsed['attendance_rate']) {
                    $parsed['attendance_amount'] = $getMappedValue('attendance_allowance_header', $row) ?: ($parsed['attendance_rate'] * $parsed['days_present']);
                }
                
                if (!$parsed['grand_total'] || !$parsed['net_salary']) {
                    $guessedGrandTotal = $getCellValue(\PhpOffice\PhpSpreadsheet\Cell\Coordinate::stringFromColumnIndex($highestColIndex), $row);
                    $guessedNet = $getCellValue(\PhpOffice\PhpSpreadsheet\Cell\Coordinate::stringFromColumnIndex($highestColIndex), $row);
                    
                    if ($parsed['total_salary_2']) {
                        $calculatedTotal = $parsed['total_salary_2'] + $parsed['policy_ho'] - $parsed['deduction_total'];
                        $parsed['grand_total'] = $parsed['grand_total'] ?: $calculatedTotal;
                        $parsed['net_salary'] = $parsed['net_salary'] ?: ($parsed['grand_total'] - $parsed['ewa_amount']);
                    } elseif ($guessedGrandTotal > 0) {
                         $parsed['grand_total'] = $parsed['grand_total'] ?: $guessedGrandTotal;
                         $parsed['net_salary'] = $parsed['net_salary'] ?: $guessedNet;
                    }
                }
                
                $dataRows[] = $parsed;
            }


            return response()->json([
                'message' => 'File parsed successfully',
                'file_name' => $file->getClientOriginalName(),
                'rows_count' => count($dataRows),
                'rows' => $dataRows,
            ]);

        } catch (\Exception $e) {
            Log::error('Hans Payroll Import Error: ' . $e->getMessage());
            return response()->json(['message' => 'Error: ' . $e->getMessage()], 500);
        }
    }
    
    /**
     * Save imported Hans payroll data
     */

    public function parseHeaders(Request $request)
    {
        $request->validate([
            'file' => 'required|file|mimes:xlsx,xls',
            'division_type' => 'required|string',
        ]);

        $file = $request->file('file');

        try {
            $reader = \PhpOffice\PhpSpreadsheet\IOFactory::createReader('Xlsx');
            $reader->setReadDataOnly(true); 
            $spreadsheet = $reader->load($file->getRealPath());
            
            $sheet = $spreadsheet->getSheetByName('gabungan');
            $headerRowIndex = -1;
            
            if ($sheet) {
                $highestRow = $sheet->getHighestRow();
                $highestColumn = $sheet->getHighestColumn();
                for ($row = 1; $row <= min(30, $highestRow); $row++) {
                    $rowIterator = $sheet->getRowIterator($row, $row)->current();
                    $cellIterator = $rowIterator->getCellIterator('A', $highestColumn);
                    $cellIterator->setIterateOnlyExistingCells(false);
                    foreach ($cellIterator as $cell) {
                        $cellValue = (string) $cell->getValue();
                        if ($cellValue && (stripos($cellValue, 'Nama Karyawan') !== false || stripos($cellValue, 'Nama Pegawai') !== false)) {
                            $headerRowIndex = $row;
                            break 2;
                        }
                    }
                }
            }
            
            if ($headerRowIndex === -1) {
                foreach ($spreadsheet->getAllSheets() as $testSheet) {
                    $highestRow = $testSheet->getHighestRow();
                    $highestColumn = $testSheet->getHighestColumn();
                    for ($row = 1; $row <= min(30, $highestRow); $row++) {
                        $rowIterator = $testSheet->getRowIterator($row, $row)->current();
                        $cellIterator = $rowIterator->getCellIterator('A', $highestColumn);
                        $cellIterator->setIterateOnlyExistingCells(false);
                        foreach ($cellIterator as $cell) {
                            $cellValue = (string) $cell->getValue();
                            if ($cellValue && (stripos($cellValue, 'Nama Karyawan') !== false || stripos($cellValue, 'Nama Pegawai') !== false)) {
                                $sheet = $testSheet;
                                $headerRowIndex = $row;
                                break 3;
                            }
                        }
                    }
                }
            }
            
            if ($headerRowIndex === -1) {
                return response()->json(['message' => 'Format Excel tidak dikenali. Pastikan ada kolom "Nama Karyawan".'], 422);
            }
            
            $highestRow = $sheet->getHighestRow();
            $highestColumn = $sheet->getHighestColumn();
            
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
                'meal_rate' => [['Uang Makan', '/ Hari'], ['Makan', '/ Hari']],
                'meal_amount' => [['Uang Makan', 'Jumlah'], ['Makan', 'Jumlah'], 'Uang Makan'],
                'attendance_rate' => [['Kehadiran', '/ Hari']],
                'attendance_allowance' => [['Kehadiran', 'Jumlah'], 'Kehadiran', 'Uang Kehadiran'],
                'transport_rate' => [['Transport', '/ Hari']],
                'transport_amount' => [['Transport', 'Jumlah'], 'Transport', 'Uang Transport'],
                'health_allowance' => ['Tunj. Kesehatan', 'Kesehatan', 'Tunjangan Kesehatan'],
                'position_allowance' => ['Tunj. Jabatan', 'Jabatan', 'Tunjangan Jabatan'],
                'total_salary_1' => ['Total Gaji            ( Rp )', 'Total Gaji'],
                'overtime_rate' => [['Lembur', '/ Jam']],
                'mandatory_overtime_rate' => [['Lembur Wajib', '/ Hari'], 'Lembur Wajib'],
                'overtime_hours' => [['Lembur', 'Jam']],
                'overtime_amount' => [['Lembur', 'Jumlah'], 'Lembur', 'Uang Lembur'],
                'target_koli' => ['Target Koli', 'Koli'],
                'accessory_fee' => ['Aksesoris', 'Fee Aksesoris', 'Accessory'],
                'backup_allowance' => ['Backup'],
                'attendance_incentive' => ['Insentif Kehadrian', 'Insentif Kehadiran'],
                'holiday_allowance' => ['Insentif Lebaran', 'THR'],
                'total_salary_gross' => ['Total Gaji    (Rp)', 'Total Gaji & Bonus'],
                'bonus' => ['Bonus', 'Insentif', 'Bonus/THR', 'THR/Bonus', 'Bonus / THR', 'THR / Bonus'],
                'policy_ho_amount' => ['Kebijakan'],
                'deduction_absent' => ['Absen 1X', 'Absen 1x'],
                'late_minutes' => ['terlambat (menit)'],
                'deduction_late' => ['Terlambat', 'Potongan Terlambat'],
                'shortage_deduction' => ['Selisih SO', 'Selisih'],
                'deduction_loan' => ['Pinjaman', 'Kasbon'],
                'bank_fee' => ['Adm Bank', 'Admin Bank'],
                'bpjs_tk_deduction' => ['BPJS TK', 'BPJS Ketenagakerjaan'],
                'total_deduction' => [['Potongan', 'Jumlah'], 'Total Potongan'],
                'thp' => ['Grand Total'],
                'ewa_amount' => ['EWA', 'Pinjaman ke Stafbook', 'Pinjaman stafbook', 'Potongan EWA'],
                'net_salary' => ['Total Gaji Ditransfer', 'Payroll', 'THP'],
                'adjustment' => ['Adj', 'Penyesuaian', 'Kekurangan Gaji'],
            ];
            
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
                'headers' => $uiHeaders,
                'default_mapping' => $columnMapping,
                'headerRowIndex' => $headerRowIndex,
            ]);

        } catch (\Throwable $e) {
            Log::error('Retail Payroll Parse Error: ' . $e->getMessage() . "\n" . $e->getTraceAsString());
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

        if (empty($columnMapping['employee_name'])) {
            return response()->json(['message' => 'Kolom Nama Karyawan (employee_name) wajib dipetakan!'], 422);
        }

        try {
            // Prevent PHP fatal crashes on large Excel files
            ini_set('memory_limit', '512M');
            set_time_limit(120);
            
            $reader = \PhpOffice\PhpSpreadsheet\IOFactory::createReader('Xlsx');
            $reader->setReadDataOnly(true); 
            $spreadsheet = $reader->load($file->getRealPath());
            
            $dummyHeaderRowIndex = -1;
            $sheet = $this->findDataSheet($spreadsheet, $dummyHeaderRowIndex);
            if (!$sheet) {
                return response()->json(['message' => 'Format Excel tidak dikenali di semua sheet.'], 422);
            }
            
            $highestRow = $sheet->getHighestRow();
            $getCellValue = function($col, $row) use ($sheet) {
                if (!$col) return 0;
                try {
                    $cell = $sheet->getCell($col . $row);
                    $value = $cell->getCalculatedValue();
                    
                    if (is_numeric($value)) return (float) $value;
                    
                    if (is_string($value)) {
                        $cleaned = preg_replace('/[^0-9\.\,\-]/', '', $value);
                        if ($cleaned !== '' && is_numeric($cleaned)) {
                            return (float) $cleaned;
                        }
                        return $value;
                    }
                    
                    return $value ?? 0;
                } catch (\Exception $e) {
                    return 0;
                }
            };

            $dataRows = [];
            $startDataRow = $headerRowIndex + 2; 
            
            // Cache employees to avoid N+1 queries and prevent timeouts
            $employeeCache = [];
            $empColumns = ['full_name'];
            if (Schema::hasColumn('employees', 'mandatory_overtime_amount')) {
                $empColumns[] = 'mandatory_overtime_amount';
            }
            \App\Models\Employee::select($empColumns)->get()->each(function($emp) use (&$employeeCache) {
                $cleanName = strtolower(trim(preg_replace('/\s+/', ' ', $emp->full_name)));
                $employeeCache[$cleanName] = (float)($emp->mandatory_overtime_amount ?? 0);
            });
            
            $emptyRows = 0;
            for ($row = $startDataRow; $row <= $highestRow; $row++) {
                $employeeName = $getCellValue($columnMapping['employee_name'] ?? null, $row);
                $employeeNameStr = is_string($employeeName) ? trim($employeeName) : (is_numeric($employeeName) ? (string)$employeeName : '');
                
                if ($employeeNameStr === '') {
                    $emptyRows++;
                    if ($emptyRows > 15) break; // Prevent memory exhaustion
                    continue;
                }
                $emptyRows = 0;
                
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
                
                $basicSalary = $getCellValue($columnMapping['basic_salary'] ?? null, $row);
                $attendanceRate = $getCellValue($columnMapping['attendance_rate'] ?? null, $row);
                $attendanceAmount = $getCellValue($columnMapping['attendance_allowance'] ?? null, $row);
                
                // Fallback: Infer rate if missing
                if ((float)$attendanceRate <= 0 && (float)$attendanceAmount > 0 && $daysPresent > 0) {
                    $attendanceRate = (float)$attendanceAmount / $daysPresent;
                }
                
                $mealRate = $getCellValue($columnMapping['meal_rate'] ?? null, $row);
                $mealAmount = $getCellValue($columnMapping['meal_amount'] ?? null, $row);
                
                // Fallback: Infer meal rate if missing
                if ((float)$mealRate <= 0 && (float)$mealAmount > 0 && $daysPresent > 0) {
                    $mealRate = (float)$mealAmount / $daysPresent;
                }
                
                $transportRate = $getCellValue($columnMapping['transport_rate'] ?? null, $row);
                $transportAmount = $getCellValue($columnMapping['transport_amount'] ?? null, $row);
                
                // Fallback: Infer transport rate if missing
                if ((float)$transportRate <= 0 && (float)$transportAmount > 0 && $daysPresent > 0) {
                    $transportRate = (float)$transportAmount / $daysPresent;
                }
                
                $healthAllowance = $getCellValue($columnMapping['health_allowance'] ?? null, $row);
                $positionAllowance = $getCellValue($columnMapping['position_allowance'] ?? null, $row);
                $totalSalary1 = $getCellValue($columnMapping['total_salary_1'] ?? null, $row);
                $overtimeRate = (float)$getCellValue($columnMapping['overtime_rate'] ?? null, $row);
                $overtimeHours = (float)$getCellValue($columnMapping['overtime_hours'] ?? null, $row);
                $overtimeAmount = (float)$getCellValue($columnMapping['overtime_amount'] ?? null, $row);
                
                // Auto-correct swapped overtime hours and amount (nobody works > 500 hours overtime)
                if ($overtimeHours > 500 && $overtimeAmount <= 500) {
                    $temp = $overtimeAmount;
                    $overtimeAmount = $overtimeHours;
                    $overtimeHours = $temp;
                }
                
                // Detect if same column was mapped to both rate and amount (values are identical)
                if ($overtimeAmount > 0 && $overtimeRate > 0 && abs($overtimeAmount - $overtimeRate) < 1) {
                    $overtimeAmount = 0; // It's actually the rate, not the total
                }
                
                // Fetch mandatory overtime from Master Data
                $empNameClean = strtolower(trim(preg_replace('/\s+/', ' ', $employeeName)));
                $masterMandatoryOvertime = $employeeCache[$empNameClean] ?? 0;
                
                $mandatoryOvertimeRate = (float)$getCellValue($columnMapping['mandatory_overtime_rate'] ?? null, $row);
                $mandatoryOvertimeAmount = (float)$getCellValue($columnMapping['mandatory_overtime_amount'] ?? null, $row);
                
                // Detect if same column was mapped to both mandatory rate and amount
                if ($mandatoryOvertimeAmount > 0 && $mandatoryOvertimeRate > 0 && abs($mandatoryOvertimeAmount - $mandatoryOvertimeRate) < 1) {
                    $mandatoryOvertimeAmount = 0;
                }
                
                // If excel didn't map the rate or it's 0, but Master Data has it, use Master Data as the RATE
                if ($mandatoryOvertimeRate <= 0 && $masterMandatoryOvertime > 0) {
                    $mandatoryOvertimeRate = $masterMandatoryOvertime;
                }
                
                // Fallback: Infer overtime rate if missing
                if ($overtimeRate <= 0 && $overtimeAmount > 0 && $overtimeHours > 0) {
                    $overtimeRate = $overtimeAmount / $overtimeHours;
                }
                
                // Fallback: Calculate overtime amount from rate × hours if amount not mapped or was deduped
                if ($overtimeAmount <= 0 && $overtimeRate > 0 && $overtimeHours > 0) {
                    $overtimeAmount = $overtimeRate * $overtimeHours;
                }
                
                // Fallback: Calculate mandatory overtime amount from rate × days_present if amount not mapped or was deduped
                if ($mandatoryOvertimeAmount <= 0 && $mandatoryOvertimeRate > 0 && $daysPresent > 0) {
                    $mandatoryOvertimeAmount = $mandatoryOvertimeRate * $daysPresent;
                }
                
                // Log overtime debug info for first row only
                if (count($dataRows) === 0) {
                    Log::info('Overtime Debug', [
                        'employee' => $employeeName,
                        'mapping_overtime_rate' => $columnMapping['overtime_rate'] ?? 'NOT MAPPED',
                        'mapping_overtime_hours' => $columnMapping['overtime_hours'] ?? 'NOT MAPPED',
                        'mapping_overtime_amount' => $columnMapping['overtime_amount'] ?? 'NOT MAPPED',
                        'mapping_mandatory_rate' => $columnMapping['mandatory_overtime_rate'] ?? 'NOT MAPPED',
                        'mapping_mandatory_amount' => $columnMapping['mandatory_overtime_amount'] ?? 'NOT MAPPED',
                        'raw_overtime_rate' => $overtimeRate,
                        'raw_overtime_hours' => $overtimeHours,
                        'final_overtime_amount' => $overtimeAmount,
                        'final_mandatory_amount' => $mandatoryOvertimeAmount,
                    ]);
                }
                $targetKoli = $getCellValue($columnMapping['target_koli'] ?? null, $row);
                $accessoryFee = $getCellValue($columnMapping['accessory_fee'] ?? null, $row);
                $backup = $getCellValue($columnMapping['backup_allowance'] ?? null, $row);
                $insentifKehadiran = $getCellValue($columnMapping['attendance_incentive'] ?? null, $row);
                $holidayAllowance = $getCellValue($columnMapping['holiday_allowance'] ?? null, $row);
                $bonus = $getCellValue($columnMapping['bonus'] ?? null, $row);
                $adjustment = $getCellValue($columnMapping['adjustment'] ?? null, $row);
                $totalSalary2 = $getCellValue($columnMapping['total_salary_gross'] ?? null, $row);
                $policyHo = $getCellValue($columnMapping['policy_ho_amount'] ?? null, $row);
                $deductionAbsent = $getCellValue($columnMapping['deduction_absent'] ?? null, $row);
                $deductionLate = $getCellValue($columnMapping['deduction_late'] ?? null, $row);
                $deductionShortage = $getCellValue($columnMapping['shortage_deduction'] ?? null, $row);
                $deductionLoan = $getCellValue($columnMapping['deduction_loan'] ?? null, $row);
                $deductionAdminFee = $getCellValue($columnMapping['bank_fee'] ?? null, $row);
                $deductionBpjsTk = $getCellValue($columnMapping['bpjs_tk_deduction'] ?? null, $row);
                $totalDeductions = $getCellValue($columnMapping['total_deduction'] ?? null, $row);
                
                if ($totalDeductions <= 0) {
                    $totalDeductions = abs((float)$deductionAbsent) + abs((float)$deductionLate) + abs((float)$deductionShortage) + abs((float)$deductionLoan) + abs((float)$deductionAdminFee) + abs((float)$deductionBpjsTk);
                }
                
                $grandTotal = $getCellValue($columnMapping['thp'] ?? null, $row);
                $ewa = $getCellValue($columnMapping['ewa_amount'] ?? null, $row);
                $netSalary = $getCellValue($columnMapping['net_salary'] ?? null, $row);
                
                if ($netSalary <= 0 && $grandTotal > 0) {
                    $netSalary = (float)$grandTotal - (float)$ewa;
                }
                
                if ($totalSalary2 > 0) {
                    $grossSalary = $totalSalary2;
                } elseif ($totalSalary1 > 0) {
                    $grossSalary = $totalSalary1;
                } else {
                    $grossSalary = (float)$basicSalary + (float)$mealAmount + (float)$attendanceAmount + (float)$transportAmount + (float)$healthAllowance + (float)$positionAllowance + (float)$overtimeAmount + (float)$mandatoryOvertimeAmount + (float)$targetKoli + (float)$accessoryFee + (float)$backup + (float)$insentifKehadiran + (float)$holidayAllowance + (float)$bonus + (float)$adjustment + (float)$policyHo;
                }
                
                // Skip rows that are clearly not payroll data (e.g. signature section)
                if ($grossSalary <= 0 && $netSalary <= 0 && $basicSalary <= 0 && $totalDeductions <= 0 && $daysTotal <= 0 && $daysPresent <= 0) {
                    continue;
                }
                
                $dataRows[] = [
                    'employee_name' => $employeeName,
                    'period' => $request->period ?? date('Y-m'),
                    'account_number' => $getCellValue($columnMapping['account_number'] ?? null, $row),
                    
                    'days_total' => (int) $daysTotal,
                    'days_off' => (int) $daysOff,
                    'days_sick' => (int) $daysSick,
                    'days_permission' => (int) $daysPermission,
                    'days_alpha' => (int) $daysAlpha,
                    'days_leave' => (int) $daysLeave,
                    'days_present' => (int) $daysPresent,
                    
                    'basic_salary' => (float) $basicSalary,
                    'meal_rate' => (float) $mealRate,
                    'meal_amount' => (float) $mealAmount,
                    'attendance_rate' => (float) $attendanceRate,
                    'attendance_amount' => (float) $attendanceAmount,
                    'attendance_allowance' => (float) $attendanceAmount, // For money_changer
                    'transport_rate' => (float) $transportRate,
                    'transport_amount' => (float) $transportAmount,
                    'health_allowance' => (float) $healthAllowance,
                    'position_allowance' => (float) $positionAllowance,
                    'total_salary_1' => (float) $totalSalary1,
                    'subtotal_1' => (float) $totalSalary1, // For cellullers
                    
                    'overtime_rate' => (float) $overtimeRate,
                    'overtime_hours' => (float) $overtimeHours,
                    'overtime_amount' => (float) $overtimeAmount,
                    'mandatory_overtime_rate' => (float) $mandatoryOvertimeRate,
                    'mandatory_overtime_amount' => (float) $mandatoryOvertimeAmount,
                    'target_koli' => (float) $targetKoli,
                    'accessory_fee' => (float) $accessoryFee,
                    
                    'backup' => (float) $backup,
                    'insentif_kehadiran' => (float) $insentifKehadiran,
                    'holiday_allowance' => (float) $holidayAllowance,
                    'bonus' => (float) $bonus,
                    'adjustment' => (float) $adjustment,
                    'total_salary_2' => (float) $grossSalary, 
                    'gross_salary' => (float) $grossSalary, // For cellullers
                    'total_salary_gross' => (float) $grossSalary, // For wrapping
                    'policy_ho' => (float) $policyHo,
                    
                    'deduction_absent' => (float) $deductionAbsent,
                    'deduction_late' => (float) $deductionLate,
                    'deduction_shortage' => (float) $deductionShortage,
                    'deduction_so_shortage' => (float) $deductionShortage, // Alias
                    'deduction_loan' => (float) $deductionLoan,
                    'deduction_admin_fee' => (float) $deductionAdminFee,
                    'deduction_bpjs_tk' => (float) $deductionBpjsTk,
                    'total_deductions' => (float) $totalDeductions,
                    'deduction_total' => (float) $totalDeductions, // Alias
                    'total_deduction' => (float) $totalDeductions, // Alias
                    
                    'grand_total' => (float) $grandTotal,
                    'ewa_amount' => (float) $ewa,
                    'net_salary' => (float) $netSalary,
                ];
            }

            return response()->json([
                'message' => 'File parsed successfully',
                'file_name' => $file->getClientOriginalName(),
                'rows_count' => count($dataRows),
                'rows' => $dataRows,
            ]);

        } catch (\Throwable $e) {
            Log::error('Retail Payroll Simulate Error: ' . $e->getMessage() . "\n" . $e->getTraceAsString());
            return response()->json(['message' => 'Error: ' . $e->getMessage()], 500);
        }
    }

    public function saveImport(Request $request)
    {
        $request->validate([
            'division_type' => 'required|string',
            'rows' => 'required|array',
        ]);

        try {
            $saved = 0;
            $errors = [];
            
            // Cache employees to avoid N+1 queries
            $employeeCache = [];
            \App\Models\Employee::get()->each(function($emp) use (&$employeeCache) {
                $cleanName = strtolower(trim(preg_replace('/\s+/', ' ', $emp->full_name)));
                $employeeCache[$cleanName] = $emp;
            });
            
            // Cache table columns once for filtering
            $model = $this->getModel($request->division_type);
            $tableColumns = Schema::getColumnListing($model->getTable());
            
            foreach ($request->rows as $index => $row) {
                // Skip rows with missing or non-string employee names (footer/total rows)
                if (empty($row['employee_name']) || !is_string($row['employee_name'])) {
                    continue;
                }
                
                // Find employee by full_name - robust lookup for spaces and case
                $employeeName = trim($row['employee_name']);
                $employeeName = preg_replace('/\s+/', ' ', $employeeName);
                
                $empNameClean = strtolower($employeeName);
                $employee = $employeeCache[$empNameClean] ?? null;
                
                if (!$employee) {
                    // Fallback to LIKE if strict match fails (may be risky but helpful for typos)
                    $employee = Employee::where('full_name', 'LIKE', '%' . $employeeName . '%')->first();
                }
                
                if (!$employee) {
                    $errors[] = "Row " . ($index + 1) . ": Employee '{$row['employee_name']}' not found";
                    continue;
                }
                
                // Check duplicate
                $existing = $this->getModel($request->division_type)->where('employee_id', $employee->id)
                    ->where('period', $row['period'])
                    ->first();
                
                if ($existing) {
                    $errors[] = "Row " . ($index + 1) . ": Payroll info for '{$row['employee_name']}' already exists";
                    continue;
                }
                
                // Filter row data to only include columns that exist in the target table
                $filteredRow = array_intersect_key($row, array_flip($tableColumns));
                
                $this->getModel($request->division_type)->create(array_merge($filteredRow, [
                    'employee_id' => $employee->id,
                    'status' => 'draft',
                    'adjustment' => $row['adjustment'] ?? 0,
                    'deduction_so_shortage' => $row['deduction_so_shortage'] ?? 0,
                ]));
                
                $saved++;
            }
            
            return response()->json([
                'message' => "Successfully saved $saved payroll records",
                'saved' => $saved,
                'errors' => $errors,
            ]);

        } catch (\Throwable $e) {
            Log::error('Retail Payroll Save Error: ' . $e->getMessage() . "\n" . $e->getTraceAsString());
            return response()->json(['message' => 'Error: ' . $e->getMessage()], 500);
        }
    }
    
    public function show(Request $request, $id)
    {
        $payroll = $this->getModel($request->division_type)->with('employee')->findOrFail($id);
        
        // Security check
        $user = auth()->user();
        $roleName = $user->role ? strtolower($user->role->name) : '';
        if (!in_array($roleName, [Role::SUPER_ADMIN, Role::ADMIN, Role::HR])) {
             if (!$user->employee || $user->employee->id !== $payroll->employee_id) {
                 return response()->json(['message' => 'Unauthorized'], 403);
             }
        }
        
        return response()->json($this->formatPayrollData($payroll));
    }
    
    public function updateStatus(Request $request, $id)
    {
         $request->validate([
            'division_type' => 'required|string',
            'status' => 'required|in:draft,approved,paid',
            'approval_signature' => 'nullable|string',
            'notes' => 'nullable|string',
        ]);
            
        $payroll = $this->getModel($request->division_type)->findOrFail($id);
        
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
    
    public function destroy(Request $request, $id)
    {
        $payroll = $this->getModel($request->division_type)->findOrFail($id);
        $payroll->delete();
        return response()->json(['message' => 'Payroll delete successfully']);
    }
    
    /**
     * Generate PDF Slip
     */
    public function generateSlip(Request $request, $id)
    {
        try {
            $payroll = $this->getModel($request->division_type)->with('employee')->findOrFail($id);
            
            // Security check
            $user = auth()->user();
            $roleName = $user->role ? strtolower($user->role->name) : '';
            if (!in_array($roleName, [Role::SUPER_ADMIN, Role::ADMIN, Role::HR])) {
                 if (!$user->employee || $user->employee->id !== $payroll->employee_id) {
                     return response()->json(['message' => 'Unauthorized'], 403);
                 }
            }
            
            $formatted = $this->formatPayrollData($payroll); 
            unset($formatted['employee']);
            foreach ($formatted as $key => $val) {
                $payroll->$key = $val;
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
            
            // Determine view based on division_type
            $viewName = 'payslips.retail_unified';
            $divType = $request->division_type;
            
            $payroll->division_type = $divType; // Inject division type for the view

            if ($divType === 'fnb') {
                $viewName = 'payslips.fnb';
            }

            // Pass simple object to view, view can format
            $pdf = PDF::loadView($viewName, [
                'payroll' => $payroll,
                'aiMessage' => $aiMessage
            ]);
            
            $filename = 'payslip_' . $divType . '_' . str_replace(' ', '_', $payroll->employee->full_name) . '_' . $payroll->period . '.pdf';
            
            return $pdf->download($filename);
        } catch (\Exception $e) {
            Log::error('Error generating Hans payslip: ' . $e->getMessage());
             return response()->json([
                'message' => 'Failed to generate payslip', 
                'error' => $e->getMessage()
            ], 500);
        }
    }
    
    private function formatPayrollData($payroll)
    {
        $formatted = $payroll->toArray();
        unset($formatted['ewa_amount']);
        
        $formatted['allowances'] = [
             'Uang Makan' => [
                 'rate' => $payroll->meal_rate ?? null,
                 'amount' => $payroll->meal_amount ?? 0,
             ],
             'Transport' => [
                 'rate' => $payroll->transport_rate,
                 'amount' => $payroll->transport_amount,
             ],
             'Kehadiran' => [
                 'rate' => $payroll->attendance_rate ?? null,
                 'amount' => $payroll->attendance_amount ?? $payroll->attendance_allowance ?? 0,
             ],
             'Tunjangan Kesehatan' => $payroll->health_allowance,
             'Tunjangan Jabatan' => $payroll->position_allowance,
         ];
         
         // Auto-correct swapped overtime for existing drafts
         $oRate = (float) $payroll->overtime_rate;
         $oHours = (float) $payroll->overtime_hours;
         $oAmount = (float) $payroll->overtime_amount;
         
         if ($oHours > 500 && $oAmount <= 500) {
             $temp = $oAmount;
             $oAmount = $oHours;
             $oHours = $temp;
             // Try to infer rate if rate is 0
             if ($oRate <= 0 && $oHours > 0) {
                 $oRate = $oAmount / $oHours;
             }
         }
         
         $formatted['allowances']['Lembur'] = [
             'rate' => $oRate,
             'hours' => $oHours,
             'amount' => $oAmount,
         ];

         if ((float)$payroll->mandatory_overtime_amount > 0 || (float)$payroll->mandatory_overtime_rate > 0) {
             $formatted['allowances']['Lembur Wajib'] = [
                 'rate' => $payroll->mandatory_overtime_rate,
                 'amount' => $payroll->mandatory_overtime_amount,
             ];
         }

         $formatted['allowances'] += [
             'Target Koli' => $payroll->target_koli ?? 0,
             'Fee Aksesoris' => $payroll->accessory_fee ?? 0,
             'Backup' => $payroll->backup ?? 0,
             'Insentif Kehadiran' => $payroll->insentif_kehadiran ?? 0,
             'Insentif Lebaran' => $payroll->holiday_allowance,
             'Bonus' => $payroll->bonus ?? 0,
             'Adjustment' => $payroll->adjustment,
             'Kebijakan HO' => $payroll->policy_ho,
        ];
        
        $formatted['deductions'] = [
            'Potongan Absen' => $payroll->deduction_absent,
            'Terlambat' => $payroll->deduction_late, 
            'Selisih SO' => $payroll->deduction_shortage ?? $payroll->deduction_so_shortage ?? 0,
            'Pinjaman' => $payroll->deduction_loan,
            'Adm Bank' => $payroll->deduction_admin_fee,
            'BPJS TK' => $payroll->deduction_bpjs_tk,
        ];
        
        // Dynamic THP calculation with fallback for import anomalies
        $thpResult = $this->calculateThp($payroll, 
            ['basic_salary', 'attendance_amount', 'transport_amount', 'health_allowance', 'position_allowance', 'overtime_amount', 'mandatory_overtime_amount', 'target_koli', 'accessory_fee', 'backup', 'insentif_kehadiran', 'holiday_allowance', 'adjustment', 'policy_ho'],
            ['deduction_absent', 'deduction_late', 'deduction_shortage', 'deduction_loan', 'deduction_admin_fee', 'deduction_bpjs_tk']
        );
        $formatted['thp'] = $thpResult['thp'];
        if ($thpResult['net_salary'] !== null) {
            $formatted['net_salary'] = $thpResult['net_salary'];
        }
        
        // Fallback for gross salary if it's 0 or missing in DB
        $gross = (float)($payroll->total_salary_2 ?? 0);
        $formatted['total_salary_2'] = $gross > 0 ? $gross : $thpResult['total_income'];
        
        // Add new extras to array
        $formatted['days_long_shift'] = $payroll->days_long_shift;
        $formatted['years_of_service'] = $payroll->years_of_service;
        $formatted['notes'] = $payroll->notes;
        $formatted['ewa_amount'] = $payroll->ewa_amount ?? 0;

        // Add attendance data for Mobile App
        $formatted['attendance'] = [
            'Total Hari' => $payroll->days_total,
            'Long Shift' => $payroll->days_long_shift ?? 0, 
            'Off' => $payroll->days_off,
            'Sakit' => $payroll->days_sick,
            'Ijin' => $payroll->days_permission,
            'Alfa' => $payroll->days_alpha,
            'Cuti' => $payroll->days_leave,
            'Hadir' => $payroll->days_present,
        ];
        
        return $formatted;
    }
}
