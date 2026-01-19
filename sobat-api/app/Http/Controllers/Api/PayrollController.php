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
            
            // Non-admin users can ONLY see approved or paid payrolls
            $query->whereIn('status', ['approved', 'paid']);
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
                    'period' => $payroll->period, // Add strict period string (YYYY-MM)
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
            'file' => 'required|file|mimes:xlsx,xls,csv',
        ]);

        $file = $request->file('file');
        $storedPath = $file->storeAs('imports', $file->getClientOriginalName());

        try {
            // Use PhpSpreadsheet directly to read calculated values
            $reader = \PhpOffice\PhpSpreadsheet\IOFactory::createReader('Xlsx');
            $reader->setReadDataOnly(true); // READ CALCULATED VALUES, NOT FORMULAS
            $spreadsheet = $reader->load($file->getRealPath());
            $sheet = $spreadsheet->getActiveSheet();
            
            $highestRow = $sheet->getHighestRow();
            $highestColumn = $sheet->getHighestColumn();
            
            // Helper function to get calculated value from cell
            $getCellValue = function($col, $row) use ($sheet) {
                $cell = $sheet->getCell($col . $row);
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
            };
            
            // Detect header row (look for "Nama Karyawan")
            $headerRowIndex = -1;
            for ($row = 1; $row <= min(10, $highestRow); $row++) {
                // Use cell iterator instead of range() to support columns beyond Z
                $rowIterator = $sheet->getRowIterator($row, $row)->current();
                $cellIterator = $rowIterator->getCellIterator('A', $highestColumn);
                $cellIterator->setIterateOnlyExistingCells(false);
                
                foreach ($cellIterator as $cell) {
                    $cellValue = $cell->getValue();
                    
                    if ($cellValue && stripos($cellValue, 'Nama Karyawan') !== false) {
                        $headerRowIndex = $row;
                        \Illuminate\Support\Facades\Log::info("Header found at row $row, col " . $cell->getColumn());
                        break 2;
                    }
                }
            }
            
            if ($headerRowIndex === -1) {
                \Illuminate\Support\Facades\Log::error('Header detection failed', [
                    'highest_row' => $highestRow,
                    'highest_column' => $highestColumn,
                ]);
                return response()->json(['message' => 'Format tidak dikenali. Pastikan ada kolom "Nama Karyawan".'], 422);
            }
            
            // BUILD COLUMN MAPPING based on header names
            $columnMapping = [];
            $headerPatterns = [
                'periode' => 'Periode',
                'nama_karyawan' => 'Nama Karyawan',
                'no_rekening' => 'No Rekening',
                'gaji_pokok' => 'Gaji Pokok',
                'kehadiran_jumlah' => ['Kehadiran', 'Jumlah'], // Multi-row header
                'transport_jumlah' => ['Transport', 'Jumlah'],
                'kesehatan_jumlah' => ['Kesehatan', 'Jumlah'],
                'tunj_jabatan' => 'Tunj. Jabatan',
                'total_gaji' => 'Total Gaji',
                'lembur_jam' => ['Lembur', 'Jam'],
                'lembur_jumlah' => ['Lembur', 'Jumlah'],
                'insentif' => 'Insentif',
                'adjustment' => 'Adj',
                'absen' => 'Absen',
                'terlambat' => 'Terlambat',
                'selisih' => 'Selisih',
                'pinjaman' => 'Pinjaman',
                'adm_bank' => 'Adm Bank',
                'bpjs_tk' => 'BPJS TK',
                'jumlah_potongan' => ['Potongan', 'Jumlah'],
                'grand_total' => 'Grand Total',
                'ewa' => 'EWA',
                'payroll' => 'Payroll',
            ];
            
            // Use cell iterator to support columns beyond Z (AA, AB, etc.)
            $headerRow = $sheet->getRowIterator($headerRowIndex, $headerRowIndex)->current();
            $cellIterator = $headerRow->getCellIterator('A', $highestColumn);
            $cellIterator->setIterateOnlyExistingCells(false);
            
            foreach ($cellIterator as $cell) {
                $col = $cell->getColumn();
                $headerValue = $cell->getValue();
                $unitsValue = $sheet->getCell($col . ($headerRowIndex + 1))->getValue();
                
                foreach ($headerPatterns as $key => $pattern) {
                    if (is_array($pattern)) {
                        // Multi-row header check (e.g., "Kehadiran" in row 2, "Jumlah" in row 3)
                        $headerMatch = $headerValue && stripos($headerValue, $pattern[0]) !== false;
                        $unitsMatch = $unitsValue && stripos($unitsValue, $pattern[1]) !== false;
                        
                        if ($headerMatch && $unitsMatch) {
                            $columnMapping[$key] = $col;
                        }
                    } else {
                        // Single header check
                        if ($headerValue && stripos($headerValue, $pattern) !== false) {
                            $columnMapping[$key] = $col;
                        }
                    }
                }
            }
            
            \Illuminate\Support\Facades\Log::info('Column Mapping Detected', $columnMapping);
            
            $dataRows = [];
            // Data starts after header row (usually header is row 2, units row 3, data starts row 4)
            $startDataRow = $headerRowIndex + 2;
            
            for ($row = $startDataRow; $row <= $highestRow; $row++) {
                // Get employee name
                $namaCol = $columnMapping['nama_karyawan'] ?? 'B';
                $employeeName = $getCellValue($namaCol, $row);
                
                // Skip if no employee name
                if (empty($employeeName) || !is_string($employeeName)) continue;
                
                // Read values using mapped columns
                $periode = $getCellValue($columnMapping['periode'] ?? 'A', $row);
                $accountNumber = $getCellValue($columnMapping['no_rekening'] ?? 'C', $row);
                
                // Basic Salary
                $basicSalary = $getCellValue($columnMapping['gaji_pokok'] ?? 'K', $row);
                
                // Allowances - use "Jumlah" columns
                $kehadiranAllowance = $getCellValue($columnMapping['kehadiran_jumlah'] ?? 'M', $row);
                $transportAllowance = $getCellValue($columnMapping['transport_jumlah'] ?? 'O', $row);
                $healthAllowance = $getCellValue($columnMapping['kesehatan_jumlah'] ?? 'Q', $row);
                $positionAllowance = $getCellValue($columnMapping['tunj_jabatan'] ?? 'R', $row);
                
                // Overtime
                $overtimeHours = $getCellValue($columnMapping['lembur_jam'] ?? 'U', $row);
                $overtimePay = $getCellValue($columnMapping['lembur_jumlah'] ?? 'V', $row);
                
                // Other Income
                $holidayAllowance = $getCellValue($columnMapping['insentif'] ?? 'W', $row);
                $adjustment = $getCellValue($columnMapping['adjustment'] ?? 'X', $row);
                
                // Totals (FORMULAS or calculated)
                $totalGaji = $getCellValue($columnMapping['total_gaji'] ?? 'Y', $row);
                
                // Deductions Breakdown
                $absen = $getCellValue($columnMapping['absen'] ?? 'AA', $row);
                $terlambat = $getCellValue($columnMapping['terlambat'] ?? 'AB', $row);
                $selisihSO = $getCellValue($columnMapping['selisih'] ?? 'AC', $row);
                $pinjaman = $getCellValue($columnMapping['pinjaman'] ?? 'AD', $row);
                $admBank = $getCellValue($columnMapping['adm_bank'] ?? 'AE', $row);
                $bpjsTK = $getCellValue($columnMapping['bpjs_tk'] ?? 'AF', $row);
                
                // Total Deductions (FORMULA)
                $totalDeductions = $getCellValue($columnMapping['jumlah_potongan'] ?? 'AG', $row);
                
                // Grand Total and Final Net Salary (FORMULAS)
                $grandTotal = $getCellValue($columnMapping['grand_total'] ?? 'AH', $row);
                $ewa = $getCellValue($columnMapping['ewa'] ?? 'AI', $row);
                $netSalary = $getCellValue($columnMapping['payroll'] ?? 'AJ', $row);
                
                // Calculate total allowances for storage
                $allowancesTotal = $kehadiranAllowance + $transportAllowance + $healthAllowance + $positionAllowance;
                
                // Use Total Gaji from Excel if available, otherwise calculate
                if ($totalGaji > 0) {
                    $grossSalary = $totalGaji;
                } else {
                    // Fallback: calculate from components
                    $grossSalary = $basicSalary + $allowancesTotal + $overtimePay + $holidayAllowance + $adjustment;
                }
                
                // If net salary is 0, try to calculate it
                if ($netSalary == 0 && $grandTotal > 0) {
                    $netSalary = $grandTotal - $ewa;
                }
                
                // Details for JSON storage
                $details = [
                    'account_number' => $accountNumber,
                    'transport_allowance' => $transportAllowance,
                    'health_allowance' => $healthAllowance,
                    'position_allowance' => $positionAllowance,
                    'holiday_allowance' => $holidayAllowance,
                    'attendance_allowance' => $kehadiranAllowance,
                    'adjustment' => $adjustment,
                    'overtime_hours' => $overtimeHours,
                    'deductions' => [
                        'absent' => $absen,
                        'late' => $terlambat,
                        'shortage' => $selisihSO,
                        'loan' => $pinjaman,
                        'bank_fee' => $admBank,
                        'bpjs_tk' => $bpjsTK,
                    ],
                    'ewa' => $ewa,
                    'grand_total' => $grandTotal,
                ];
                
                $parsed = [
                    'employee_name' => $employeeName,
                    'period' => date('Y-m'),
                    'basic_salary' => $basicSalary,
                    'allowances' => $allowancesTotal,
                    'overtime' => $overtimePay,
                    'total_deductions' => $totalDeductions,
                    'net_salary' => $netSalary,
                    'gross_salary' => $grossSalary,
                    'details' => $details,
                ];
                
                // Debug logging
                \Illuminate\Support\Facades\Log::info("Excel Import Row $row", [
                    'employee' => $employeeName,
                    'basic_salary' => $basicSalary,
                    'allowances_total' => $allowancesTotal,
                    'gross_salary' => $grossSalary,
                    'total_deductions' => $totalDeductions,
                    'grand_total' => $grandTotal,
                    'ewa' => $ewa,
                    'net_salary' => $netSalary,
                ]);
                
                $dataRows[] = $parsed;
            }

            return response()->json([
                'message' => 'File parsed successfully',
                'file_name' => $file->getClientOriginalName(),
                'rows_count' => count($dataRows),
                'rows' => $dataRows,
            ]);

        } catch (\Exception $e) {
            return response()->json(['message' => 'Error: ' . $e->getMessage()], 500);
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
                $deductions = $details['deductions'] ?? [];
                
                $bpjsTK = (float) ($deductions['bpjs_tk'] ?? 0);
                $absen = (float) ($deductions['absent'] ?? 0);
                $terlambat = (float) ($deductions['late'] ?? 0);
                $selisih = (float) ($deductions['shortage'] ?? 0);
                $pinjaman = (float) ($deductions['loan'] ?? 0);
                $admBank = (float) ($deductions['bank_fee'] ?? 0);
                
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
     * Approve ALL draft payrolls for a specific period
     */
    public function approveAll(Request $request)
    {
        $request->validate([
            'month' => 'required|integer|min:1|max:12',
            'year' => 'required|integer|min:2020',
        ]);

        $periodString = sprintf('%04d-%02d', $request->year, $request->month);

        $updated = Payroll::where('period', $periodString)
            ->where('status', 'draft')
            ->update(['status' => 'approved']);

        return response()->json([
            'message' => "Successfully approved {$updated} payrolls for period {$periodString}",
            'count' => $updated,
        ]);
    }

    /**
     * Approve SELECTED draft payrolls
     */
    public function bulkApprove(Request $request)
    {
        $request->validate([
            'ids' => 'required|array',
            'ids.*' => 'integer|exists:payrolls,id',
        ]);

        $ids = $request->input('ids');

        $updated = Payroll::whereIn('id', $ids)
            ->where('status', 'draft')
            ->update(['status' => 'approved']);

        return response()->json([
            'message' => "Successfully approved {$updated} selected payrolls",
            'count' => $updated,
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
