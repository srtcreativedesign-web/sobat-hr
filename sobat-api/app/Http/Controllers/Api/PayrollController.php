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
                    'allowances' => (float) ($payroll->overtime_pay ?? 0),
                    'deductions' => (float) ($payroll->bpjs_kesehatan ?? 0),
                    'bpjs_health' => (float) ($payroll->bpjs_kesehatan ?? 0),
                    'bpjs_employment' => (float) ($payroll->bpjs_ketenagakerjaan ?? 0),
                    'tax' => (float) ($payroll->pph21 ?? 0),
                    'gross_salary' => (float) $payroll->gross_salary,
                    'net_salary' => (float) $payroll->net_salary,
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
     * Download template Excel untuk import payroll
     */
    public function downloadTemplate()
    {
        // Temporary: return error since PhpSpreadsheet is not available
        return response()->json([
            'message' => 'Template download temporarily unavailable. Please use CSV format for import.',
            'error' => 'PhpSpreadsheet not installed due to PHP version compatibility',
        ], 503);
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
            // Parse Excel file and FORCE formula calculation
            $path = $file->getRealPath();

            // Load spreadsheet
            $spreadsheet = \PhpOffice\PhpSpreadsheet\IOFactory::load($path);

            // Note: toArray with second param=true forces calculation for formulas that haven't been calculated yet

            // Convert to array with calculated values, but RAW data (no formatting)
            // This ensures 12000 is read as 12000 (number), not "12.000" (string)
            $data = $spreadsheet->getActiveSheet()->toArray(null, true, false, true);

            if (empty($data)) {
                return response()->json(['message' => 'File is empty or invalid'], 422);
            }

            // Get header row
            $headerRow = reset($data);
            $header = [];
            foreach ($headerRow as $i => $h) {
                $key = trim(strtolower(str_replace(' ', '_', $h)));

                // Column aliases
                $columnAliases = [
                    'no' => 'no',
                    'nama' => 'employee_name',
                    'name' => 'employee_name',
                    'employee_name' => 'employee_name',
                    'employee_code' => 'employee_code',
                    'kode_karyawan' => 'employee_code',
                    'periode' => 'period',
                    'period' => 'period',
                    'gaji_pokok' => 'basic_salary',
                    'basic_salary' => 'basic_salary',
                    'lemburan' => 'overtime',
                    'lembur' => 'overtime',
                    'overtime' => 'overtime',
                    'bpjs_kesehatan' => 'bpjs_health',
                    'bpjs_health' => 'bpjs_health',
                    'bpis_tk' => 'bpjs_employment',
                    'bpjs_tk' => 'bpjs_employment',
                    'bpjs_employment' => 'bpjs_employment',
                    'pph21' => 'tax_pph21',
                    'tax_pph21' => 'tax_pph21',
                    'take_home_pay' => 'net_salary',
                    'net_salary' => 'net_salary',
                    'gross_salary' => 'gross_salary',
                    'gaji_kotor' => 'gross_salary',
                    'total_deductions' => 'total_deductions',
                    'total_potongan' => 'total_deductions',
                    'other_deductions' => 'other_deductions',
                    'potongan_lain' => 'other_deductions',
                ];

                $mappedKey = $columnAliases[$key] ?? $key;
                $header[$i] = $mappedKey;
            }

            // Check required columns
            $available = array_values($header);
            $hasEmployeeIdentifier = in_array('employee_code', $available) || in_array('employee_name', $available);

            if (!$hasEmployeeIdentifier || !in_array('period', $available) || !in_array('basic_salary', $available)) {
                return response()->json([
                    'message' => 'Missing required columns. Need: employee identifier (code/name), period, basic_salary',
                    'available_columns' => $available,
                ], 422);
            }

            // Remove header row from data
            array_shift($data);

            $rows = [];
            foreach ($data as $index => $rowData) {
                // Header already removed

                $parsed = [];
                foreach ($rowData as $i => $value) {
                    $key = $header[$i] ?? null;
                    if ($key) {
                        // Convert encoding to UTF-8
                        $parsed[$key] = mb_convert_encoding($value, 'UTF-8', 'auto');
                    }
                }

                if (empty($parsed['employee_code']) && empty($parsed['employee_name'])) {
                    continue;
                }

                $parsed['basic_salary'] = $parsed['basic_salary'] ?? 0;
                $parsed['overtime'] = $parsed['overtime'] ?? 0;
                $parsed['bpjs_health'] = $parsed['bpjs_health'] ?? 0;
                $parsed['bpjs_employment'] = $parsed['bpjs_employment'] ?? 0;
                $parsed['tax_pph21'] = $parsed['tax_pph21'] ?? 0;
                $parsed['net_salary'] = isset($parsed['net_salary']) ? $parsed['net_salary'] : null;
                $parsed['gross_salary'] = isset($parsed['gross_salary']) ? $parsed['gross_salary'] : null;
                $parsed['total_deductions'] = isset($parsed['total_deductions']) ? $parsed['total_deductions'] : null;
                $parsed['other_deductions'] = isset($parsed['other_deductions']) ? $parsed['other_deductions'] : 0;

                $rows[] = $parsed;
            }

            return response()->json([
                'message' => 'File parsed successfully',
                'file_name' => $file->getClientOriginalName(),
                'rows_count' => count($rows),
                'rows' => $rows,
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
            'rows.*.period' => 'required|string',
            'rows.*.basic_salary' => 'required|numeric',
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

                // Parse period (assuming format like "Januari 2026" or "2026-01")
                $period = $row['period'];
                $periodParsed = $this->parsePeriod($period);

                if (!$periodParsed) {
                    $failed[] = [
                        'row' => $index + 1,
                        'employee_name' => $row['employee_name'],
                        'reason' => 'Invalid period format: ' . $period,
                    ];
                    continue;
                }

                // Use values from Excel directly
                // Parse currency here for storage
                $basicSalary = $this->parseCurrency($row['basic_salary']);
                $allowances = 0;
                $overtime = $this->parseCurrency($row['overtime'] ?? 0);
                $bpjsHealth = $this->parseCurrency($row['bpjs_health'] ?? 0);
                $bpjsEmployment = $this->parseCurrency($row['bpjs_employment'] ?? 0);
                $taxPph21 = $this->parseCurrency($row['tax_pph21'] ?? 0);
                $otherDeductions = $this->parseCurrency($row['other_deductions'] ?? 0);

                // Use values from Excel directly - NO CALCULATION AT ALL
                $grossSalary = $this->parseCurrency($row['gross_salary'] ?? 0);
                $totalDeductions = $this->parseCurrency($row['total_deductions'] ?? 0);
                $netSalary = $this->parseCurrency($row['net_salary'] ?? 0);

                // Format period as YYYY-MM
                $periodString = sprintf('%04d-%02d', $periodParsed['year'], $periodParsed['month']);

                // Check if payroll already exists for this employee and period
                $existing = Payroll::where('employee_id', $employee->id)
                    ->where('period', $periodString)
                    ->first();

                if ($existing) {
                    // Update existing
                    $existing->update([
                        'basic_salary' => $basicSalary,
                        'allowances' => $allowances,
                        'overtime_pay' => $overtime,
                        'gross_salary' => $grossSalary,
                        'bpjs_kesehatan' => $bpjsHealth,
                        'bpjs_ketenagakerjaan' => $bpjsEmployment,
                        'pph21' => $taxPph21,
                        'other_deductions' => $otherDeductions,
                        'total_deductions' => $totalDeductions,
                        'net_salary' => $netSalary,
                        'status' => 'draft',
                    ]);
                    $saved[] = [
                        'row' => $index + 1,
                        'employee_name' => $row['employee_name'],
                        'action' => 'updated',
                    ];
                } else {
                    // Create new
                    Payroll::create([
                        'employee_id' => $employee->id,
                        'period' => $periodString,
                        'basic_salary' => $basicSalary,
                        'allowances' => $allowances,
                        'overtime_pay' => $overtime,
                        'gross_salary' => $grossSalary,
                        'bpjs_kesehatan' => $bpjsHealth,
                        'bpjs_ketenagakerjaan' => $bpjsEmployment,
                        'pph21' => $taxPph21,
                        'other_deductions' => $otherDeductions,
                        'total_deductions' => $totalDeductions,
                        'net_salary' => $netSalary,
                        'status' => 'draft',
                    ]);
                    $saved[] = [
                        'row' => $index + 1,
                        'employee_name' => $row['employee_name'],
                        'action' => 'created',
                    ];
                }
            } catch (\Exception $e) {
                $failed[] = [
                    'row' => $index + 1,
                    'employee_name' => $row['employee_name'] ?? 'Unknown',
                    'reason' => $e->getMessage(),
                ];
            }
        }

        return response()->json([
            'message' => 'Import completed',
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
