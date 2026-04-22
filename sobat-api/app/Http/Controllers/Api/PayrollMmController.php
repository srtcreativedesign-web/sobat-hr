<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;


use App\Models\PayrollMm;
use App\Models\Employee;
use App\Models\Role;
use Illuminate\Support\Facades\Log;
use Barryvdh\DomPDF\Facade\Pdf;
use App\Services\GroqAiService;

class PayrollMmController extends Controller
{
    private function isAdmin(): bool
    {
        $user = auth()->user();
        $roleName = $user->role ? strtolower($user->role->name) : '';
        return in_array($roleName, [Role::SUPER_ADMIN, Role::ADMIN, Role::ADMIN_CABANG, Role::HR]);
    }

    /**
     * Display a listing of Minimarket payrolls
     */
    public function index(Request $request)
    {
        $user = auth()->user();
        $query = PayrollMm::with('employee');

        // SECURITY CHECK: Scope query to authenticated user
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
        
        // Filter by status (override for admins)
        if ($request->has('status')) {
            $query->where('status', $request->status);
        }
        
        $payrolls = $query->orderBy('period', 'desc')
            ->orderBy('created_at', 'desc')
            ->paginate(20);
        
        // Transform data structurally for the frontend
        $payrolls->getCollection()->transform(function ($payroll) {
            return $this->formatPayroll($payroll);
        });
        
        return response()->json($payrolls);
    }
    
