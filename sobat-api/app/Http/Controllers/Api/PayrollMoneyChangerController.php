<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;

use App\Models\PayrollMoneyChanger;
use App\Models\Employee;
use App\Models\Role;
use Illuminate\Support\Facades\Log;
use Barryvdh\DomPDF\Facade\Pdf;
use App\Services\GroqAiService;

class PayrollMoneyChangerController extends Controller
{
    /**
     * Display a listing of Money Changer payrolls
     */
    public function index(Request $request)
    {
        $user = auth()->user();
        $query = PayrollMoneyChanger::with('employee');
        
        // SECURITY CHECK: Scope query to authenticated user
        $roleName = $user->role ? strtolower($user->role->name) : '';
        if (!in_array($roleName, [Role::ADMIN, Role::SUPER_ADMIN, Role::HR])) {
            $employeeId = $user->employee ? $user->employee->id : null;
            if ($employeeId) {
                $query->where('employee_id', $employeeId);
                $query->whereIn('status', ['approved', 'paid']);
            } else {
                return response()->json([]);
            }
        }
        
        // Filter by period
        if ($request->has('period')) {
            $query->where('period', $request->period);
        }

        // Filter by month and year
        if (!$request->has('period') && $request->has('month') && $request->has('year') && $request->month != 0 && $request->year != 0) {
            $period = $request->year . '-' . str_pad($request->month, 2, '0', STR_PAD_LEFT);
            $query->where('period', $period);
        }
        
        
        // Filter by search name
        if ($request->has('search') && !empty($request->search)) {
            $query->whereHas('employee', function($q) use ($request) {
                $q->where('full_name', 'like', '%' . $request->search . '%');
            });
        }

        // Filter by status
        if ($request->has('status')) {
            $query->where('status', $request->status);
        }
        
        $payrolls = $query->orderBy('period', 'desc')
            ->orderBy('created_at', 'desc')
            ->paginate(20);
        
        $payrolls->getCollection()->transform(function ($payroll) {
            return $this->formatPayroll($payroll);
        });
        
        return response()->json($payrolls);
    }
    
    /**
     * Import Money Changer payroll from Excel
     */
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
            $sheet = $spreadsheet->getActiveSheet();
            
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
            
