<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class EmployeeResource extends JsonResource
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
            'employee_number' => $this->employee_number,
            'full_name' => $this->full_name,
            'email' => $this->email,
            'phone' => $this->phone,
            'address' => $this->address,
            'date_of_birth' => $this->date_of_birth?->format('Y-m-d'),
            'join_date' => $this->join_date?->format('Y-m-d'),
            'position' => $this->position,
            'department' => $this->department,
            'base_salary' => $this->base_salary,
            'status' => $this->status,
            'track' => $this->track, // 'office' or 'operational'
            'contract_type' => $this->contract_type,
            'contract_end_date' => $this->contract_end_date?->format('Y-m-d'),
            'organization' => new OrganizationResource($this->whenLoaded('organization')),
            'role' => new RoleResource($this->whenLoaded('role')),
            'shift' => new ShiftResource($this->whenLoaded('shift')),
            'user' => new UserResource($this->whenLoaded('user')),
            'created_at' => $this->created_at?->toISOString(),
            'updated_at' => $this->updated_at?->toISOString(),
        ];
    }
}
