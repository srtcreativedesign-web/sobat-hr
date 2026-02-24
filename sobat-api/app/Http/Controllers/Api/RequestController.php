<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\RequestModel;
use App\Models\Approval;
use Illuminate\Support\Facades\Notification;
use Illuminate\Support\Facades\DB;
use App\Notifications\RequestNotification;
use Barryvdh\DomPDF\Facade\Pdf;

class RequestController extends Controller
{
    public function index(Request $request)
    {
        $user = $request->user();
        $query = RequestModel::with(['employee.organization', 'approvals']);
        
        
        \Illuminate\Support\Facades\Log::info('Request Index Params:', $request->all());

        // Check Role
        $roleName = $user->role ? $user->role->name : '';
        $isAdmin = in_array($roleName, ['super_admin', 'admin_cabang', 'hrd']);
        
        \Illuminate\Support\Facades\Log::info('User Info:', ['id' => $user->id, 'role' => $roleName, 'isAdmin' => $isAdmin]);

        if (!$isAdmin) {
            if (!$user->employee) {
                return response()->json([]);
            }
            $query->where('employee_id', $user->employee->id);
        }

        if ($request->has('employee_id')) {
            $query->where('employee_id', $request->employee_id);
        }

        if ($request->has('type')) {
            $query->where('type', $request->type);
        }

        if ($request->has('organization_id')) {
            $orgId = $request->organization_id;
            $query->whereHas('employee', function($q) use ($orgId) {
                $q->where('organization_id', $orgId);
            });
        }

        if ($request->has('search')) {
            $search = $request->search;
            $query->whereHas('employee', function($q) use ($search) {
                $q->where('full_name', 'like', "%{$search}%")
                  ->orWhere('employee_code', 'like', "%{$search}%");
            });
        }

        if ($request->has('status')) {
            $status = $request->status;
            if (str_contains($status, ',')) {
                $query->whereIn('status', explode(',', $status));
            } else {
                $query->where('status', $status);
            }
        }
        
        \Illuminate\Support\Facades\Log::info('SQL:', [$query->toSql(), $query->getBindings()]);
        \Illuminate\Support\Facades\Log::info('Count:', [$query->count()]);

        $requests = $query->orderBy('created_at', 'desc')->paginate(20);

        return response()->json($requests);
    }