    /**
     * Import MM payroll from Excel
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
            
            // --- TARGET THE SHEET ---
            $sheetNames = $spreadsheet->getSheetNames();
            Log::info("MM Import - Available sheets: " . implode(', ', $sheetNames));
            
            $sheet = null;
            // Try specific names first
            foreach (['minimarket', 'gaji'] as $targetName) {
                foreach ($sheetNames as $actualName) {
                    if (stripos($actualName, $targetName) !== false) {
                        $sheet = $spreadsheet->getSheetByName($actualName);
                        Log::info("MM Import - Using sheet: {$actualName}");
                        break 2;
                    }
                }
            }
            
            if (!$sheet) {
                $sheet = $spreadsheet->getSheet(0);
                Log::warning("MM Import - Target sheet not found. Using first sheet: " . $sheet->getTitle());
            }
            
            $highestRow = $sheet->getHighestRow();
            $highestColIndex = \PhpOffice\PhpSpreadsheet\Cell\Coordinate::columnIndexFromString($sheet->getHighestColumn());
            
            // Helper with safety net for formulas
            $getCellValue = function($col, $row) use ($sheet) {
                try {
                    $cell = $sheet->getCell($col . $row);
                    $val = $cell->getCalculatedValue();
                    
                    if (is_numeric($val)) return (float)$val;
                    if (is_string($val)) {
                        $cleaned = preg_replace('/[^0-9\.\,\-]/', '', $val);
                        return is_numeric($cleaned) ? (float)$cleaned : 0;
                    }
                    return 0;
                } catch (\Exception $e) {
                    Log::warning("Formula error in cell {$col}{$row}: " . $e->getMessage());
                    $val = $sheet->getCell($col . $row)->getValue();
                    if (is_numeric($val)) return (float)$val;
                    return 0;
                }
            };
            
            // --- DYNAMIC HEADER DETECTION ---
            // Find the header row containing "Nama Karyawan" in column B
            $headerRowIndex = -1;
            for ($row = 1; $row <= min(15, $highestRow); $row++) {
                $cellValue = $sheet->getCell('B' . $row)->getValue();
                if ($cellValue && stripos($cellValue, 'Nama Karyawan') !== false) {
                    $headerRowIndex = $row;
                    break;
                }
            }
            
            if ($headerRowIndex === -1) {
                Log::warning("MM Import - Header not found. Defaulting to Row 5.");
                $headerRowIndex = 5;
            }
            Log::info("MM Import - Header at Row {$headerRowIndex}");
            
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
                'total gaji' => 'total_salary_1',
                'lembur' => 'overtime_rate_header',
                'bonus' => 'bonus',
                'insentif lebaran' => 'holiday_allowance',
                'thr' => 'holiday_allowance',
                'insentif' => 'incentive',
                'total gaji & bonus' => 'total_salary_2',
                'kebijakan' => 'policy_ho',
                'adj' => 'policy_ho',
                'potongan' => 'deductions_header',
                'grand total' => 'grand_total',
                'pinjaman ewa' => 'ewa_amount',
                'ewa' => 'ewa_amount',
                'payroll' => 'net_salary',
            ];
            
            // Subheader labels (Row headerRowIndex+1)
            $subHeaderLabels = [
                'hari' => 'days_total',
                'off' => 'days_off',
                'sakit' => 'days_sick',
                'ijin' => 'days_permission',
                'alfa' => 'days_alpha',
                'cuti' => 'days_leave',
                'ada' => 'days_present',
                '/ hari' => null, // handled contextually
                'jumlah' => null, // handled contextually
                '/ jam' => 'overtime_rate',
                'jam' => 'overtime_hours',
                'absen 1x' => 'deduction_absent',
                'terlambat' => 'deduction_absent', // Maybe same deduction column
                'selisih so' => 'deduction_shortage',
                'pinjaman' => 'deduction_loan',
                'adm bank' => 'deduction_admin_fee',
                'bpjs tk' => 'deduction_bpjs_tk',
            ];
            
            // Scan header row
            for ($colIndex = 1; $colIndex <= min(45, $highestColIndex); $colIndex++) {
                $col = \PhpOffice\PhpSpreadsheet\Cell\Coordinate::stringFromColumnIndex($colIndex);
                $headerVal = strtolower(trim((string)$sheet->getCell($col . $headerRowIndex)->getValue()));
                $subHeaderVal = strtolower(trim((string)$sheet->getCell($col . ($headerRowIndex + 1))->getValue()));
                
                // Check main header
                foreach ($headerLabels as $key => $field) {
                    if ($headerVal && stripos($headerVal, $key) !== false && !isset($columnMap[$field])) {
                        $columnMap[$field] = $col;
                        break;
                    }
                }
                
                // Check sub-header
                foreach ($subHeaderLabels as $key => $field) {
                    if ($field && $subHeaderVal === $key && !isset($columnMap[$field])) {
                        $columnMap[$field] = $col;
                        break;
                    }
                }
                
                // Handle "Jumlah" subheaders contextually
                if ($subHeaderVal === 'jumlah') {
                    if (stripos($headerVal, 'makan') !== false) {
                        $columnMap['meal_amount'] = $col;
                    } elseif (stripos($headerVal, 'transport') !== false) {
                        $columnMap['transport_amount'] = $col;
                    } elseif (stripos($headerVal, 'kehadiran') !== false) {
                        $columnMap['attendance_amount'] = $col;
                    } elseif (stripos($headerVal, 'lembur') !== false) {
                        $columnMap['overtime_amount'] = $col;
                    } elseif (stripos($headerVal, 'potongan') !== false || !empty($columnMap['deduction_bpjs_tk'])) {
                        $columnMap['deduction_total'] = $col;
                    }
                    
                    // Merged header context fallback
                    if (!isset($columnMap['meal_amount']) && isset($columnMap['meal_rate_header']) && $colIndex === (\PhpOffice\PhpSpreadsheet\Cell\Coordinate::columnIndexFromString($columnMap['meal_rate_header']) + 1)) {
                        $columnMap['meal_amount'] = $col;
                    }
                    if (!isset($columnMap['transport_amount']) && isset($columnMap['transport_rate_header']) && $colIndex === (\PhpOffice\PhpSpreadsheet\Cell\Coordinate::columnIndexFromString($columnMap['transport_rate_header']) + 1)) {
                        $columnMap['transport_amount'] = $col;
                    }
                    if (!isset($columnMap['attendance_amount']) && isset($columnMap['attendance_allowance_header']) && $colIndex === (\PhpOffice\PhpSpreadsheet\Cell\Coordinate::columnIndexFromString($columnMap['attendance_allowance_header']) + 1)) {
                        $columnMap['attendance_amount'] = $col;
                    }
                }
                
                // Handle "/ Hari" contextually
                if ($subHeaderVal === '/ hari') {
                    if (stripos($headerVal, 'makan') !== false || (!isset($columnMap['meal_rate']) && isset($columnMap['total_salary_1']))) {
                        $columnMap['meal_rate'] = $col;
                    } elseif (stripos($headerVal, 'transport') !== false || (!isset($columnMap['transport_rate']) && isset($columnMap['meal_rate']))) {
                        $columnMap['transport_rate'] = $col;
                    } elseif (stripos($headerVal, 'kehadiran') !== false || (!isset($columnMap['attendance_rate']) && isset($columnMap['transport_rate']))) {
                        $columnMap['attendance_rate'] = $col;
                    }
                    
                    // Specific matching for "x / Hari"
                    if (stripos($headerVal, 'makan') !== false) $columnMap['meal_rate'] = $col;
                    if (stripos($headerVal, 'transport') !== false) $columnMap['transport_rate'] = $col;
                    if (stripos($headerVal, 'kehadiran') !== false) $columnMap['attendance_rate'] = $col;
                }
            }
            
            Log::info("MM Import - Column Map: " . json_encode($columnMap));
            
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
                                Log::info("MM Import - Detected period from cell {$col}{$row}: {$detectedPeriod}");
                                break 3;
                            }
                        }
                    }
                }
            }
            
            if (!$detectedPeriod) {
                // Check if any row has Periode column filled, else fallback
                $detectedPeriod = date('Y-m'); 
                Log::warning("MM Import - Could not detect period. Using current: {$detectedPeriod}");
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
                    // if shift happened, it's C
                     $accountCol = 'C'; 
                }
                
                // Identify period for this row: if we detected it globally, use it. Some MM files have Periode in col C
                $rowPeriod = $detectedPeriod;
                if (!isset($columnMap['account_number'])) { // meaning we couldn't properly detect account number, so Periode might be C
                     $periodCell = $sheet->getCell('C' . $row)->getValue();
                     if (is_numeric($periodCell)) {
                        try {
                            $rowPeriod = \PhpOffice\PhpSpreadsheet\Shared\Date::excelToDateTimeObject($periodCell)->format('Y-m');
                        } catch (\Exception $e) {}
                     } elseif (is_string($periodCell) && preg_match('/^\d{4}-\d{2}$/', $periodCell)) {
                         $rowPeriod = $periodCell;
                     }
                }
                
                $parsed = [
                    'employee_name' => $employeeName,
                    'period' => $rowPeriod,
                    'account_number' => $sheet->getCell($accountCol . $row)->getValue(),
                    
                    // Attendance 
                    'days_total' => (int) $getMappedValue('days_total', $row),
                    'days_off' => (int) $getMappedValue('days_off', $row),
                    'days_sick' => (int) $getMappedValue('days_sick', $row),
                    'days_permission' => (int) $getMappedValue('days_permission', $row),
                    'days_alpha' => (int) $getMappedValue('days_alpha', $row),
                    'days_leave' => (int) $getMappedValue('days_leave', $row),
                    'days_present' => (int) $getMappedValue('days_present', $row),
                    
                    // Salary
                    'basic_salary' => $getMappedValue('basic_salary', $row),
                    
                    // Allowances
                    'meal_rate' => $getMappedValue('meal_rate', $row),
                    'meal_amount' => $getMappedValue('meal_amount', $row),
                    
                    'transport_rate' => $getMappedValue('transport_rate', $row),
                    'transport_amount' => $getMappedValue('transport_amount', $row),
                    
                    'attendance_rate' => $getMappedValue('attendance_rate', $row),
                    'attendance_amount' => $getMappedValue('attendance_amount', $row), // Also corresponds to attendance_allowance_header
                    
                    'health_allowance' => $getMappedValue('health_allowance', $row),
                    'position_allowance' => $getMappedValue('position_allowance', $row),
                    
                    'total_salary_1' => $getMappedValue('total_salary_1', $row),
                    
                    // Overtime
                    'overtime_rate' => $getMappedValue('overtime_rate', $row),
                    'overtime_hours' => $getMappedValue('overtime_hours', $row),
                    'overtime_amount' => $getMappedValue('overtime_amount', $row),
                    
                    // Bonus & Incentives
                    'bonus' => $getMappedValue('bonus', $row),
                    'incentive' => $getMappedValue('incentive', $row),
                    'holiday_allowance' => $getMappedValue('holiday_allowance', $row), // THR / Lebaran
                    
                    'total_salary_2' => $getMappedValue('total_salary_2', $row),
                    'policy_ho' => $getMappedValue('policy_ho', $row),
                    
                    // Deductions
                    'deduction_absent' => $getMappedValue('deduction_absent', $row), 
                    'deduction_alpha' => $getMappedValue('days_alpha', $row) > 0 ? $getMappedValue('deduction_absent', $row) : 0, // Fallback if no specific deduction_alpha mapped
                    'deduction_shortage' => $getMappedValue('deduction_shortage', $row),
                    'deduction_loan' => $getMappedValue('deduction_loan', $row),
                    'deduction_admin_fee' => $getMappedValue('deduction_admin_fee', $row),
                    'deduction_bpjs_tk' => $getMappedValue('deduction_bpjs_tk', $row),
                    
                    'deduction_total' => $getMappedValue('deduction_total', $row),
                    
                    // Finals
                    'grand_total' => $getMappedValue('grand_total', $row),
                    'ewa_amount' => $getMappedValue('ewa_amount', $row),
                    'net_salary' => $getMappedValue('net_salary', $row),
                ];
                
                // --- FALLBACK CALCULATIONS ---
                // If the column names didn't map perfectly for attendance_amount, but we found the header
                if (!$parsed['attendance_amount'] && $parsed['attendance_rate']) {
                     $parsed['attendance_amount'] = $getMappedValue('attendance_allowance_header', $row) ?: ($parsed['attendance_rate'] * clone $parsed['days_present']);
                }
                
                // Fallback for deduction total if missing
                if (!$parsed['deduction_total']) {
                    $parsed['deduction_total'] = $parsed['deduction_absent'] + $parsed['deduction_alpha'] + $parsed['deduction_shortage'] + $parsed['deduction_loan'] + $parsed['deduction_admin_fee'] + $parsed['deduction_bpjs_tk'];
                }
                
                // Fallback for grand total and net salary if header is missing (like in 04. Gaji Bekal.xlsx format)
                if (!$parsed['grand_total']) {
                    // Try to guess from the last column if it contains a formula for total
                    $guessedGrandTotal = $getCellValue(\PhpOffice\PhpSpreadsheet\Cell\Coordinate::stringFromColumnIndex($highestColIndex), $row);
                    $guessedNet = $getCellValue(\PhpOffice\PhpSpreadsheet\Cell\Coordinate::stringFromColumnIndex($highestColIndex), $row);
                    
                    if ($parsed['total_salary_2']) {
                        $calculatedTotal = $parsed['total_salary_2'] + $parsed['policy_ho'] - $parsed['deduction_total'];
                        $parsed['grand_total'] = $calculatedTotal;
                        $parsed['net_salary'] = $calculatedTotal - $parsed['ewa_amount'];
                    } elseif ($guessedGrandTotal > 0) {
                         $parsed['grand_total'] = $guessedGrandTotal;
                         $parsed['net_salary'] = $guessedNet;
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
            Log::error('MM Payroll Import Error: ' . $e->getMessage() . "\n" . $e->getTraceAsString());
            return response()->json(['message' => 'Error: ' . $e->getMessage()], 500);
        }
    }
    
    /**
     * Save imported MM payroll data
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
                // Find employee by full_name
                $employee = Employee::where('full_name', $row['employee_name'])->first();
                
                if (!$employee) {
                    $errors[] = "Row " . ($index + 1) . ": Employee '{$row['employee_name']}' not found";
                    continue;
                }
                
                // Check duplicate
                $existing = PayrollMm::where('employee_id', $employee->id)
                    ->where('period', $row['period'])
                    ->first();
                
                if ($existing) {
                    $errors[] = "Row " . ($index + 1) . ": Payroll info for '{$row['employee_name']}' already exists";
                    continue;
                }
                
                PayrollMm::create(array_merge($row, [
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
            Log::error('MM Payroll Save Error: ' . $e->getMessage());
            return response()->json(['message' => 'Error: ' . $e->getMessage()], 500);
        }
    }
    
    public function show($id)
    {
        $payroll = PayrollMm::with('employee')->findOrFail($id);

        if (!$this->isAdmin()) {
            $user = auth()->user();
            if (!$user->employee || $user->employee->id !== $payroll->employee_id) {
                return response()->json(['message' => 'Unauthorized'], 403);
            }
        }
        
        return response()->json($this->formatPayroll($payroll));
    }
    
    public function updateStatus(Request $request, $id)
    {
        if (!$this->isAdmin()) {
            return response()->json(['message' => 'Anda tidak memiliki akses untuk operasi ini.'], 403);
        }

         $request->validate([
            'status' => 'required|in:draft,approved,paid',
            'approval_signature' => 'nullable|string',
        ]);

        $payroll = PayrollMm::findOrFail($id);
        
        $data = ['status' => $request->status];
        
        if ($request->status === 'approved' && $request->has('approval_signature')) {
            $data['approval_signature'] = $request->approval_signature;
            $data['signer_name'] = $request->signer_name;
            $data['approved_by'] = auth()->id();
        }

        $payroll->update($data);

        return response()->json([
            'message' => 'Status updated successfully',
            'payroll' => $payroll,
        ]);
    }
    
    public function destroy($id)
    {
        if (!$this->isAdmin()) {
            return response()->json(['message' => 'Anda tidak memiliki akses untuk operasi ini.'], 403);
        }

        $payroll = PayrollMm::findOrFail($id);
        $payroll->delete();
        return response()->json(['message' => 'Payroll deleted successfully']);
    }
    
    /**
     * Generate PDF Slip
     */
    public function generateSlip($id)
    {
        try {
            $payroll = PayrollMm::with('employee')->findOrFail($id);
            
            if (!$this->isAdmin()) {
                $user = auth()->user();
                if (!$user->employee || $user->employee->id !== $payroll->employee_id) {
                    return response()->json(['message' => 'Unauthorized'], 403);
                }
            }
            
            $formatted = $this->formatPayroll($payroll); 
            
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

            // Pass simple object to view, view can format
            $pdf = PDF::loadView('payslips.mm', [
                'payroll' => $payroll,
                'aiMessage' => $aiMessage
            ]);
            
            $filename = 'payslip_mm_' . str_replace(' ', '_', $payroll->employee->full_name) . '_' . $payroll->period . '.pdf';
            
            return $pdf->download($filename);
        } catch (\Exception $e) {
            Log::error('Error generating MM payslip: ' . $e->getMessage());
             return response()->json([
                'message' => 'Failed to generate payslip', 
                'error' => $e->getMessage()
            ], 500);
        }
    }
    
