<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;


use App\Models\PayrollRef;
use App\Models\Employee;
use Illuminate\Support\Facades\Log;
use Barryvdh\DomPDF\Facade\Pdf;
use App\Services\GroqAiService;

class PayrollRefController extends Controller
{
    /**
     * Display a listing of Reflexiology payrolls
     */
    public function index(Request $request)
    {
        $user = auth()->user();
        $query = PayrollRef::with('employee');
        
        // SECURITY CHECK: Scope query to authenticated user
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

        // Filter by month and year (if period not explicitly provided)
        if (!$request->has('period') && $request->has('month') && $request->has('year') && $request->month != 0 && $request->year != 0) {
            $period = $request->year . '-' . str_pad($request->month, 2, '0', STR_PAD_LEFT);
            $query->where('period', $period);
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
     * Import Reflexiology payroll from Excel
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
                return response()->json(['message' => 'Format Excel tidak dikenali. Pastikan ada kolom "Nama Karyawan".'], 422);
            }
            
            $dataRows = [];
            $startDataRow = $headerRowIndex + 2; // Skip header and units row
            
            for ($row = $startDataRow; $row <= $highestRow; $row++) {
                // Column B assumed to be Employee Name based on MM analysis
                $employeeName = $getCellValue('B', $row);
                
                if (empty($employeeName) || !is_string($employeeName)) continue;
                
                // MAP COLUMNS FOR REFLEXIOLOGY (Updated for 'payroll reflexy.xlsx')
                // A: No, B: Name, C: Account, D: Days Total
                // E-I: Off, Sick, Permission, Alpha, Leave(Cuti)
                // J: Long Shift, K: Present
                // L: Basic, M-N: Meal, O-P: Transport, Q-R: Attendance, S: Position, T: Health
                // U: Subtotal 1, V-X: Overtime, Y: Bonus, Z: Incentive
                // AA: Gross, AB: Policy HO (Empty?), AC: Absen 1X, AD: Late, AE: No Show, AF: Loan, AG: Admin, AH: BPJS TK
                // AI: Deduction Total, AJ: Net, AK: Years Service, AL: Notes

                $parsed = [
                    'employee_name' => $employeeName,
                    'period' => date('Y-m'), // Default to current
                    'account_number' => $getCellValue('C', $row), // Corrected from D
                    
                    // Attendance
                    'days_total' => (int) $getCellValue('D', $row),
                    'days_off' => (int) $getCellValue('E', $row),
                    'days_sick' => (int) $getCellValue('F', $row),
                    'days_permission' => (int) $getCellValue('G', $row),
                    'days_alpha' => (int) $getCellValue('H', $row),
                    'days_leave' => (int) $getCellValue('I', $row),
                    'days_long_shift' => (int) $getCellValue('J', $row), // New
                    'days_present' => (int) $getCellValue('K', $row),
                    
                    // Salary
                    'basic_salary' => $getCellValue('L', $row),
                    
                    // Allowances
                    'meal_rate' => $getCellValue('M', $row),
                    'meal_amount' => $getCellValue('N', $row),
                    
                    'transport_rate' => $getCellValue('O', $row),
                    'transport_amount' => $getCellValue('P', $row),
                    
                    'attendance_rate' => $getCellValue('Q', $row),
                    'attendance_amount' => $getCellValue('R', $row),
                    
                    'position_allowance' => $getCellValue('S', $row),
                    'health_allowance' => $getCellValue('T', $row),
                    
                    'total_salary_1' => $getCellValue('U', $row),
                    
                    // Overtime
                    'overtime_rate' => $getCellValue('V', $row),
                    'overtime_hours' => $getCellValue('W', $row),
                    'overtime_amount' => $getCellValue('X', $row),
                    
                    // Bonus & Incentives
                    'bonus' => $getCellValue('Y', $row),
                    'incentive' => $getCellValue('Z', $row),
                    // 'holiday_allowance' => $getCellValue('AA', $row), // NO, AA is Gross in this file
                    'holiday_allowance' => 0, // Not in this file?
                    
                    'total_salary_2' => $getCellValue('AA', $row), // Used to be AB
                    'policy_ho' => $getCellValue('AB', $row), // Might be empty
                    
                    // Deductions
                    'deduction_absent' => $getCellValue('AC', $row), // Absen 1X
                    'deduction_late' => $getCellValue('AD', $row), // Terlambat (New)
                    'deduction_alpha' => $getCellValue('AE', $row), // Tidak Hadir -> Alpha
                    'deduction_loan' => $getCellValue('AF', $row), // Pinjaman
                    'deduction_admin_fee' => $getCellValue('AG', $row), // Adm Bank
                    'deduction_bpjs_tk' => $getCellValue('AH', $row), // BPJS TK
                    
                    'deduction_total' => $getCellValue('AI', $row),
                    
                    // Finals
                    // AJ is Net (Grand Total)
                    'net_salary' => $getCellValue('AJ', $row),
                    'grand_total' => $getCellValue('AJ', $row), // Duplicate net to grand total for structure consistency
                    'ewa_amount' => 0, // No EWA column in this file
                    
                    // Extras
                    'years_of_service' => $getCellValue('AK', $row),
                    'notes' => $getCellValue('AL', $row),
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
            Log::error('Ref Payroll Import Error: ' . $e->getMessage());
            return response()->json(['message' => 'Error: ' . $e->getMessage()], 500);
        }
    }
    
    /**
     * Save imported Reflexiology payroll data
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
                $existing = PayrollRef::where('employee_id', $employee->id)
                    ->where('period', $row['period'])
                    ->first();
                
                if ($existing) {
                    $errors[] = "Row " . ($index + 1) . ": Payroll info for '{$row['employee_name']}' already exists";
                    continue;
                }
                
                PayrollRef::create(array_merge($row, [
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
            Log::error('Ref Payroll Save Error: ' . $e->getMessage());
            return response()->json(['message' => 'Error: ' . $e->getMessage()], 500);
        }
    }
    
    public function show($id)
    {
        $payroll = PayrollRef::with('employee')->findOrFail($id);
        
        // Security check
        $user = auth()->user();
        $roleName = $user->role ? strtolower($user->role->name) : '';
        if (!in_array($roleName, ['super_admin', 'admin', 'hr'])) {
             if (!$user->employee || $user->employee->id !== $payroll->employee_id) {
                 return response()->json(['message' => 'Unauthorized'], 403);
             }
        }
        
        return response()->json($this->formatPayroll($payroll));
    }
    
    public function updateStatus(Request $request, $id)
    {
         $request->validate([
            'status' => 'required|in:draft,approved,paid',
            'approval_signature' => 'nullable|string',
        ]);

        $payroll = PayrollRef::findOrFail($id);
        
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
        $payroll = PayrollRef::findOrFail($id);
        $payroll->delete();
        return response()->json(['message' => 'Payroll delete successfully']);
    }
    
    /**
     * Generate PDF Slip
     */
    public function generateSlip($id)
    {
        try {
            $payroll = PayrollRef::with('employee')->findOrFail($id);
            
            // Security check
            $user = auth()->user();
            $roleName = $user->role ? strtolower($user->role->name) : '';
            if (!in_array($roleName, ['super_admin', 'admin', 'hr'])) {
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
            
            // Or create 'payslips.ref' to be safe.
            // Let's create 'payslips.ref' to be safe and specific.
            $pdf = PDF::loadView('payslips.ref', [
                'payroll' => $payroll,
                'aiMessage' => $aiMessage
            ]);
            
            $filename = 'payslip_ref_' . str_replace(' ', '_', $payroll->employee->full_name) . '_' . $payroll->period . '.pdf';
            
            return $pdf->download($filename);
        } catch (\Exception $e) {
            Log::error('Error generating Ref payslip: ' . $e->getMessage());
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
            'Terlambat' => $payroll->deduction_late, // New
            'Tidak Hadir' => $payroll->deduction_alpha,
            'Pinjaman' => $payroll->deduction_loan,
            'Adm Bank' => $payroll->deduction_admin_fee,
            'BPJS TK' => $payroll->deduction_bpjs_tk,
        ];
        
        // Add new extras to array
        $formatted['days_long_shift'] = $payroll->days_long_shift;
        $formatted['years_of_service'] = $payroll->years_of_service;
        $formatted['notes'] = $payroll->notes;

        // Add attendance data for Mobile App (PayrollScreen.dart expects this map)
        $formatted['attendance'] = [
            'Total Hari' => $payroll->days_total,
            'Long Shift' => $payroll->days_long_shift, // Specific to Reflexiology
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