    public function store(Request $request, \App\Services\ApprovalService $approvalService)
    {
        $user = $request->user();
        if (!$user->employee) {
             return response()->json(['message' => 'User is not linked to an employee record'], 403);
        }

        // Merge employee_id
        $request->merge(['employee_id' => $user->employee->id]);

        // Validate Master Data
        // Note: added business_trip, sick_leave to allowed types
        $validated = $request->validate([
            'employee_id' => 'required|exists:employees,id',
            'type' => 'required|in:leave,sick_leave,overtime,reimbursement,business_trip,resignation,asset',
            'title' => 'required|string|max:255',
            'description' => 'required|string',
            'reason' => 'nullable|string', // Optional override
            // Specific fields can be validated here or manually pulled
            'start_date' => 'nullable|date',
            'end_date' => 'nullable|date',
            'date' => 'nullable|date', // for overtime/reimbursement
            'start_time' => 'nullable', // time string
            'end_time' => 'nullable', // time string
            'duration' => 'nullable|integer',
            'amount' => 'nullable|numeric',
            'budget' => 'nullable|numeric',
            'destination' => 'nullable|string',
            'attachments' => 'nullable|json',
            // Asset fields
            'brand' => 'nullable|string',
            'specification' => 'nullable|string',
            'is_urgent' => 'nullable|boolean',
            // Resignation fields
            'last_working_date' => 'nullable|date',
        ]);

        // Prevent Double Submission using Atomic Lock
        $lockKey = 'submit_request_' . $user->id;
        $lock = \Illuminate\Support\Facades\Cache::lock($lockKey, 10); // Lock for 10 seconds

        if (!$lock->get()) {
             return response()->json(['message' => 'Sedang memproses permintaan sebelumnya. Mohon tunggu.'], 429);
        }

        try {
            return DB::transaction(function () use ($validated, $request, $approvalService, $user) {
                // 1. Create Master Request
                $masterData = [
                    'employee_id' => $validated['employee_id'],
                    'type' => $validated['type'],
                    'title' => $validated['title'],
                    'description' => $validated['description'],
                    'reason' => $validated['reason'] ?? $validated['description'],
                    'status' => 'draft',
                    // Populate summary fields for backward compatibility (List View)
                    'start_date' => $validated['start_date'] ?? $validated['date'] ?? null,
                    'end_date' => $validated['end_date'] ?? $validated['date'] ?? null,
                    'amount' => $validated['amount'] ?? $validated['budget'] ?? (($validated['duration'] ?? 0) ? ($validated['duration']/60) : null), 
                    'attachments' => $validated['attachments'] ?? null,
                ];

                $requestModel = RequestModel::create($masterData);

                // 2. Create Detail based on Type
                switch ($validated['type']) {
                    case 'leave':
                        // 1. Check Eligibility (1 Year Service)
                        if (!$user->employee->join_date || $user->employee->join_date->diffInYears(now()) < 1) {
                            throw new \Illuminate\Validation\ValidationException(\Illuminate\Support\Facades\Validator::make([], [
                                'type' => 'Anda belum bekerja selama 1 tahun, belum berhak mengajukan cuti tahunan.',
                            ]));
                        }

                        // 2. Calculate Duration
                        $startDate = \Carbon\Carbon::parse($request->start_date);
                        $endDate = \Carbon\Carbon::parse($request->end_date);
                        $duration = $startDate->diffInDays($endDate) + 1; // Inclusive

                        // 3. Check Quota
                        $quota = 12;
                        $used = RequestModel::where('employee_id', $user->employee->id)
                            ->where('type', 'leave')
                            ->where('status', 'approved')
                            ->whereYear('start_date', now()->year)
                            ->get()
                            ->sum(function ($req) {
                                if ($req->amount > 0) return $req->amount;
                                if ($req->start_date && $req->end_date) {
                                    return $req->start_date->diffInDays($req->end_date) + 1;
                                }
                                return 0;
                            });

                        if (($used + $duration) > $quota) {
                            return response()->json([
                                'message' => 'Sisa cuti tidak mencukupi.',
                                'details' => [
                                    'quota' => $quota,
                                    'used' => $used,
                                    'requested' => $duration,
                                    'remaining' => max(0, $quota - $used)
                                ]
                            ], 422);
                        }

                        // Update Master Data Amount (Days)
                        $requestModel->update(['amount' => $duration]);

                        \App\Models\LeaveDetail::create([
                            'request_id' => $requestModel->id,
                            'start_date' => $request->start_date,
                            'end_date' => $request->end_date,
                            'amount' => $duration, // days
                            'reason' => $request->description,
                        ]);
                        break;
                    
                    case 'sick_leave':
                        if (!$request->attachments) {
                             throw new \Illuminate\Validation\ValidationException(\Illuminate\Support\Facades\Validator::make([], [
                                'attachments' => 'Surat dokter wajib diupload untuk pengajuan sakit.',
                            ]));
                        }
                        \App\Models\SickLeaveDetail::create([
                            'request_id' => $requestModel->id,
                            'start_date' => \Carbon\Carbon::parse($request->start_date)->format('Y-m-d'),
                            'end_date' => \Carbon\Carbon::parse($request->end_date)->format('Y-m-d'),
                            'reason' => $request->description,
                            'attachment' => $request->attachments ? json_decode($request->attachments, true) : null,
                        ]);
                        break;

                    case 'overtime':
                        \App\Models\OvertimeDetail::create([
                            'request_id' => $requestModel->id,
                            'date' => $request->start_date ?? $request->date, // Mobile sends start_date usually
                            'start_time' => $request->start_time,
                            'end_time' => $request->end_time,
                            'duration' => $request->duration,
                            'reason' => $request->description,
                        ]);
                        break;

                    case 'business_trip':
                        \App\Models\BusinessTripDetail::create([
                            'request_id' => $requestModel->id,
                            'destination' => $request->destination ?? $request->title,
                            'start_date' => $request->start_date,
                            'end_date' => $request->end_date,
                            'purpose' => $request->description,
                            'budget' => $request->amount, // Map amount to budget
                        ]);
                        break;

                    case 'reimbursement': // Reimburse Medis/Transport/Etc
                         \App\Models\ReimbursementDetail::create([
                            'request_id' => $requestModel->id,
                            // 'type' removed from schema, rely on title for now or add subtype later if needed
                            'date' => $request->date ?? $request->start_date,
                            'title' => $request->title,
                            'description' => $request->description,
                            'amount' => $request->amount,
                            'attachment' => $request->attachments ? json_decode($request->attachments, true) : null,
                        ]);
                        break;

                    case 'asset': // Pengajuan Aset
                         \App\Models\AssetDetail::create([
                            'request_id' => $requestModel->id,
                            'brand' => $request->brand,
                            'specification' => $request->specification,
                            'amount' => $request->amount, // Estimasi Harga
                            'is_urgent' => $request->boolean('is_urgent'),
                            'reason' => $request->reason ?? $request->description,
                            'attachment' => $request->attachments ? json_decode($request->attachments, true) : null,
                        ]);
                        break;
                    
                    case 'resignation':
                         \App\Models\ResignationDetail::create([
                            'request_id' => $requestModel->id,
                            'last_working_date' => $request->last_working_date,
                             // Default to normal for now, can be expanded later
                            'resign_type' => 'normal',
                        ]);
                        break;
                }

                // 3. Auto-Submit Logic - Use ApprovalService to determine approvers based on role
                $approverIds = $approvalService->determineApprovers($user->employee, $requestModel);

                if (empty($approverIds)) {
                     // Fallback 1: Super Admin
                     $superAdmins = \App\Models\User::whereHas('role', function($q){
                         $q->where('name', 'super_admin');
                     })->with('employee')->get()->pluck('employee.id')->filter()->toArray();
                     
                     if (!empty($superAdmins)) {
                         $approverIds = array_unique($superAdmins);
                     }
                }

                // Fallback 2: Force assign to HRD or COO if specific IDs known (from Seeder)
                if (empty($approverIds)) {
                    $hrdCode = \App\Models\Employee::where('employee_code', 'HRD001')->value('id');
                    if ($hrdCode) $approverIds[] = $hrdCode;
                    else {
                        $cooCode = \App\Models\Employee::where('employee_code', 'COO001')->value('id');
                        if ($cooCode) $approverIds[] = $cooCode;
                    }
                }

                if (!empty($approverIds)) {
                    $approvalService->createApprovalSteps($requestModel, $approverIds);
                    $requestModel->status = 'pending';
                    $requestModel->submitted_at = now();
                } else {
                    // Critical Failure: No approvers could be determined.
                    // Revert to DRAFT so user knows it failed to submit.
                    // Or throw error? Throwing error rolls back transaction, which is better.
                    throw new \Exception("Gagal mengirim pengajuan: Tidak dapat menentukan approver (Penyetuju). Silakan hubungi HRD.");
                }

                $requestModel->save();

                return response()->json($requestModel->load('approvals'), 201);
            });
        } finally {
            $lock->release();
        }
    }

