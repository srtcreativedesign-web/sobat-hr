<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\PayrollCelluller;
use App\Models\Employee;
use Illuminate\Support\Facades\Log;
use Barryvdh\DomPDF\Facade\Pdf;
use App\Services\GroqAiService;

class PayrollCellullerController extends Controller
{
    /**
     * Display a listing of Celluller payrolls
     */
    public function index(Request $request)
    {
        $user = auth()->user();
        $query = PayrollCelluller::with('employee');
        
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
     * Import Celluller payroll from Excel
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
            
            // Detect header row (Look for "Nama" or "Nama Karyawan")
            $headerRowIndex = -1;
            for ($row = 1; $row <= min(10, $highestRow); $row++) {
                $cellValue = $sheet->getCell('B' . $row)->getValue(); // Check Column B based on Excel file analysis
                if ($cellValue && (stripos($cellValue, 'Nama') !== false)) {
                     $headerRowIndex = $row;
                     break;
                }
            }
            
            if ($headerRowIndex === -1) {
                // Fallback: Check standard Row 1
                $headerRowIndex = 1;
            }
            
            $dataRows = [];
            $startDataRow = $headerRowIndex + 1; // Row after header
            
            // Based on 'payslip cell.xlsx': header is row 1, data starts row 2 (or header row 1 & 2, data 3?)
            // The read_headers.php showed Row 1 has headers like "No", "Nama", etc.
            // Let's assume data starts at row 2 if header detected at 1. Correct logic based on file:
            // "Row 1: [A]No | [B]Nama ..."
            
            for ($row = $startDataRow; $row <= $highestRow; $row++) {
                $employeeName = $getCellValue('B', $row);
                
                if (empty($employeeName) || !is_string($employeeName)) continue;
                
                // MAPPING BASED ON 'payslip cell.xlsx' (refer to payslip_celluller_format.md)
                $parsed = [
                    'employee_name' => $employeeName,
                    'period' => $request->period ?? date('Y-m'), // Use period from request if provided
                    'account_number' => $getCellValue('C', $row),
                    
                    // Attendance
                    'days_total' => (int) $getCellValue('D', $row),
                    'days_off' => (int) $getCellValue('E', $row),
                    'days_sick' => (int) $getCellValue('F', $row),
                    'days_permission' => (int) $getCellValue('G', $row),
                    'days_alpha' => (int) $getCellValue('H', $row),
                    'days_leave' => (int) $getCellValue('I', $row),
                    'days_present' => (int) $getCellValue('J', $row),
                    
                    // Income
                    'basic_salary' => $getCellValue('K', $row),
                    'position_allowance' => $getCellValue('L', $row),
                    
                    'meal_rate' => $getCellValue('M', $row),
                    'meal_amount' => $getCellValue('N', $row),
                    
                    'transport_rate' => $getCellValue('O', $row),
                    'transport_amount' => $getCellValue('P', $row),
                    
                    'mandatory_overtime_rate' => $getCellValue('Q', $row),
                    'mandatory_overtime_amount' => $getCellValue('R', $row),
                    
                    'attendance_allowance' => $getCellValue('S', $row),
                    'health_allowance' => $getCellValue('T', $row),
                    
                    'subtotal_1' => $getCellValue('U', $row), // Total Gaji
                    
                    // Overtime
                    'overtime_rate' => $getCellValue('V', $row),
                    'overtime_hours' => $getCellValue('W', $row),
                    'overtime_amount' => $getCellValue('X', $row),
                    
                    // Bonus & Incentives
                    'bonus' => $getCellValue('Y', $row),
                    'holiday_allowance' => $getCellValue('Z', $row), // Insentif Lebaran
                    'adjustment' => $getCellValue('AA', $row),
                    
                    'gross_salary' => $getCellValue('AB', $row), // Total Gaji & Bonus
                    'policy_ho' => $getCellValue('AC', $row),
                    
                    // Deductions
                    'deduction_absent' => $getCellValue('AD', $row),
                    'deduction_late' => $getCellValue('AE', $row),
                    'deduction_so_shortage' => $getCellValue('AF', $row), // Selisih SO
                    'deduction_loan' => $getCellValue('AG', $row),
                    'deduction_admin_fee' => $getCellValue('AH', $row),
                    'deduction_bpjs_tk' => $getCellValue('AI', $row),
                    
                    'total_deduction' => $getCellValue('AJ', $row),
                    
                    // Finals
                    'net_salary' => $getCellValue('AK', $row), // Grand Total
                    'ewa_amount' => $getCellValue('AL', $row),
                    'final_payment' => $getCellValue('AM', $row), // PAYROLL
                    
                    // Extras (No specific columns mapped in Excel for these, keeping nullable)
                    'years_of_service' => null, 
                    'notes' => null,
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
            Log::error('Celluller Payroll Import Error: ' . $e->getMessage());
            return response()->json(['message' => 'Error: ' . $e->getMessage()], 500);
        }
    }
    
    /**
     * Save imported Celluller payroll data
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
                $existing = PayrollCelluller::where('employee_id', $employee->id)
                    ->where('period', $row['period'])
                    ->first();
                
                if ($existing) {
                    $errors[] = "Row " . ($index + 1) . ": Payroll info for '{$row['employee_name']}' already exists";
                    continue;
                }
                
                // Remove employee_name from row data as it's not in the table
                $data = $row;
                unset($data['employee_name']);

                PayrollCelluller::create(array_merge($data, [
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
            Log::error('Celluller Payroll Save Error: ' . $e->getMessage());
            return response()->json(['message' => 'Error: ' . $e->getMessage()], 500);
        }
    }
    
    public function show($id)
    {
        $payroll = PayrollCelluller::with('employee')->findOrFail($id);
        
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

        $payroll = PayrollCelluller::findOrFail($id);
        
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
        $payroll = PayrollCelluller::findOrFail($id);
        $payroll->delete();
        return response()->json(['message' => 'Payroll delete successfully']);
    }
    
    /**
     * Generate PDF Slip
     */
    public function generateSlip($id)
    {
        try {
            $payroll = PayrollCelluller::with('employee')->findOrFail($id);
            
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
                    'net_salary' => $payroll->final_payment, // Use Final Payment for AI message context
                    'join_date' => $payroll->employee->join_date,
                ]);
            } catch (\Exception $e) {
                // Ignore AI error
            }
            
