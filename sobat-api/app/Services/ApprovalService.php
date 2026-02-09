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
            // 1. Validate Actor
            // Check if actor has admin role
            $isAdmin = false;
            if ($actor->user && $actor->user->role) {
                $roleName = $actor->user->role->name;
                $isAdmin = in_array($roleName, ['super_admin', 'admin_cabang', 'hrd']);
            }
            
            $query = Approval::where('approvable_type', get_class($request))
                ->where('approvable_id', $request->id)
                ->where('level', $request->step_now)
                ->where('status', 'pending');

            // STRICT CHECK: Always enforce that the actor matches the assigned approver
            // This prevents Super Admin from jumping the queue (e.g. approving Level 1 before Manager)
            $query->where('approver_id', $actor->id);
            
            $currentStep = $query->first();

            if (!$currentStep) {
                throw new \Exception("Unauthorized or Invalid Approval Step. (You might not be the current approver)");
            }

            // 2. Mark Current Step as Approved
            $currentStep->update([
                'status' => 'approved',
                'acted_at' => now(),
                'note' => $note ?? ('Approved by: ' . $actor->full_name),
                'signature' => $signature, 
            ]);

            // 3. Check Next Step
            $nextStep = Approval::where('approvable_type', get_class($request))
                ->where('approvable_id', $request->id)
                ->where('level', $request->step_now + 1)
                ->first();

            if ($nextStep) {
                // Move ball forward
                $request->increment('step_now');
                // Trigger Notification for Next Approver here
                Log::info("Approval moved to Level {$nextStep->level} (Approver ID: {$nextStep->approver_id})");
                
                if ($nextStep->approver && $nextStep->approver->user) {
                    try {
                        $nextStep->approver->user->notify(new \App\Notifications\RequestNotification($request, 'pending'));
                    } catch (\Exception $e) {
                        Log::error("Failed to notify next approver: " . $e->getMessage());
                    }
                }
            } else {
                // Finish Line
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

                // Hook for finalizing (e.g., deduct balance)
                // This could be an Event listener
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
    public function determineApprovers(Employee $requester): array
    {
        // Get requester's approval level from their user's role
        $userRoleLevel = $requester->user?->role?->approval_level ?? 0;
        
        // Get requester's organization for finding same-org approvers
        $organizationId = $requester->organization_id;
        
        Log::info("Determining approvers for Employee ID: {$requester->id}, Role Level: {$userRoleLevel}, Org ID: {$organizationId}");
        
        $approvers = [];
        
        if ($userRoleLevel >= 2) {
            // Manager Divisi level -> Only COO approves
            $coo = $this->findApproverByRoleName('coo');
            if ($coo) {
                $approvers[] = $coo->id;
            }
        } elseif ($userRoleLevel == 1) {
            // SPV level -> Manager Divisi + HRD
            $managerDivisi = $this->findApproverByRoleName('manager_divisi', $organizationId);
            $hrd = $this->findApproverByRoleName('hrd');
            
            if ($managerDivisi) $approvers[] = $managerDivisi->id;
            if ($hrd) $approvers[] = $hrd->id;
        } else {
            // Staff/Crew/Leader level -> SPV + Manager Divisi + HRD
            $spv = $this->findApproverByRoleName('spv', $organizationId);
            $managerDivisi = $this->findApproverByRoleName('manager_divisi', $organizationId);
            $hrd = $this->findApproverByRoleName('hrd');
            
            if ($spv) $approvers[] = $spv->id;
            if ($managerDivisi) $approvers[] = $managerDivisi->id;
            if ($hrd) $approvers[] = $hrd->id;
        }
        
        Log::info("Determined approvers: " . json_encode($approvers));
        
        return $approvers;
    }
    
    /**
     * Find an approver by role name, optionally filtered by organization
     */
    private function findApproverByRoleName(string $roleName, ?int $organizationId = null): ?Employee
    {
        $query = Employee::whereHas('user.role', function ($q) use ($roleName) {
            $q->where('name', $roleName);
        });
        
        // For SPV and Manager Divisi, try to find someone in the same organization first
        if ($organizationId && in_array($roleName, ['spv', 'manager_divisi'])) {
            $sameOrgApprover = (clone $query)->where('organization_id', $organizationId)->first();
            if ($sameOrgApprover) {
                return $sameOrgApprover;
            }
        }
        
        // Fallback: get any employee with that role
        return $query->first();
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

