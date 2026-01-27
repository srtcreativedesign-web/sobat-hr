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

            if (!$isAdmin) {
                // strict check
                $query->where('approver_id', $actor->id);
            }
            
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
            } else {
                // Finish Line
                $request->update(['status' => 'approved']);
                Log::info("Request ID {$request->id} Fully Approved!");
                
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
}
