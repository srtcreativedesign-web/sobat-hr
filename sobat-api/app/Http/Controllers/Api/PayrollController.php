<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Payroll;
use App\Models\Employee;
use Barryvdh\DomPDF\Facade\Pdf;
use PhpOffice\PhpSpreadsheet\IOFactory;
use App\Services\GroqAiService;

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
     * Calculate payroll for employee
     */
    public function calculate(Request $request)
    {
        $validated = $request->validate([
            'employee_id' => 'required|exists:employees,id',
            'period_month' => 'required|integer|min:1|max:12',
            'period_year' => 'required|integer|min:2020',
        ]);

        $employee = Employee::findOrFail($validated['employee_id']);

        // Get attendance data for the period
        $attendances = $employee->attendances()
            ->whereMonth('date', $validated['period_month'])
            ->whereYear('date', $validated['period_year'])
            ->get();

        $totalWorkDays = $attendances->where('status', 'present')->count();
        $totalWorkHours = $attendances->sum('work_hours');
        $totalOvertimeHours = 0; // TODO: Calculate from overtime requests

        // Calculate components
        $baseSalary = $employee->base_salary;
        $allowances = 0; // TODO: Calculate allowances
        $overtimePay = $totalOvertimeHours * ($baseSalary / 173); // Assuming 173 work hours/month
        
        // BPJS calculations (simplified)
        $bpjsHealth = $baseSalary * 0.01; // 1% employee contribution
        $bpjsEmployment = $baseSalary * 0.02; // 2% employee contribution
        
        // PPh21 calculation (simplified - needs proper tax bracket)
        $grossSalary = $baseSalary + $allowances + $overtimePay;
        $taxableIncome = $grossSalary - $bpjsHealth - $bpjsEmployment;
        $taxPph21 = $this->calculatePph21($taxableIncome);

        $deductions = 0; // TODO: Calculate other deductions
        $totalDeductions = $deductions + $bpjsHealth + $bpjsEmployment + $taxPph21;
        
        $netSalary = $grossSalary - $totalDeductions;

        $payroll = Payroll::create([
            'employee_id' => $validated['employee_id'],
            'period_month' => $validated['period_month'],
            'period_year' => $validated['period_year'],
            'base_salary' => $baseSalary,
            'allowances' => $allowances,
            'overtime_pay' => $overtimePay,
            'deductions' => $deductions,
            'bpjs_health' => $bpjsHealth,
            'bpjs_employment' => $bpjsEmployment,
            'tax_pph21' => $taxPph21,
            'net_salary' => $netSalary,
            'status' => 'draft',
        ]);

        return response()->json($payroll);
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
     * Calculate PPh21 tax (simplified)
     */
    private function calculatePph21($taxableIncome)
    {
        // Simplified PPh21 calculation
        // Real implementation should use proper tax brackets
        $yearlyIncome = $taxableIncome * 12;
        $ptkp = 54000000; // PTKP for single person (TK/0)

        if ($yearlyIncome <= $ptkp) {
            return 0;
        }

        $taxable = $yearlyIncome - $ptkp;
        
        // Tax brackets (simplified)
        if ($taxable <= 60000000) {
            $yearlyTax = $taxable * 0.05;
        } elseif ($taxable <= 250000000) {
            $yearlyTax = 3000000 + ($taxable - 60000000) * 0.15;
        } else {
            $yearlyTax = 31500000 + ($taxable - 250000000) * 0.25;
        }

        return $yearlyTax / 12; // Monthly tax
    }

    /**
     * Download template Excel untuk import payroll
     */
    public function downloadTemplate()
    {
        $spreadsheet = new \PhpOffice\PhpSpreadsheet\Spreadsheet();
        $sheet = $spreadsheet->getActiveSheet();

        // Set header
        $headers = ['No', 'Nama', 'Periode', 'Gaji Pokok', 'Lemburan', 'BPJS Kesehatan', 'BPJS TK', 'PPh21', 'Take Home Pay'];
        $sheet->fromArray($headers, null, 'A1');

        // Style header
        $headerStyle = [
            'font' => ['bold' => true, 'color' => ['rgb' => 'FFFFFF']],
            'fill' => ['fillType' => \PhpOffice\PhpSpreadsheet\Style\Fill::FILL_SOLID, 'startColor' => ['rgb' => '1A4D2E']],
            'alignment' => ['horizontal' => \PhpOffice\PhpSpreadsheet\Style\Alignment::HORIZONTAL_CENTER],
        ];
        $sheet->getStyle('A1:I1')->applyFromArray($headerStyle);

        // Add sample data
        $sampleData = [
            [1, 'John Doe', 'Januari 2026', 5000000, 500000, 50000, 100000, 250000, 5100000],
            [2, 'Jane Smith', 'Januari 2026', 6000000, 300000, 60000, 120000, 300000, 5820000],
        ];
        $sheet->fromArray($sampleData, null, 'A2');

        // Add instruction comment
        $sheet->getComment('C2')->getText()->createTextRun('Format periode: "Januari 2026" atau "2026-01"');

        // Auto-size columns
        foreach (range('A', 'I') as $col) {
            $sheet->getColumnDimension($col)->setAutoSize(true);
        }

        // Create writer and download
        $writer = new \PhpOffice\PhpSpreadsheet\Writer\Xlsx($spreadsheet);
        $fileName = 'Template_Import_Payroll_' . date('Y-m-d') . '.xlsx';
        $tempFile = tempnam(sys_get_temp_dir(), 'payroll_template');
        $writer->save($tempFile);

        return response()->download($tempFile, $fileName)->deleteFileAfterSend(true);
    }

    /**
     * Import payroll from Excel
     */
    public function import(Request $request)
    {
        $request->validate([
            'file' => 'required|file|mimes:xlsx,xls|max:10240', // 10MB max
        ]);

        $file = $request->file('file');

        // Use temporary uploaded file path directly (more reliable than store)
        $fullPath = $file->getRealPath();
        
        // Also store for audit purposes
        $storedPath = $file->store('payroll_imports', 'local');

        // Try to parse Excel file using PhpSpreadsheet if available
        $rows = [];
        try {
            if (!class_exists('\\PhpOffice\\PhpSpreadsheet\\IOFactory')) {
                // Fallback: if CSV file, parse using native methods
                $ext = strtolower(pathinfo($fullPath, PATHINFO_EXTENSION));
                if ($ext === 'csv' || $file->getClientMimeType() === 'text/csv') {
                    if (($handle = fopen($fullPath, 'r')) !== false) {
                        $headerRow = fgetcsv($handle);
                        if ($headerRow === false) {
                            return response()->json(['message' => 'CSV file is empty or invalid'], 422);
                        }

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

                        while (($data = fgetcsv($handle)) !== false) {
                            $parsed = [];
                            foreach ($data as $i => $value) {
                                $key = $header[$i] ?? null;
                                if ($key) {
                                    $parsed[$key] = $value;
                                }
                            }

                            if (empty($parsed['employee_code']) && empty($parsed['employee_name'])) {
                                continue;
                            }

                            $parsed['basic_salary'] = isset($parsed['basic_salary']) ? (float) preg_replace('/[^0-9.\\-]/', '', (string)$parsed['basic_salary']) : 0;
                            $parsed['overtime'] = isset($parsed['overtime']) ? (float) preg_replace('/[^0-9.\\-]/', '', (string)$parsed['overtime']) : 0;
                            $parsed['bpjs_health'] = isset($parsed['bpjs_health']) ? (float) preg_replace('/[^0-9.\\-]/', '', (string)$parsed['bpjs_health']) : 0;
                            $parsed['bpjs_employment'] = isset($parsed['bpjs_employment']) ? (float) preg_replace('/[^0-9.\\-]/', '', (string)$parsed['bpjs_employment']) : 0;
                            $parsed['tax_pph21'] = isset($parsed['tax_pph21']) ? (float) preg_replace('/[^0-9.\\-]/', '', (string)$parsed['tax_pph21']) : 0;
                            $parsed['net_salary'] = isset($parsed['net_salary']) ? (float) preg_replace('/[^0-9.\\-]/', '', (string)$parsed['net_salary']) : null;

                            $rows[] = $parsed;
                        }

                        fclose($handle);

                        return response()->json([
                            'message' => 'CSV parsed successfully',
                            'file_name' => $file->getClientOriginalName(),
                            'rows_count' => count($rows),
                            'rows' => $rows,
                        ]);
                    }

                    return response()->json(['message' => 'Unable to open CSV file'], 500);
                }

                return response()->json([
                    'message' => 'PhpSpreadsheet not installed. Install ext-gd or run composer require phpoffice/phpspreadsheet, or upload CSV files as fallback.',
                    'file_name' => $file->getClientOriginalName(),
                    'stored_path' => $storedPath,
                ], 500);
            }

            $spreadsheet = IOFactory::load($fullPath);
            $sheet = $spreadsheet->getActiveSheet();
            $highestRow = $sheet->getHighestDataRow();
            $highestColumn = $sheet->getHighestDataColumn();

            // Expect header row in row 1
            $header = [];
            $headerRow = $sheet->rangeToArray('A1:' . $highestColumn . '1', null, true, false, false);
            $headerRow = $headerRow[0]; // Get first row with 0-based index
            
            // Column aliases for flexible mapping
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
                'salary' => 'basic_salary',
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
                'gaji_bersih' => 'net_salary',
            ];
            
            foreach ($headerRow as $col => $value) {
                $key = trim(strtolower(str_replace(' ', '_', $value)));
                $mappedKey = $columnAliases[$key] ?? $key;
                $header[$col] = $mappedKey;
            }

            // Required minimal columns: employee identifier (name or code), period, basic_salary
            $available = array_values($header);
            $hasEmployeeIdentifier = in_array('employee_code', $available) || in_array('employee_name', $available);
            $hasPeriod = in_array('period', $available);
            $hasSalary = in_array('basic_salary', $available);
            
            if (!$hasEmployeeIdentifier) {
                return response()->json([
                    'message' => 'Missing employee identifier column (employee_code or employee_name/nama)',
                    'available_columns' => $available,
                ], 422);
            }
            
            if (!$hasPeriod) {
                return response()->json([
                    'message' => 'Missing required column: period/periode',
                    'available_columns' => $available,
                ], 422);
            }
            
            if (!$hasSalary) {
                return response()->json([
                    'message' => 'Missing required column: basic_salary/gaji_pokok',
                    'available_columns' => $available,
                ], 422);
            }

            // Parse data rows starting from row 2
            for ($row = 2; $row <= $highestRow; $row++) {
                $rowData = $sheet->rangeToArray('A' . $row . ':' . $highestColumn . $row, null, true, false, false);
                $rowData = $rowData[0]; // Get first row with 0-based index
                
                $parsed = [];
                foreach ($rowData as $col => $value) {
                    $key = $header[$col] ?? null;
                    if ($key) {
                        $parsed[$key] = $value;
                    }
                }

                // Basic normalization
                if ((empty($parsed['employee_code']) && empty($parsed['employee_name'])) || empty($parsed['period'])) {
                    // skip empty rows
                    continue;
                }

                $parsed['basic_salary'] = isset($parsed['basic_salary']) ? (float) preg_replace('/[^0-9.\-]/', '', (string)$parsed['basic_salary']) : 0;
                $parsed['overtime'] = isset($parsed['overtime']) ? (float) preg_replace('/[^0-9.\-]/', '', (string)$parsed['overtime']) : 0;
                $parsed['bpjs_health'] = isset($parsed['bpjs_health']) ? (float) preg_replace('/[^0-9.\-]/', '', (string)$parsed['bpjs_health']) : 0;
                $parsed['bpjs_employment'] = isset($parsed['bpjs_employment']) ? (float) preg_replace('/[^0-9.\-]/', '', (string)$parsed['bpjs_employment']) : 0;
                $parsed['tax_pph21'] = isset($parsed['tax_pph21']) ? (float) preg_replace('/[^0-9.\-]/', '', (string)$parsed['tax_pph21']) : 0;
                $parsed['net_salary'] = isset($parsed['net_salary']) ? (float) preg_replace('/[^0-9.\-]/', '', (string)$parsed['net_salary']) : null;

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

                // Calculate total deductions and gross salary
                $basicSalary = $row['basic_salary'];
                $allowances = 0;
                $overtime = $row['overtime'] ?? 0;
                $bpjsHealth = $row['bpjs_health'] ?? 0;
                $bpjsEmployment = $row['bpjs_employment'] ?? 0;
                $taxPph21 = $row['tax_pph21'] ?? 0;
                $otherDeductions = 0;
                $netSalary = $row['net_salary'] ?? ($basicSalary + $overtime - $bpjsHealth - $bpjsEmployment - $taxPph21);
                
                $totalDeductions = $bpjsHealth + $bpjsEmployment + $taxPph21 + $otherDeductions;
                $grossSalary = $basicSalary + $allowances + $overtime;

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
            return ['year' => (int)$matches[1], 'month' => (int)$matches[2]];
        }

        // Try format: "Januari 2026" or "January 2026"
        $monthNames = [
            'januari' => 1, 'january' => 1, 'jan' => 1,
            'februari' => 2, 'february' => 2, 'feb' => 2,
            'maret' => 3, 'march' => 3, 'mar' => 3,
            'april' => 4, 'apr' => 4,
            'mei' => 5, 'may' => 5,
            'juni' => 6, 'june' => 6, 'jun' => 6,
            'juli' => 7, 'july' => 7, 'jul' => 7,
            'agustus' => 8, 'august' => 8, 'aug' => 8,
            'september' => 9, 'sep' => 9,
            'oktober' => 10, 'october' => 10, 'oct' => 10,
            'november' => 11, 'nov' => 11,
            'desember' => 12, 'december' => 12, 'dec' => 12,
        ];

        $parts = preg_split('/\s+/', strtolower(trim($period)));
        if (count($parts) === 2) {
            $monthName = $parts[0];
            $year = (int)$parts[1];
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
}
