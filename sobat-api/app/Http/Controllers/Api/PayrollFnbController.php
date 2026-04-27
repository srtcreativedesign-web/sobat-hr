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
    private function isAdmin(): bool
    {
        $user = auth()->user();
        $roleName = $user->role ? strtolower($user->role->name) : '';
        return in_array($roleName, [Role::SUPER_ADMIN, Role::ADMIN, Role::ADMIN_CABANG, Role::HR]);
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
     * Import FnB payroll from Excel
     */
    public function import(Request $request)
    {
        $request->validate([
            'file' => 'required|file|mimes:xlsx,xls',
        ]);

        $file = $request->file('file');

        try {
            // Use PhpSpreadsheet to read calculated values
            $reader = \PhpOffice\PhpSpreadsheet\IOFactory::createReader('Xlsx');
            $reader->setReadDataOnly(true); // Read calculated values, not formulas
            $spreadsheet = $reader->load($file->getRealPath());
            $sheet = $spreadsheet->getActiveSheet();
            
            $highestRow = $sheet->getHighestRow();
            $highestColumn = $sheet->getHighestColumn();
            
            // Helper to get calculated cell value (null-safe)
            $getCellValue = function($col, $row) use ($sheet) {
                if (!$col) return 0;
                try {
                    $cell = $sheet->getCell($col . $row);
                    $value = $cell->getCalculatedValue();
                    
                    if (is_numeric($value)) {
                        return (float) $value;
                    }
                    
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
            
            // Detect header row
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
                return response()->json(['message' => 'Format Excel tidak dikenali. Pastikan ada kolom "Nama Karyawan".'], 422);
            }
            
            // BUILD COLUMN MAPPING dynamically from headers
            $headerPatterns = [
                'nama_karyawan' => ['Nama Karyawan', 'Nama Pegawai'],
                'no_rekening' => ['No Rekening', 'Rekening'],
                'days_total' => [['Jumlah', 'Hari']],
                'days_off' => ['Off'],
                'days_sick' => ['Sakit'],
                'days_permission' => ['Ijin'],
                'days_alpha' => ['Alfa', 'ALFA', 'Alpa'],
                'days_leave' => ['Cuti'],
                'days_present' => ['Ada', 'Hadir'],
                'gaji_pokok' => ['Gaji Pokok', 'Gapok', 'Basic Salary'],
                'kehadiran_rate' => [['Kehadiran', '/ Hari']],
                'kehadiran_jumlah' => [['Kehadiran', 'Jumlah']],
                'transport_rate' => [['Transport', '/ Hari']],
                'transport_jumlah' => [['Transport', 'Jumlah']],
                'kesehatan' => ['Tunj. Kesehatan'],
                'jabatan' => ['Tunj. Jabatan'],
                'total_gaji' => [['Total Gaji', '( Rp )']],
                'lembur_rate' => [['Lembur', '/ Jam']],
                'lembur_jam' => [['Lembur', 'Jam']],
                'lembur_jumlah' => [['Lembur', 'Jumlah']],
                'backup' => ['Backup'],
                'insentif_kehadiran' => ['Insentif Kehadrian', 'Insentif Kehadiran'],
                'insentif_lebaran' => ['Insentif Lebaran'],
                'total_gaji_bonus' => ['Total Gaji & Bonus'],
                'kebijakan_ho' => ['Kebijakan'],
                'absen_count' => ['Absen 1x'],
                'absen' => ['Absen 1X'],
                'terlambat_menit' => ['terlambat (menit)'],
                'terlambat' => ['Terlambat'],
                'selisih' => ['Selisih SO', 'Selisih'],
                'pinjaman' => ['Pinjaman'],
                'adm_bank' => ['Adm Bank', 'Admin Bank'],
                'bpjs_tk' => ['BPJS TK', 'BPJS Ketenagakerjaan'],
                'jumlah_potongan' => [['Potongan', 'Jumlah'], 'Total Potongan'],
                'grand_total' => ['Grand Total'],
                'ewa' => ['EWA', 'Pinjaman ke Stafbook', 'Pinjaman stafbook'],
                'potongan_ewa' => ['Potongan EWA'],
                'payroll' => ['Payroll', 'THP'],
                'adjustment' => ['Adj', 'Penyesuaian'],
            ];
            
            // Build header lookup (supports merged cells)
            $allHeaders = [];
            $allSubs = [];
            $colOrder = [];
            
            $headerRow = $sheet->getRowIterator($headerRowIndex, $headerRowIndex)->current();
            $cellIterator = $headerRow->getCellIterator('A', $highestColumn);
            $cellIterator->setIterateOnlyExistingCells(false);
            
            foreach ($cellIterator as $cell) {
                $col = $cell->getColumn();
                $colOrder[] = $col;
                $allHeaders[$col] = $cell->getValue();
                $allSubs[$col] = $sheet->getCell($col . ($headerRowIndex + 1))->getValue();
            }
            
            $columnMapping = [];
            foreach ($colOrder as $idx => $col) {
                $headerValue = $allHeaders[$col];
                $unitsValue = $allSubs[$col];
                
                // Merged cell support: inherit header from previous column if empty
                $effectiveHeader = $headerValue;
                if (empty($effectiveHeader) && $idx > 0) {
                    $prevCol = $colOrder[$idx - 1];
                    $effectiveHeader = $allHeaders[$prevCol];
                }
                
                foreach ($headerPatterns as $key => $patterns) {
                    if (isset($columnMapping[$key])) continue;
                    
                    $alternativePatterns = is_array($patterns) ? $patterns : [$patterns];
                    
                    foreach ($alternativePatterns as $pattern) {
                        if (is_array($pattern)) {
                            // Multi-row header check (merged cell aware)
                            $headerMatch = $effectiveHeader && stripos($effectiveHeader, $pattern[0]) !== false;
                            $unitsMatch = $unitsValue && stripos($unitsValue, $pattern[1]) !== false;
                            
                            if ($headerMatch && $unitsMatch) {
                                $columnMapping[$key] = $col;
                                break;
                            }
                        } else {
                            // Single check: header OR sub-header
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
            
            Log::info('FnB Column Mapping Detected', $columnMapping);
            
            // Detect outlet name from first cell
            $firstCell = $sheet->getCell('A1')->getValue();
            $outletName = 'FnB';
            if ($firstCell && stripos($firstCell, 'Tung Tau') !== false) {
                $outletName = 'Tung Tau';
            } elseif ($firstCell && stripos($firstCell, 'GD 600') !== false) {
                $outletName = 'GD 600';
            }
            
            $dataRows = [];
            $startDataRow = $headerRowIndex + 2; // Skip header and units row
            
            for ($row = $startDataRow; $row <= $highestRow; $row++) {
                $employeeName = $getCellValue($columnMapping['nama_karyawan'] ?? null, $row);
                
                // Skip if no employee name
                if (empty($employeeName) || !is_string($employeeName)) continue;
                
                // Read all values dynamically
                $daysTotal = (int) $getCellValue($columnMapping['days_total'] ?? null, $row);
                $daysOff = (int) $getCellValue($columnMapping['days_off'] ?? null, $row);
                $daysSick = (int) $getCellValue($columnMapping['days_sick'] ?? null, $row);
                $daysPermission = (int) $getCellValue($columnMapping['days_permission'] ?? null, $row);
                $daysAlpha = (int) $getCellValue($columnMapping['days_alpha'] ?? null, $row);
                $daysLeave = (int) $getCellValue($columnMapping['days_leave'] ?? null, $row);
                $daysPresent = (int) $getCellValue($columnMapping['days_present'] ?? null, $row);
                
                // If days_present not detected, calculate it
                if ($daysPresent <= 0 && $daysTotal > 0) {
                    $daysPresent = $daysTotal - $daysOff - $daysSick - $daysPermission - $daysAlpha - $daysLeave;
                    if ($daysPresent < 0) $daysPresent = 0;
                }
                
                $basicSalary = $getCellValue($columnMapping['gaji_pokok'] ?? null, $row);
                
                $attendanceRate = $getCellValue($columnMapping['kehadiran_rate'] ?? null, $row);
                $attendanceAmount = $getCellValue($columnMapping['kehadiran_jumlah'] ?? null, $row);
                $transportRate = $getCellValue($columnMapping['transport_rate'] ?? null, $row);
                $transportAmount = $getCellValue($columnMapping['transport_jumlah'] ?? null, $row);
                $healthAllowance = $getCellValue($columnMapping['kesehatan'] ?? null, $row);
                $positionAllowance = $getCellValue($columnMapping['jabatan'] ?? null, $row);
                
                $totalSalary1 = $getCellValue($columnMapping['total_gaji'] ?? null, $row);
                
                $overtimeRate = $getCellValue($columnMapping['lembur_rate'] ?? null, $row);
                $overtimeHours = $getCellValue($columnMapping['lembur_jam'] ?? null, $row);
                $overtimeAmount = $getCellValue($columnMapping['lembur_jumlah'] ?? null, $row);
                
                $backup = $getCellValue($columnMapping['backup'] ?? null, $row);
                $insentifKehadiran = $getCellValue($columnMapping['insentif_kehadiran'] ?? null, $row);
                $holidayAllowance = $getCellValue($columnMapping['insentif_lebaran'] ?? null, $row);
                $adjustment = $getCellValue($columnMapping['adjustment'] ?? null, $row);
                
                $totalSalary2 = $getCellValue($columnMapping['total_gaji_bonus'] ?? null, $row);
                $policyHo = $getCellValue($columnMapping['kebijakan_ho'] ?? null, $row);
                
                $deductionAbsent = $getCellValue($columnMapping['absen'] ?? null, $row);
                $deductionLate = $getCellValue($columnMapping['terlambat'] ?? null, $row);
                $deductionShortage = $getCellValue($columnMapping['selisih'] ?? null, $row);
                $deductionLoan = $getCellValue($columnMapping['pinjaman'] ?? null, $row);
                $deductionAdminFee = $getCellValue($columnMapping['adm_bank'] ?? null, $row);
                $deductionBpjsTk = $getCellValue($columnMapping['bpjs_tk'] ?? null, $row);
                
                $totalDeductions = $getCellValue($columnMapping['jumlah_potongan'] ?? null, $row);
                
                // Fallback: calculate total deductions from individual items if not detected
                if ($totalDeductions <= 0) {
                    $totalDeductions = abs($deductionAbsent) + abs($deductionLate) + abs($deductionShortage) + abs($deductionLoan) + abs($deductionAdminFee) + abs($deductionBpjsTk);
                }
                $grandTotal = $getCellValue($columnMapping['grand_total'] ?? null, $row);
                $ewa = $getCellValue($columnMapping['ewa'] ?? null, $row);
                $netSalary = $getCellValue($columnMapping['payroll'] ?? null, $row);
                
                // Fallback: if net_salary is 0 but grand_total exists
                if ($netSalary <= 0 && $grandTotal > 0) {
                    $netSalary = $grandTotal;
                }
                
                // Use best available gross salary
                if ($totalSalary2 > 0) {
                    $grossSalary = $totalSalary2;
                } elseif ($totalSalary1 > 0) {
                    $grossSalary = $totalSalary1;
                } else {
                    $grossSalary = $basicSalary + $attendanceAmount + $transportAmount + $healthAllowance + $positionAllowance + $overtimeAmount + $holidayAllowance + $adjustment + $backup + $insentifKehadiran;
                }
                
                $parsed = [
                    'employee_name' => $employeeName,
                    'period' => $request->period ?? date('Y-m'),
                    'account_number' => $getCellValue($columnMapping['no_rekening'] ?? null, $row),
                    'outlet_name' => $outletName,
                    
                    // Attendance
                    'days_total' => $daysTotal,
                    'days_off' => $daysOff,
                    'days_sick' => $daysSick,
                    'days_permission' => $daysPermission,
                    'days_alpha' => $daysAlpha,
                    'days_leave' => $daysLeave,
                    'days_present' => $daysPresent,
                    
                    // Salary
                    'basic_salary' => $basicSalary,
                    'attendance_rate' => $attendanceRate,
                    'attendance_amount' => $attendanceAmount,
                    'transport_rate' => $transportRate,
                    'transport_amount' => $transportAmount,
                    'health_allowance' => $healthAllowance,
                    'position_allowance' => $positionAllowance,
                    'total_salary_1' => $totalSalary1,
                    
                    // Overtime
                    'overtime_rate' => $overtimeRate,
                    'overtime_hours' => $overtimeHours,
                    'overtime_amount' => $overtimeAmount,
                    
                    // Other Income
                    'backup' => $backup,
                    'insentif_kehadiran' => $insentifKehadiran,
                    'holiday_allowance' => $holidayAllowance,
                    'adjustment' => $adjustment,
                    'total_salary_2' => $grossSalary, // Frontend uses total_salary_2 as gross_salary
                    'policy_ho' => $policyHo,
                    
                    // Deductions
                    'deduction_absent' => $deductionAbsent,
                    'deduction_late' => $deductionLate,
                    'deduction_shortage' => $deductionShortage,
                    'deduction_loan' => $deductionLoan,
                    'deduction_admin_fee' => $deductionAdminFee,
                    'deduction_bpjs_tk' => $deductionBpjsTk,
                    'total_deductions' => $totalDeductions,
                    
                    // Finals
                    'grand_total' => $grandTotal,
                    'ewa_amount' => $ewa,
                    'net_salary' => $netSalary,
                ];
                
                $dataRows[] = $parsed;
            }

            return response()->json([
                'message' => 'File parsed successfully',
                'file_name' => $file->getClientOriginalName(),
                'rows_count' => count($dataRows),
                'rows' => $dataRows,
            ]);

        } catch (\Exception $e) {
            Log::error('FnB Payroll Import Error: ' . $e->getMessage());
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
                
                if ($existing) {
                    $errors[] = "Row " . ($index + 1) . ": Payroll for '{$row['employee_name']}' in period {$row['period']} already exists";
                    continue;
                }
                
                // Debug log the data being saved
                Log::info('FnB Payroll Save Data', [
                    'employee_id' => $employee->id,
                    'employee_name' => $row['employee_name'],
                    'data_keys' => array_keys($row),
                ]);
                
                // Create payroll
                PayrollFnb::create(array_merge($row, [
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
            'approval_signature' => 'nullable|string', // Base64 string
        ]);

        $payroll = PayrollFnb::findOrFail($id);
        
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
