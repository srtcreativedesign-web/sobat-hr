<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\RequestModel;
use App\Models\Approval;

class RequestController extends Controller
{
    public function index(Request $request)
    {
        $query = RequestModel::with(['employee', 'approvals']);

        if ($request->has('employee_id')) {
            $query->where('employee_id', $request->employee_id);
        }

        if ($request->has('type')) {
            $query->where('type', $request->type);
        }

        if ($request->has('status')) {
            $query->where('status', $request->status);
        }

        $requests = $query->orderBy('created_at', 'desc')->paginate(20);

        return response()->json($requests);
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'employee_id' => 'required|exists:employees,id',
            'type' => 'required|in:leave,overtime,reimbursement,resignation',
            'title' => 'required|string|max:255',
            'description' => 'required|string',
            'start_date' => 'nullable|date',
            'end_date' => 'nullable|date',
            'amount' => 'nullable|numeric',
            'attachments' => 'nullable|json',
        ]);

        if ($validated['type'] === 'leave') {
             $user = $request->user();
             $employee = $user->employee; // Make sure relationships are loaded or access directly
             
             // Check Eligibility
             if (!$employee->join_date || $employee->join_date->diffInYears(now()) < 1) {
                  return response()->json([
                      'message' => 'Anda belum memenuhi syarat cuti tahunan (minimal 1 tahun masa kerja).'
                  ], 422);
             }

             // Calculate requested days
             $days = 0;
             $startDate = \Carbon\Carbon::parse($validated['start_date']);
             $endDate = \Carbon\Carbon::parse($validated['end_date']);
             
             if ($startDate && $endDate) {
                 $days = $startDate->diffInDays($endDate) + 1;
             }
             if (isset($validated['amount']) && $validated['amount'] > 0) {
                 $days = $validated['amount'];
             }
             // Ensure amount is saved
             $validated['amount'] = $days;

             // Check Balance
             $quota = 12;
             $used = RequestModel::where('employee_id', $employee->id)
                ->where('type', 'leave')
                ->whereIn('status', ['pending', 'approved'])
                ->whereYear('start_date', now()->year)
                ->get()
                ->sum('amount'); // Use amount column
             
             $balance = $quota - $used;
             
             if ($days > $balance) {
                 return response()->json([
                     'message' => "Sisa cuti tidak mencukupi. Sisa: $balance hari, Diajukan: $days hari."
                 ], 422);
             }
        }

        $validated['status'] = 'draft';

        $requestModel = RequestModel::create($validated);

        return response()->json($requestModel, 201);
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

    /**
     * Submit request for approval
     */
    public function submit(string $id)
    {
        $requestModel = RequestModel::findOrFail($id);

        if ($requestModel->status !== 'draft') {
            return response()->json([
                'message' => 'Request has already been submitted'
            ], 422);
        }

        $requestModel->status = 'pending';
        $requestModel->submitted_at = now();
        $requestModel->save();

        // Create approval workflow
        // TODO: Implement dynamic approval workflow based on organization structure

        return response()->json([
            'message' => 'Request submitted successfully',
            'request' => $requestModel,
        ]);
    }

    /**
     * Approve request
     */
    public function approve(Request $request, string $id)
    {
        $requestModel = RequestModel::findOrFail($id);
        $user = $request->user();

        // Find pending approval for this user
        $approval = Approval::where('request_id', $id)
            ->where('approver_id', $user->employee->id)
            ->where('status', 'pending')
            ->first();

        if (!$approval) {
            return response()->json([
                'message' => 'No pending approval found for this user'
            ], 403);
        }

        $validated = $request->validate([
            'notes' => 'nullable|string',
        ]);

        $approval->status = 'approved';
        $approval->approved_at = now();
        $approval->notes = $validated['notes'] ?? null;
        $approval->save();

        // Check if all approvals are completed
        $pendingApprovals = Approval::where('request_id', $id)
            ->where('status', 'pending')
            ->count();

        if ($pendingApprovals === 0) {
            $requestModel->status = 'approved';
            $requestModel->save();
        }

        return response()->json([
            'message' => 'Request approved successfully',
            'request' => $requestModel->load('approvals'),
        ]);
    }

    /**
     * Reject request
     */
    public function reject(Request $request, string $id)
    {
        $requestModel = RequestModel::findOrFail($id);
        $user = $request->user();

        // Find pending approval for this user
        $approval = Approval::where('request_id', $id)
            ->where('approver_id', $user->employee->id)
            ->where('status', 'pending')
            ->first();

        if (!$approval) {
            return response()->json([
                'message' => 'No pending approval found for this user'
            ], 403);
        }

        $validated = $request->validate([
            'notes' => 'required|string',
        ]);

        $approval->status = 'rejected';
        $approval->approved_at = now();
        $approval->notes = $validated['notes'];
        $approval->save();

        // Reject the entire request
        $requestModel->status = 'rejected';
        $requestModel->save();

        return response()->json([
            'message' => 'Request rejected',
            'request' => $requestModel->load('approvals'),
        ]);
    }
    /**
     * Get leave balance for current user
     */
    public function leaveBalance(Request $request)
    {
        $user = $request->user();
        $employee = $user->employee;

        if (!$employee) {
            return response()->json(['message' => 'Employee not found'], 404);
        }

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
            ->whereIn('status', ['pending', 'approved'])
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
}
