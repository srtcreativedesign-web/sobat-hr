<?php

namespace App\Services;

use App\Models\Employee;
use App\Models\User;

class ApprovalHierarchyService
{
    /**
     * Determine approval steps based on employee level and department.
     *
     * @param Employee $requester
     * @return array
     */
    public function getApprovalSteps(Employee $requester): array
    {
        $steps = [];
        $jobLevel = strtolower($requester->job_level ?? '');
        
        // Determine Track: Operational vs Office
        // Operational: crew, spv, manager divisi, HRD
        // Office: staff, spv, manager, deputy manager, HRD
        $isOperational = in_array($jobLevel, ['crew']); // Simple heuristic

        // HRD is always the final step
        $hrdId = $this->findApprover($requester, 'hrd', false);
        
        if (! $hrdId) {
            // Fallback: Find Manager of HRD department if no explicit 'hrd' level
            $hrdId = Employee::where('department', 'HRD')
                ->whereIn('job_level', ['manager', 'manager_divisi'])
                ->value('id');
        }
        
        // Fallback: Super Admin must be HRD
        if (! $hrdId) {
            $superAdmin = User::whereHas('role', fn ($q) => $q->where('name', 'super_admin'))
                ->with('employee')
                ->first();
            $hrdId = $superAdmin?->employee?->id;
        }

        // --- Logic Implementation ---

        // 1. If Requester is SPV
        if ($jobLevel === 'spv') {
            // Step 1: Manager (Direct)
            if ($isOperational) {
                // Operational: Manager Divisi
                $managerId = $this->findApprover($requester, 'manager_divisi', true);
                if (! $managerId) {
                    $managerId = $this->findApprover($requester, 'manager', true);
                }
            } else {
                // Office: Manager or Deputy Manager
                $managerId = $this->findApprover($requester, 'manager', true);
                if (! $managerId) {
                    $managerId = $this->findApprover($requester, 'deputy_manager', true);
                }
            }
            if ($managerId) {
                $steps[] = $managerId;
            }

            // Step 2: HRD / Super Admin (Final)
            if ($hrdId) {
                $steps[] = $hrdId;
            }
        }
        // 2. If Requester is Manager (or Manager Divisi, Deputy Manager)
        elseif (in_array($jobLevel, ['manager', 'manager_divisi', 'deputy_manager'])) {
            // Step 1: HRD / Super Admin (Direct)
            if ($hrdId) {
                $steps[] = $hrdId;
            }
        }
        // 3. Default Logic (Crew, Staff, Team Leader, etc)
        elseif (in_array($jobLevel, ['crew', 'staff', 'team_leader'])) {
            // Step 1: SPV
            $spvId = $this->findApprover($requester, 'spv', true);
            if ($spvId) {
                $steps[] = $spvId;
            }

            // Step 2: Manager
            if ($isOperational) {
                $managerId = $this->findApprover($requester, 'manager_divisi', true);
                if (! $managerId) {
                    $managerId = $this->findApprover($requester, 'manager', true);
                }
            } else {
                $managerId = $this->findApprover($requester, 'manager', true);
                if (! $managerId) {
                    $managerId = $this->findApprover($requester, 'deputy_manager', true);
                }
            }
            if ($managerId) {
                $steps[] = $managerId;
            }

            // Step 3: HRD (Final)
            if ($hrdId) {
                $steps[] = $hrdId;
            }
        }
        // 4. Fallback for others (Director, etc) - Direct to HRD
        else {
            if ($hrdId) {
                $steps[] = $hrdId;
            }
        }

        // Remove duplicates and self-approval
        $steps = array_unique($steps);
        $steps = array_filter($steps, fn ($id) => $id != $requester->id);

        return array_values($steps);
    }

    /**
     * Helper to find employee by level.
     *
     * @param Employee $requester
     * @param string $level
     * @param bool $sameDepartment
     * @return int|null
     */
    private function findApprover(Employee $requester, string $level, bool $sameDepartment = true): ?int
    {
        $query = Employee::where('job_level', $level)
            ->where('status', 'active');

        if ($sameDepartment && $requester->department) {
            $query->where('department', $requester->department);
        }

        $approver = $query->inRandomOrder()->value('id');

        if (! $approver && $sameDepartment) {
            $approver = Employee::where('job_level', $level)
                ->where('status', 'active')
                ->inRandomOrder()
                ->value('id');
        }

        return $approver;
    }
}