    public function show(string $id)
    {
        $requestModel = RequestModel::with(['employee', 'approvals.approver'])->findOrFail($id);
        return response()->json($requestModel);
    }

    public function update(Request $request, string $id)
    {
        $requestModel = RequestModel::findOrFail($id);

        // Only allow updates if status is draft
        if ($requestModel->status !== 'draft') {
            return response()->json([
                'message' => 'Cannot update request that has been submitted'
            ], 422);
        }

        $validated = $request->validate([
            'title' => 'sometimes|string|max:255',
            'description' => 'sometimes|string',
            'start_date' => 'nullable|date',
            'end_date' => 'nullable|date',
            'amount' => 'nullable|numeric',
            'attachments' => 'nullable|json',
        ]);

        $requestModel->update($validated);

        return response()->json($requestModel);
    }

    public function destroy(string $id)
    {
        $requestModel = RequestModel::findOrFail($id);
        
        // Only allow deletion if status is draft or rejected
        if (!in_array($requestModel->status, ['draft', 'rejected'])) {
            return response()->json([
                'message' => 'Cannot delete request in current status'
            ], 422);
        }

        $requestModel->delete();

        return response()->json(['message' => 'Request deleted successfully']);
    }

    public function exportProof($id)
    {
        $requestModel = RequestModel::with(['employee', 'approvals.approver', 'businessTripDetail', 'leaveDetail', 'reimbursementDetail', 'assetDetail', 'overtimeDetail'])->findOrFail($id);
        
        if ($requestModel->type == 'asset') {
            $pdf = Pdf::loadView('pdf.approval_proof_asset', ['request' => $requestModel]);
        } elseif ($requestModel->type == 'reimbursement') {
            $pdf = Pdf::loadView('pdf.approval_proof_reimbursement', ['request' => $requestModel]);
        } elseif ($requestModel->type == 'resignation') {
            $pdf = Pdf::loadView('pdf.approval_proof_resignation', ['request' => $requestModel]);
        } else {
            $pdf = Pdf::loadView('pdf.approval_proof', ['request' => $requestModel]);
        }
        return $pdf->download("Proof-REQ-{$id}.pdf");
    }

