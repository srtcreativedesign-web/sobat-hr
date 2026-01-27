'use client';

import DashboardLayout from '@/components/DashboardLayout';
import ApprovalTimeline from '@/components/ApprovalTimeline';
import { STORAGE_KEYS } from '@/lib/config';
import { useAuthStore } from '@/store/auth-store';
import { Request } from '@/types';
import { useRouter } from 'next/navigation';
import { useEffect, useState } from 'react';
import { use, use as ReactUse } from 'react';

export default function ApprovalDetailPage({ params }: { params: Promise<{ id: string }> }) {
    const router = useRouter();
    const { user } = useAuthStore();
    const [request, setRequest] = useState<Request | null>(null);
    const [isLoading, setIsLoading] = useState(true);
    const [actionNote, setActionNote] = useState('');
    const [isProcessing, setIsProcessing] = useState(false);
    const { id } = ReactUse(params);

    useEffect(() => {
        const fetchDetail = async () => {
            try {
                const token = localStorage.getItem(STORAGE_KEYS.TOKEN);
                // We use the generic RequestController@show endpoint which eagerly loads approvals
                const response = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/requests/${id}`, {
                    headers: {
                        'Authorization': `Bearer ${token}`
                    }
                });

                if (response.ok) {
                    const data = await response.json();
                    setRequest(data);
                }
            } catch (error) {
                console.error("Failed to fetch request detail", error);
            } finally {
                setIsLoading(false);
            }
        };

        fetchDetail();
    }, [id]);

    const handleAction = async (action: 'approve' | 'reject') => {
        if (action === 'reject' && !actionNote) {
            alert('Please provide a reason for rejection.');
            return;
        }
        if (!confirm(`Are you sure you want to ${action} this request?`)) return;

        setIsProcessing(true);
        try {
            const token = localStorage.getItem(STORAGE_KEYS.TOKEN);
            const response = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/requests/${id}/${action}`, {
                method: 'POST',
                headers: {
                    'Authorization': `Bearer ${token}`,
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({
                    notes: actionNote, // Backend uses 'notes' or 'reason' depending on controller. RequestController uses 'notes' for approve, 'reason' for reject, let's normalize or check Backend.
                    // Checking RequestController.php: approve uses 'notes', reject uses 'reason'. I will send both or fix backend. 
                    // Let's send both to be safe or context sensitive.
                    reason: actionNote,
                })
            });

            if (response.ok) {
                alert(`Request ${action}d successfully`);
                router.push('/approvals');
            } else {
                const err = await response.json();
                alert(err.message || 'Action failed');
            }
        } catch (error) {
            console.error("Action error", error);
            alert('Failed to process action');
        } finally {
            setIsProcessing(false);
        }
    };

    if (isLoading) {
        return (
            <DashboardLayout>
                <div className="p-8 text-center text-gray-500">Loading Detail...</div>
            </DashboardLayout>
        );
    }

    if (!request) {
        return (
            <DashboardLayout>
                <div className="p-8 text-center text-red-500">Request not found</div>
            </DashboardLayout>
        );
    }

    return (
        <DashboardLayout>
            <div className="max-w-4xl mx-auto p-6 md:p-8">
                {/* Header */}
                <div className="mb-8">
                    <button
                        onClick={() => router.back()}
                        className="text-sm text-gray-500 hover:text-gray-700 mb-2 flex items-center gap-1"
                    >
                        ← Back to Inbox
                    </button>
                    <div className="flex justify-between items-start">
                        <div>
                            <h1 className="text-2xl font-bold text-[#462e37]">{request.title}</h1>
                            <p className="text-[#462e37]/70">Submitted by {request.employee?.full_name}</p>
                        </div>
                        <div className={`px-4 py-1.5 rounded-full text-sm font-bold capitalize
                     ${request.status === 'approved' ? 'bg-green-100 text-green-800' :
                                request.status === 'rejected' ? 'bg-red-100 text-red-800' :
                                    request.status === 'pending' ? 'bg-yellow-100 text-yellow-800' : 'bg-gray-100 text-gray-800'
                            }`}>
                            {request.status}
                        </div>
                    </div>
                </div>

                <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
                    {/* Left: Detail Content */}
                    <div className="md:col-span-2 space-y-6">
                        <div className="bg-white rounded-2xl shadow-sm border border-[#462e37]/10 p-6">
                            <h3 className="text-lg font-bold text-[#462e37] mb-4 border-b border-gray-100 pb-2">Request Details</h3>

                            <div className="space-y-4">
                                <div className="grid grid-cols-2 gap-4">
                                    <div>
                                        <label className="text-xs uppercase text-gray-400 font-semibold">Type</label>
                                        <p className="font-medium text-gray-900 capitalize">{request.type}</p>
                                    </div>
                                    <div>
                                        <label className="text-xs uppercase text-gray-400 font-semibold">Duration/Amount</label>
                                        <p className="font-medium text-gray-900">{request.amount} Days/Unit</p>
                                    </div>
                                    <div>
                                        <label className="text-xs uppercase text-gray-400 font-semibold">Start Date</label>
                                        <p className="font-medium text-gray-900">{request.start_date || '-'}</p>
                                    </div>
                                    <div>
                                        <label className="text-xs uppercase text-gray-400 font-semibold">End Date</label>
                                        <p className="font-medium text-gray-900">{request.end_date || '-'}</p>
                                    </div>
                                </div>

                                <div>
                                    <label className="text-xs uppercase text-gray-400 font-semibold">Description / Reason</label>
                                    <div className="bg-gray-50 p-4 rounded-lg text-gray-700 mt-1 whitespace-pre-wrap">
                                        {request.description}
                                    </div>
                                </div>
                            </div>
                        </div>

                        {/* Attachments (Placeholder) */}
                        <div className="bg-white rounded-2xl shadow-sm border border-[#462e37]/10 p-6">
                            <h3 className="text-lg font-bold text-[#462e37] mb-4">Attachments</h3>
                            {request.attachments ? (
                                <div className="text-sm text-blue-600 underline cursor-pointer">View Attachment</div>
                            ) : (
                                <div className="text-sm text-gray-400 italic">No attachments provided.</div>
                            )}
                        </div>
                    </div>

                    {/* Right: Timeline & Actions */}
                    <div className="space-y-6">
                        {/* Timeline */}
                        <div className="bg-white rounded-2xl shadow-sm border border-[#462e37]/10 p-6">
                            <ApprovalTimeline approvals={request.approvals || []} />
                        </div>

                        {/* Action Panel - Only show if Pending and User has permission (Checked by Backend, but frontend should hide if not relevant) 
                     Ideally we check if current user is the current approver using logic. 
                     For MVP we show form, backend will reject with 403 if unauthorized.
                 */}
                        {request.status === 'pending' && (
                            <div className="bg-white rounded-2xl shadow-sm border border-[#462e37]/10 p-6">
                                <h3 className="text-lg font-bold text-[#462e37] mb-4">Your Action</h3>
                                <textarea
                                    className="w-full border border-gray-300 rounded-lg p-3 text-sm focus:ring-[#462e37] focus:border-[#462e37] mb-4"
                                    rows={3}
                                    placeholder="Add a note (Optional for Approve, Required for Reject)..."
                                    value={actionNote}
                                    onChange={(e) => setActionNote(e.target.value)}
                                ></textarea>

                                <div className="flex gap-3">
                                    <button
                                        onClick={() => handleAction('reject')}
                                        disabled={isProcessing}
                                        className="flex-1 bg-red-50 text-red-600 border border-red-200 py-2.5 rounded-lg font-bold hover:bg-red-100 transition-all disabled:opacity-50"
                                    >
                                        Reject
                                    </button>
                                    <button
                                        onClick={() => handleAction('approve')}
                                        disabled={isProcessing}
                                        className="flex-1 bg-gradient-to-r from-[#462e37] to-[#2d1e24] text-white py-2.5 rounded-lg font-bold shadow-lg hover:shadow-xl hover:-translate-y-0.5 transition-all disabled:opacity-50"
                                    >
                                        Approve
                                    </button>
                                </div>
                            </div>
                        )}
                    </div>
                </div>
            </div>
        </DashboardLayout>
    );
}
