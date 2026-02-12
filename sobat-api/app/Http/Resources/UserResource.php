<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class UserResource extends JsonResource
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
            'name' => $this->name,
            'email' => $this->email,
            'role' => new RoleResource($this->whenLoaded('role')),
            'employee' => new EmployeeResource($this->whenLoaded('employee')),
            'approval_level' => max(
                $this->whenLoaded('role')?->approval_level ?? 0,
                $this->whenLoaded('employee')?->jobPosition?->level ?? 0
            ),
            'has_pin' => $this->has_pin,
            'created_at' => $this->created_at?->toISOString(),
        ];
    }
}
