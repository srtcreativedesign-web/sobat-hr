<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Employee;
use Illuminate\Http\Request;
use Carbon\Carbon;
use Barryvdh\DomPDF\Facade\Pdf;

class ContractController extends Controller
{
    /**
     * Get list of employees with contracts expiring within the next 30 days.
     */
    public function getExpiringContracts(Request $request)
    {
        $days = $request->query('days', 30);
        $startDate = Carbon::today();
        $endDate = Carbon::today()->addDays($days);

        $employees = Employee::with(['user', 'organization'])
            ->whereBetween('contract_end_date', [$startDate, $endDate])
            ->orderBy('contract_end_date', 'asc')
            ->get()
            ->map(function ($employee) {
                return [
                    'id' => $employee->id,
                    'name' => $employee->full_name,
                    'position' => $employee->position,
                    'department' => $employee->organization ? $employee->organization->name : '-',
                    'contract_end_date' => $employee->contract_end_date,
                    'days_remaining' => Carbon::parse($employee->contract_end_date)->diffInDays(Carbon::now()),
                ];
            });

        return response()->json([
            'status' => 'success',
            'data' => $employees,
            'count' => $employees->count()
        ]);
    }

    /**
     * Generate Contract Renewal PDF
     */
    public function generatePdf($id)
    {
        $employee = Employee::with('organization')->findOrFail($id);
        
        // Logic for dates (default 1 year renewal)
        $currentContractEnd = $employee->contract_end_date ? Carbon::parse($employee->contract_end_date) : Carbon::today();
        $newStartDate = $currentContractEnd->copy()->addDay();
        $newEndDate = $newStartDate->copy()->addMonths(12)->subDay();
        
        // Get Template
        $template = \App\Models\ContractTemplate::where('is_active', true)->first();
        if (!$template) {
            return response()->json(['message' => 'No active contract template found'], 404);
        }

        $content = $template->content;

        // Prepare Replacements
        Carbon::setLocale('id'); // Ensure Indonesian locale for date names
        
        $replacements = [
            '[CONTRACT_NUMBER]' => 'PKWT/' . date('Y') . '/' . $employee->employee_code,
            '[DAY_NAME]' => Carbon::now()->isoFormat('dddd'),
            '[DATE_DAY]' => Carbon::now()->isoFormat('D'),
            '[DATE_MONTH]' => Carbon::now()->isoFormat('MMMM'),
            '[DATE_YEAR]' => Carbon::now()->isoFormat('Y'),
            '[EMPLOYEE_NAME]' => $employee->full_name,
            '[EMPLOYEE_CODE]' => $employee->employee_code ?? '-',
            '[EMPLOYEE_POSITION]' => $employee->position,
            '[EMPLOYEE_ADDRESS]' => $employee->ktp_address ?? '-',
            '[DEPARTMENT_NAME]' => $employee->organization->name ?? '-',
            '[DURATION_MONTHS]' => '12', // Currently hardcoded/default
            '[START_DATE]' => $newStartDate->isoFormat('D MMMM Y'),
            '[END_DATE]' => $newEndDate->isoFormat('D MMMM Y'),
        ];

        // Apply Replacements
        foreach ($replacements as $key => $value) {
            $content = str_replace($key, $value, $content);
        }
        
        $pdf = Pdf::loadHTML($content);
        
        return $pdf->download('Kontrak_' . str_replace(' ', '_', $employee->full_name) . '.pdf');
    }
}
