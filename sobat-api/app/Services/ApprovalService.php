<?php

namespace App\Services;

use App\Models\Approval;
use App\Models\Employee;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class ApprovalService
{
    /**
     * Generate step-by-step approvals
     * 
     * @param Model $request The request model (LeaveRequest, etc)
     * @param array $approverIds List of employee IDs in order [Level 1, Level 2...]
     */
    public function createApprovalSteps(Model $request, array $approverIds)
    {
        DB::transaction(function () use ($request, $approverIds) {
            foreach ($approverIds as $index => $approverId) {
                Approval::create([
                    'approvable_type' => get_class($request),
                    'approvable_id' => $request->id,
                    'approver_id' => $approverId,
                    'level' => $index + 1,
                    'status' => 'pending'
                ]);
            }
            
            // Set initial step
            $request->update(['step_now' => 1]);

            // Notification to Level 1 Approver
            if (isset($approverIds[0])) {
                $approver = Employee::find($approverIds[0]);
                if ($approver && $approver->user) {
                    try {
                        $approver->user->notify(new \App\Notifications\RequestNotification($request, 'pending'));
                    } catch (\Exception $e) {
                         Log::error("Failed to notify approver: " . $e->getMessage());
                    }
                }
            }
        });
    }

    /**
     * Execute Approval Logic
     */
    public function approve(Model $request, Employee $actor, ?string $signature = null, ?string $note = null)
    {
        return DB::transaction(function () use ($request, $actor, $signature, $note) {
            // 1. Find the pending approval step for this actor
            $currentStep = Approval::where('approvable_type', get_class($request))
                ->where('approvable_id', $request->id)
                ->where('approver_id', $actor->id)
                ->where('status', 'pending')
                ->first();

            if (!$currentStep) {
                // Check if already approved?
                $alreadyApproved = Approval::where('approvable_type', get_class($request))
                    ->where('approvable_id', $request->id)
                    ->where('approver_id', $actor->id)
                    ->where('status', 'approved')
                    ->exists();
                
                if ($alreadyApproved) {
                    throw new \Exception("Anda sudah menyetujui pengajuan ini.");
                }

                throw new \Exception("Unauthorized or Invalid Approval Step. (Anda tidak memiliki akses untuk menyetujui saat ini)");
            }

            // 2. Mark This Step as Approved
            $currentStep->update([
                'status' => 'approved',
                'acted_at' => now(),
                'note' => $note ?? ('Approved by: ' . $actor->full_name),
                'signature' => $signature, 
            ]);

            Log::info("Step Level {$currentStep->level} approved by {$actor->full_name}");

            // 3. Determine Next State
            // Check if there are any remaining pending approvals
            $nextPendingStep = Approval::where('approvable_type', get_class($request))
                ->where('approvable_id', $request->id)
                ->where('status', 'pending')
                ->orderBy('level', 'asc') // Find the lowest level pending
                ->first();

            if ($nextPendingStep) {
                // Still waiting for someone else.
                // Update 'step_now' to point to the lowest pending step level
                // This ensures that if Level 2 approves before Level 1, step_now stays at 1 until Level 1 approves.
                // Once Level 1 approves, step_now moves to the next pending (which might be 3 if 2 is done).
                
                $request->update(['step_now' => $nextPendingStep->level]);
                
                Log::info("Request ID {$request->id} still pending. Step Now set to Level {$nextPendingStep->level}");
                
                // NOTIFY the next pending approver(s)? 
                // In a strictly sequential flow, we notify next. 
                // In parallel, they might have already been notified or we want to re-notify?
                // For now, let's notify the person at 'step_now' if they haven't approved yet.
                
                if ($nextPendingStep->approver && $nextPendingStep->approver->user) {
                     try {
                        // Optional: Check if we just sent them a notification recently to avoid spam
                        $nextPendingStep->approver->user->notify(new \App\Notifications\RequestNotification($request, 'pending'));
                    } catch (\Exception $e) {
                         Log::error("Failed to notify next approver: " . $e->getMessage());
                    }
                }

            } else {
                // All steps approved!
                $request->update(['status' => 'approved']);
                Log::info("Request ID {$request->id} Fully Approved!");
                
                // Hook for Overtime
                if ($request->type === 'overtime' && $request->overtimeDetail) {
                    \App\Models\OvertimeRecord::updateOrCreate(
                        ['request_id' => $request->id],
                        [
                            'employee_id' => $request->employee_id,
                            'date' => $request->start_date,
                            'start_time' => $request->overtimeDetail->start_time,
                            'end_time' => $request->overtimeDetail->end_time,
                            'duration' => $request->overtimeDetail->duration,
                            'reason' => $request->reason,
                            'approved_at' => now(),
                        ]
                    );
                }
            }

            return $request->fresh();
        });
    }

    /**
     * Execute Rejection Logic
     */
    public function reject(Model $request, Employee $actor, string $reason)
    {
        return DB::transaction(function () use ($request, $actor, $reason) {
            $currentStep = Approval::where('approvable_type', get_class($request))
                ->where('approvable_id', $request->id)
                ->where('level', $request->step_now)
                ->where('approver_id', $actor->id)
                ->first();

            if (!$currentStep) {
                throw new \Exception("Unauthorized Rejection.");
            }

            // 1. Mark Current Step Rejected
            $currentStep->update([
                'status' => 'rejected',
                'acted_at' => now(),
                'note' => $reason
            ]);

            // 2. Kill the Request
            $request->update([
                'status' => 'rejected',
                'rejection_reason' => "Rejected at Level {$currentStep->level}: $reason"
            ]);

            // 3. Void Future Steps (Optional but cleaner)
            Approval::where('approvable_type', get_class($request))
                ->where('approvable_id', $request->id)
                ->where('level', '>', $request->step_now)
                ->update(['status' => 'rejected', 'note' => 'Voided due to previous rejection']);

            return $request->fresh();
        });
    }

    /**
     * Determine approvers based on requester's role level
     * 
     * @param Employee $requester The employee submitting the request
     * @return array Array of employee IDs in approval order
     */
    /**
     * Determine approvers based on requester's role level
     * 
     * @param Employee $requester The employee submitting the request
     * @return array Array of employee IDs in approval order
     */
    public function determineApprovers(Employee $requester, ?Model $request = null): array
    {
        $approvers = [];

        // 1. DIRECT SUPERVISOR LOGIC (Priority)
        if ($requester->supervisor_id) {
            Log::info("Using Direct Supervisor Flow for Employee ID: {$requester->id}");
            
            // Step 1: Direct Supervisor
            $approvers[] = $requester->supervisor_id;

            // Step 2: HRD (Final Step)
            // Unless the supervisor IS the HRD, to avoid double approval
            $hrd = $this->findApproverByRoleName('hrd');
            
            // If Supervisor is NOT HRD, add HRD as second step
            if ($hrd && $hrd->id != $requester->supervisor_id) {
                 $approvers[] = $hrd->id;
            }
            
            Log::info("Direct Supervisor Flow Approvers: " . json_encode($approvers));
            return array_unique($approvers);
        }

        // ==========================================
        // FALLBACK: EXISTING ROLE-BASED LOGIC
        // ==========================================

        // Get requester's approval level from their user's role
        $userRoleLevel = $requester->user?->role?->approval_level ?? 0;
        
        // Get requester's organization for finding same-org approvers
        $organizationId = $requester->organization_id;
        
        Log::info("Determining approvers for Employee ID: {$requester->id} ({$requester->full_name}), Role Level: {$userRoleLevel}, Org ID: {$organizationId}, Request Type: " . ($request ? $request->type : 'null'));
        
        // ... (rest of the existing logic)

        // SPECIAL CASE: Sick Leave for Manager Level (Level >= 2)
        // Workflow: COO -> HRD
        if ($userRoleLevel >= 2 && $request && $request->type === 'sick_leave') {
            Log::info("Special Workflow: Sick Leave for Manager");
            $coo = $this->findApproverByRoleName('coo');
            $hrd = $this->findApproverByRoleName('hrd');
            
            if ($coo) {
                $approvers[] = $coo->id;
                Log::info("Found COO: {$coo->id} - {$coo->full_name}");
            } else {
                Log::warning("COO not found for Special Workflow");
            }

            if ($hrd) {
                $approvers[] = $hrd->id;
                Log::info("Found HRD: {$hrd->id} - {$hrd->full_name}");
            } else {
                 Log::warning("HRD not found for Special Workflow");
            }

            return $approvers;
        }
        
        if ($userRoleLevel >= 2) {
            // Manager Divisi level -> Only COO approves
            Log::info("Manager Level Request -> COO Only");
            
            $coo = $this->findApproverByRoleName('coo');
            if ($coo) {
                $approvers[] = $coo->id;
            } else {
                Log::warning("COO not found for Manager Request");
            }
        } elseif ($userRoleLevel == 1) {
            // SPV level -> Manager Divisi + HRD
            Log::info("SPV Level Request -> Manager Divisi + HRD");

            $managerDivisi = $this->findApproverByRoleName('manager_divisi', $organizationId);
            $hrd = $this->findApproverByRoleName('hrd');
            
            if ($managerDivisi) {
                $approvers[] = $managerDivisi->id;
            } else {
                 // Fallback to generic manager if manager_divisi not found?
                 Log::warning("Manager Divisi not found in Org {$organizationId}, trying generic 'manager'");
                 $manager = $this->findApproverByRoleName('manager', $organizationId);
                 if ($manager) $approvers[] = $manager->id;
            }

            if ($hrd) $approvers[] = $hrd->id;
        } else {
            // Staff/Crew/Leader level -> SPV + Manager Divisi + HRD
            Log::info("Staff Level Request -> SPV + Manager + HRD");

            $spv = $this->findApproverByRoleName('spv', $organizationId);
            $managerDivisi = $this->findApproverByRoleName('manager_divisi', $organizationId);
            $hrd = $this->findApproverByRoleName('hrd');
            
            if ($spv) $approvers[] = $spv->id;
            
            if ($managerDivisi) {
                $approvers[] = $managerDivisi->id;
            } else {
                // Fallback
                 $manager = $this->findApproverByRoleName('manager', $organizationId);
                 if ($manager) $approvers[] = $manager->id;
            }

            if ($hrd) $approvers[] = $hrd->id;
        }
        
        Log::info("Final Approvers List: " . json_encode($approvers));
        
        return $approvers;
    }
    
    /**
     * Find an approver by role name, optionally filtered by organization
     */
    private function findApproverByRoleName(string $roleName, ?int $organizationId = null): ?Employee
    {
        Log::info("Searching for approver with role: {$roleName}" . ($organizationId ? " in Org {$organizationId}" : ""));

        // HRD function is handled by Super Admin
        // When looking for 'hrd', also match 'super_admin'
        $roleNames = ($roleName === 'hrd') ? ['hrd', 'super_admin'] : [$roleName];

        $query = Employee::whereHas('user.role', function ($q) use ($roleNames) {
            $q->whereIn('name', $roleNames);
        });
        
        $count = (clone $query)->count();
        Log::info("Found {$count} employees with role(s) " . implode('/', $roleNames) . " (globally)");

        // For SPV and Manager Divisi, try to find someone in the same organization first
        if ($organizationId && in_array($roleName, ['spv', 'manager_divisi', 'manager'])) {
            $sameOrgApprover = (clone $query)->where('organization_id', $organizationId)->first();
            if ($sameOrgApprover) {
                Log::info("Found same-org approver: {$sameOrgApprover->id} - {$sameOrgApprover->full_name}");
                return $sameOrgApprover;
            }
            Log::info("No same-org approver found for {$roleName} in Org {$organizationId}");
        }
        
        // Fallback: get any employee with that role?
        // Maybe for SPV we don't want cross-dept approval? 
        // For now, keep original logic (fallback to first found) or restrict.
        // Original code: return $query->first(); -> This implies cross-dept is allowed as fallback.
        
        $fallback = $query->first();
        if ($fallback) {
             Log::info("Using fallback approver: {$fallback->id} - {$fallback->full_name}");
        } else {
             Log::warning("No approver found at all for role {$roleName}");
        }

        return $fallback;
    }
    
    /**
     * Check if a request can be printed (for manager-level requests pending COO approval)
     */
    public function canPrintRequest(Model $request): bool
    {
        $requester = $request->employee;
        if (!$requester || !$requester->user || !$requester->user->role) {
            return false;
        }
        
        $roleLevel = $requester->user->role->approval_level ?? 0;
        
        // Only manager-level (level 2) requests can be printed before final approval
        return $roleLevel >= 2 && $request->status === 'pending';
    }
}

