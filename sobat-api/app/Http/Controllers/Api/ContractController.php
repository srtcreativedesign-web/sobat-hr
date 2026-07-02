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

        $employees = Employee::with(['user', 'division'])
            ->whereBetween('contract_end_date', [$startDate, $endDate])
            ->orderBy('contract_end_date', 'asc')
            ->get()
            ->map(function ($employee) {
                return [
                    'id' => $employee->id,
                    'name' => $employee->full_name,
                    'position' => $employee->position,
                    'department' => $employee->division ? $employee->division->name : '-',
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
    public function generatePdf(Request $request, $id)
    {
        $employee = Employee::with('division')->findOrFail($id);
        
        // Custom variables
        $durationMonths = $request->input('duration_months', 12);
        
        if ($request->has('start_date') && $request->has('end_date')) {
            $newStartDate = Carbon::parse($request->input('start_date'));
            $newEndDate = Carbon::parse($request->input('end_date'));
        } else {
            // Default logic
            $currentContractEnd = $employee->contract_end_date ? Carbon::parse($employee->contract_end_date) : Carbon::today();
            $newStartDate = $currentContractEnd->copy()->addDay();
            $newEndDate = $newStartDate->copy()->addMonths($durationMonths)->subDay();
        }

        $contractNumber = $request->input('contract_number', 'PKWT/' . date('Y') . '/' . $employee->employee_code);

        // Update the contract end date in the database
        $employee->update([
            'contract_end_date' => $newEndDate->format('Y-m-d'),
            'employment_status' => 'contract', // Ensure status is contract
        ]);
        
        // Get Template
        $template = \App\Models\ContractTemplate::where('is_active', true)->first();
        if (!$template) {
            return response()->json(['message' => 'No active contract template found'], 404);
        }

        $content = $template->content;

        // Prepare Replacements
        Carbon::setLocale('id'); // Ensure Indonesian locale for date names
        
        $replacements = [
            '[CONTRACT_NUMBER]' => $contractNumber,
            '[DAY_NAME]' => Carbon::now()->isoFormat('dddd'),
            '[DATE_DAY]' => Carbon::now()->isoFormat('D'),
            '[DATE_MONTH]' => Carbon::now()->isoFormat('MMMM'),
            '[DATE_YEAR]' => Carbon::now()->isoFormat('Y'),
            '[EMPLOYEE_NAME]' => $employee->full_name,
            '[EMPLOYEE_CODE]' => $employee->employee_code ?? '-',
            '[EMPLOYEE_POSITION]' => $employee->position,
            '[EMPLOYEE_ADDRESS]' => $employee->ktp_address ?? '-',
            '[DEPARTMENT_NAME]' => $employee->division->name ?? '-',
            '[DURATION_MONTHS]' => $durationMonths,
            '[START_DATE]' => $newStartDate->isoFormat('D MMMM Y'),
            '[END_DATE]' => $newEndDate->isoFormat('D MMMM Y'),
        ];

        // Apply Replacements
        foreach ($replacements as $key => $value) {
            $content = str_replace($key, $value, $content);
        }
        
        // Inject Custom Page Settings
        $settings = $template->settings ?? [];
        $pageSizeCss = 'A4';
        if (isset($settings['paperSize'])) {
            if ($settings['paperSize'] === 'F4') $pageSizeCss = '21.5cm 33cm';
            else if ($settings['paperSize'] === 'Letter') $pageSizeCss = 'letter';
            else if ($settings['paperSize'] === 'Legal') $pageSizeCss = 'legal';
        }
        
        $marginTop = $settings['marginTop'] ?? 2;
        $marginRight = $settings['marginRight'] ?? 2;
        $marginBottom = $settings['marginBottom'] ?? 2;
        $marginLeft = $settings['marginLeft'] ?? 2;
        
        $styledContent = "
            <html>
            <head>
                <style>
                    @page { 
                        size: {$pageSizeCss}; 
                        margin: {$marginTop}cm {$marginRight}cm {$marginBottom}cm {$marginLeft}cm; 
                    }
                    body { 
                        font-family: "Times New Roman", Times, serif;
                        line-height: 1.5;
                        color: #111827;
                        margin: 0;
                        padding: 0;
                    }
                    p { margin: 0 0 1em 0; }
                    h1, h2, h3, h4, h5, h6 { font-weight: bold; margin-bottom: 0.5em; }
                    strong { font-weight: bold; }
                    em { font-style: italic; }
                    ul, ol { padding-left: 1.5em; margin-bottom: 1em; }
                    .ql-align-center { text-align: center; }
                    .ql-align-right { text-align: right; }
                    .ql-align-justify { text-align: justify; }
                    table { 
                        width: 100%; 
                        table-layout: fixed; 
                        border-collapse: collapse; 
                        margin-bottom: 1em; 
                        border: none !important; 
                    }
                    table tr, table td, table th, table tbody, table thead { 
                        border: none !important; 
                        padding: 0.5em; 
                        vertical-align: top; 
                    }
                </style>
            </head>
            <body>
                {$content}
            </body>
            </html>
        ";
        
        $pdf = Pdf::loadHTML($styledContent);
        
        return $pdf->download('Kontrak_' . str_replace(' ', '_', $employee->full_name) . '.pdf');
    }
}
