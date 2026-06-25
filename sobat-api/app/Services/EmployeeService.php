<?php

namespace App\Services;

use App\Models\Employee;
use Illuminate\Http\Request;
use App\Models\Division;
use App\Models\JobPosition;

class EmployeeService
{
    /**
     * Map validated request data into an array suitable for database insertion/update.
     *
     * @param array $validated
     * @param Request|null $request
     * @return array
     */
    public function mapEmployeeData(array $validated, ?Request $request = null): array
    {
        $data = [];
        if (isset($validated['user_id'])) $data['user_id'] = $validated['user_id'];
        if (isset($validated['role_id'])) $data['role_id'] = $validated['role_id'];
        
        // support both employee_number and employee_code from clients
        if (isset($validated['employee_number'])) $data['employee_code'] = $validated['employee_number'];
        if (isset($validated['employee_code'])) $data['employee_code'] = $validated['employee_code'];
        
        if (isset($validated['full_name'])) $data['full_name'] = $validated['full_name'];
        if (isset($validated['email'])) $data['email'] = $validated['email'];
        if (isset($validated['phone'])) $data['phone'] = $validated['phone'];
        if (isset($validated['address'])) $data['address'] = $validated['address'];
        
        if (isset($validated['date_of_birth'])) $data['birth_date'] = $validated['date_of_birth'];
        if (isset($validated['birth_date'])) $data['birth_date'] = $validated['birth_date'];
        
        if (isset($validated['join_date'])) $data['join_date'] = $validated['join_date'];
        if (isset($validated['position'])) $data['position'] = $validated['position'];
        if (isset($validated['level'])) $data['level'] = $validated['level'];
        
        if (isset($validated['base_salary'])) $data['basic_salary'] = $validated['base_salary'];
        if (isset($validated['basic_salary'])) $data['basic_salary'] = $validated['basic_salary'];
        
        if (isset($validated['mandatory_overtime_amount'])) $data['mandatory_overtime_amount'] = $validated['mandatory_overtime_amount'];
        if (isset($validated['contract_end_date'])) $data['contract_end_date'] = $validated['contract_end_date'];
        
        if (isset($validated['contract_type'])) $data['employment_status'] = $validated['contract_type'];
        if (isset($validated['employment_status'])) $data['employment_status'] = $validated['employment_status'];
        
        if (isset($validated['status'])) $data['status'] = $validated['status'];
        if (isset($validated['job_level'])) $data['job_level'] = $validated['job_level'];
        if (isset($validated['track'])) $data['track'] = $validated['track'];

        // Handle Master Data logic
        if (isset($validated['division_id'])) {
            $data['division_id'] = $validated['division_id'];
            $div = Division::find($validated['division_id']);
            if ($div) $data['department'] = $div->name;
        }
        
        if (isset($validated['job_position_id'])) {
            $data['job_position_id'] = $validated['job_position_id'];
            $pos = JobPosition::find($validated['job_position_id']);
            if ($pos) {
                $data['position'] = $pos->name;
                $data['job_level'] = (string)$pos->level;
            }
        }

        // Additional fields
        $extraFields = [
            'place_of_birth', 'ktp_address', 'current_address', 'gender', 'religion',
            'marital_status', 'ptkp_status', 'nik', 'npwp', 'bank_account_number',
            'bank_account_name', 'father_name', 'mother_name', 'spouse_name',
            'family_contact_number', 'education', 'leave_quota', 'supervisor_name',
            'supervisor_position', 'supervisor_id', 'department', 'photo_path'
        ];
        foreach ($extraFields as $f) {
            if (isset($validated[$f])) {
                $data[$f] = $validated[$f];
            }
        }

        // Apply defaults for new employee creation if request is passed
        if ($request && $request->isMethod('post')) {
            $this->applyCreationDefaults($data, $request);
        }

        return $data;
    }

    /**
     * Apply default values for a new employee.
     */
    private function applyCreationDefaults(array &$data, Request $request)
    {
        if (empty($data['user_id'])) {
            $authUser = $request->user();
            if ($authUser) {
                $data['user_id'] = $authUser->id;
            }
        }

        if (empty($data['employee_code'])) {
            $authUser = $request->user();
            $uid = $data['user_id'] ?? ($authUser ? $authUser->id : null);
            $prefix = $uid ? ('EMP' . $uid . '-') : 'EMP-';
            $data['employee_code'] = $prefix . substr(uniqid(), -6);
        }

        if (empty($data['division_id'])) {
            $defaultDiv = Division::first();
            if ($defaultDiv) {
                $data['division_id'] = $defaultDiv->id;
            }
        }

        if (empty($data['position'])) {
            $data['position'] = '-';
        }
        if (empty($data['join_date'])) {
            $data['join_date'] = now()->toDateString();
        }
    }
}
