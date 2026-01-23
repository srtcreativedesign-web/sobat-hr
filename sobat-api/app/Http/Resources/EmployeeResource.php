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
            'employee_code' => $this->employee_code,
            'employee_number' => $this->employee_code, // Keep for backward compatibility
            'full_name' => $this->full_name,
            'email' => $this->email,
            'phone' => $this->phone,
            'address' => $this->address,
            'date_of_birth' => $this->date_of_birth?->format('Y-m-d'),
            'join_date' => $this->join_date?->format('Y-m-d'),
            'join_date_edit_count' => $this->join_date_edit_count ?? 0,
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
            // Extra fields
            'place_of_birth' => $this->place_of_birth,
            'ktp_address' => $this->ktp_address,
            'current_address' => $this->current_address,
            'gender' => $this->gender,
            'religion' => $this->religion,
            'marital_status' => $this->marital_status,
            'ptkp_status' => $this->ptkp_status,
            'nik' => $this->nik,
            'npwp' => $this->npwp,
            'bank_account_number' => $this->bank_account_number,
            'bank_account_name' => $this->bank_account_name,
            'father_name' => $this->father_name,
            'mother_name' => $this->mother_name,
            'spouse_name' => $this->spouse_name,
            'family_contact_number' => $this->family_contact_number,
            'education' => $this->education,
            'supervisor_name' => $this->supervisor_name,
            'supervisor_position' => $this->supervisor_position,
            'photo_path' => $this->photo_path,
            'face_photo_path' => $this->face_photo_path,
        ];
    }
}
