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
    /**
     * Get all approvals for authenticated user
     */
    public function index(Request $request)
    {
        $user = $request->user();
        $query = Approval::with(['approvable.employee']);

        // Check Role
        $roleName = $user->role ? $user->role->name : '';
        $isAdmin = in_array($roleName, ['super_admin', 'admin_cabang', 'hrd']);

        if (!$isAdmin) {
             if (!$user->employee) {
                return response()->json(['message' => 'User is not associated with an employee'], 403);
            }
            $query->where('approver_id', $user->employee->id);
        }

        $approvals = $query->orderBy('created_at', 'desc')->paginate(20);

        return response()->json($approvals);
    }

    /**
     * Get pending approvals for authenticated user
     */
    public function pending(Request $request)
    {
        try {
            $user = $request->user();
            if (!$user) {
                return response()->json(['message' => 'Unauthenticated'], 401);
            }
            
            $query = Approval::with(['approvable.employee']);

            // Check Role
            $user->load('role');
            $roleName = $user->role ? $user->role->name : '';
            $isAdmin = in_array($roleName, ['super_admin', 'admin_cabang', 'hrd']);

            if (!$isAdmin) {
                 if (!$user->employee) {
                    return response()->json(['message' => 'User is not associated with an employee'], 403);
                }
                $query->where('approver_id', $user->employee->id);
            }

            $approvals = $query->where('status', 'pending')
                ->orderBy('created_at', 'desc')
                ->paginate(20);

            return response()->json($approvals);
        } catch (\Exception $e) {
            return response()->json([
                'message' => 'Error fetching pending approvals',
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ], 500);
        }
    }
}
