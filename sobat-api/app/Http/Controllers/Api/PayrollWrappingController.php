<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\PayrollWrapping;
use App\Models\Employee;
use App\Models\Role;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use PDF;
use App\Services\GroqAiService;

class PayrollWrappingController extends Controller
{
    private function isAdmin(): bool
    {
        $user = auth()->user();
        $roleName = $user->role ? strtolower($user->role->name) : '';
        return in_array($roleName, [Role::SUPER_ADMIN, Role::ADMIN, Role::ADMIN_CABANG, Role::HR]);
    }

    public function index(Request $request)
    {
        $user = auth()->user();
        $query = PayrollWrapping::with('employee');

        // Check scope
        if (!$this->isAdmin()) {
            $employeeId = $user->employee ? $user->employee->id : null;
            if ($employeeId) {
                $query->where('employee_id', $employeeId);
                $query->whereIn('status', ['approved', 'paid']);
            } else {
                return response()->json([]);
            }
        }
        
        if ($request->has('month') && $request->has('year') && $request->month != 0 && $request->year != 0) {
            $period = $request->year . '-' . str_pad($request->month, 2, '0', STR_PAD_LEFT);
            $query->where('period', $period);
        }
        // Fallback if only one provided (rare but robust)
        else {
             if ($request->has('month') && $request->month != 0) {
                 $query->whereRaw('MONTH(STR_TO_DATE(CONCAT(period, "-01"), "%Y-%m-%d")) = ?', [$request->month]);
             }
             if ($request->has('year') && $request->year != 0) {
                 $query->whereRaw('LEFT(period, 4) = ?', [$request->year]);
        }
        
        }
        
        $payrolls = $query->orderBy('period', 'desc')->paginate(20);
        
        $payrolls->getCollection()->transform(function ($payroll) {
            return $this->formatPayroll($payroll);
        });
        
        return response()->json($payrolls);
    }

    private function formatPayroll($payroll)
    {
        $formatted = $payroll->toArray();
        
        // Structured Allowances for UI
        $formatted['allowances'] = [
            'Kehadiran' => [
                'amount' => $payroll->attendance_allowance, // Tunj Kehadiran
            ],
            'Gaji Training' => $payroll->training_salary,
            'Transport' => [
                'rate' => $payroll->transport_rate,
                'amount' => $payroll->transport_amount,
            ],
            'Uang Makan' => [
                'rate' => $payroll->meal_rate,
                'amount' => $payroll->meal_amount,
            ],
            'Tunjangan Kesehatan' => $payroll->health_allowance,
            'Lembur' => [
                'hours' => $payroll->overtime_hours,
                'amount' => $payroll->overtime_amount,
            ],
            'Bonus' => $payroll->bonus,
            'Target Koli' => $payroll->target_koli,
            'Fee Aksesoris' => $payroll->fee_aksesoris,
            'Adj BPJS' => $payroll->adj_bpjs,
        ];
        
        // Deductions
        $formatted['deductions'] = [
            'Potongan Absen' => $payroll->deduction_absent,
            'Terlambat' => $payroll->deduction_late,
            'Tidak Hadir (Alpha)' => $payroll->deduction_alpha,
            'Kasbon' => $payroll->deduction_loan,
            'Adm Bank' => $payroll->deduction_admin_fee,
            'BPJS TK' => $payroll->deduction_bpjs_tk,
        ];
        
         // Add attendance data for Mobile App
        $formatted['attendance'] = [
            'Total Hari' => $payroll->days_total,
            'Hadir' => $payroll->days_present,
            'Off' => $payroll->days_off,
            'Sakit' => $payroll->days_sick,
            'Ijin' => $payroll->days_permission,
            'Alfa' => $payroll->days_alpha,
            'Cuti' => $payroll->days_leave,
        ];
        
        return $formatted;
    }

