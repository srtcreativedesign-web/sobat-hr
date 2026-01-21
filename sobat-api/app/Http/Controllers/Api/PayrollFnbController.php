<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\PayrollFnb;
use App\Models\Employee;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use PDF;

class PayrollFnbController extends Controller
{
    /**
     * Display a listing of FnB payrolls
     */
    public function index(Request $request)
    {
        $user = auth()->user();
        $query = PayrollFnb::with('employee');

        // Check scope
        $roleName = $user->role ? strtolower($user->role->name) : '';
        if (!in_array($roleName, ['admin', 'super_admin', 'hr'])) {
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
        
        // Filter by status (allow overriding if user is checking 'draft' etc, but mostly for admins)
        if ($request->has('status')) {
            $query->where('status', $request->status);
        }
        
        $payrolls = $query->orderBy('period', 'desc')
            ->orderBy('created_at', 'desc')
            ->paginate(50);
        
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
            
            // Helper to get calculated cell value
            $getCellValue = function($col, $row) use ($sheet) {
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
            
            $dataRows = [];
            $startDataRow = $headerRowIndex + 2; // Skip header and units row
            
            for ($row = $startDataRow; $row <= $highestRow; $row++) {
                $employeeName = $getCellValue('B', $row);
                
                // Skip if no employee name
                if (empty($employeeName) || !is_string($employeeName)) continue;
                
                // Map all columns based on FnB Excel structure (from analysis)
                $parsed = [
                    'employee_name' => $employeeName,
                    'period' => date('Y-m'), // Current period
                    'account_number' => $getCellValue('C', $row),
                    
                    // Attendance (D-J)
                    'days_total' => (int) $getCellValue('D', $row),
                    'days_off' => (int) $getCellValue('E', $row),
                    'days_sick' => (int) $getCellValue('F', $row),
                    'days_permission' => (int) $getCellValue('G', $row),
                    'days_alpha' => (int) $getCellValue('H', $row),
                    'days_leave' => (int) $getCellValue('I', $row),
                    'days_present' => (int) $getCellValue('J', $row),
                    
                    // Basic Salary (K)
                    'basic_salary' => $getCellValue('K', $row),
                    
                    // Allowances (L-Q)
                    'attendance_rate' => $getCellValue('L', $row),
                    'attendance_amount' => $getCellValue('M', $row),
                    'transport_rate' => $getCellValue('N', $row),
                    'transport_amount' => $getCellValue('O', $row),
                    'health_allowance' => $getCellValue('P', $row),
                    'position_allowance' => $getCellValue('Q', $row),
                    
                    // Total Salary 1 (R)
                    'total_salary_1' => $getCellValue('R', $row),
                    
                    // Overtime (S-U)
                    'overtime_rate' => $getCellValue('S', $row),
                    'overtime_hours' => $getCellValue('T', $row),
                    'overtime_amount' => $getCellValue('U', $row),
                    
                    // Other Income (V-W)
                    'holiday_allowance' => $getCellValue('V', $row),
                    'adjustment' => $getCellValue('W', $row),
                    
                    // Total Salary 2 (X)
                    'total_salary_2' => $getCellValue('X', $row),
                    
                    // Policy (Y)
                    'policy_ho' => $getCellValue('Y', $row),
                    
                    // Deductions (Z-AE)
                    'deduction_absent' => $getCellValue('Z', $row),
                    'deduction_late' => $getCellValue('AA', $row),
                    'deduction_shortage' => $getCellValue('AB', $row),
                    'deduction_loan' => $getCellValue('AC', $row),
                    'deduction_admin_fee' => $getCellValue('AD', $row),
                    'deduction_bpjs_tk' => $getCellValue('AE', $row),
                    
                    // Total Deductions (AF)
                    'total_deductions' => $getCellValue('AF', $row),
                    
                    // Final Calculations (AG-AI)
                    'grand_total' => $getCellValue('AG', $row),
                    'ewa_amount' => $getCellValue('AH', $row),
                    'net_salary' => $getCellValue('AI', $row),
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
                \Illuminate\Support\Facades\Log::info('FnB Payroll Save Data', [
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

            $pdf = PDF::loadView('payslips.fnb', ['payroll' => $payroll]);
            
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
