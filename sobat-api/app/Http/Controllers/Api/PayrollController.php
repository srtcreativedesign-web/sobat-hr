<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Payroll;
use App\Models\Employee;
use Barryvdh\DomPDF\Facade\Pdf;
use App\Services\GroqAiService;
use Maatwebsite\Excel\Facades\Excel;

class PayrollController extends Controller
{
    public function index(Request $request)
    {
        $query = Payroll::with(['employee']);

        // Filter by status
        if ($request->has('status')) {
            $query->where('status', $request->status);
        }

        // Filter by employee
        if ($request->has('employee_id')) {
            $query->where('employee_id', $request->employee_id);
        }

        // Automatic scope for non-admin users
        $user = auth()->user();
        // Check if user has a role relation and if that role is admin/hr
        $roleName = $user->role ? strtolower($user->role->name) : '';
        \Illuminate\Support\Facades\Log::info("DEBUG PAYROLL: User ID {$user->id}, Role: {$roleName}"); // DEBUG

        if (!in_array($roleName, ['admin', 'super_admin', 'hr'])) {
            // Access employee via relation
            $employeeId = $user->employee ? $user->employee->id : null;

            if ($employeeId) {
                $query->where('employee_id', $employeeId);
                \Illuminate\Support\Facades\Log::info("DEBUG PAYROLL: Filtered by Employee ID {$employeeId}");
            } else {
                // If user has no employee_id linked, they shouldn't see any payrolls
                \Illuminate\Support\Facades\Log::info("DEBUG PAYROLL: No Employee ID linked for non-admin");
                return response()->json(['data' => []]);
            }
        } else {
            \Illuminate\Support\Facades\Log::info("DEBUG PAYROLL: Admin Access Granted");
        }

        // Filter by period (month and year)
        if ($request->has('month') && $request->has('year')) {
            // period is stored as YYYY-MM
            $periodString = sprintf('%04d-%02d', $request->year, $request->month);
            $query->where('period', $periodString);
        }
        // Filter by year only
        elseif ($request->has('year')) {
            $query->where('period', 'like', $request->year . '-%');
        }

        $payrolls = $query->orderBy('period', 'desc')
            ->get();

        return response()->json([
            'data' => $payrolls->map(function ($payroll) {
                // Parse period (YYYY-MM format)
                $periodDate = $payroll->period . '-01';
                $periodStart = date('Y-m-01', strtotime($periodDate));
                $periodEnd = date('Y-m-t', strtotime($periodDate));

                return [
                    'id' => $payroll->id,
                    'employee' => [
                        'employee_code' => $payroll->employee->employee_code ?? 'N/A',
                        'full_name' => $payroll->employee->full_name ?? 'Unknown',
                    ],
                    'period_start' => $periodStart,
                    'period_end' => $periodEnd,
                    'basic_salary' => (float) $payroll->basic_salary,
                    'allowances' => (float) ($payroll->allowances ?? 0),
                    'overtime_pay' => (float) ($payroll->overtime_pay ?? 0),
                    'deductions' => (float) ($payroll->total_deductions ?? 0),
                    'bpjs_health' => (float) ($payroll->bpjs_kesehatan ?? 0),
                    'bpjs_employment' => (float) ($payroll->bpjs_ketenagakerjaan ?? 0),
                    'tax' => (float) ($payroll->pph21 ?? 0),
                    'gross_salary' => (float) $payroll->gross_salary,
                    'net_salary' => (float) $payroll->net_salary,
                    'details' => $payroll->details,
                    'status' => $payroll->status === 'draft' ? 'pending' : $payroll->status,
                ];
            }),
        ]);
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'employee_id' => 'required|exists:employees,id',
            'period_month' => 'required|integer|min:1|max:12',
            'period_year' => 'required|integer|min:2020',
            'base_salary' => 'required|numeric|min:0',
            'allowances' => 'nullable|numeric|min:0',
            'overtime_pay' => 'nullable|numeric|min:0',
            'deductions' => 'nullable|numeric|min:0',
            'bpjs_health' => 'nullable|numeric|min:0',
            'bpjs_employment' => 'nullable|numeric|min:0',
            'tax_pph21' => 'nullable|numeric|min:0',
            'net_salary' => 'required|numeric',
            'status' => 'required|in:draft,approved,paid',
        ]);

        $payroll = Payroll::create($validated);

        return response()->json($payroll, 201);
    }

    public function show(string $id)
    {
        $payroll = Payroll::with('employee')->findOrFail($id);
        return response()->json($payroll);
    }

    public function update(Request $request, string $id)
    {
        $payroll = Payroll::findOrFail($id);

        $validated = $request->validate([
            'base_salary' => 'sometimes|numeric|min:0',
            'allowances' => 'nullable|numeric|min:0',
            'overtime_pay' => 'nullable|numeric|min:0',
            'deductions' => 'nullable|numeric|min:0',
            'bpjs_health' => 'nullable|numeric|min:0',
            'bpjs_employment' => 'nullable|numeric|min:0',
            'tax_pph21' => 'nullable|numeric|min:0',
            'net_salary' => 'sometimes|numeric',
            'status' => 'sometimes|in:draft,approved,paid',
        ]);

        $payroll->update($validated);

        return response()->json($payroll);
    }

    public function destroy(string $id)
    {
        $payroll = Payroll::findOrFail($id);
        $payroll->delete();

        return response()->json(['message' => 'Payroll deleted successfully']);
    }

    /**
     * Generate payroll slip PDF
     */
    public function generateSlip(string $id)
    {
        $payroll = Payroll::with(['employee', 'employee.organization'])->findOrFail($id);

        // Generate AI-powered personalized message
        $groqService = new GroqAiService();
        $aiMessage = $groqService->generatePayslipMessage([
            'employee_name' => $payroll->employee->full_name,
            'period' => date('F Y', strtotime($payroll->period . '-01')),
            'basic_salary' => $payroll->basic_salary,
            'overtime' => $payroll->overtime_pay,
            'net_salary' => $payroll->net_salary,
        ]);

        // Generate PDF
        $pdf = Pdf::loadView('payroll.slip', [
            'payroll' => $payroll,
            'employee' => $payroll->employee,
            'aiMessage' => $aiMessage,
        ]);

        $pdf->setPaper('a4', 'portrait');

        $filename = 'Slip_Gaji_' . $payroll->employee->employee_code . '_' . $payroll->period . '.pdf';

        return $pdf->download($filename);
    }

    /**
     * Get payrolls for specific period
     */
    public function periodPayrolls(int $month, int $year)
    {
        $payrolls = Payroll::with('employee')
            ->where('period_month', $month)
            ->where('period_year', $year)
            ->get();

        $summary = [
            'total_employees' => $payrolls->count(),
            'total_base_salary' => $payrolls->sum('base_salary'),
            'total_allowances' => $payrolls->sum('allowances'),
            'total_overtime' => $payrolls->sum('overtime_pay'),
            'total_deductions' => $payrolls->sum('deductions'),
            'total_bpjs_health' => $payrolls->sum('bpjs_health'),
            'total_bpjs_employment' => $payrolls->sum('bpjs_employment'),
            'total_tax' => $payrolls->sum('tax_pph21'),
            'total_net_salary' => $payrolls->sum('net_salary'),
        ];

        return response()->json([
            'summary' => $summary,
            'payrolls' => $payrolls,
        ]);
    }

    /**
     * Download template Excel (CSV) for payroll import
     */
    public function downloadTemplate()
    {
        $headers = [
            'No',
            'Employee Name',
            'Employee Code', // NIK
            'Period',        // Format: YYYY-MM or "Januari 2024"
            'Basic Salary',
            'Overtime',
            'BPJS Health',
            'BPJS Employment',
            'Tax PPh21',
            'Other Deductions',
            'Net Salary'
        ];

        $callback = function () use ($headers) {
            $file = fopen('php://output', 'w');
            // Write BOM for Excel to recognize UTF-8
            fwrite($file, "\xEF\xBB\xBF");
            fputcsv($file, $headers);

            // Example row 1
            fputcsv($file, [
                '1',
                'Budi Santoso',
                'EMP001',
                date('Y-m'),
                '5000000',
                '500000',
                '100000',
                '200000',
                '50000',
                '0',
                '5150000'
            ]);

            fclose($file);
        };

        return response()->stream($callback, 200, [
            "Content-Type" => "text/csv",
            "Content-Disposition" => "attachment; filename=template_import_payroll.csv",
        ]);
    }

    /**
     * Import payroll from Excel/CSV file
     */
    public function import(Request $request)
    {
        $request->validate([
            'file' => 'required|file|mimes:xlsx,xls,csv|max:10240', // 10MB max
        ]);

        $file = $request->file('file');
        $storedPath = $file->store('payroll_imports', 'local');

        try {
            $path = $file->getRealPath();
            $spreadsheet = \PhpOffice\PhpSpreadsheet\IOFactory::load($path);
            $sheet = $spreadsheet->getActiveSheet();
            
            // Get all data
            $rows = [];
            foreach ($sheet->getRowIterator() as $row) {
                $cellIterator = $row->getCellIterator();
                $cellIterator->setIterateOnlyExistingCells(FALSE); // Loop all cells
                $rowData = [];
                foreach ($cellIterator as $cell) {
                    $rowData[] = $cell->getCalculatedValue(); // Get calculated value
                }
                $rows[] = $rowData;
            }

            if (empty($rows)) {
                return response()->json(['message' => 'File is empty or invalid'], 422);
            }

            // DETECT HEADER FORMAT
            // We assume the complex format (Row 2 + Row 3) usually.
            // Let's look for "Nama Karyawan" in first 5 rows
            $headerRowIndex = -1;
            foreach ($rows as $idx => $r) {
                if (isset($r[1]) && stripos($r[1], 'Nama Karyawan') !== false) {
                    $headerRowIndex = $idx;
                    break;
                }
            }

            if ($headerRowIndex === -1) {
                return response()->json(['message' => 'Format tidak dikenali. Pastikan ada kolom "Nama Karyawan".'], 422);
            }

            // MAPPING CONFIGURATION based on Column Analysis (0-indexed)
            // A=0, B=1, ... K=10, L=11, M=12, N=13, O=14, P=15, Q=16, R=17, S=18, T=19, U=20 
            // V=21, W=22, X=23, Y=24, Z=25, AA=26, AB=27, AC=28, AD=29, AE=30, AF=31
            
            // Check if Row 3 exists (idx + 1) for detailed columns
            $hasDetailedRow = isset($rows[$headerRowIndex + 1]);

            $idxEmployeeName = 1; // Col B
            $idxPeriod = -1; // Usually not in row, we might need to ask user or infer? 
            // Wait, in previous analysis "Period" wasn't explicitly in the columns shown.
            // The template uses Row 2: "No | Nama Karyawan ...". No Period column?
            // Let's check user data usage. Often period is in filename OR there is a generic period column.
            // In the `analyze_columns.php` output: NO Period column found in Row 2 headers.
            // But checking `saveImport`, we need period.
            // We will Try to find a Date/Period in the whole sheet before the header? 
            // OR default to Current Month if missing?
            // Let's look for separate "Period" logic later. For now assume it might be missing from row data.
            
            $dataRows = [];
            
            // Start reading data from Header + 2 (because Row 3 is sub-header)
            // If Header is Row 2 (index 1), Data starts at Row 4 (index 3)
            $startDataIndex = $headerRowIndex + ($hasDetailedRow ? 2 : 1);

            for ($i = $startDataIndex; $i < count($rows); $i++) {
                $row = $rows[$i];
                
                // Skip empty name
                if (empty($row[$idxEmployeeName])) continue;

                // Extract Values (Safe defaults)
                $extract = function($idx) use ($row) {
                    return isset($row[$idx]) ? $this->parseCurrency($row[$idx]) : 0;
                };

                // MAPPING (Based on Analysis)
                // K (10) = Basic Salary
                $basicSalary = $extract(10); 
                
                // Q (16) = Tunj. Jabatan => Existing 'allowances'
                $allowances = $extract(16);

                // P (15) = Tunj. Kesehatan => BPJS Health (Company portion? or allowance?)
                // Usually "Tunjangan BPJS" is income. "Potongan BPJS" is deduction.
                // Let's map P to 'bpjs_health' field for now, assuming it's the allowance part or the deduction part shown as positive?
                // Header says "Tunj. Kesehatan". So likely Income.
                // But DB 'bpjs_kesehatan' is usually the standard deduction amount stored?
                // If this is Tunjangan, add to Allowances? Or store in Details?
                // Let's store in `details['tunjangan_kesehatan']` and map to allowances total if needed.
                $tunjKesehatan = $extract(15);
                
                // N (13) Transport? No, Row 3 "Jumlah" is O (14). (Row 2 N is merged?)
                $transportAllowance = $extract(14); 

                // U (20) Lembur (Jumlah)
                $overtime = $extract(20);

                // V (21) Insentif Lebaran
                $insentif = $extract(21);

                // Z (25) Potongan -> Row 3 says "Absen 1X" at Z?
                // Wait. Column Analysis:
                // ROW 2: [Z] Potongan (Rp)
                // ROW 3: [Z] Absen 1X  [AA] Terlambat  [AB] Selisih SO  [AC] Pinjaman  [AD] Adm Bank  [AE] BPJS TK  [AF] Jumlah
                
                $absen1x = $extract(25);
                $terlambat = $extract(26);
                $selisihSO = $extract(27);
                $pinjaman = $extract(28); // AC (28)
                $admBank = $extract(29);
                $bpjsTKDeduction = $extract(30); // AE (30) BPJS TK
                
                // AF (31) Total Potongan
                $totalDeduction = $extract(31);

                // Calculate Totals to verify
                // Gross = Basic + Tunj Jabatan + Tunj Kesehatan + Transport + Overtime + Insentif
                // Note: Tunj Kesehatan might be Benefit (Non-cash)? 
                // Let's stick to explicitly explicit columns being saved.

                $details = [
                    'transport_allowance' => $transportAllowance, // O
                    'tunjangan_kesehatan' => $tunjKesehatan, // P
                    'insentif_lebaran' => $insentif, // V
                    'adj_kekurangan_gaji' => $extract(22), // W
                    'kebijakan_ho' => $extract(24), // Y
                    'absen_1x' => $absen1x, // Z
                    'terlambat' => $terlambat, // AA
                    'selisih_so' => $selisihSO, // AB
                    'pinjaman' => $pinjaman, // AC
                    'adm_bank' => $admBank, // AD
                    'bpjs_tk_deduction' => $bpjsTKDeduction, // AE
                ];

                $parsed = [
                    'employee_name' => $row[$idxEmployeeName],
                    'employee_code' => $row[2] ?? null, // C (2) No Rekening? Wait.
                    // Row 2 Analysis: [C] No Rekening. No Employee Code found in headers!
                    // We must rely on Name matching.
                    
                    'period' => date('Y-m'), // Default to current if missing
                    'basic_salary' => $basicSalary,
                    'allowances' => $allowances + $tunjKesehatan + $transportAllowance + $insentif, // Aggregate for backward compat
                    'overtime' => $overtime,
                    // Use Total Potongan from AF (31)
                    'total_deductions' => $totalDeduction,
                    'net_salary' => $extract(33), // AH (33) THP?
                    // [AG] Grand Total (32). [AH] THP (33).
                    
                    'details' => $details
                ];
                
                // If THP is 0/empty, calculate it?
                if ($parsed['net_salary'] == 0) {
                     $parsed['net_salary'] = $parsed['basic_salary'] + $parsed['allowances'] + $parsed['overtime'] - $parsed['total_deductions'];
                }

                $dataRows[] = $parsed;
            }

            return response()->json([
                'message' => 'File parsed successfully (Complex Format)',
                'file_name' => $file->getClientOriginalName(),
                'rows_count' => count($dataRows),
                'rows' => $dataRows,
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'message' => 'Failed to parse file: ' . $e->getMessage(),
                'file_name' => $file->getClientOriginalName(),
                'stored_path' => $storedPath,
            ], 500);
        }
    }

    /**
     * Save imported payroll data to database
     */
    public function saveImport(Request $request)
    {
        $request->validate([
            'rows' => 'required|array',
            'rows.*.employee_name' => 'required|string',
            'rows.*.basic_salary' => 'required|numeric',
            'rows.*.period' => 'nullable|string', // Period can be defaulted
            'rows.*.allowances' => 'nullable|numeric',
            'rows.*.overtime' => 'nullable|numeric',
            'rows.*.total_deductions' => 'nullable|numeric',
            'rows.*.net_salary' => 'required|numeric',
            'rows.*.details' => 'nullable|array', // For JSON column
        ]);

        $rows = $request->input('rows');
        $saved = [];
        $failed = [];

        foreach ($rows as $index => $row) {
            try {
                // Find employee by name (case insensitive)
                $employee = Employee::whereRaw('LOWER(full_name) = ?', [strtolower($row['employee_name'])])->first();

                if (!$employee) {
                    $failed[] = [
                        'row' => $index + 1,
                        'employee_name' => $row['employee_name'],
                        'reason' => 'Employee not found in database',
                    ];
                    continue;
                }

                // Parse period
                $period = $row['period'] ?? date('Y-m'); // Fallback
                $periodParsed = $this->parsePeriod($period);
                if (!$periodParsed) $periodParsed = ['year' => (int)date('Y'), 'month' => (int)date('m')];
                $periodString = sprintf('%04d-%02d', $periodParsed['year'], $periodParsed['month']);

                $basicSalary = $row['basic_salary'];
                $allowances = $row['allowances'] ?? 0;
                $overtime = $row['overtime'] ?? 0;
                $totalDeductions = $row['total_deductions'] ?? 0;
                $netSalary = $row['net_salary'];
                
                // Gross = Basic + Allowances + Overtime
                $grossSalary = $basicSalary + $allowances + $overtime;
                
                $details = $row['details'] ?? [];

                // Calculate known deductions from details to separate them from 'other_deductions'
                $bpjsTK = (float) ($details['bpjs_tk_deduction'] ?? 0);
                $absen = (float) ($details['absen_1x'] ?? 0);
                $terlambat = (float) ($details['terlambat'] ?? 0);
                $selisih = (float) ($details['selisih_so'] ?? 0);
                $pinjaman = (float) ($details['pinjaman'] ?? 0);
                $admBank = (float) ($details['adm_bank'] ?? 0);
                
                $knownDeductions = $bpjsTK + $absen + $terlambat + $selisih + $pinjaman + $admBank;
                $otherDeductions = $totalDeductions - $knownDeductions;
                
                // Ensure no negative other deductions (floating point safety)
                if ($otherDeductions < 0) $otherDeductions = 0;

                // Enforce Net Salary Consistency
                // Net Salary = Gross - Total Deductions
                // We use the calculated value to ensure the Slip PDF math matches the Database value
                $calculatedNetSalary = $grossSalary - $totalDeductions;

                // Check update or create
                $payroll = Payroll::updateOrCreate(
                    [
                        'employee_id' => $employee->id,
                        'period' => $periodString,
                    ],
                    [
                        'basic_salary' => $basicSalary,
                        'allowances' => $allowances,
                        'overtime_pay' => $overtime,
                        'gross_salary' => $grossSalary,
                        'total_deductions' => $totalDeductions,
                        'net_salary' => $calculatedNetSalary, // Use consistent calculated value
                        'details' => $details, // Save JSON
                        'status' => 'draft',
                        'bpjs_kesehatan' => 0, 
                        'bpjs_ketenagakerjaan' => $bpjsTK,
                        'pph21' => 0,
                        'other_deductions' => $otherDeductions,
                    ]
                );

                $saved[] = [
                    'row' => $index + 1,
                    'employee_name' => $row['employee_name'],
                    'action' => $payroll->wasRecentlyCreated ? 'created' : 'updated',
                ];

            } catch (\Exception $e) {
                $failed[] = [
                    'row' => $index + 1,
                    'employee_name' => $row['employee_name'] ?? 'Unknown',
                    'reason' => $e->getMessage(),
                ];
            }
        }

        return response()->json([
            'message' => 'Import updated successfully',
            'summary' => [
                'total' => count($rows),
                'saved' => count($saved),
                'failed' => count($failed),
            ],
            'saved' => $saved,
            'failed' => $failed,
        ]);
    }

    /**
     * Parse period string to month and year
     */
    private function parsePeriod($period)
    {
        // Clean the period string - remove leading numbers and extra spaces
        $period = preg_replace('/^\d+\s+/', '', trim($period));

        // Try format: YYYY-MM or YYYY/MM
        if (preg_match('/^(\d{4})[-\/](\d{1,2})$/', $period, $matches)) {
            return ['year' => (int) $matches[1], 'month' => (int) $matches[2]];
        }

        // Try format: "Januari 2026" or "January 2026"
        $monthNames = [
            'januari' => 1,
            'january' => 1,
            'jan' => 1,
            'februari' => 2,
            'february' => 2,
            'feb' => 2,
            'maret' => 3,
            'march' => 3,
            'mar' => 3,
            'april' => 4,
            'apr' => 4,
            'mei' => 5,
            'may' => 5,
            'juni' => 6,
            'june' => 6,
            'jun' => 6,
            'juli' => 7,
            'july' => 7,
            'jul' => 7,
            'agustus' => 8,
            'august' => 8,
            'aug' => 8,
            'september' => 9,
            'sep' => 9,
            'oktober' => 10,
            'october' => 10,
            'oct' => 10,
            'november' => 11,
            'nov' => 11,
            'desember' => 12,
            'december' => 12,
            'dec' => 12,
        ];

        $parts = preg_split('/\s+/', strtolower(trim($period)));
        if (count($parts) === 2) {
            $monthName = $parts[0];
            $year = (int) $parts[1];
            if (isset($monthNames[$monthName]) && $year > 2000) {
                return ['year' => $year, 'month' => $monthNames[$monthName]];
            }
        }

        return null;
    }

    /**
     * Update payroll status
     */
    public function updateStatus(Request $request, $id)
    {
        $request->validate([
            'status' => 'required|in:pending,approved,paid',
        ]);

        $payroll = Payroll::findOrFail($id);
        $payroll->status = $request->status;
        $payroll->save();

        return response()->json([
            'message' => 'Payroll status updated successfully',
            'data' => $payroll,
        ]);
    }

    /**
     * Generate payslip PDF
     */
    public function generatePayslip($id)
    {
        $payroll = Payroll::with(['employee'])->findOrFail($id);

        // TODO: Implement PDF generation
        // This will be implemented after payslip template is finalized

        return response()->json([
            'message' => 'Payslip generation will be implemented',
            'payroll_id' => $id,
        ]);
    }

    /**
     * Parse currency string to float (Handles Indonesian format)
     */
    private function parseCurrency($value)
    {
        if (is_numeric($value)) {
            return (float) $value;
        }

        $string = (string) $value;

        // Remove "Rp", "IDR", and spaces
        $string = preg_replace('/[^0-9,.-]/', '', $string);

        // Handle empty string
        if (empty($string)) {
            return 0.0;
        }

        // Indonesian format handling:
        // PRIORITY: Check for dots with exactly 3 digits pattern (thousands)
        // This catches 12.000, 200.000, 5.000.000 etc EARLY
        if (preg_match('/^\d{1,3}(\.\d{3})+$/', $string)) {
            // Definitely thousands separator format
            return (float) str_replace('.', '', $string);
        }

        // Mixed: has both dots and commas
        if (str_contains($string, '.') && str_contains($string, ',')) {
            // Assume 5.000.000,00 -> Remove dots, replace comma
            $string = str_replace('.', '', $string);
            $string = str_replace(',', '.', $string);
        }
        // Multiple dots (thousands separator)
        elseif (substr_count($string, '.') > 1) {
            $string = str_replace('.', '', $string);
        }
        // Single dot - ambiguous case
        elseif (str_contains($string, '.') && !str_contains($string, ',')) {
            // Try removing dot and see if result >= 1000
            $temp = str_replace('.', '', $string);
            if (is_numeric($temp) && (float) $temp >= 1000) {
                $string = $temp;
            }
            // Otherwise leave as decimal
        }

        // Final cleanup
        return (float) $string;
    }
}
