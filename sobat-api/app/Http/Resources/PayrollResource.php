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
            'base_salary' => $this->base_salary,
            'allowances' => $this->allowances,
            'overtime_pay' => $this->overtime_pay,
            'gross_salary' => $this->base_salary + $this->allowances + $this->overtime_pay,
            'deductions' => $this->deductions,
            'bpjs_health' => $this->bpjs_health,
            'bpjs_employment' => $this->bpjs_employment,
            'tax_pph21' => $this->tax_pph21,
            'total_deductions' => $this->deductions + $this->bpjs_health + $this->bpjs_employment + $this->tax_pph21,
            'net_salary' => $this->net_salary,
            'status' => $this->status,
            'paid_at' => $this->paid_at?->toISOString(),
            'created_at' => $this->created_at?->toISOString(),
        ];
    }
}
