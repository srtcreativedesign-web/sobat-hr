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
     * Determine approvers based on requester's track and division
     * 
     * @param Employee $requester The employee submitting the request
     * @return array Array of employee IDs in approval order
     */
    public function determineApprovers(Employee $requester, ?Model $request = null): array
    {
        $approvers = [];
        $divisionId = $requester->division_id;
        $track = strtolower($requester->track ?? 'office'); // Default to office if null

        Log::info("Determining approvers for Employee ID: {$requester->id} ({$requester->full_name}), Track: {$track}, Division ID: {$divisionId}");

        // Step 1: Supervisor (Priority if exists)
        if ($requester->supervisor_id) {
            $approvers[] = $requester->supervisor_id;
            Log::info("Added Direct Supervisor: {$requester->supervisor_id}");
        } else {
            // If no direct supervisor, use SPV as first step (common for both tracks)
            $spv = $this->findApproverByRoleName('spv', $divisionId);
            if ($spv) {
                $approvers[] = $spv->id;
                Log::info("Found SPV: {$spv->id} - {$spv->full_name}");
            }
        }

        // Step 2: Manager Level (Track Specific)
        if ($track === 'operational') {
            // Operational Track: Manager Divisi
            $managerDivisi = $this->findApproverByRoleName('manager_divisi', $divisionId);
            if ($managerDivisi) {
                $approvers[] = $managerDivisi->id;
                Log::info("Found Manager Divisi (Operational): {$managerDivisi->id}");
            }
        } else {
            // Office Track: Assistant Manager / Deputy Manager / Manager Operasional
            // We search for any of these roles in the same division
            $officeManagerRoles = ['assistant_manager', 'deputy_manager', 'manager_operasional', 'manager'];
            $officeManager = $this->findApproverByRoleName($officeManagerRoles, $divisionId);
            if ($officeManager) {
                $approvers[] = $officeManager->id;
                Log::info("Found Office Manager ({$officeManager->user->role->name}): {$officeManager->id}");
            }
        }

        // Step 3: HRD (Final Step)
        $hrd = $this->findApproverByRoleName('hrd');
        if ($hrd) {
            $approvers[] = $hrd->id;
            Log::info("Found HRD: {$hrd->id}");
        }

        // --- Final Cleanup ---
        // 1. Remove duplicates
        $approvers = array_values(array_unique($approvers));
        
        // 2. Remove requester themselves from approval chain
        $approvers = array_filter($approvers, fn($id) => $id != $requester->id);

        Log::info("Final Approvers List for {$requester->full_name}: " . json_encode($approvers));
        
        return array_values($approvers);
    }
    
    /**
     * Find an approver by role name(s), strictly filtered by division
     * 
     * @param string|array $roleName Single role name or array of role names
     * @param int|null $divisionId Division to filter by
     */
    private function findApproverByRoleName($roleName, ?int $divisionId = null): ?Employee
    {
        $roleNames = is_array($roleName) ? $roleName : [$roleName];
        
        // HRD fallback to Super Admin
        if (in_array('hrd', $roleNames)) {
            $roleNames[] = 'super_admin';
            $roleNames[] = 'hr'; // Sometimes used interchangeably
        }

        $query = Employee::whereHas('user.role', function ($q) use ($roleNames) {
            $q->whereIn('name', $roleNames);
        })->with('user.role')->where('status', 'active');

        // Apply Division Filter
        if ($divisionId) {
            $query->where('division_id', $divisionId);
        }

        // For HRD and Super Admin, if not found in same division, search globally
        // (HRD is often centralized)
        if ($divisionId && in_array('hrd', $roleNames)) {
            $approver = (clone $query)->first();
            if ($approver) return $approver;
            
            // Fallback to global HRD/Super Admin
            Log::info("No HRD found in Division {$divisionId}, searching globally.");
            return Employee::whereHas('user.role', function ($q) {
                $q->whereIn('name', ['hrd', 'super_admin', 'hr']);
            })->where('status', 'active')->first();
        }

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

