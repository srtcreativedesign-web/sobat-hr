<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Jobs\ProcessPayrollImport;
use App\Models\Employee;
use App\Models\Payroll;
use App\Services\GroqAiService;
use Barryvdh\DomPDF\Facade\Pdf;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Maatwebsite\Excel\Facades\Excel;

class PayrollController extends Controller
{
    public function index(Request $request)
    {
        $query = Payroll::with(['employee']);

        // Filter by search name
        if ($request->has('search') && ! empty($request->search)) {
            $query->whereHas('employee', function ($q) use ($request) {
                $q->where('full_name', 'like', '%'.$request->search.'%');
            });
        }

        // Filter by status
        if ($request->has('status')) {
            $query->where('status', $request->status);
        }

        $user = auth()->user();
        $roleName = $user->role ? strtolower($user->role->name) : '';

        // --- SECURE PLATFORM CHECK (BROWSER FINGERPRINT) ---
        // Modern browsers (Web Admin) ALWAYS send 'Sec-Fetch-Site' or 'Referer'.
        // Mobile apps (Dio) NEVER send 'Sec-Fetch-Site' by default.
        $isMobile = ! $request->hasHeader('Sec-Fetch-Site');

        // IF MOBILE: Force self-view permanently, no matter who is logging in.
        if ($isMobile) {
            $employeeId = $user->employee ? $user->employee->id : null;
            if ($employeeId) {
                // Fetch from ALL models for mobile!
                $payrollModels = [
                    \App\Models\Payroll::class => 'ho',
                    \App\Models\PayrollCelluller::class => 'cellular',
                    \App\Models\PayrollFnb::class => 'fnb',
                    \App\Models\PayrollHans::class => 'hans',
                    \App\Models\PayrollMaximum::class => 'maximum',
                    \App\Models\PayrollMm::class => 'minimarket',
                    \App\Models\PayrollMoneyChanger::class => 'money_changer',
                    \App\Models\PayrollRef::class => 'reflexiology',
                    \App\Models\PayrollTungtau::class => 'tungtau',
                    \App\Models\PayrollWrapping::class => 'wrapping',
                ];

                $allPayrolls = collect();
                $employeeData = $user->employee;

                foreach ($payrollModels as $modelClass => $type) {
                    $records = $modelClass::where('employee_id', $employeeId)
                        ->whereIn('status', ['approved', 'paid'])
                        ->get();
                        
                    foreach ($records as $record) {
                        $responseService = app(\App\Services\PayrollResponseService::class);
                        
                        if ($modelClass === \App\Models\Payroll::class) {
                            $data = $responseService->formatStandardPayroll($record);
                            $data['division_type_label'] = $type;
                        } else {
                            $data = $responseService->formatRetailPayroll($record);
                            $data['division_type_label'] = $type;
                        }
                        
                        $allPayrolls->push($data);
                    }
                }

                $sorted = $allPayrolls->sortByDesc('period')->values();
                return response()->json(['data' => $sorted]);
            } else {
                return response()->json(['data' => []]);
            }
        }
        // IF WEB: Admin can see everything, others are filtered.
        else {
            $isAdmin = in_array($roleName, [Role::ADMIN, Role::SUPER_ADMIN, Role::HR, Role::HRD, Role::ADMIN_CABANG, 'admin_hr']);
            if (! $isAdmin) {
                $query->where('employee_id', $user->employee?->id);
                $query->whereIn('status', ['approved', 'paid']);
            }

            if ($roleName === 'admin_hr') {
                $query->whereHas('employee', function($q) {
                    $q->where(function($subQ) {
                        $subQ->where('track', '!=', 'office')->orWhereNull('track');
                    });
                });
            }

            // Allow admin on web to filter by specific employee_id if provided
            if ($isAdmin && $request->has('employee_id') && ! empty($request->employee_id)) {
                $query->where('employee_id', $request->employee_id);
            }
        }

        // Filter by period (month and year)
        if ($request->has('month') && $request->has('year')) {
            // period is stored as YYYY-MM
            $periodString = sprintf('%04d-%02d', $request->year, $request->month);
            $query->where('period', $periodString);
        }
        // Filter by year only
        elseif ($request->has('year')) {
            $query->where('period', 'like', $request->year.'-%');
        }

        $payrolls = $query->orderBy('period', 'desc')
            ->get();

        return response()->json([
            'data' => $payrolls->map(function ($payroll) {
                $responseService = app(\App\Services\PayrollResponseService::class);
                return $responseService->formatStandardPayroll($payroll);
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

        // --- IDOR GUARD ---
        $user = auth()->user();
        $roleName = $user->role ? strtolower($user->role->name) : '';
        $isAdmin = in_array($roleName, [Role::ADMIN, Role::SUPER_ADMIN, Role::HR, 'admin_hr']);

        if (! $isAdmin && $payroll->employee_id !== $user->employee?->id) {
            return response()->json(['message' => 'Anda tidak memiliki akses ke data payroll ini.'], 403);
        }

        if ($roleName === 'admin_hr' && $payroll->employee && strtolower($payroll->employee->track) === 'office') {
            return response()->json(['message' => 'Anda tidak memiliki akses ke data payroll Head Office.'], 403);
        }

        $responseService = app(\App\Services\PayrollResponseService::class);
        $data = $responseService->formatStandardPayroll($payroll);

        return response()->json($data);
    }

    public function update(Request $request, string $id)
    {
        $payroll = Payroll::findOrFail($id);

        // --- IDOR GUARD ---
        $user = auth()->user();
        $roleName = $user->role ? strtolower($user->role->name) : '';
        $isAdmin = in_array($roleName, [Role::ADMIN, Role::SUPER_ADMIN, Role::HR, 'admin_hr']);

        if (! $isAdmin) {
            return response()->json(['message' => 'Hanya Admin/HR yang dapat mengubah data payroll.'], 403);
        }

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

        // --- IDOR GUARD ---
        $user = auth()->user();
        $roleName = $user->role ? strtolower($user->role->name) : '';
        $isAdmin = in_array($roleName, [Role::ADMIN, Role::SUPER_ADMIN, Role::HR, 'admin_hr']);

        if (! $isAdmin) {
            return response()->json(['message' => 'Hanya Admin/HR yang dapat menghapus data payroll.'], 403);
        }

        $payroll->delete();

        return response()->json(['message' => 'Payroll deleted successfully']);
    }

    /**
     * Generate payroll slip PDF
     */
    public function generateSlip(string $id)
    {
        $payroll = Payroll::with(['employee', 'employee.division'])->findOrFail($id);

        // Forward to the correct controller if this is a mirror record!
        if (isset($payroll->details['original_model']) && isset($payroll->details['original_id'])) {
            $originalModelClass = $payroll->details['original_model'];
            $originalId = $payroll->details['original_id'];
            
            if ($originalModelClass === \App\Models\PayrollFnb::class) return app(\App\Http\Controllers\Api\PayrollFnbController::class)->generateSlip($originalId);
            if ($originalModelClass === \App\Models\PayrollTungtau::class) return app(\App\Http\Controllers\Api\PayrollFnbController::class)->generateSlip($originalId);
            if ($originalModelClass === \App\Models\PayrollMaximum::class) return app(\App\Http\Controllers\Api\PayrollFnbController::class)->generateSlip($originalId);
            if ($originalModelClass === \App\Models\PayrollHo::class) return app(\App\Http\Controllers\Api\PayrollHoController::class)->generatePayslip($originalId);
            
            // Retail
            $request = request();
            if (isset($payroll->details['division_type'])) {
                $request->merge(['division_type' => $payroll->details['division_type']]);
            }
            return app(\App\Http\Controllers\Api\PayrollRetailController::class)->generateSlip($request, $originalId);
        }

        // --- IDOR GUARD ---
        $user = auth()->user();
        $roleName = $user->role ? strtolower($user->role->name) : '';
        $isAdmin = in_array($roleName, [Role::ADMIN, Role::SUPER_ADMIN, Role::HR, 'admin_hr']);

        if (! $isAdmin && $payroll->employee_id !== $user->employee?->id) {
            return response()->json(['message' => 'Anda tidak memiliki akses ke slip gaji ini.'], 403);
        }

        // Generate AI-powered personalized message
        $groqService = new GroqAiService;
        $aiMessage = $groqService->generatePayslipMessage([
            'employee_name' => $payroll->employee->full_name,
            'period' => date('F Y', strtotime($payroll->period.'-01')),
            'basic_salary' => $payroll->basic_salary,
            'overtime' => $payroll->overtime_pay,
            'net_salary' => $payroll->net_salary,
            'join_date' => $payroll->employee->join_date,
        ]);

        // Generate PDF
        $pdf = Pdf::loadView('payroll.slip', [
            'payroll' => $payroll,
            'employee' => $payroll->employee,
            'aiMessage' => $aiMessage,
        ]);

        $pdf->setPaper('a4', 'portrait');

        $filename = 'Slip_Gaji_'.$payroll->employee->employee_code.'_'.$payroll->period.'.pdf';

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
            'Net Salary',
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
                '5150000',
            ]);

            fclose($file);
        };

        return response()->stream($callback, 200, [
            'Content-Type' => 'text/csv',
            'Content-Disposition' => 'attachment; filename=template_import_payroll.csv',
        ]);
    }

    /**
     * Import payroll from Excel/CSV file
     */
    public function import(Request $request, \App\Services\PayrollImportService $importService)
    {
        $request->validate([
            'file' => 'required|file|mimes:xlsx,xls,csv',
        ]);

        $file = $request->file('file');
        $period = $request->period; // Optional period string

        $result = $importService->processImport($file, $period);

        if ($result['success']) {
            return response()->json([
                'message' => 'File parsed successfully',
                'file_name' => $result['file_name'],
                'rows_count' => $result['rows_count'],
                'rows' => $result['rows'],
            ]);
        } else {
            return response()->json(['message' => 'Error: ' . $result['message']], 422);
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
            'rows.*.period' => 'nullable|string',
            'rows.*.allowances' => 'nullable|numeric',
            'rows.*.overtime' => 'nullable|numeric',
            'rows.*.total_deductions' => 'nullable|numeric',
            'rows.*.net_salary' => 'required|numeric',
            'rows.*.details' => 'nullable|array',
        ]);

        $rows = $request->input('rows');
        $adminId = auth()->id();

        Log::info('Dispatching Payroll Import Job. Rows: '.count($rows));

        // Dispatch Background Job
        ProcessPayrollImport::dispatch($rows, $adminId);

        return response()->json([
            'message' => 'Proses simpan data sedang berjalan di latar belakang. Silakan tunggu beberapa saat.',
            'summary' => [
                'total' => count($rows),
            ],
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

        if ($request->status === 'approved' && $request->has('approval_signature')) {
            $payroll->approval_signature = $request->approval_signature;
            $payroll->signer_name = $request->signer_name;
            $payroll->approved_by = auth()->id();
        }

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
            'division' => 'nullable|string|in:office,fnb,minimarket,reflexiology,wrapping,hans,cellular,money_changer,tungtau,maximum',
        ]);

        $division = $request->input('division', 'office');

        $model = Payroll::class;
        if ($division === 'fnb') {
            $model = \App\Models\PayrollFnb::class;
        }
        if ($division === 'minimarket') {
            $model = \App\Models\PayrollMm::class;
        }
        if ($division === 'reflexiology') {
            $model = \App\Models\PayrollRef::class;
        }
        if ($division === 'wrapping') {
            $model = \App\Models\PayrollWrapping::class;
        }
        if ($division === 'hans') {
            $model = \App\Models\PayrollHans::class;
        }
        if ($division === 'cellular') {
            $model = \App\Models\PayrollCelluller::class;
        }
        if ($division === 'money_changer') {
            $model = \App\Models\PayrollMoneyChanger::class;
        }
        if ($division === 'tungtau') {
            $model = \App\Models\PayrollTungtau::class;
        }
        if ($division === 'maximum') {
            $model = \App\Models\PayrollMaximum::class;
        }

        $periodString = sprintf('%04d-%02d', $request->year, $request->month);

        $payrolls = $model::where('period', $periodString)
            ->where('status', 'draft')
            ->get();

        $updated = count($payrolls);

        foreach ($payrolls as $payroll) {
            $payroll->status = 'approved';
            $payroll->save();
        }

        return response()->json([
            'message' => "Successfully approved {$updated} payrolls for period {$periodString}",
            'count' => $updated,
        ]);
    }