    public function import(Request $request)
    {
        $request->validate(['file' => 'required|file|mimes:xlsx,xls']);
        $file = $request->file('file');

        try {
            $reader = \PhpOffice\PhpSpreadsheet\IOFactory::createReader('Xlsx');
            $reader->setReadDataOnly(true);
            $spreadsheet = $reader->load($file->getRealPath());
            
            // --- TARGET THE "Gaji" SHEET ---
            $sheetNames = $spreadsheet->getSheetNames();
            Log::info("Wrapping Import - Available sheets: " . implode(', ', $sheetNames));
            
            $sheet = null;
            foreach ($sheetNames as $name) {
                if (stripos($name, 'gaji') !== false) {
                    $sheet = $spreadsheet->getSheetByName($name);
                    Log::info("Wrapping Import - Using sheet: {$name}");
                    break;
                }
            }
            
            if (!$sheet) {
                $sheet = $spreadsheet->getSheet(0);
                Log::warning("Wrapping Import - 'Gaji' sheet not found. Using first sheet: " . $sheet->getTitle());
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
                Log::warning("Wrapping Import - Header not found. Defaulting to Row 5.");
                $headerRowIndex = 5;
            }
            Log::info("Wrapping Import - Header at Row {$headerRowIndex}");
            
            // --- DYNAMIC COLUMN MAPPING ---
            // Read header row (headerRowIndex) AND subheader row (headerRowIndex+1) to build a column map
            $columnMap = [];
            $headerLabels = [
                'nama karyawan' => 'employee_name',
                'no rekening' => 'account_number',
                'gaji pokok' => 'basic_salary',
                'gaji  training' => 'training_salary',
                'gaji training' => 'training_salary',
                'uang makan' => 'meal_rate_header',
                'transport' => 'transport_rate_header',
                'tunj. kehadiran' => 'attendance_allowance',
                'tunj kehadiran' => 'attendance_allowance',
                'tunj. kesehatan' => 'health_allowance',
                'tunj kesehatan' => 'health_allowance',
                'insentif lebaran' => 'bonus',
                'bonus' => 'bonus',
                'total gaji' => 'subtotal',
                'lembur' => 'overtime_rate_header',
                'target koli' => 'target_koli',
                'fee aksesoris' => 'fee_aksesoris',
                'total gaji & bonus' => 'total_salary_gross',
                'adj gaji' => 'adj_bpjs',
                'potongan' => 'deductions_header',
                'grand total' => 'net_salary',
                'pinjaman ewa' => 'ewa_amount',
                'payroll' => 'payroll_final',
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
                '/ hari' => null, // handled contextually (meal or transport amount)
                'jumlah' => null, // handled contextually
                '/ jam' => 'overtime_rate',
                'jam' => 'overtime_hours',
                'absen 1x' => 'deduction_absent',
                'terlambat' => 'deduction_late',
                'tidak hadir' => 'deduction_alpha',
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
                
                // Check sub-header for attendance & deduction columns
                foreach ($subHeaderLabels as $key => $field) {
                    if ($field && $subHeaderVal === $key && !isset($columnMap[$field])) {
                        $columnMap[$field] = $col;
                        break;
                    }
                }
                
                // Handle "Jumlah" subheaders contextually (meal_amount, transport_amount, overtime_amount, deduction_total)
                if ($subHeaderVal === 'jumlah') {
                    // Find what the main header says for this column
                    if (stripos($headerVal, 'makan') !== false) {
                        $columnMap['meal_amount'] = $col;
                    } elseif (stripos($headerVal, 'transport') !== false) {
                        $columnMap['transport_amount'] = $col;
                    } elseif (stripos($headerVal, 'lembur') !== false) {
                        $columnMap['overtime_amount'] = $col;
                    } elseif (stripos($headerVal, 'potongan') !== false || !empty($columnMap['deduction_bpjs_tk'])) {
                        $columnMap['deduction_total'] = $col;
                    }
                    // Also check merged header context: if previous columns were meal/transport
                    if (!isset($columnMap['meal_amount']) && isset($columnMap['meal_rate_header'])) {
                        // Check if this col is right after meal_rate_header
                        $mealCol = $columnMap['meal_rate_header'];
                        $mealIdx = \PhpOffice\PhpSpreadsheet\Cell\Coordinate::columnIndexFromString($mealCol);
                        if ($colIndex === $mealIdx + 1) {
                            $columnMap['meal_amount'] = $col;
                        }
                    }
                    if (!isset($columnMap['transport_amount']) && isset($columnMap['transport_rate_header'])) {
                        $transCol = $columnMap['transport_rate_header'];
                        $transIdx = \PhpOffice\PhpSpreadsheet\Cell\Coordinate::columnIndexFromString($transCol);
                        if ($colIndex === $transIdx + 1) {
                            $columnMap['transport_amount'] = $col;
                        }
                    }
                }
                
                // Handle "/ Hari" subheaders (rate columns for meal/transport)
                if ($subHeaderVal === '/ hari') {
                    if (!isset($columnMap['meal_rate'])) {
                        $columnMap['meal_rate'] = $col;
                    } elseif (!isset($columnMap['transport_rate'])) {
                        $columnMap['transport_rate'] = $col;
                    }
                }
            }
            
            Log::info("Wrapping Import - Column Map: " . json_encode($columnMap));
            
            // --- EXTRACT PERIOD FROM SHEET ---
            // Look for "GAJI MARET 2026" or "Periode: ..." in rows above header
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
                                Log::info("Wrapping Import - Detected period from cell {$col}{$row}: {$detectedPeriod}");
                                break 3;
                            }
                        }
                    }
                }
            }
            
            if (!$detectedPeriod) {
                $detectedPeriod = date('Y-m');
                Log::warning("Wrapping Import - Could not detect period. Using current: {$detectedPeriod}");
            }
            
            // --- DATA EXTRACTION ---
            $dataStartRow = $headerRowIndex + 2;
            Log::info("Wrapping Import - Data starts at Row {$dataStartRow}, Highest Row: {$highestRow}");
            
            $dataRows = [];
            $consecutiveEmptyRows = 0;
            
            // Helper to get value from mapped column
            $getCol = function($field) use ($columnMap) {
                return $columnMap[$field] ?? null;
            };
            
            $getMappedValue = function($field, $row) use ($getCellValue, $getCol) {
                $col = $getCol($field);
                return $col ? $getCellValue($col, $row) : 0;
            };
            
            for ($row = $dataStartRow; $row <= $highestRow; $row++) {
                $name = $sheet->getCell('B' . $row)->getValue();
                
                if (empty($name) || !is_string($name)) {
                    $consecutiveEmptyRows++;
                    if ($consecutiveEmptyRows >= 5) {
                        Log::info("Wrapping Import - 5 consecutive empty rows at row {$row}. Stopping.");
                        break;
                    }
                    continue; 
                }
                
                $consecutiveEmptyRows = 0;
                
                $accountCol = $getCol('account_number') ?? 'C';
                
                $parsed = [
                    'employee_name' => $name,
                    'period' => $detectedPeriod,
                    'account_number' => $sheet->getCell($accountCol . $row)->getValue(),
                    
                    // Attendance
                    'days_total' => (int)$getMappedValue('days_total', $row),
                    'days_off' => (int)$getMappedValue('days_off', $row),
                    'days_sick' => (int)$getMappedValue('days_sick', $row),
                    'days_permission' => (int)$getMappedValue('days_permission', $row),
                    'days_alpha' => (int)$getMappedValue('days_alpha', $row),
                    'days_leave' => (int)$getMappedValue('days_leave', $row),
                    'days_present' => (int)$getMappedValue('days_present', $row),
                    
                    // Income
                    'basic_salary' => $getMappedValue('basic_salary', $row),
                    'training_salary' => $getMappedValue('training_salary', $row),
                    
                    'meal_rate' => $getMappedValue('meal_rate', $row),
                    'meal_amount' => $getMappedValue('meal_amount', $row),
                    
                    'transport_rate' => $getMappedValue('transport_rate', $row),
                    'transport_amount' => $getMappedValue('transport_amount', $row),
                    
                    'attendance_allowance' => $getMappedValue('attendance_allowance', $row), 
                    'health_allowance' => $getMappedValue('health_allowance', $row),
                    'bonus' => $getMappedValue('bonus', $row),
                    
                    // Overtime
                    'overtime_hours' => $getMappedValue('overtime_hours', $row),
                    'overtime_amount' => $getMappedValue('overtime_amount', $row), 
                    
                    'target_koli' => $getMappedValue('target_koli', $row),
                    'fee_aksesoris' => $getMappedValue('fee_aksesoris', $row),
                    
                    'total_salary_gross' => $getMappedValue('total_salary_gross', $row),
                    'adj_bpjs' => $getMappedValue('adj_bpjs', $row),
                    
                    // Deductions
                    'deduction_absent' => $getMappedValue('deduction_absent', $row),
                    'deduction_late' => $getMappedValue('deduction_late', $row),
                    'deduction_alpha' => $getMappedValue('deduction_alpha', $row),
                    'deduction_loan' => $getMappedValue('deduction_loan', $row),
                    'deduction_admin_fee' => $getMappedValue('deduction_admin_fee', $row),
                    'deduction_bpjs_tk' => $getMappedValue('deduction_bpjs_tk', $row),
                    
                    'deduction_total' => $getMappedValue('deduction_total', $row),
                    
                    // Finals
                    'net_salary' => $getMappedValue('net_salary', $row),
                    'ewa_amount' => $getMappedValue('ewa_amount', $row),
                ];
                
                $dataRows[] = $parsed;
            }
            
            Log::info("Wrapping Import - Parsed " . count($dataRows) . " employee rows.");
             
            return response()->json([
                'message' => 'File parsed successfully',
                'rows' => $dataRows
            ]);

        } catch (\Exception $e) {
            Log::error("Wrapping Import Error: " . $e->getMessage() . "\n" . $e->getTraceAsString());
            return response()->json(['message' => 'Error: ' . $e->getMessage()], 500);
        }
    }
    
    public function saveImport(Request $request)
    {
        $request->validate(['rows' => 'required|array']);
        
        $saved = 0;
        $errors = [];
        
        foreach ($request->rows as $index => $row) {
            $employee = Employee::where('full_name', $row['employee_name'])->first();
            if (!$employee) {
                // Try fuzzy?
                $errors[] = "Row " . ($index + 1) . ": Employee '{$row['employee_name']}' not found";
                // Optionally create dummy employee or skip
                continue; 
            }
            
            $existing = PayrollWrapping::where('employee_id', $employee->id)
                ->where('period', $row['period'])
                ->first();
                
            if ($existing) {
                 $errors[] = "Row " . ($index + 1) . ": Payroll already exists for {$row['employee_name']} in {$row['period']}";
                 continue;
            }
            
            PayrollWrapping::create(array_merge($row, ['employee_id' => $employee->id]));
            $saved++;
        }
        
        return response()->json([
            'saved' => $saved,
            'errors' => $errors, 
            'message' => "Saved $saved records"
        ]);
    }
    
    public function show($id)
    {
        $payroll = PayrollWrapping::with('employee')->findOrFail($id);

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

        $payroll = PayrollWrapping::findOrFail($id);
        $payroll->update([
            'status' => $request->status,
            'approval_signature' => $request->approval_signature,
            'signer_name' => $request->signer_name,
            'approved_at' => now(),
            'approved_by' => auth()->id()
        ]);
        return response()->json(['message' => 'Updated']);
    }
    
    public function generateSlip($id)
    {
        $payroll = PayrollWrapping::with('employee')->findOrFail($id);

        if (!$this->isAdmin()) {
            $user = auth()->user();
            if (!$user->employee || $user->employee->id !== $payroll->employee_id) {
                return response()->json(['message' => 'Unauthorized'], 403);
            }
        }

        $data = $this->formatPayroll($payroll); 
        
        // Remove 'employee' to prevent overwriting the relationship object with an array
        unset($data['employee']);
        
        // Inject into model for blade
        foreach ($data as $key => $val) {
            $payroll->$key = $val;
        }
        
        // Generate AI-powered personalized message
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
            $aiMessage = null; // Fallback if AI fails
        }
        
        $pdf = PDF::loadView('payslips.wrapping', [
            'payroll' => $payroll,
            'aiMessage' => $aiMessage
        ]);
        return $pdf->download('payslip_wrapping.pdf');
    }
}
