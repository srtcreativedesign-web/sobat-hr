'use client';

import DashboardLayout from '@/components/DashboardLayout';
import ApprovalTimeline from '@/components/ApprovalTimeline';
import { STORAGE_KEYS } from '@/lib/config';
import { useAuthStore } from '@/store/auth-store';
import { format, differenceInDays } from 'date-fns';
import { Request } from '@/types';
import { useRouter } from 'next/navigation';
import { useEffect, useState, useRef, use as ReactUse } from 'react';
import SignatureCanvas from 'react-signature-canvas';

const LiveTimer = ({ startTime, date }: { startTime: string, date: string }) => {
    const [duration, setDuration] = useState('00:00:00');

    useEffect(() => {
        const updateTimer = () => {
            const now = new Date();
            const dateOnly = date.split('T')[0];
            const startStr = `${dateOnly}T${startTime}`;
            const start = new Date(startStr);
            if (isNaN(start.getTime())) return;
            
            const diffInSeconds = Math.floor((now.getTime() - start.getTime()) / 1000);
            if (diffInSeconds < 0) return;

            const h = Math.floor(diffInSeconds / 3600);
            const m = Math.floor((diffInSeconds % 3600) / 60);
            const s = diffInSeconds % 60;
            
            setDuration(
                `${h.toString().padStart(2, '0')}:${m.toString().padStart(2, '0')}:${s.toString().padStart(2, '0')}`
            );
        };
        
        updateTimer(); // Initial call
        const interval = setInterval(updateTimer, 1000);
        return () => clearInterval(interval);
    }, [startTime, date]);

    return <span className="font-mono text-[#1C3ECA] font-bold">{duration}</span>;
};

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
                const token = localStorage.getItem(STORAGE_KEYS.TOKEN);
                const response = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/requests/${id}`, {
                    headers: { 'Authorization': `Bearer ${token}` }
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
            const token = localStorage.getItem(STORAGE_KEYS.TOKEN);

            // Note logic: Rejection uses 'reason', Approval uses 'notes'
            let finalNote = actionNote;
            if (action === 'approve' && extraNote) {
                finalNote = extraNote;
            }

            const response = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/requests/${id}/${action}`, {
                method: 'POST',
                headers: {
                    'Authorization': `Bearer ${token}`,
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({
                    notes: finalNote,
                    reason: finalNote,
                    signature: signatureData
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
            const token = localStorage.getItem(STORAGE_KEYS.TOKEN);
            const response = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/requests/${id}/proof`, {
                headers: { 'Authorization': `Bearer ${token}` }
            });
            if (!response.ok) throw new Error('Download failed');

            const blob = await response.blob();
            const url = window.URL.createObjectURL(blob);
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
                {/* Header Section */}
                <div className="flex flex-col md:flex-row justify-between items-start md:items-center mb-10 gap-4">
                    <div>
                        <div className="flex items-center justify-between w-full">
                            <button
                                onClick={() => router.back()}
                                className="group flex items-center text-sm font-medium text-gray-500 hover:text-[#1C3ECA] mb-4 transition-colors"
                            >
                                <svg className="w-4 h-4 mr-1 transition-transform group-hover:-translate-x-1" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M10 19l-7-7m0 0l7-7m-7 7h18" />
                                </svg>
                                Back to Inbox
                            </button>
                            <button
                                onClick={handleDownloadProof}
                                className="inline-flex items-center px-4 py-2 bg-white border border-gray-200 rounded-xl text-sm font-semibold text-gray-600 hover:bg-gray-50 shadow-sm transition-all mb-4"
                            >
                                <svg className="w-4 h-4 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-4l-4 4m0 0l-4-4m4 4V4" />
                                </svg>
                                Export Proof
                            </button>
                        </div>
                        <h1 className="text-3xl md:text-4xl font-extrabold text-[#1C3ECA] tracking-tight mb-2">{request.title}</h1>
                        <div className="flex items-center gap-3 text-gray-500 text-sm">
                            <span className="flex items-center gap-1 bg-gray-100 px-2 py-0.5 rounded-md font-medium text-gray-700">
                                <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
                                </svg>
                                {request.employee?.full_name}
                            </span>
                            <span>•</span>
                            <span>Submitted on {request.submitted_at ? format(new Date(request.submitted_at), 'dd MMM yyyy') : '-'}</span>
                        </div>
                    </div>

                    <div className={`px-5 py-2 rounded-full text-sm font-bold tracking-wide uppercase shadow-sm border
                        ${request.status === 'approved' ? 'bg-green-50 text-green-700 border-green-100' :
                            request.status === 'spl_open' ? 'bg-emerald-50 text-emerald-700 border-emerald-100' :
                            request.status === 'spl_approved' ? 'bg-blue-50 text-blue-700 border-blue-100' :
                            request.status === 'rejected' ? 'bg-red-50 text-red-700 border-red-100' :
                                request.status === 'pending' ? 'bg-amber-50 text-amber-700 border-amber-100' : 'bg-gray-50 text-gray-700 border-gray-200'
                        }`}>
                        {request.status === 'spl_open' ? 'Lembur Berjalan' : request.status === 'spl_approved' ? 'Menunggu Mulai' : request.status}
                    </div>
                </div>

                <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
                    {/* Left Column: Details */}
                    <div className="lg:col-span-2 space-y-6">
                        {/* Main Detail Card */}
                        <div className="bg-white rounded-3xl shadow-[0_2px_20px_rgba(0,0,0,0.04)] border border-gray-100/50 p-8 overflow-hidden relative">
                            <div className="absolute top-0 left-0 w-full h-1 bg-gradient-to-r from-[#1C3ECA] to-[#8a5d6e] opacity-20"></div>
                            <h3 className="text-xl font-bold text-[#1C3ECA] mb-8 flex items-center gap-2">
                                <svg className="w-5 h-5 opacity-50" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
                                </svg>
                                Request Details
                            </h3>

                            <div className="grid grid-cols-1 md:grid-cols-2 gap-y-8 gap-x-12">
                                <div className="space-y-1">
                                    <label className="text-xs uppercase tracking-wider text-gray-400 font-bold">Request Type</label>
                                    <div className="font-semibold text-lg text-gray-900 capitalize flex items-center gap-2">
                                        {request.type === 'leave' && '🌴'}
                                        {request.type === 'business_trip' && '✈️'}
                                        {request.type === 'overtime' && '⏰'}
                                        {request.type === 'asset' && '💻'}
                                        {request.type === 'resignation' && '🚪'}
                                        {request.type.replace('_', ' ')}
                                    </div>
                                </div>

                                {request.type !== 'resignation' && (
                                    <div className="space-y-1">
                                        <label className="text-xs uppercase tracking-wider text-gray-400 font-bold">
                                            {request.type === 'asset' ? 'Estimated Cost' : 'Duration / Amount'}
                                        </label>
                                        <div className="font-semibold text-lg text-gray-900">
                                            {request.type === 'asset'
                                                ? `IDR ${request.amount?.toLocaleString('id-ID')}`
                                                : (() => {
                                                    if (request.type === 'overtime') {
                                                        if (request.status === 'spl_open') {
                                                            return <LiveTimer startTime={request.detail?.start_time} date={request.detail?.date} />;
                                                        }
                                                        if (['pending', 'spl_approved'].includes(request.status)) {
                                                            return '-';
                                                        }
                                                    }
                                                    const val = request.amount || (request.start_date && request.end_date ? differenceInDays(new Date(request.end_date), new Date(request.start_date)) + 1 : 1);
                                                    return Number(val).toLocaleString('id-ID', { maximumFractionDigits: 0 });
                                                })()
                                            }
                                            <span className="text-sm text-gray-500 ml-1 font-normal">
                                                {(() => {
                                                    if (request.type === 'overtime' && ['spl_open', 'pending', 'spl_approved'].includes(request.status)) return '';
                                                    if (['leave', 'business_trip', 'sick_leave'].includes(request.type)) return 'Days';
                                                    if (request.type === 'overtime') return 'Hours';
                                                    if (['reimbursement', 'asset', 'resignation'].includes(request.type)) return '';
                                                    return 'Units';
                                                })()}
                                            </span>
                                        </div>
                                    </div>
                                )}

                                {request.type === 'resignation' && request.detail ? (
                                    <>
                                        <div className="space-y-1">
                                            <label className="text-xs uppercase tracking-wider text-gray-400 font-bold">Last Working Date</label>
                                            <div className="font-semibold text-lg text-gray-900">
                                                {request.detail.last_working_date ? format(new Date(request.detail.last_working_date), 'dd MMM yyyy') : '-'}
                                            </div>
                                        </div>
                                        <div className="space-y-1">
                                            <label className="text-xs uppercase tracking-wider text-gray-400 font-bold">Type</label>
                                            <div className="font-semibold text-lg text-gray-900 capitalize">
                                                {request.detail.resign_type === '1_month_notice' ? 'One Month Notice' : 'Normal'}
                                            </div>
                                        </div>
                                    </>
                                ) : request.type === 'asset' && request.detail ? (
                                    <>
                                        <div className="space-y-1">
                                            <label className="text-xs uppercase tracking-wider text-gray-400 font-bold">Brand / Item</label>
                                            <div className="font-semibold text-lg text-gray-900">{request.detail.brand || '-'}</div>
                                        </div>
                                        <div className="space-y-1">
                                            <label className="text-xs uppercase tracking-wider text-gray-400 font-bold">Specification</label>
                                            <div className="font-semibold text-lg text-gray-900">{request.detail.specification || '-'}</div>
                                        </div>
                                        <div className="space-y-1">
                                            <label className="text-xs uppercase tracking-wider text-gray-400 font-bold">Urgency</label>
                                            <div className={`font-semibold text-lg px-3 py-1 inline-flex rounded-full text-sm ${request.detail.is_urgent ? 'bg-red-100 text-red-700' : 'bg-green-100 text-green-700'}`}>
                                                {request.detail.is_urgent ? '🔥 Urgent' : 'Regular'}
                                            </div>
                                        </div>
                                    </>
                                ) : request.type === 'overtime' && request.detail ? (
                                    <>
                                        <div className="space-y-1">
                                            <label className="text-xs uppercase tracking-wider text-gray-400 font-bold">Start Time</label>
                                            <div className="font-semibold text-lg text-gray-900">{request.detail.start_time || '-'}</div>
                                        </div>
                                        <div className="space-y-1">
                                            <label className="text-xs uppercase tracking-wider text-gray-400 font-bold">End Time (Actual)</label>
                                            <div className="font-semibold text-lg text-gray-900">{request.detail.end_time || '-'}</div>
                                        </div>
                                        
                                        {/* Proof Image Section */}
                                        {request.detail.proof_image_done && request.detail.proof_image_done.length > 0 && (
                                            <div className="space-y-2 md:col-span-2 pt-4 border-t border-gray-100">
                                                <label className="text-xs uppercase tracking-wider text-gray-400 font-bold">Bukti Selesai Lembur</label>
                                                <div className="grid grid-cols-2 sm:grid-cols-3 gap-4 mt-2">
                                                    {request.detail.proof_image_done.map((img: string, idx: number) => (
                                                        <a key={idx} href={`${process.env.NEXT_PUBLIC_API_URL}/storage/${img}`} target="_blank" rel="noopener noreferrer" className="block relative aspect-square rounded-xl overflow-hidden border border-gray-200 hover:border-[#1C3ECA] transition-colors shadow-sm">
                                                            <img 
                                                                src={`${process.env.NEXT_PUBLIC_API_URL}/storage/${img}`} 
                                                                alt={`Proof ${idx + 1}`} 
                                                                className="object-cover w-full h-full"
                                                            />
                                                            <div className="absolute inset-0 bg-black/0 hover:bg-black/10 transition-colors flex items-center justify-center opacity-0 hover:opacity-100">
                                                                <span className="bg-white/90 text-[#1C3ECA] text-xs font-bold px-3 py-1.5 rounded-full shadow-sm backdrop-blur-sm">Lihat Penuh</span>
                                                            </div>
                                                        </a>
                                                    ))}
                                                </div>
                                            </div>
                                        )}
                                    </>
                                ) : (
                                    <>
                                        <div className="space-y-1">
                                            <label className="text-xs uppercase tracking-wider text-gray-400 font-bold">Start Date</label>
                                            <div className="font-semibold text-lg text-gray-900">{request.start_date ? format(new Date(request.start_date), 'dd MMM yyyy') : '-'}</div>
                                        </div>
                                        <div className="space-y-1">
                                            <label className="text-xs uppercase tracking-wider text-gray-400 font-bold">End Date</label>
                                            <div className="font-semibold text-lg text-gray-900">{request.end_date ? format(new Date(request.end_date), 'dd MMM yyyy') : '-'}</div>
                                        </div>
                                    </>
                                )}
                            </div>
                            <div className="mt-8 pt-8 border-t border-gray-100">
                                <label className="text-xs uppercase tracking-wider text-gray-400 font-bold mb-3 block">Description / Reason</label>
                                <div className="bg-gray-50 rounded-2xl p-6 text-gray-700 leading-relaxed text-sm md:text-base border border-gray-100">
                                    {request.description}
                                </div>
                            </div>
                        </div>
                    </div>

                    {/* Attachments Card (Only show if present) */}
                    {(() => {
                        let attachmentsArray = request.attachments;
                        if (typeof attachmentsArray === 'string') {
                            try {
                                attachmentsArray = JSON.parse(attachmentsArray);
                            } catch (e) {
                                attachmentsArray = [];
                            }
                        }
                        return attachmentsArray && Array.isArray(attachmentsArray) && attachmentsArray.length > 0 ? (
                        <div className="bg-white rounded-3xl shadow-[0_2px_20px_rgba(0,0,0,0.04)] border border-gray-100/50 p-8">
                            <h3 className="text-xl font-bold text-[#1C3ECA] mb-6 flex items-center gap-2">
                                <svg className="w-5 h-5 opacity-50" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15.172 7l-6.586 6.586a2 2 0 102.828 2.828l6.414-6.586a4 4 0 00-5.656-5.656l-6.415 6.585a6 6 0 108.486 8.486L20.5 13" />
                                </svg>
                                Attachments
                            </h3>
                            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                                {attachmentsArray.map((att: string, idx: number) => (
                                    <div key={idx} className="relative group rounded-xl overflow-hidden border border-gray-200 bg-gray-50">
                                        {typeof att === 'string' && att.startsWith('data:image') ? (
                                            <img
                                                src={att}
                                                alt={`Attachment ${idx + 1}`}
                                                className="w-full h-auto object-cover cursor-pointer hover:opacity-90 transition-opacity"
                                                onClick={() => {
                                                    const w = window.open("");
                                                    w?.document.write('<img src="' + att + '" style="max-width:100%"/>');
                                                }}
                                            />
                                        ) : (
                                            <a href={att} target="_blank" rel="noopener noreferrer" className="flex items-center gap-3 p-4 hover:bg-gray-100 transition-colors">
                                                <div className="bg-blue-100 p-2 rounded-lg text-blue-600">
                                                    <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
                                                    </svg>
                                                </div>
                                                <div className="overflow-hidden">
                                                    <p className="text-sm font-semibold text-gray-900 truncate">Attachment {idx + 1}</p>
                                                    <p className="text-xs text-gray-500">Click to view</p>
                                                </div>
                                            </a>
                                        )}
                                    </div>
                                ))}
                            </div>
                        </div>
                        ) : null;
                    })()}

                    {/* Final Proof Image for Overtime */}
                    {request.type === 'overtime' && request.detail?.proof_image_done && Array.isArray(request.detail.proof_image_done) && request.detail.proof_image_done.length > 0 && (
                        <div className="bg-white rounded-3xl shadow-[0_2px_20px_rgba(0,0,0,0.04)] border border-gray-100/50 p-8 mt-6">
                            <h3 className="text-xl font-bold text-[#1C3ECA] mb-6 flex items-center gap-2">
                                <svg className="w-5 h-5 opacity-50" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3 9a2 2 0 012-2h.93a2 2 0 001.664-.89l.812-1.22A2 2 0 0110.07 4h3.86a2 2 0 011.664.89l.812 1.22A2 2 0 0018.07 7H19a2 2 0 012 2v9a2 2 0 01-2 2H5a2 2 0 01-2-2V9z" />
                                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 13a3 3 0 11-6 0 3 3 0 016 0z" />
                                </svg>
                                Bukti Selesai Lembur
                            </h3>
                            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                                {request.detail.proof_image_done.map((att: string, idx: number) => (
                                    <div key={idx} className="relative group rounded-xl overflow-hidden border border-gray-200 bg-gray-50">
                                        {typeof att === 'string' && att.startsWith('data:image') ? (
                                            <img
                                                src={att}
                                                alt={`Final Proof ${idx + 1}`}
                                                className="w-full h-auto object-cover cursor-pointer hover:opacity-90 transition-opacity"
                                                onClick={() => {
                                                    const w = window.open("");
                                                    w?.document.write('<img src="' + att + '" style="max-width:100%"/>');
                                                }}
                                            />
                                        ) : (
                                            <a href={att} target="_blank" rel="noopener noreferrer" className="flex items-center gap-3 p-4 hover:bg-gray-100 transition-colors">
                                                <div className="bg-blue-100 p-2 rounded-lg text-blue-600">
                                                    <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
                                                    </svg>
                                                </div>
                                                <div className="overflow-hidden">
                                                    <p className="text-sm font-semibold text-gray-900 truncate">Proof {idx + 1}</p>
                                                    <p className="text-xs text-gray-500">Click to view</p>
                                                </div>
                                            </a>
                                        )}
                                    </div>
                                ))}
                            </div>
                        </div>
                    )}

                    {/* Right Column: Timeline & Actions */}
                    <div className="space-y-6">
                        {/* Timeline */}
                        <div className="bg-white rounded-3xl shadow-[0_2px_20px_rgba(0,0,0,0.04)] border border-gray-100/50 p-6 md:p-8">
                            <ApprovalTimeline approvals={request.approvals || []} />
                        </div>

                        {/* Action Panel - ONLY show if it's THIS user's turn */}
                        {['pending', 'pending_final'].includes(request.status) && (() => {
                            // Find the current pending step
                            const pendingStep = request.approvals?.find(a => a.status === 'pending');

                            // Check if current user is the approver
                            // Note: user.employee_id is needed in auth store, assuming user.id maps or we use name/email as fallback
                            // Ideally, the API response should include a 'can_approve' flag, but let's try client-side match first.
                            // The backend modification prevented the action, so this is just UI.

                            // Optimization: Check simply if the user is the assigned approver for the current step.
                            const isAdmin = ['super_admin', 'admin', 'hrd'].includes(user?.role?.name || user?.role || '');
                            const isMyTurn = isAdmin || (pendingStep && pendingStep.approver?.id === user?.employee?.id);

                            if (!isMyTurn) {
                                return (
                                    <div className="bg-gray-50 rounded-3xl border border-gray-100 p-6 md:p-8 sticky top-6 text-center">
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
                                );
                            }

                            return (
                                <div className="bg-white rounded-3xl shadow-[0_4px_30px_rgba(0,0,0,0.06)] border border-gray-100/50 p-6 md:p-8 sticky top-6">
                                    <h3 className="text-lg font-bold text-[#1C3ECA] mb-4">Take Action</h3>
                                    <textarea
                                        className="w-full bg-gray-50 border-0 ring-1 ring-gray-200 rounded-xl p-4 text-sm focus:ring-2 focus:ring-[#1C3ECA]/20 focus:bg-white transition-all mb-6 resize-none"
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
                                            className="w-full bg-[#1C3ECA] text-white hover:bg-[#2d1e24] py-3.5 rounded-xl font-bold shadow-lg shadow-[#1C3ECA]/20 hover:shadow-xl hover:-translate-y-0.5 transition-all disabled:opacity-50 text-sm"
                                        >
                                            Approve
                                        </button>
                                    </div>
                                </div>
                            );
                        })()}
                    </div>
                </div>
            </div>

            {showApproveModal && (
                <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50 backdrop-blur-sm">
                    <div className="bg-white rounded-2xl w-full max-w-md p-6 shadow-2xl relative">
                        <button onClick={() => setShowApproveModal(false)} className="absolute top-4 right-4 text-gray-400 hover:text-gray-600">
                            <svg className="w-6 h-6" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" /></svg>
                        </button>
                        <h3 className="text-xl font-bold text-[#1C3ECA] mb-6">Confirm Approval</h3>
                        <div className="space-y-4">
                            <div>
                                <label className="block text-sm font-bold text-gray-700 mb-1">Signer Name</label>
                                <input
                                    type="text"
                                    value={signerName}
                                    onChange={(e) => setSignerName(e.target.value)}
                                    className="w-full border border-gray-300 rounded-lg p-2.5 focus:ring-2 focus:ring-[#1C3ECA] focus:border-[#1C3ECA]"
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
                                        onClick={() => sigCanvas.current.clear()}
                                        className="absolute bottom-2 right-2 text-xs bg-white border border-gray-200 px-2 py-1 rounded shadow-sm hover:bg-gray-100"
                                    >Clear</button>
                                </div>
                            </div>

                            <div className="pt-4 flex gap-3">
                                <button onClick={() => setShowApproveModal(false)} className="flex-1 py-3 border border-gray-200 rounded-xl font-bold text-gray-600 hover:bg-gray-50">Cancel</button>
                                <button onClick={submitApproval} disabled={isProcessing} className="flex-1 py-3 bg-[#1C3ECA] text-white rounded-xl font-bold hover:bg-[#2d1e24]">
                                    {isProcessing ? 'Processing...' : 'Confirm Approve'}
                                </button>
                            </div>
                        </div>
                    </div>
                </div>
            )}
        </DashboardLayout>
    );
}
