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
}