    /**
     * Approve SELECTED draft payrolls
     */
    /**
     * Approve SELECTED draft payrolls with Division support
     */
    public function bulkApprove(Request $request)
    {
        $request->validate([
            'ids' => 'required|array',
            'ids.*' => 'integer',
            'division' => 'nullable|string|in:office,fnb,minimarket,reflexiology,wrapping,hans,cellular,money_changer,tungtau,maximum',
            'approval_signature' => 'nullable|string',
            'notes' => 'nullable|string',
            'signer_name' => 'nullable|string',
        ]);

        $ids = $request->input('ids');
        $division = $request->input('division', 'office');

        $model = Payroll::class;
        if ($division === 'fnb') {
            $model = \App\Models\PayrollFnb::class;
        }
        if ($division === 'minimarket') {
            $model = \App\Models\PayrollMm::class;
        }
        if ($division === 'reflexiology') {
            $model = \App\Models\PayrollRef::class;
        }
        if ($division === 'wrapping') {
            $model = \App\Models\PayrollWrapping::class;
        }
        if ($division === 'hans') {
            $model = \App\Models\PayrollHans::class;
        }
        if ($division === 'cellular') {
            $model = \App\Models\PayrollCelluller::class;
        }
        if ($division === 'money_changer') {
            $model = \App\Models\PayrollMoneyChanger::class;
        }
        if ($division === 'tungtau') {
            $model = \App\Models\PayrollTungtau::class;
        }
        if ($division === 'maximum') {
            $model = \App\Models\PayrollMaximum::class;
        }

        $modelInstance = new $model;
        $table = $modelInstance->getTable();

        $updateData = ['status' => 'approved'];

        if ($request->has('approval_signature')) {
            if (\Illuminate\Support\Facades\Schema::hasColumn($table, 'approval_signature')) {
                $updateData['approval_signature'] = $request->approval_signature;
            }
            if (\Illuminate\Support\Facades\Schema::hasColumn($table, 'signer_name')) {
                $updateData['signer_name'] = $request->signer_name;
            }
            if (\Illuminate\Support\Facades\Schema::hasColumn($table, 'notes')) {
                $updateData['notes'] = $request->notes;
            }
            if (\Illuminate\Support\Facades\Schema::hasColumn($table, 'approved_by')) {
                $updateData['approved_by'] = auth()->id();
            }
        }

        // Pending status varies: 'draft' or 'pending'
        // Generic uses 'draft', others use 'pending'. Let's handle both or check model.
        // FnB/MM/Ref/Wrapping/Hans usually use 'pending' as initial status after import?
        // Let's rely on the frontend sending correct IDs for 'pending' items.
        // We will update where status is NOT approved/paid to be safe?
        // Or simpler: Update whereIn ids.

        $payrolls = $model::whereIn('id', $ids)
            ->whereIn('status', ['draft', 'pending'])
            ->get();

        $updated = 0;
        foreach ($payrolls as $payroll) {
            foreach ($updateData as $field => $value) {
                $payroll->$field = $value;
            }
            $payroll->save();
            $updated++;
        }

        return response()->json([
            'message' => "Successfully approved {$updated} selected payrolls for {$division}",
            'count' => $updated,
        ]);
    }