    /**
     * Submit request for approval
     */
    public function submit(string $id, \App\Services\ApprovalService $approvalService)
    {
        $requestModel = RequestModel::with('employee.organization')->findOrFail($id);

        if ($requestModel->status !== 'draft') {
            return response()->json([
                'message' => 'Request has already been submitted'
            ], 422);
        }

        // Determine Approvers Logic - Use ApprovalService for role-based approval chain
        $employee = $requestModel->employee;
        $approverIds = $approvalService->determineApprovers($employee, $requestModel);
        
        if (empty($approverIds)) {
             return response()->json(['message' => 'System configuration error: No approvers found.'], 500);
        }

        $requestModel->status = 'pending';
        $requestModel->submitted_at = now();
        $requestModel->save();

        // Generate Steps
        $approvalService->createApprovalSteps($requestModel, array_values($approverIds));

        return response()->json([
            'message' => 'Request submitted successfully',
            'request' => $requestModel->load('approvals'),
        ]);
    }

    /**
     * Approve request
     */
    public function approve(Request $request, string $id, \App\Services\ApprovalService $approvalService)
    {
        $requestModel = RequestModel::findOrFail($id);
        $user = $request->user();

        if (!$user->employee) {
             return response()->json(['message' => 'User is not linked to an employee record'], 403);
        }

        try {
            $updatedRequest = $approvalService->approve($requestModel, $user->employee, $request->input('signature'), $request->input('notes'));
            
            // Notify User if fully approved
            if ($updatedRequest->status == 'approved' && $requestModel->employee && $requestModel->employee->user) {
                // $requestModel->employee->user->notify(new RequestNotification($updatedRequest, 'approved'));
            }

            return response()->json([
                'message' => 'Approval successful',
                'request' => $updatedRequest->load('approvals.approver'), // Eager load
            ]);

        } catch (\Exception $e) {
            return response()->json(['message' => $e->getMessage()], 403);
        }
    }

    /**
     * Reject request
     */
    public function reject(Request $request, string $id, \App\Services\ApprovalService $approvalService)
    {
        $requestModel = RequestModel::findOrFail($id);
        $user = $request->user();

        $validated = $request->validate([
            'reason' => 'required|string',
        ]);

        if (!$user->employee) {
             return response()->json(['message' => 'User is not linked to an employee record'], 403);
        }

        try {
            $updatedRequest = $approvalService->reject($requestModel, $user->employee, $validated['reason']);
            
             // Notify User
            if ($requestModel->employee && $requestModel->employee->user) {
                // $requestModel->employee->user->notify(new RequestNotification($updatedRequest, 'rejected'));
            }

            return response()->json([
                'message' => 'Request rejected',
                'request' => $updatedRequest->load('approvals'),
            ]);

        } catch (\Exception $e) {
             return response()->json(['message' => $e->getMessage()], 403);
        }
    }
    /**
     * Get leave balance for current user
     */
    public function leaveBalance(Request $request)
    {
        $user = $request->user();
        $employee = $user->employee;

        if (!$employee->join_date) {
             // Handle case where join_date is missing. Assume eligible? Or not?
             // User requirement says criteria is join date. If missing, safer to say not eligible or ask admin.
             // For now, return 0 eligible.
             return response()->json([
                'eligible' => false,
                'message' => 'Tanggal bergabung belum diatur',
                'quota' => 0,
                'used' => 0,
                'balance' => 0,
                'years_of_service' => 0
            ]);
        }

        $yearsOfService = $employee->join_date->diffInYears(now());

        if ($yearsOfService < 1) {
            return response()->json([
                'eligible' => false,
                'message' => 'Masa kerja belum mencapai 1 tahun',
                'quota' => 0,
                'used' => 0,
                'balance' => 0,
                'years_of_service' => $yearsOfService
            ]);
        }

        $quota = 12;

        // Calculate used leave
        // Assuming 'amount' is days, or fallback to date diff
        $used = RequestModel::where('employee_id', $employee->id)
            ->where('type', 'leave')
            ->where('status', 'approved')
            ->whereYear('start_date', now()->year)
            ->get()
            ->sum(function ($req) {
                if ($req->amount > 0) return $req->amount;
                if ($req->start_date && $req->end_date) {
                    return $req->start_date->diffInDays($req->end_date) + 1;
                }
                return 0;
            });

        return response()->json([
            'eligible' => true,
            'message' => 'Eligible',
            'quota' => $quota,
            'used' => $used,
            'balance' => max(0, $quota - $used), // No negative balance
            'years_of_service' => $yearsOfService
        ]);
    }