    private function formatPayroll($payroll)
    {
        $formatted = $payroll->toArray();
        
        $formatted['allowances'] = [
             'Uang Makan' => [
                 'rate' => $payroll->meal_rate,
                 'amount' => $payroll->meal_amount,
             ],
             'Transport' => [
                 'rate' => $payroll->transport_rate,
                 'amount' => $payroll->transport_amount,
             ],
             'Kehadiran' => [
                 'rate' => $payroll->attendance_rate,
                 'amount' => $payroll->attendance_amount,
             ],
             'Tunjangan Kesehatan' => $payroll->health_allowance,
             'Tunjangan Jabatan' => $payroll->position_allowance,
             'Lembur' => [
                 'rate' => $payroll->overtime_rate,
                 'hours' => $payroll->overtime_hours,
                 'amount' => $payroll->overtime_amount,
             ],
             'Bonus' => $payroll->bonus,
             'Insentif' => $payroll->incentive,
             'THR' => $payroll->holiday_allowance,
             'Kebijakan HO' => $payroll->policy_ho,
        ];
        
        $formatted['deductions'] = [
            'Absen 1X' => $payroll->deduction_absent,
            'Alfa' => $payroll->deduction_alpha,
            'Selisih SO' => $payroll->deduction_shortage,
            'Pinjaman' => $payroll->deduction_loan,
            'Adm Bank' => $payroll->deduction_admin_fee,
            'BPJS TK' => $payroll->deduction_bpjs_tk,
        ];
        
        return $formatted;
    }
}
