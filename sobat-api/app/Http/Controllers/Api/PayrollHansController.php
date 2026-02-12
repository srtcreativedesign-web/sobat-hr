<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;


use App\Models\PayrollHans;
use App\Models\Employee;
use Illuminate\Support\Facades\Log;
use Barryvdh\DomPDF\Facade\Pdf;
use App\Services\GroqAiService;

class PayrollHansController extends Controller
{
    /**
     * Display a listing of Hans payrolls
     */
    public function index(Request $request)
    {
        $user = auth()->user();
        $query = PayrollHans::with('employee');
        
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
     * Import Hans payroll from Excel
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
                $employeeName = $getCellValue('B', $row);
                
                if (empty($employeeName) || !is_string($employeeName)) continue;
                
                $parsed = [
                    'employee_name' => $employeeName,
                    'period' => $request->period ?? date('Y-m'), // Use period from request if provided
                    'account_number' => $getCellValue('D', $row),
                    
                    // Attendance
                    'days_total' => (int) $getCellValue('E', $row),
                    'days_off' => (int) $getCellValue('F', $row),
                    'days_sick' => (int) $getCellValue('G', $row),
                    'days_permission' => (int) $getCellValue('H', $row),
                    'days_alpha' => (int) $getCellValue('I', $row),
                    'days_leave' => (int) $getCellValue('J', $row),
                    'days_long_shift' => 0, // Not present in Excel K
                    'days_present' => (int) $getCellValue('K', $row), // K is Ada/Hadir
                    
                    // Salary
                    'basic_salary' => $getCellValue('L', $row),
                    
                    // Allowances
                    'meal_rate' => $getCellValue('N', $row),
                    'meal_amount' => $getCellValue('O', $row),
                    
                    'transport_rate' => $getCellValue('P', $row),
                    'transport_amount' => $getCellValue('Q', $row),
                    
                    'attendance_rate' => 0, // No rate column for Attendance in Excel
                    'attendance_amount' => $getCellValue('R', $row),
                    
                    'position_allowance' => $getCellValue('M', $row), // M is Tunj Jabatan
                    'health_allowance' => $getCellValue('S', $row), // S is Tunj Kesehatan
                    
                    'total_salary_1' => $getCellValue('T', $row), 
                    
                    // Overtime
                    'overtime_rate' => $getCellValue('U', $row),
                    'overtime_hours' => $getCellValue('V', $row),
                    'overtime_amount' => $getCellValue('W', $row),
                    
                    // Bonus & Incentives
                    'bonus' => $getCellValue('X', $row),
                    'holiday_allowance' => $getCellValue('Y', $row), // Insentif Lebaran
                    'adjustment' => $getCellValue('Z', $row), // Adj Kekurangan Gaji
                    'incentive' => 0, 

                    'total_salary_2' => $getCellValue('AA', $row), 
                    'policy_ho' => $getCellValue('AB', $row), 
                    
                    // Deductions
                    'deduction_absent' => $getCellValue('AC', $row), 
                    'deduction_late' => $getCellValue('AD', $row), 
                    'deduction_so_shortage' => $getCellValue('AE', $row), // Selisih SO
                    'deduction_alpha' => 0, 
                    'deduction_loan' => $getCellValue('AF', $row), // Pinjaman
                    'deduction_admin_fee' => $getCellValue('AG', $row), // Adm Bank
                    'deduction_bpjs_tk' => $getCellValue('AH', $row), // BPJS TK
                    
                    'deduction_total' => $getCellValue('AI', $row),
                    
                    // Finals
                    'net_salary' => $getCellValue('AJ', $row),
                    'grand_total' => $getCellValue('AJ', $row), 
                    
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
            Log::error('Hans Payroll Import Error: ' . $e->getMessage());
            return response()->json(['message' => 'Error: ' . $e->getMessage()], 500);
        }
    }
    
    /**
     * Save imported Hans payroll data
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
                $existing = PayrollHans::where('employee_id', $employee->id)
                    ->where('period', $row['period'])
                    ->first();
                
                if ($existing) {
                    $errors[] = "Row " . ($index + 1) . ": Payroll info for '{$row['employee_name']}' already exists";
                    continue;
                }
                
                PayrollHans::create(array_merge($row, [
                    'employee_id' => $employee->id,
                    'status' => 'draft',
                    'adjustment' => $row['adjustment'] ?? 0,
                    'deduction_so_shortage' => $row['deduction_so_shortage'] ?? 0,
                ]));
                
                $saved++;
            }
            
            return response()->json([
                'message' => "Successfully saved $saved payroll records",
                'saved' => $saved,
                'errors' => $errors,
            ]);

        } catch (\Exception $e) {
            Log::error('Hans Payroll Save Error: ' . $e->getMessage());
            return response()->json(['message' => 'Error: ' . $e->getMessage()], 500);
        }
    }
    
    public function show($id)
    {
        $payroll = PayrollHans::with('employee')->findOrFail($id);
        
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

        $payroll = PayrollHans::findOrFail($id);
        
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
        $payroll = PayrollHans::findOrFail($id);
        $payroll->delete();
        return response()->json(['message' => 'Payroll delete successfully']);
    }
    
    /**
     * Generate PDF Slip
     */
    public function generateSlip($id)
    {
        try {
            $payroll = PayrollHans::with('employee')->findOrFail($id);
            
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
            
            // Pass simple object to view, view can format
            $pdf = PDF::loadView('payslips.hans', [
                'payroll' => $payroll,
                'aiMessage' => $aiMessage
            ]);
            
            $filename = 'payslip_hans_' . str_replace(' ', '_', $payroll->employee->full_name) . '_' . $payroll->period . '.pdf';
            
            return $pdf->download($filename);
        } catch (\Exception $e) {
            Log::error('Error generating Hans payslip: ' . $e->getMessage());
             return response()->json([
                'message' => 'Failed to generate payslip', 
                'error' => $e->getMessage()
            ], 500);
        }
    }
    
    private function formatPayroll($payroll)
    {
        $formatted = $payroll->toArray();
        unset($formatted['ewa_amount']);
        
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
             'Adj Kekurangan Gaji' => $payroll->adjustment, // New
             'Kebijakan HO' => $payroll->policy_ho,
        ];
        
        $formatted['deductions'] = [
            'Absen 1X' => $payroll->deduction_absent,
            'Terlambat' => $payroll->deduction_late, 
            'Selisih SO' => $payroll->deduction_so_shortage, // New
            'Tidak Hadir' => $payroll->deduction_alpha,
            'Pinjaman' => $payroll->deduction_loan,
            'Adm Bank' => $payroll->deduction_admin_fee,
            'BPJS TK' => $payroll->deduction_bpjs_tk,
        ];
        
        // Add new extras to array
        $formatted['days_long_shift'] = $payroll->days_long_shift;
        $formatted['years_of_service'] = $payroll->years_of_service;
        $formatted['notes'] = $payroll->notes;

        // Add attendance data for Mobile App
        $formatted['attendance'] = [
            'Total Hari' => $payroll->days_total,
            'Long Shift' => $payroll->days_long_shift, 
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
