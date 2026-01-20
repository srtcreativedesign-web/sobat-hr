<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\ContractTemplate;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Artisan;

class ContractTemplateController extends Controller
{
    /**
     * Get the active contract template.
     */
    public function index()
    {
        $template = ContractTemplate::where('is_active', true)->first();

        // If no template exists (shouldn't happen if seeded), return default structure
        if (!$template) {
            return response()->json([
                'content' => '',
                'variables' => $this->getAvailableVariables()
            ]);
        }

        return response()->json([
            'content' => $template->content,
            'variables' => $this->getAvailableVariables()
        ]);
    }

    /**
     * Update the contract template content.
     */
    public function update(Request $request)
    {
        $request->validate([
            'content' => 'required|string',
        ]);

        $template = ContractTemplate::where('is_active', true)->first();

        if ($template) {
            $template->update(['content' => $request->content]);
        } else {
            $template = ContractTemplate::create([
                'name' => 'Custom Template',
                'content' => $request->content,
                'is_active' => true
            ]);
        }

        return response()->json([
            'message' => 'Template updated successfully',
            'content' => $template->content
        ]);
    }

    /**
     * Restore the default template from seed.
     */
    public function restore()
    {
        // Re-run the seeder logic to reset
        // For simplicity, we can just grab the content from a known source or hardcode the default here again
        // Or simpler: truncate and re-seed
        
        ContractTemplate::truncate();
        Artisan::call('db:seed', ['--class' => 'ContractTemplateSeeder']);

        $template = ContractTemplate::first();

        return response()->json([
            'message' => 'Template restored to default',
            'content' => $template->content
        ]);
    }

    /**
     * List available placeholder variables for the frontend.
     */
    private function getAvailableVariables()
    {
        return [
            '[CONTRACT_NUMBER]' => 'Contract Number (e.g. PKWT/2026/EMP-001)',
            '[DAY_NAME]' => 'Day Name (e.g. Senin)',
            '[DATE_DAY]' => 'Day of Month (e.g. 20)',
            '[DATE_MONTH]' => 'Month Name (e.g. Januari)',
            '[DATE_YEAR]' => 'Year (e.g. 2026)',
            '[EMPLOYEE_NAME]' => 'Employee Full Name',
            '[EMPLOYEE_CODE]' => 'Employee NIK/Code',
            '[EMPLOYEE_POSITION]' => 'Employee Job Position',
            '[EMPLOYEE_ADDRESS]' => 'Employee KTP Address',
            '[DEPARTMENT_NAME]' => 'Organization/Division Name',
            '[DURATION_MONTHS]' => 'Contract Duration in Months',
            '[START_DATE]' => 'Contract Start Date',
            '[END_DATE]' => 'Contract End Date',
        ];
    }
}