    /**
     * Determine approval steps based on employee level and department
     */
    private function getApprovalSteps(\App\Models\Employee $requester)
    {
        $steps = [];
        $jobLevel = strtolower($requester->job_level ?? '');
        // Determine Track: Operational vs Office
        // Based on user request: 
        // Operational: crew, spv, manager divisi, HRD
        // Office: staff, spv, manager, deputy manager, HRD
        $isOperational = in_array($jobLevel, ['crew']); // Simple heuristic
        
        // Helper to find employee by level
        $findApprover = function($level, $sameDepartment = true) use ($requester) {
            $query = \App\Models\Employee::where('job_level', $level)
                        ->where('status', 'active');
            
            if ($sameDepartment && $requester->department) {
                // Try same department first
                $query->where('department', $requester->department);
            }
            
            $approver = $query->inRandomOrder()->value('id');
            
            // If failed to find in department, fallback to any active employee of that level?
            // User implies strict hierarchy, but let's be safe.
            if (!$approver && $sameDepartment) {
                 $approver = \App\Models\Employee::where('job_level', $level)
                            ->where('status', 'active')
                            ->inRandomOrder()
                            ->value('id');
            }
            return $approver;
        };

        // HRD is always the final step
        // HRD is always the final step
        $hrdId = $findApprover('hrd', false); // Any HRD
        if (!$hrdId) {
             // Fallback: Find Manager of HRD department if no explicit 'hrd' level
             $hrdId = \App\Models\Employee::where('department', 'HRD')
                        ->whereIn('job_level', ['manager', 'manager_divisi'])
                        ->value('id');
        }
        // User Requirement: Super Admin must be HRD (Fallback)
        if (!$hrdId) {
            $superAdmin = \App\Models\User::whereHas('role', fn($q) => $q->where('name', 'super_admin'))
                            ->with('employee')->first();
            $hrdId = $superAdmin?->employee?->id;
        }

        // --- Logic Implementation ---

        // 1. If Requester is SPV
        if ($jobLevel === 'spv') {
            // Step 1: Manager (Direct)
            if ($isOperational) {
                // Operational: Manager Divisi
                $managerId = $findApprover('manager_divisi', true);
                 // Fallback if no manager_divisi, try 'manager'
                if (!$managerId) $managerId = $findApprover('manager', true);
            } else {
                // Office: Manager or Deputy Manager
                $managerId = $findApprover('manager', true);
                if (!$managerId) $managerId = $findApprover('deputy_manager', true);
            }
            if ($managerId) $steps[] = $managerId;

            // Step 2: HRD / Super Admin (Final)
            if ($hrdId) $steps[] = $hrdId;
        }

        // 2. If Requester is Manager (or Manager Divisi, Deputy Manager)
        else if (in_array($jobLevel, ['manager', 'manager_divisi', 'deputy_manager'])) {
            // Step 1: HRD / Super Admin (Direct)
            if ($hrdId) $steps[] = $hrdId;
        }

        // 3. Current Default Logic (Crew, Staff, Team Leader, etc)
        else if (in_array($jobLevel, ['crew', 'staff', 'team_leader'])) {
            // Step 1: SPV
             $spvId = $findApprover('spv', true);
             if ($spvId) $steps[] = $spvId;

             // Step 2: Manager
             if ($isOperational) {
                $managerId = $findApprover('manager_divisi', true);
                if (!$managerId) $managerId = $findApprover('manager', true); // Fallback
            } else {
                $managerId = $findApprover('manager', true);
                if (!$managerId) $managerId = $findApprover('deputy_manager', true);
            }
            if ($managerId) $steps[] = $managerId;

            // Step 3: HRD (Final)
             if ($hrdId) $steps[] = $hrdId;
        }
        
        // 4. Fallback for others (Director, etc) - Direct to HRD
        else {
             if ($hrdId) $steps[] = $hrdId;
        }

        // Remove duplicates and self-approval
        $steps = array_unique($steps);
        $steps = array_filter($steps, fn($id) => $id != $requester->id);

        return array_values($steps);
    }

    public function exportOvertime(Request $request)
    {
        return \Maatwebsite\Excel\Facades\Excel::download(new \App\Exports\OvertimeExport($request), 'overtime-report-' . now()->format('YmdHis') . '.xlsx');
    }
}
