<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class PayrollResource extends JsonResource
{
    /**
     * Transform the resource into an array.
     *
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'employee' => new EmployeeResource($this->whenLoaded('employee')),
            'period_month' => $this->period_month,
            'period_year' => $this->period_year,
            'period_label' => date('F Y', mktime(0, 0, 0, $this->period_month, 1, $this->period_year)),
            'basic_salary' => $this->basic_salary,
            'allowances' => $this->allowances,
            'overtime_pay' => $this->overtime_pay,
            // Mirror Excel: Use stored Gross
            'gross_salary' => $this->gross_salary, 
            'deductions' => $this->deductions,
            'bpjs_health' => $this->bpjs_health,
            'tax_pph21' => $this->tax_pph21,
            
            // Mirror Excel: Use stored Total Deductions (Column 31)
            'total_deductions' => $this->total_deductions,
            
            // Mirror Excel: Use stored Net Salary (Column 33)
            'net_salary' => $this->net_salary,
            
            'status' => $this->status,
            'paid_at' => $this->paid_at?->toISOString(),
            'created_at' => $this->created_at?->toISOString(),
        ];
    }
}