            // Pass simple object to view, view can format
            $pdf = PDF::loadView('payslips.celluller', [
                'payroll' => $payroll,
                'aiMessage' => $aiMessage
            ]);
            
            $filename = 'payslip_celluller_' . str_replace(' ', '_', $payroll->employee->full_name) . '_' . $payroll->period . '.pdf';
            
            return $pdf->download($filename);
        } catch (\Exception $e) {
            Log::error('Error generating Celluller payslip: ' . $e->getMessage());
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
             'Lembur Wajib' => [
                 'rate' => $payroll->mandatory_overtime_rate,
                 'amount' => $payroll->mandatory_overtime_amount,
             ],
             'Tunjangan Kehadiran' => $payroll->attendance_allowance,
             'Tunjangan Kesehatan' => $payroll->health_allowance,
             'Tunjangan Jabatan' => $payroll->position_allowance,
             'Lembur Tambahan' => [
                 'rate' => $payroll->overtime_rate,
                 'hours' => $payroll->overtime_hours,
                 'amount' => $payroll->overtime_amount,
             ],
             'Bonus' => $payroll->bonus,
             'Insentif Lebaran' => $payroll->holiday_allowance,
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
        
        // Add attendance data for Mobile App
        $formatted['attendance'] = [
            'Total Hari' => $payroll->days_total,
            'Off' => $payroll->days_off,
            'Sakit' => $payroll->days_sick,
            'Ijin' => $payroll->days_permission,
            'Alfa' => $payroll->days_alpha,
            'Cuti' => $payroll->days_leave,
            'Hadir' => $payroll->days_present,
        ];
        
        // Explicitly set net_salary to final_payment for frontend consistency if needed, 
        // or keep as distinct in mapped object
        $formatted['net_salary_display'] = $payroll->final_payment; 
        
        return $formatted;
    }
}
