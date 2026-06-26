import React from 'react';
import SignatureCanvas from 'react-signature-canvas';
import { Request } from '@/types';

interface ApprovalActionPanelProps {
    request: Request;
    user: any;
    actionNote: string;
    setActionNote: (note: string) => void;
    isProcessing: boolean;
    handleAction: (action: 'approve' | 'reject') => void;
    showApproveModal: boolean;
    setShowApproveModal: (show: boolean) => void;
    signerName: string;
    setSignerName: (name: string) => void;
    sigCanvas: React.RefObject<any>;
    submitApproval: () => void;
}

export default function ApprovalActionPanel({
    request,
    user,
    actionNote,
    setActionNote,
    isProcessing,
    handleAction,
    showApproveModal,
    setShowApproveModal,
    signerName,
    setSignerName,
    sigCanvas,
    submitApproval
}: ApprovalActionPanelProps) {
    if (!['pending', 'pending_final'].includes(request.status)) {
        return null;
    }

    const pendingStep = request.approvals?.find(a => a.status === 'pending');
    const roleName = (typeof user?.role === 'object' && user.role !== null && 'name' in user.role) 
        ? (user.role as any).name 
        : (user?.role || '');
    const isAdmin = ['super_admin', 'admin', 'hrd'].includes(roleName);
    const isMyTurn = isAdmin || (pendingStep && pendingStep.approver?.id === user?.employee?.id);

    return (
        <>
            {!isMyTurn ? (
                <div className="bg-gray-50 rounded-3xl border border-gray-100 p-6 md:p-8 text-center h-fit">
                    <h3 className="text-lg font-bold text-gray-400 mb-2">Waiting for Approval</h3>
                    <p className="text-sm text-gray-500">
                        Current Approver: <span className="font-semibold">{pendingStep?.approver?.full_name || 'System / Unassigned'}</span> (Level {pendingStep?.level || '-'})
                    </p>
                    {!pendingStep && (
                        <p className="text-xs text-red-400 mt-2">
                            No pending approval step found. Please contact HR.
                        </p>
                    )}
                </div>
            ) : (
                <div className="bg-white rounded-3xl shadow-[0_4px_30px_rgba(0,0,0,0.06)] border border-gray-100/50 p-6 md:p-8 h-fit">
                    <h3 className="text-lg font-bold text-[#419cc3] mb-4">Take Action</h3>
                    <textarea
                        className="w-full bg-gray-50 border-0 ring-1 ring-gray-200 rounded-xl p-4 text-sm focus:ring-2 focus:ring-[#419cc3]/20 focus:bg-white transition-all mb-6 resize-none"
                        rows={4}
                        placeholder="Add a reason or note (Required for rejection)..."
                        value={actionNote}
                        onChange={(e) => setActionNote(e.target.value)}
                    ></textarea>

                    <div className="grid grid-cols-2 gap-4">
                        <button
                            onClick={() => handleAction('reject')}
                            disabled={isProcessing}
                            className="w-full bg-white text-red-600 border border-red-100 hover:bg-red-50 hover:border-red-200 py-3.5 rounded-xl font-bold transition-all disabled:opacity-50 text-sm shadow-sm"
                        >
                            Reject
                        </button>
                        <button
                            onClick={() => handleAction('approve')}
                            disabled={isProcessing}
                            className="w-full bg-[#419cc3] text-white hover:bg-[#2d1e24] py-3.5 rounded-xl font-bold shadow-lg shadow-[#419cc3]/20 hover:shadow-xl hover:-translate-y-0.5 transition-all disabled:opacity-50 text-sm"
                        >
                            Approve
                        </button>
                    </div>
                </div>
            )}

            {/* Signature Modal */}
            {showApproveModal && (
                <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50 backdrop-blur-sm">
                    <div className="bg-white rounded-2xl w-full max-w-md p-6 shadow-2xl relative">
                        <button onClick={() => setShowApproveModal(false)} className="absolute top-4 right-4 text-gray-400 hover:text-gray-600">
                            <svg className="w-6 h-6" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" /></svg>
                        </button>
                        <h3 className="text-xl font-bold text-[#419cc3] mb-6">Confirm Approval</h3>
                        <div className="space-y-4">
                            <div>
                                <label className="block text-sm font-bold text-gray-700 mb-1">Signer Name</label>
                                <input
                                    type="text"
                                    value={signerName}
                                    onChange={(e) => setSignerName(e.target.value)}
                                    className="w-full border border-gray-300 rounded-lg p-2.5 focus:ring-2 focus:ring-[#419cc3] focus:border-[#419cc3]"
                                    placeholder="Enter your name"
                                />
                            </div>

                            <div>
                                <label className="block text-sm font-bold text-gray-700 mb-1">Signature</label>
                                <div className="border border-gray-300 rounded-lg overflow-hidden bg-gray-50 h-[200px] relative">
                                    <SignatureCanvas
                                        ref={sigCanvas}
                                        penColor="black"
                                        canvasProps={{ className: 'signature-canvas w-full h-full' }}
                                    />
                                    <button
                                        onClick={() => sigCanvas.current?.clear()}
                                        className="absolute bottom-2 right-2 text-xs bg-white border border-gray-200 px-2 py-1 rounded shadow-sm hover:bg-gray-100"
                                    >Clear</button>
                                </div>
                            </div>

                            <div className="pt-4 flex gap-3">
                                <button onClick={() => setShowApproveModal(false)} className="flex-1 py-3 border border-gray-200 rounded-xl font-bold text-gray-600 hover:bg-gray-50">Cancel</button>
                                <button onClick={submitApproval} disabled={isProcessing} className="flex-1 py-3 bg-[#419cc3] text-white rounded-xl font-bold hover:bg-[#2d1e24]">
                                    {isProcessing ? 'Processing...' : 'Confirm Approve'}
                                </button>
                            </div>
                        </div>
                    </div>
                </div>
            )}
        </>
    );
}