    /**
     * Generate payslip PDF for Head Office
     */
    public function generatePayslip($id)
    {
        $payroll = Payroll::with(['employee'])->findOrFail($id);

        // Generate AI-powered personalized message
        $aiMessage = null;
        try {
            $groqService = new GroqAiService;
            $aiMessage = $groqService->generatePayslipMessage([
                'employee_name' => $payroll->employee->full_name,
                'period' => date('F Y', strtotime($payroll->period.'-01')),
                'basic_salary' => $payroll->basic_salary,
                'overtime' => $payroll->overtime_pay ?? 0,
                'net_salary' => $payroll->net_salary,
                'join_date' => $payroll->employee->join_date,
            ]);
        } catch (\Exception $e) {
        }

        $pdf = Pdf::loadView('payslips.ho', [
            'payroll' => $payroll,
            'aiMessage' => $aiMessage,
            'employee' => $payroll->employee,
        ]);

        $pdf->setPaper('a4', 'portrait');

        $filename = 'Slip_Gaji_HO_'.str_replace(' ', '_', $payroll->employee->full_name).'_'.$payroll->period.'.pdf';

        return $pdf->download($filename);
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
        elseif (str_contains($string, '.') && ! str_contains($string, ',')) {
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

    /**
     * Bulk Download Payslips as ZIP
     */
    public function bulkDownload(Request $request)
    {
        $request->validate([
            'period' => 'required|string', // YYYY-MM
            'division' => 'required|string', // all, office, hans, fnb, maximum, mm, ref, wrapping, tungtau
        ]);

        $period = $request->period;
        $division = $request->division;
        $files = [];

        try {
            // Helper to process division
            $processDivision = function ($modelClass, $viewName, $prefix) use ($period, &$files) {
                // Determine query based on model structure
                $query = $modelClass::with('employee')->where('period', $period);
                $payrolls = $query->get();

                $groqService = new GroqAiService;

                foreach ($payrolls as $payroll) {

                    // Specific Logic for specific models
                    if (str_contains($modelClass, 'PayrollHans')) {
                        $payroll->allowances = [
                            'Uang Makan' => ['rate' => $payroll->meal_rate, 'amount' => $payroll->meal_amount],
                            'Transport' => ['rate' => $payroll->transport_rate, 'amount' => $payroll->transport_amount],
                            'Kehadiran' => ['rate' => $payroll->attendance_rate, 'amount' => $payroll->attendance_amount],
                            'Tunjangan Kesehatan' => $payroll->health_allowance,
                            'Tunjangan Jabatan' => $payroll->position_allowance,
                            'Lembur' => ['rate' => $payroll->overtime_rate, 'hours' => $payroll->overtime_hours, 'amount' => $payroll->overtime_amount],
                            'Bonus' => $payroll->bonus,
                            'Insentif' => $payroll->incentive,
                            'THR' => $payroll->holiday_allowance,
                            'Adj Kekurangan Gaji' => $payroll->adjustment,
                            'Kebijakan HO' => $payroll->policy_ho,
                        ];
                        $payroll->deductions = [
                            'Absen 1X' => $payroll->deduction_absent,
                            'Terlambat' => $payroll->deduction_late,
                            'Selisih SO' => $payroll->deduction_so_shortage,
                            'Tidak Hadir' => $payroll->deduction_alpha,
                            'Pinjaman' => $payroll->deduction_loan,
                            'Adm Bank' => $payroll->deduction_admin_fee,
                            'BPJS TK' => $payroll->deduction_bpjs_tk,
                        ];
                    } elseif (str_contains($modelClass, 'PayrollFnb')) {
                        // FnB logic
                        $payroll->allowances = [
                            'Kehadiran' => ['rate' => $payroll->attendance_rate, 'amount' => $payroll->attendance_amount],
                            'Transport' => ['rate' => $payroll->transport_rate, 'amount' => $payroll->transport_amount],
                            'Tunjangan Kesehatan' => $payroll->health_allowance,
                            'Tunjangan Jabatan' => $payroll->position_allowance,
                            'Lembur' => ['rate' => $payroll->overtime_rate, 'hours' => $payroll->overtime_hours, 'amount' => $payroll->overtime_amount],
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
                    }
                    // Wrapping - Assuming identical to FnB (Check if needed, but logical guess)
                    // Wrapping Logic
                    elseif (str_contains($modelClass, 'PayrollWrapping')) {
                        $payroll->allowances = [
                            'Gaji Training' => $payroll->training_salary,
                            'Uang Makan' => ['rate' => $payroll->meal_rate, 'amount' => $payroll->meal_amount],
                            'Transport' => ['rate' => $payroll->transport_rate, 'amount' => $payroll->transport_amount],
                            'Tunjangan Kesehatan' => $payroll->health_allowance,
                            'Kehadiran' => $payroll->attendance_allowance,
                            'Lembur' => $payroll->overtime_amount,
                            'Bonus' => $payroll->bonus,
                            'Target Koli' => $payroll->target_koli,
                            'Fee Aksesoris' => $payroll->fee_aksesoris,
                            'Adj BPJS (Refund)' => $payroll->adj_bpjs,
                        ];
                        $payroll->deductions = [
                            'Potongan Absen' => $payroll->deduction_absent,
                            'Terlambat' => $payroll->deduction_late,
                            'Tidak Hadir (Alpha)' => $payroll->deduction_alpha,
                            'Pinjaman' => $payroll->deduction_loan,
                            'Adm Bank' => $payroll->deduction_admin_fee,
                            'BPJS TK' => $payroll->deduction_bpjs_tk,
                        ];
                    }
                    // Celluller Logic
                    elseif (str_contains($modelClass, 'PayrollCelluller')) {
                        $payroll->allowances = [
                            'Uang Makan' => ['rate' => $payroll->meal_rate, 'amount' => $payroll->meal_amount],
                            'Transport' => ['rate' => $payroll->transport_rate, 'amount' => $payroll->transport_amount],
                            'Lembur Wajib' => ['rate' => $payroll->mandatory_overtime_rate, 'amount' => $payroll->mandatory_overtime_amount],
                            'Tunjangan Kehadiran' => $payroll->attendance_allowance,
                            'Tunjangan Kesehatan' => $payroll->health_allowance,
                            'Tunjangan Jabatan' => $payroll->position_allowance,
                            'Lembur Tambahan' => ['rate' => $payroll->overtime_rate, 'hours' => $payroll->overtime_hours, 'amount' => $payroll->overtime_amount],
                            'Bonus' => $payroll->bonus,
                            'Insentif Lebaran' => $payroll->holiday_allowance,
                            'Adj Kekurangan Gaji' => $payroll->adjustment,
                            'Kebijakan HO' => $payroll->policy_ho,
                        ];
                        $payroll->deductions = [
                            'Absen 1X' => $payroll->deduction_absent,
                            'Terlambat' => $payroll->deduction_late,
                            'Selisih SO' => $payroll->deduction_so_shortage,
                            'Pinjaman' => $payroll->deduction_loan,
                            'Adm Bank' => $payroll->deduction_admin_fee,
                            'BPJS TK' => $payroll->deduction_bpjs_tk,
                        ];
                    }
                    // MM & Ref - Assuming identical to FnB
                    elseif (str_contains($modelClass, 'PayrollMm') || str_contains($modelClass, 'PayrollRef')) {
                        $payroll->allowances = [
                            'Kehadiran' => ['rate' => $payroll->attendance_rate, 'amount' => $payroll->attendance_amount],
                            'Transport' => ['rate' => $payroll->transport_rate, 'amount' => $payroll->transport_amount],
                            'Tunjangan Kesehatan' => $payroll->health_allowance,
                            'Tunjangan Jabatan' => $payroll->position_allowance,
                            'Lembur' => ['rate' => $payroll->overtime_rate, 'hours' => $payroll->overtime_hours, 'amount' => $payroll->overtime_amount],
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
                    }
                    // Money Changer
                    elseif (str_contains($modelClass, 'PayrollMoneyChanger')) {
                        $payroll->allowances = [
                            'Tunjangan Jabatan' => $payroll->position_allowance,
                            'Uang Makan' => ['rate' => $payroll->meal_rate, 'amount' => $payroll->meal_amount],
                            'Transport' => ['rate' => $payroll->transport_rate, 'amount' => $payroll->transport_amount],
                            'Tunjangan Kehadiran' => $payroll->attendance_allowance,
                            'Tunjangan Kesehatan' => $payroll->health_allowance,
                            'Lembur' => ['rate' => $payroll->overtime_rate, 'hours' => $payroll->overtime_hours, 'amount' => $payroll->overtime_amount],
                            'Bonus' => $payroll->bonus,
                            'THR' => $payroll->holiday_allowance,
                            'Adj Kekurangan Gaji' => $payroll->adjustment,
                            'Kebijakan HO' => $payroll->policy_ho,
                        ];
                        $payroll->deductions = [
                            'Absen 1X' => $payroll->deduction_absent,
                            'Terlambat' => $payroll->deduction_late,
                            'Selisih SO' => $payroll->deduction_so_shortage,
                            'Pinjaman' => $payroll->deduction_loan,
                            'Adm Bank' => $payroll->deduction_admin_fee,
                            'BPJS TK' => $payroll->deduction_bpjs_tk,
                        ];
                    }

                    // Generate AI Message
                    $aiMessage = null;
                    try {
                        $aiMessage = $groqService->generatePayslipMessage([
                            'employee_name' => $payroll->employee->full_name,
                            'period' => date('F Y', strtotime($period.'-01')),
                            'basic_salary' => $payroll->basic_salary,
                            'overtime' => $payroll->overtime_amount ?? ($payroll->overtime_pay ?? 0),
                            'net_salary' => $payroll->net_salary,
                            'join_date' => $payroll->employee->join_date,
                        ]);
                    } catch (\Exception $e) {
                    }

                    $pdf = Pdf::loadView($viewName, [
                        'payroll' => $payroll,
                        'aiMessage' => $aiMessage,
                        'employee' => $payroll->employee,
                    ]);

                    $filename = $prefix.'_'.str_replace(' ', '_', $payroll->employee->full_name).'.pdf';
                    $files[$filename] = $pdf->output();
                }
            };

            // Switch Divisions
            if ($division === 'all' || $division === 'maximum') {
                $processDivision(\App\Models\PayrollMaximum::class, 'payslips.maximum', 'Maximum600');
            }
            if ($division === 'all' || $division === 'tungtau') {
                $processDivision(\App\Models\PayrollTungtau::class, 'payslips.tungtau', 'Tungtau');
            }
            if ($division === 'all' || $division === 'hans') {
                $processDivision(\App\Models\PayrollHans::class, 'payslips.hans', 'Hans');
            }
            if ($division === 'all' || $division === 'fnb') {
                $processDivision(\App\Models\PayrollFnb::class, 'payslips.fnb', 'FnB');
            }
            if ($division === 'all' || $division === 'mm') {
                $processDivision(\App\Models\PayrollMm::class, 'payslips.mm', 'MM');
            }
            if ($division === 'all' || $division === 'ref') {
                $processDivision(\App\Models\PayrollRef::class, 'payslips.ref', 'Reflexy');
            }
            if ($division === 'all' || $division === 'wrapping') {
                $processDivision(\App\Models\PayrollWrapping::class, 'payslips.wrapping', 'Wrapping');
            }
            if ($division === 'all' || $division === 'office') {
                $processDivision(Payroll::class, 'payslips.ho', 'HO');
            }
            if ($division === 'all' || $division === 'cellular') {
                $processDivision(\App\Models\PayrollCelluller::class, 'payslips.celluller', 'Cellular');
            }
            if ($division === 'all' || $division === 'money_changer') {
                $processDivision(\App\Models\PayrollMoneyChanger::class, 'payslips.money_changer', 'MoneyChanger');
            }

            if (empty($files)) {
                return response()->json(['message' => 'No payrolls found for this period'], 404);
            }

            // Create ZIP
            $zipFileName = "Payrolls_{$division}_{$period}_".time().'.zip';
            $zipPath = storage_path("app/public/{$zipFileName}");

            // Ensure directory exists
            if (! file_exists(dirname($zipPath))) {
                mkdir(dirname($zipPath), 0755, true);
            }

            $zip = new \ZipArchive;
            if ($zip->open($zipPath, \ZipArchive::CREATE) === true) {
                foreach ($files as $name => $content) {
                    $zip->addFromString($name, $content);
                }
                $zip->close();
            } else {
                return response()->json(['message' => 'Failed to create zip file'], 500);
            }

            return response()->download($zipPath)->deleteFileAfterSend(true);

        } catch (\Exception $e) {
            Log::error('Bulk Download Error: '.$e->getMessage());

            return response()->json(['message' => $e->getMessage()], 500);
        }
    }
}