            // Detect header row (Look for "Nama Karyawan")
            $headerRowIndex = -1;
            for ($row = 1; $row <= min(10, $highestRow); $row++) {
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
                Log::warning("Money Changer Import - Header not found. Defaulting to Row 5.");
                $headerRowIndex = 5;
            }
            
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
                'total gaji & bonus' => 'total_salary_2',
                'total gaji' => 'total_salary_1',
                'lembur wajib' => 'mandatory_overtime_header',
                'lembur' => 'overtime_rate_header',
                'insentif lebaran' => 'holiday_allowance',
                'thr' => 'holiday_allowance',
                'insentif' => 'incentive',
                'bonus' => 'bonus',
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
                'adm bank' => 'deduction_admin_fee',
                'bpjs tk' => 'deduction_bpjs_tk',
                'long shift' => 'days_long_shift',
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
                                break 3;
                            }
                        }
                    }
                }
            }
            if (!$detectedPeriod) {
                $detectedPeriod = date('Y-m'); 
            }
            
            $dataRows = [];
            $consecutiveEmptyRows = 0;
            $startDataRow = $headerRowIndex + 2;
            
            $getCol = function($field) use ($columnMap) {
                return $columnMap[$field] ?? null;
            };
            
            $getMappedValue = function($field, $row) use ($getCellValue, $getCol) {
                $col = $getCol($field);
                $val = $col ? $getCellValue($col, $row) : 0;
                if (is_string($val) && !is_numeric($val)) return 0;
                return (float)$val; 
            };
            
            for ($row = $startDataRow; $row <= $highestRow; $row++) {
                $employeeName = $sheet->getCell('B' . $row)->getValue();
                
                if (empty($employeeName) || !is_string($employeeName)) {
                    $consecutiveEmptyRows++;
                    if ($consecutiveEmptyRows >= 5) break;
                    continue; 
                }
                
                $consecutiveEmptyRows = 0;
                
                $accountCol = $getCol('account_number') ?? 'C';
                
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
                    'days_present' => (int) $getMappedValue('days_present', $row),
                    
                    'basic_salary' => $getMappedValue('basic_salary', $row),
                    'position_allowance' => $getMappedValue('position_allowance', $row),
                    
                    'meal_rate' => $getMappedValue('meal_rate', $row),
                    'meal_amount' => $getMappedValue('meal_amount', $row),
                    
                    'transport_rate' => $getMappedValue('transport_rate', $row),
                    'transport_amount' => $getMappedValue('transport_amount', $row),
                    
                    // Notice MC originally saved attendance_allowance natively
                    'attendance_allowance' => $getMappedValue('attendance_allowance_header', $row) ?: ($getMappedValue('attendance_rate', $row) * $getMappedValue('days_present', $row)),
                    'health_allowance' => $getMappedValue('health_allowance', $row),
                    
                    'total_salary_1' => $getMappedValue('total_salary_1', $row),
                    
                    'overtime_rate' => $getMappedValue('overtime_rate', $row),
                    'overtime_hours' => $getMappedValue('overtime_hours', $row),
                    'overtime_amount' => $getMappedValue('overtime_amount', $row) + $getMappedValue('mandatory_overtime_amount', $row), 
                    
                    'bonus' => $getMappedValue('bonus', $row),
                    'holiday_allowance' => $getMappedValue('holiday_allowance', $row),
                    'adjustment' => $getMappedValue('adjustment', $row),
                    'incentive' => $getMappedValue('incentive', $row), // Optional for MC
                    
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
                
                // Fallbacks if calculated total is missing
                if (!$parsed['deduction_total']) {
                    $parsed['deduction_total'] = $parsed['deduction_absent'] + $parsed['deduction_late'] + $parsed['deduction_so_shortage'] + $parsed['deduction_alpha'] + $parsed['deduction_loan'] + $parsed['deduction_admin_fee'] + $parsed['deduction_bpjs_tk'];
                }
                
                if (!$parsed['grand_total'] || !$parsed['net_salary']) {
                    $guessedGrandTotal = $getMappedValue('grand_total', $row) ?: $getCellValue(\PhpOffice\PhpSpreadsheet\Cell\Coordinate::stringFromColumnIndex($highestColIndex), $row);
                    $guessedNet = $getMappedValue('net_salary', $row) ?: $getCellValue(\PhpOffice\PhpSpreadsheet\Cell\Coordinate::stringFromColumnIndex($highestColIndex), $row);
                    
                    if ($parsed['total_salary_2']) {
                        $calculatedTotal = $parsed['total_salary_2'] + $parsed['policy_ho'] - $parsed['deduction_total'];
                        $parsed['grand_total'] = $parsed['grand_total'] ?: $calculatedTotal;
                        $parsed['net_salary'] = $parsed['net_salary'] ?: ($parsed['grand_total'] - $parsed['ewa_amount']);
                    } elseif ((float)$guessedGrandTotal > 0) {
                         $parsed['grand_total'] = $parsed['grand_total'] ?: (float)$guessedGrandTotal;
                         $parsed['net_salary'] = $parsed['net_salary'] ?: (float)$guessedNet;
                    }
                    
                    // ULTRA FALLBACK: If Excel formula is broken (#VALUE!) and mapped value is strictly 0
                    if (empty($parsed['grand_total'])) {
                         $totalAllowances = $parsed['meal_amount'] + $parsed['transport_amount'] + $parsed['attendance_allowance'] + $parsed['position_allowance'] + $parsed['health_allowance'];
                         $totalOthers = $parsed['bonus'] + $parsed['incentive'] + $parsed['holiday_allowance'] + $parsed['policy_ho'] + $parsed['adjustment'];
                         
                         $grossSalary = $parsed['basic_salary'] + $totalAllowances + $parsed['overtime_amount'] + $totalOthers;
                         
                         $parsed['grand_total'] = $grossSalary - $parsed['deduction_total'];
                         $parsed['net_salary'] = $parsed['grand_total'] - $parsed['ewa_amount'];
                         
                         if (empty($parsed['total_salary_2'])) {
                             $parsed['total_salary_2'] = $grossSalary;
                         }
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
            Log::error('Money Changer Payroll Import Error: ' . $e->getMessage());
            return response()->json(['message' => 'Error: ' . $e->getMessage()], 500);
        }
    }
    
    /**
     * Save imported Money Changer payroll data
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
                $employeeName = trim($row['employee_name']);
                $employeeName = preg_replace('/\s+/', ' ', $employeeName);
                
                $employee = Employee::whereRaw('LOWER(TRIM(REPLACE(full_name, "  ", " "))) = ?', [strtolower($employeeName)])->first();
                
                if (!$employee) {
                    $employee = Employee::where('full_name', 'LIKE', '%' . $employeeName . '%')->first();
                }
                
                if (!$employee) {
                    $errors[] = "Row " . ($index + 1) . ": Employee '{$row['employee_name']}' not found";
                    continue;
                }
                
                // Check duplicate
                $existing = PayrollMoneyChanger::where('employee_id', $employee->id)
                    ->where('period', $row['period'])
                    ->first();
                
                if ($existing) {
                    $errors[] = "Row " . ($index + 1) . ": Payroll for '{$row['employee_name']}' period {$row['period']} already exists";
                    continue;
                }
                
                PayrollMoneyChanger::create(array_merge($row, [
                    'employee_id' => $employee->id,
                    'status' => 'draft',
                ]));
                
                $saved++;
            }
            
            return response()->json([
                'message' => "Successfully saved $saved payroll records",
                'saved' => $saved,
                'errors' => $errors,
            ]);

        } catch (\Exception $e) {
            Log::error('Money Changer Payroll Save Error: ' . $e->getMessage());
            return response()->json(['message' => 'Error: ' . $e->getMessage()], 500);
        }
    }
    
    /**
     * Show single payroll
     */
    public function show($id)
    {
        $payroll = PayrollMoneyChanger::with('employee')->findOrFail($id);
        
        // IDOR Guard
        $user = auth()->user();
        $roleName = $user->role ? strtolower($user->role->name) : '';
        if (!in_array($roleName, [Role::SUPER_ADMIN, Role::ADMIN, Role::HR])) {
             if (!$user->employee || $user->employee->id !== $payroll->employee_id) {
                 return response()->json(['message' => 'Unauthorized'], 403);
             }
        }
        
        return response()->json($this->formatPayroll($payroll));
    }
    
    /**
     * Update payroll status
     */
    public function updateStatus(Request $request, $id)
    {
         $request->validate([
            'status' => 'required|in:draft,approved,paid',
            'approval_signature' => 'nullable|string',
            'notes' => 'nullable|string',
        ]);
            
        $payroll = PayrollMoneyChanger::findOrFail($id);
        
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
        $payroll = PayrollMoneyChanger::findOrFail($id);
        $payroll->delete();
        return response()->json(['message' => 'Payroll deleted successfully']);
    }
    
    /**
     * Generate PDF Slip
     */
    public function generateSlip($id)
    {
        try {
            $payroll = PayrollMoneyChanger::with('employee')->findOrFail($id);
            
            // IDOR Guard
            $user = auth()->user();
            $roleName = $user->role ? strtolower($user->role->name) : '';
            if (!in_array($roleName, [Role::SUPER_ADMIN, Role::ADMIN, Role::HR])) {
                 if (!$user->employee || $user->employee->id !== $payroll->employee_id) {
                     return response()->json(['message' => 'Unauthorized'], 403);
                 }
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
            
            $pdf = PDF::loadView('payslips.money_changer', [
                'payroll' => $payroll,
                'aiMessage' => $aiMessage
            ]);
            
            $filename = 'payslip_money_changer_' . str_replace(' ', '_', $payroll->employee->full_name) . '_' . $payroll->period . '.pdf';
            
            return $pdf->download($filename);
        } catch (\Exception $e) {
            Log::error('Error generating Money Changer payslip: ' . $e->getMessage());
             return response()->json([
                'message' => 'Failed to generate payslip', 
                'error' => $e->getMessage()
            ], 500);
        }
    }
    
    /**
     * Format payroll data for API response
     */
    private function formatPayroll($payroll)
    {
        $formatted = $payroll->toArray();
        
        $formatted['allowances'] = [
             'Tunjangan Jabatan' => $payroll->position_allowance,
             'Uang Makan' => [
                 'rate' => $payroll->meal_rate,
                 'amount' => $payroll->meal_amount,
             ],
             'Transport' => [
                 'rate' => $payroll->transport_rate,
                 'amount' => $payroll->transport_amount,
             ],
             'Tunjangan Kehadiran' => $payroll->attendance_allowance,
             'Tunjangan Kesehatan' => $payroll->health_allowance,
             'Lembur' => [
                 'rate' => $payroll->overtime_rate,
                 'hours' => $payroll->overtime_hours,
                 'amount' => $payroll->overtime_amount,
             ],
             'Bonus' => $payroll->bonus,
             'THR' => $payroll->holiday_allowance,
             'Adj Kekurangan Gaji' => $payroll->adjustment,
             'Kebijakan HO' => $payroll->policy_ho,
        ];
        
        $formatted['deductions'] = [
            'Absen 1X' => $payroll->deduction_absent,
            'Terlambat' => $payroll->deduction_late, 
            'Selisih SO' => $payroll->deduction_so_shortage,
            'Pinjaman' => $payroll->deduction_loan,
            'Adm Bank' => $payroll->deduction_admin_fee,
            'BPJS TK' => $payroll->deduction_bpjs_tk,
        ];
        
        $formatted['thp'] = $payroll->net_salary + $payroll->ewa_amount;
        
        $formatted['years_of_service'] = $payroll->years_of_service;
        $formatted['notes'] = $payroll->notes;

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
    }
}
