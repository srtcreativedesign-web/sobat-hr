<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\RequestModel;
use App\Services\ApprovalService;
use Barryvdh\DomPDF\Facade\Pdf;
use Illuminate\Http\Request;

class RequestPrintController extends Controller
{
    protected ApprovalService $approvalService;

    public function __construct(ApprovalService $approvalService)
    {
        $this->approvalService = $approvalService;
    }

    /**
     * Generate printable PDF for manager-level requests before COO approval
     * This allows offline signature by COO/Director
     */
    public function printForApproval(Request $request, string $id)
    {
        $requestModel = RequestModel::with([
            'employee.organization',
            'employee.user.role',
            'approvals.approver',
            'leaveDetail',
            'overtimeDetail',
            'reimbursementDetail',
            'businessTripDetail',
            'assetDetail',
            'resignationDetail',
            'sickLeaveDetail'
        ])->findOrFail($id);

        // Check if this request can be printed
        if (!$this->approvalService->canPrintRequest($requestModel)) {
            return response()->json([
                'message' => 'Pengajuan ini tidak dapat dicetak. Hanya pengajuan dari level Manager yang menunggu approval COO yang dapat dicetak.'
            ], 403);
        }

        // Get requester info
        $requester = $requestModel->employee;
        $requesterRole = $requester->user?->role?->display_name ?? 'Unknown';

        // Find COO approver info
        $cooApprover = $requestModel->approvals()
            ->whereHas('approver.user.role', function($q) {
                $q->where('name', 'coo');
            })
            ->first();

        $data = [
            'request' => $requestModel,
            'requester' => $requester,
            'requesterRole' => $requesterRole,
            'cooApprover' => $cooApprover?->approver,
            'printedAt' => now(),
            'printedBy' => $request->user()?->name ?? 'System',
        ];

        $pdf = Pdf::loadView('pdf.manager_request_approval', $data);
        
        return $pdf->download("Request-{$requestModel->id}-Print.pdf");
    }

    /**
     * Check if a request can be printed
     */
    public function canPrint(string $id)
    {
        $requestModel = RequestModel::with(['employee.user.role'])->findOrFail($id);
        
        return response()->json([
            'can_print' => $this->approvalService->canPrintRequest($requestModel),
            'message' => $this->approvalService->canPrintRequest($requestModel) 
                ? 'Request dapat dicetak untuk approval offline' 
                : 'Request tidak dapat dicetak'
        ]);
    }
}
