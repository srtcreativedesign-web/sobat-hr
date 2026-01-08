<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Payroll;
use App\Models\Employee;
use Barryvdh\DomPDF\Facade\Pdf;

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
                    'allowances' => (float) $payroll->allowances,
                    'deductions' => (float) $payroll->total_deductions,
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
        $payroll = Payroll::with('employee')->findOrFail($id);

        // TODO: Create PDF view template
        // $pdf = Pdf::loadView('payroll.slip', compact('payroll'));
        // return $pdf->download('slip-gaji-' . $payroll->employee->employee_number . '.pdf');

        return response()->json([
            'message' => 'PDF generation not yet implemented',
            'payroll' => $payroll,
        ]);
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
     * Import payroll from Excel
     */
    public function import(Request $request)
    {
        $request->validate([
            'file' => 'required|file|mimes:xlsx,xls|max:10240', // 10MB max
        ]);

        $file = $request->file('file');
        
        // Store file temporarily
        $path = $file->store('payroll_imports', 'local');

        // TODO: Implement Excel parsing logic
        // This will be implemented after format is finalized

        return response()->json([
            'message' => 'File uploaded successfully. Import logic will be implemented after format confirmation.',
            'file_name' => $file->getClientOriginalName(),
            'file_size' => $file->getSize(),
            'stored_path' => $path,
        ]);
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
