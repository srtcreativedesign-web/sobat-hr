'use client';

import DashboardLayout from '@/components/DashboardLayout';
import { STORAGE_KEYS } from '@/lib/config';
import { useAuthStore } from '@/store/auth-store';
import { Approval, PaginatedResponse } from '@/types';
import { format, differenceInDays } from 'date-fns';
import { useRouter } from 'next/navigation';
import { useEffect, useState } from 'react';

export default function ApprovalsPage() {
    const router = useRouter();
    const { user } = useAuthStore();
    const [approvals, setApprovals] = useState<Approval[]>([]);
    const [isLoading, setIsLoading] = useState(true);
    const [activeTab, setActiveTab] = useState('pending'); // Renamed from filter
    const [activeType, setActiveType] = useState('all');
    const [currentPage, setCurrentPage] = useState(1);


    useEffect(() => {
        const fetchApprovals = async () => {
            setIsLoading(true); // Set loading to true when fetching starts
            try {
                const token = localStorage.getItem(STORAGE_KEYS.TOKEN);
                // We will fetch approvals.
                // Note: The ApprovalController needs to support filtering by "my pending action".
                const query = new URLSearchParams({
                    page: currentPage.toString(),
                    status: activeTab === 'history' ? 'approved,rejected' : 'pending' // pending is default
                });

                if (activeType !== 'all') {
                    query.append('type', activeType);
                }

                // The endpoint GET /approvals/pending is typically for this.
                // Changed to /requests as per instruction, assuming approvals are now part of requests
                const endpoint = `${process.env.NEXT_PUBLIC_API_URL}/requests?${query.toString()}`;

                const response = await fetch(endpoint, {
                    headers: {
                        'Authorization': `Bearer ${token}`
                    }
                });

                if (response.ok) {
                    // It might return PaginatedResponse or Array. Let's assume Array based on generic implementation often used.
                    // If paginated, we extract .data
                    const data = await response.json();
                    if (Array.isArray(data)) {
                        setApprovals(data);
                    } else if (data.data && Array.isArray(data.data)) {
                        setApprovals(data.data);
                    }
                } else {
                    console.error("Failed to fetch approvals, status:", response.status);
                    setApprovals([]); // Clear approvals on error
                }
            } catch (error) {
                console.error("Failed to fetch approvals", error);
                setApprovals([]); // Clear approvals on error
            } finally {
                setIsLoading(false);
            }
        };

        fetchApprovals();
    }, [activeTab, activeType, currentPage]); // Dependencies for re-fetching

    return (
        <DashboardLayout>
            <div className="p-6 md:p-8">
                <div className="mb-6">
                    <h1 className="text-2xl font-bold text-[#1C3ECA]">Approval Inbox</h1>
                    <p className="text-[#1C3ECA]/70">Manage requests awaiting your review.</p>
                </div>

                <div className="mb-6">
                    <div className="inline-flex bg-gray-100 p-1 rounded-xl">
                        <button
                            onClick={() => { setActiveTab('pending'); setCurrentPage(1); }}
                            className={`px-6 py-2 rounded-lg text-sm font-bold transition-all ${activeTab === 'pending'
                                ? 'bg-white text-[#1C3ECA] shadow-sm'
                                : 'text-gray-500 hover:text-gray-700'
                                }`}
                        >
                            Pending
                        </button>
                        <button
                            onClick={() => { setActiveTab('history'); setCurrentPage(1); }}
                            className={`px-6 py-2 rounded-lg text-sm font-bold transition-all ${activeTab === 'history'
                                ? 'bg-white text-[#1C3ECA] shadow-sm'
                                : 'text-gray-500 hover:text-gray-700'
                                }`}
                        >
                            History
                        </button>
                    </div>
                </div>

                {/* Type Filters / Sub-menus */}
                <div className="flex overflow-x-auto pb-4 gap-2 no-scrollbar mb-2">
                    {[
                        { id: 'all', label: 'All' },
                        // { id: 'business_trip', label: 'Business Trip' },
                        // { id: 'reimbursement', label: 'Reimbursement' },
                        // { id: 'asset', label: 'Asset' },
                        { id: 'leave', label: 'Leave' },
                        { id: 'overtime', label: 'Overtime' },
                        { id: 'sick_leave', label: 'Sick' },
                        // { id: 'resignation', label: 'Resignation' },
                    ].map((type) => (
                        <button
                            key={type.id}
                            onClick={() => { setActiveType(type.id); setCurrentPage(1); }}
                            className={`px-4 py-2 rounded-full text-sm font-medium whitespace-nowrap transition-all
                            ${activeType === type.id
                                    ? 'bg-[#1C3ECA] text-white shadow-md'
                                    : 'bg-white text-gray-600 border border-gray-200 hover:bg-gray-50'}`}
                        >
                            {type.label}
                        </button>
                    ))}
                </div>

                <div className="bg-white rounded-3xl shadow-[0_2px_20px_rgba(0,0,0,0.04)] border border-gray-100 overflow-hidden min-h-[400px]">
                    {isLoading ? (
                        <div className="flex flex-col items-center justify-center h-[400px] gap-3">
                            <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-[#1C3ECA]"></div>
                            <p className="text-gray-500 text-sm">Loading approvals...</p>
                        </div>
                    ) : approvals.length === 0 ? (
                        <div className="flex flex-col items-center justify-center h-[400px] text-center p-8 bg-gray-50/50">
                            <div className="w-20 h-20 bg-white rounded-full flex items-center justify-center shadow-[0_4px_20px_rgba(0,0,0,0.05)] mb-6">
                                <span className="text-3xl">📭</span>
                            </div>
                            <h3 className="text-xl font-bold text-[#1C3ECA] mb-2">No Approvals Pending</h3>
                            <p className="text-[#1C3ECA]/60">You're all caught up! There are no requests awaiting your review.</p>
                        </div>
                    ) : (
                        <div className="overflow-x-auto">
                            <table className="w-full">
                                <thead className="bg-[#1C3ECA]/5 border-b border-[#1C3ECA]/10">
                                    <tr>
                                        <th className="px-6 py-4 text-left text-xs font-bold text-[#1C3ECA]/70 uppercase tracking-wider">Requester</th>
                                        <th className="px-6 py-4 text-left text-xs font-bold text-[#1C3ECA]/70 uppercase tracking-wider">Request Type</th>
                                        <th className="px-6 py-4 text-left text-xs font-bold text-[#1C3ECA]/70 uppercase tracking-wider">Details</th>
                                        <th className="px-6 py-4 text-left text-xs font-bold text-[#1C3ECA]/70 uppercase tracking-wider">Submitted</th>
                                        <th className="px-6 py-4 text-left text-xs font-bold text-[#1C3ECA]/70 uppercase tracking-wider">Status</th>
                                        <th className="px-6 py-4 text-left text-xs font-bold text-[#1C3ECA]/70 uppercase tracking-wider">Action</th>
                                    </tr>
                                </thead>
                                <tbody className="divide-y divide-[#1C3ECA]/5">
                                    {approvals.map((req: any) => {
                                        // The API returns RequestModel objects directly when using /requests endpoint

                                        return (
                                            <tr key={req.id} className="hover:bg-[#1C3ECA]/[0.02] transition-colors group">
                                                <td className="px-6 py-4">
                                                    <div className="flex items-center">
                                                        <div className="h-9 w-9 rounded-full bg-gradient-to-br from-[#1C3ECA] to-[#2d1e24] flex items-center justify-center text-white text-xs font-bold mr-3 shadow-md">
                                                            {req.employee?.full_name?.charAt(0) || '?'}
                                                        </div>
                                                        <div>
                                                            <div className="text-sm font-bold text-[#1C3ECA] group-hover:text-[#2d1e24] transition-colors">{req.employee?.full_name}</div>
                                                            <div className="text-xs text-[#1C3ECA]/60">{req.employee?.position || 'Staff'}</div>
                                                        </div>
                                                    </div>
                                                </td>
                                                <td className="px-6 py-4">
                                                    <span className={`inline-flex items-center px-2.5 py-0.5 rounded-lg text-xs font-bold capitalize shadow-sm
                                            ${req.type === 'leave' ? 'bg-blue-50 text-blue-700 border border-blue-100' :
                                                            req.type === 'overtime' ? 'bg-purple-50 text-purple-700 border border-purple-100' :
                                                                'bg-gray-50 text-gray-700 border border-gray-100'}`}>
                                                        {req.type?.replace(/_/g, ' ')}
                                                    </span>
                                                </td>
                                                <td className="px-6 py-4">
                                                    <div className="text-sm font-medium text-[#1C3ECA] line-clamp-1">{req.title || req.description}</div>
                                                    <div className="text-xs text-[#1C3ECA]/60 mt-0.5">
                                                        {['asset', 'reimbursement'].includes(req.type)
                                                            ? `IDR ${Number(req.amount).toLocaleString('id-ID')}`
                                                            : req.type === 'resignation'
                                                                ? `${req.detail?.last_working_date ? format(new Date(req.detail.last_working_date), 'dd MMM yyyy') : req.start_date ? format(new Date(req.start_date), 'dd MMM yyyy') : '-'}`
                                                                : `${req.amount || (req.start_date && req.end_date ? differenceInDays(new Date(req.end_date), new Date(req.start_date)) + 1 : 1)} ${['leave', 'business_trip', 'sick_leave'].includes(req.type) ? 'Days' : req.type === 'overtime' ? 'Hours' : 'Units'} • ${req.start_date ? format(new Date(req.start_date), 'dd MMM yyyy') : '-'}`
                                                        }
                                                    </div>
                                                </td>
                                                <td className="px-6 py-4 text-sm text-[#1C3ECA]/50">
                                                    {new Date(req.submitted_at || '').toLocaleDateString('id-ID', { day: 'numeric', month: 'short' })}
                                                </td>
                                                <td className="px-6 py-4">
                                                    <span className={`inline-flex items-center px-2.5 py-0.5 rounded-lg text-xs font-bold capitalize shadow-sm
                                                        ${req.status === 'approved' ? 'bg-green-50 text-green-700 border border-green-100' :
                                                            req.status === 'rejected' ? 'bg-red-50 text-red-700 border border-red-100' :
                                                                'bg-amber-50 text-amber-700 border border-amber-100'}`}>
                                                        {req.status}
                                                    </span>
                                                </td>
                                                <td className="px-6 py-4">
                                                    {req.id && (
                                                        <button
                                                            onClick={() => router.push(`/approvals/${req.id}`)}
                                                            className="inline-flex items-center px-4 py-1.5 border border-[#1C3ECA]/20 text-sm font-bold rounded-lg text-[#1C3ECA] bg-white hover:bg-[#1C3ECA] hover:text-white hover:border-[#1C3ECA] transition-all shadow-sm hover:shadow-md"
                                                        >
                                                            Review
                                                        </button>
                                                    )}
                                                </td>
                                            </tr>
                                        );
                                    })}
                                </tbody>
                            </table>
                        </div>
                    )}
                </div>
            </div>
        </DashboardLayout>
    );
}
