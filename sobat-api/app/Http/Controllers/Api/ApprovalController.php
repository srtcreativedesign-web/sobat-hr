<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Approval;

class ApprovalController extends Controller
{
    /**
     * Get all approvals for authenticated user
     */
    public function index(Request $request)
    {
        $user = $request->user();

        if (!$user->employee) {
            return response()->json([
                'message' => 'User is not associated with an employee'
            ], 403);
        }

        $approvals = Approval::with(['request.employee'])
            ->where('approver_id', $user->employee->id)
            ->orderBy('created_at', 'desc')
            ->paginate(20);

        return response()->json($approvals);
    }

    /**
     * Get pending approvals for authenticated user
     */
    public function pending(Request $request)
    {
        $user = $request->user();

        if (!$user->employee) {
            return response()->json([
                'message' => 'User is not associated with an employee'
            ], 403);
        }

        $approvals = Approval::with(['request.employee'])
            ->where('approver_id', $user->employee->id)
            ->where('status', 'pending')
            ->orderBy('created_at', 'desc')
            ->paginate(20);

        return response()->json($approvals);
    }
}
