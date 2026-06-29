'use client';

import DashboardLayout from '@/components/DashboardLayout';
import ApprovalTimeline from '@/components/ApprovalTimeline';
import { STORAGE_KEYS } from '@/lib/config';
import apiClient from '@/lib/api-client';
import { useAuthStore } from '@/store/auth-store';
import { Request } from '@/types';
import { useRouter } from 'next/navigation';
import { useEffect, useState, useRef, use as ReactUse } from 'react';
import ApprovalHeader from './components/ApprovalHeader';
import RequestDetailCard from './components/RequestDetailCard';
import RequestAttachments from './components/RequestAttachments';
import ApprovalActionPanel from './components/ApprovalActionPanel';

export default function ApprovalDetailPage({ params }: { params: Promise<{ id: string }> }) {
    const router = useRouter();
    const { user } = useAuthStore();
    const [request, setRequest] = useState<Request | null>(null);
    const [isLoading, setIsLoading] = useState(true);
    const [actionNote, setActionNote] = useState('');
    const [isProcessing, setIsProcessing] = useState(false);

    // Signature State
    const [showApproveModal, setShowApproveModal] = useState(false);
    const [signerName, setSignerName] = useState('');
    const sigCanvas = useRef<any>(null);

    // Unwrap params using React.use() which is standard in Next.js 15 for async params
    const { id } = ReactUse(params);

    useEffect(() => {
        const fetchDetail = async () => {
            if (!id || id === 'undefined') return;

            try {
                const response = await apiClient.get(`/requests/${id}`);
                setRequest(response.data);
            } catch (error) {
                console.error("Failed to fetch request detail", error);
            } finally {
                setIsLoading(false);
            }
        };

        if (id) fetchDetail();
    }, [id]);

    const handleAction = async (action: 'approve' | 'reject') => {
        if (action === 'reject' && !actionNote) {
            alert('Please provide a reason for rejection.');
            return;
        }

        if (action === 'approve') {
            setSignerName(user?.name || '');
            setShowApproveModal(true);
            return;
        }

        if (!confirm(`Are you sure you want to ${action} this request?`)) return;

        processAction(action);
    };

    const processAction = async (action: 'approve' | 'reject', signatureData: string | null = null, extraNote: string = '') => {
        setIsProcessing(true);
        try {
            // Note logic: Rejection uses 'reason', Approval uses 'notes'
            let finalNote = actionNote;
            if (action === 'approve' && extraNote) {
                finalNote = extraNote;
            }

            await apiClient.post(`/requests/${id}/${action}`, {
                notes: finalNote,
                reason: finalNote,
                signature: signatureData
            });

            alert(`Request ${action}d successfully`);
            router.push('/approvals');
        } catch (error: any) {
            console.error("Action error", error);
            alert(error.response?.data?.message || 'Failed to process action');
        } finally {
            setIsProcessing(false);
            setShowApproveModal(false);
        }
    };

    const submitApproval = () => {
        if (sigCanvas.current?.isEmpty()) {
            alert("Please sign before approving");
            return;
        }
        if (!signerName) {
            alert("Please enter signer name");
            return;
        }

        const signatureData = sigCanvas.current.getCanvas().toDataURL('image/png');
        const noteWithContext = `${actionNote ? actionNote + '\n\n' : ''}Approved by: ${signerName}`;

        processAction('approve', signatureData, noteWithContext);
    };

    const handleDownloadProof = async () => {
        try {
            const response = await apiClient.get(`/requests/${id}/proof`, { responseType: 'blob' });
            
            const url = window.URL.createObjectURL(response.data);
            const a = document.createElement('a');
            a.href = url;
            a.download = `Proof-REQ-${id}.pdf`;
            document.body.appendChild(a);
            a.click();
            a.remove();
        } catch (e) {
            alert('Failed to download proof');
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
            <div className="max-w-5xl mx-auto p-6 md:p-10 font-sans">
                <ApprovalHeader 
                    request={request} 
                    onBack={() => router.back()} 
                    onDownloadProof={handleDownloadProof} 
                />

                <div className="grid grid-cols-1 lg:grid-cols-3 gap-8 items-start">
                    {/* Left Column: Details & Attachments */}
                    <div className="lg:col-span-2 space-y-6">
                        <RequestDetailCard request={request} />
                        <RequestAttachments request={request} />
                    </div>

                    {/* Right Column: Timeline & Actions */}
                    <div className="lg:col-span-1 space-y-6 sticky top-24">
                        <div className="bg-white rounded-3xl shadow-[0_2px_20px_rgba(0,0,0,0.04)] border border-gray-100/50 p-6 md:p-8">
                            <ApprovalTimeline approvals={request.approvals || []} />
                        </div>
                        
                        <ApprovalActionPanel 
                            request={request}
                            user={user}
                            actionNote={actionNote}
                            setActionNote={setActionNote}
                            isProcessing={isProcessing}
                            handleAction={handleAction}
                            showApproveModal={showApproveModal}
                            setShowApproveModal={setShowApproveModal}
                            signerName={signerName}
                            setSignerName={setSignerName}
                            sigCanvas={sigCanvas}
                            submitApproval={submitApproval}
                        />
                    </div>
                </div>
            </div>
        </DashboardLayout>
    );
}
