<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\PayrollWrapping;
use App\Models\Employee;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use PDF;
use App\Services\GroqAiService;

class PayrollWrappingController extends Controller
{
    public function index(Request $request)
    {
        $user = auth()->user();
        $query = PayrollWrapping::with('employee');

        // Check scope
        $roleName = $user->role ? strtolower($user->role->name) : '';
        if (!in_array($roleName, ['admin', 'super_admin', 'hr', 'admin_cabang'])) {
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
            $sheet = $spreadsheet->getActiveSheet();
            
            $highestRow = $sheet->getHighestRow();
            
             // Helper
            $getCellValue = function($col, $row) use ($sheet) {
                $val = $sheet->getCell($col . $row)->getCalculatedValue();
                if (is_numeric($val)) return (float)$val;
                if (is_string($val)) {
                    $cleaned = preg_replace('/[^0-9\.\,\-]/', '', $val);
                    return is_numeric($cleaned) ? (float)$cleaned : 0;
                }
                return 0;
            };
            
            // Find Header (Nama Karyawan) - usually Row 2
             $headerRow = 2;
             $dataStartRow = 4;
            
             $dataRows = [];
             for ($row = $dataStartRow; $row <= $highestRow; $row++) {
                 $name = $sheet->getCell('B' . $row)->getValue();
                 if (empty($name)) continue;
                 
                 // Column Mapping based on Analysis
                 $parsed = [
                    'employee_name' => $name,
                    'period' => date('Y-m'), // Default current
                    'account_number' => $sheet->getCell('D' . $row)->getValue(),
                    
                    // Attendance (E-K)
                    'days_total' => (int)$getCellValue('E', $row),
                    'days_off' => (int)$getCellValue('F', $row),
                    'days_sick' => (int)$getCellValue('G', $row),
                    'days_permission' => (int)$getCellValue('H', $row),
                    'days_alpha' => (int)$getCellValue('I', $row),
                    'days_leave' => (int)$getCellValue('J', $row),
                    'days_present' => (int)$getCellValue('K', $row),
                    
                    // Income
                    'basic_salary' => $getCellValue('L', $row),
                    'training_salary' => $getCellValue('M', $row),
                    
                    'meal_rate' => $getCellValue('N', $row),
                    'meal_amount' => $getCellValue('O', $row),
                    
                    'transport_rate' => $getCellValue('P', $row),
                    'transport_amount' => $getCellValue('Q', $row),
                    
                    'attendance_allowance' => $getCellValue('R', $row), 
                    'health_allowance' => $getCellValue('S', $row),
                    'bonus' => $getCellValue('T', $row),
                    
                    'overtime_amount' => $getCellValue('X', $row), 
                    'overtime_hours' => $getCellValue('W', $row),
                    
                    'target_koli' => $getCellValue('Y', $row),
                    'fee_aksesoris' => $getCellValue('Z', $row),
                    
                    'total_salary_gross' => $getCellValue('AA', $row),
                    'adj_bpjs' => $getCellValue('AB', $row),
                    
                    // Deductions
                    'deduction_absent' => $getCellValue('AC', $row),
                    'deduction_late' => $getCellValue('AD', $row),
                    'deduction_alpha' => $getCellValue('AE', $row),
                    'deduction_loan' => $getCellValue('AF', $row),
                    'deduction_admin_fee' => $getCellValue('AG', $row),
                    'deduction_bpjs_tk' => $getCellValue('AH', $row),
                    
                    'deduction_total' => $getCellValue('AI', $row),
                    'net_salary' => $getCellValue('AM', $row) > 0 ? $getCellValue('AM', $row) : $getCellValue('AL', $row), // Try AM (empty?) fallback to AL
                    
                    'ewa_amount' => $getCellValue('AK', $row),
                 ];
                 
                 // If period is date from excel (46023)
                 $periodVal = $sheet->getCell('C' . $row)->getValue();
                 if (is_numeric($periodVal)) {
                     $parsed['period'] = \PhpOffice\PhpSpreadsheet\Shared\Date::excelToDateTimeObject($periodVal)->format('Y-m');
                 }
                 
                 $dataRows[] = $parsed;
             }
             
             return response()->json([
                'message' => 'File parsed successfully',
                'rows' => $dataRows
            ]);

        } catch (\Exception $e) {
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
        return response()->json($this->formatPayroll($payroll));
    }
    
    public function updateStatus(Request $request, $id)
    {
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
