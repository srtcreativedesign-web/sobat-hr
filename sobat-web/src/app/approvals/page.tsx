'use client';

import DashboardLayout from '@/components/DashboardLayout';
import { STORAGE_KEYS } from '@/lib/config';
import { useAuthStore } from '@/store/auth-store';
import { Approval, PaginatedResponse } from '@/types';
import { useRouter } from 'next/navigation';
import { useEffect, useState } from 'react';

export default function ApprovalsPage() {
    const router = useRouter();
    const { user } = useAuthStore();
    const [approvals, setApprovals] = useState<Approval[]>([]);
    const [isLoading, setIsLoading] = useState(true);
    const [filter, setFilter] = useState<'pending' | 'history'>('pending');

    useEffect(() => {
        const fetchApprovals = async () => {
            try {
                const token = localStorage.getItem(STORAGE_KEYS.TOKEN);
                // We will fetch approvals. 
                // Note: The ApprovalController needs to support filtering by "my pending action".
                // The endpoint GET /approvals/pending is typically for this.
                const endpoint = filter === 'pending'
                    ? `${process.env.NEXT_PUBLIC_API_URL}/approvals/pending`
                    : `${process.env.NEXT_PUBLIC_API_URL}/approvals?status=finished`; // Or a specific history endpoint

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
                }
            } catch (error) {
                console.error("Failed to fetch approvals", error);
            } finally {
                setIsLoading(false);
            }
        };

        fetchApprovals();
    }, [filter]);

    return (
        <DashboardLayout>
            <div className="p-6 md:p-8">
                <div className="mb-6">
                    <h1 className="text-2xl font-bold text-[#462e37]">Approval Inbox</h1>
                    <p className="text-[#462e37]/70">Manage requests awaiting your review.</p>
                </div>

                <div className="mb-6">
                    <div className="inline-flex bg-gray-100 p-1 rounded-xl">
                        <button
                            onClick={() => setFilter('pending')}
                            className={`px-6 py-2 rounded-lg text-sm font-bold transition-all ${filter === 'pending'
                                ? 'bg-white text-[#462e37] shadow-sm'
                                : 'text-gray-500 hover:text-gray-700'
                                }`}
                        >
                            Pending
                        </button>
                        <button
                            onClick={() => setFilter('history')}
                            className={`px-6 py-2 rounded-lg text-sm font-bold transition-all ${filter === 'history'
                                ? 'bg-white text-[#462e37] shadow-sm'
                                : 'text-gray-500 hover:text-gray-700'
                                }`}
                        >
                            History
                        </button>
                    </div>
                </div>

                <div className="bg-white rounded-2xl shadow-sm border border-[#462e37]/5 overflow-hidden min-h-[400px]">
                    {isLoading ? (
                        <div className="flex flex-col items-center justify-center h-[400px] gap-3">
                            <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-[#462e37]"></div>
                            <p className="text-gray-500 text-sm">Loading approvals...</p>
                        </div>
                    ) : approvals.length === 0 ? (
                        <div className="flex flex-col items-center justify-center h-[400px] text-center p-8 bg-gray-50/50">
                            <div className="w-20 h-20 bg-white rounded-full flex items-center justify-center shadow-[0_4px_20px_rgba(0,0,0,0.05)] mb-6">
                                <span className="text-3xl">📭</span>
                            </div>
                            <h3 className="text-xl font-bold text-[#462e37] mb-2">No Approvals Pending</h3>
                            <p className="text-[#462e37]/60">You're all caught up! There are no requests awaiting your review.</p>
                        </div>
                    ) : (
                        <div className="overflow-x-auto">
                            <table className="w-full">
                                <thead className="bg-[#462e37]/5 border-b border-[#462e37]/10">
                                    <tr>
                                        <th className="px-6 py-4 text-left text-xs font-bold text-[#462e37]/70 uppercase tracking-wider">Requester</th>
                                        <th className="px-6 py-4 text-left text-xs font-bold text-[#462e37]/70 uppercase tracking-wider">Request Type</th>
                                        <th className="px-6 py-4 text-left text-xs font-bold text-[#462e37]/70 uppercase tracking-wider">Details</th>
                                        <th className="px-6 py-4 text-left text-xs font-bold text-[#462e37]/70 uppercase tracking-wider">Submitted</th>
                                        <th className="px-6 py-4 text-left text-xs font-bold text-[#462e37]/70 uppercase tracking-wider">Action</th>
                                    </tr>
                                </thead>
                                <tbody className="divide-y divide-[#462e37]/5">
                                    {approvals.map((approval) => {
                                        // Helper to extract nested data safely
                                        const req = (approval.approvable || {}) as unknown as any; // Cast to any to avoid strict checks on partial data or Request type

                                        return (
                                            <tr key={approval.id} className="hover:bg-[#462e37]/[0.02] transition-colors group">
                                                <td className="px-6 py-4">
                                                    <div className="flex items-center">
                                                        <div className="h-9 w-9 rounded-full bg-gradient-to-br from-[#462e37] to-[#2d1e24] flex items-center justify-center text-white text-xs font-bold mr-3 shadow-md">
                                                            {req.employee?.full_name?.charAt(0) || '?'}
                                                        </div>
                                                        <div>
                                                            <div className="text-sm font-bold text-[#462e37] group-hover:text-[#2d1e24] transition-colors">{req.employee?.full_name}</div>
                                                            <div className="text-xs text-[#462e37]/60">{req.employee?.position || 'Staff'}</div>
                                                        </div>
                                                    </div>
                                                </td>
                                                <td className="px-6 py-4">
                                                    <span className={`inline-flex items-center px-2.5 py-0.5 rounded-lg text-xs font-bold capitalize shadow-sm
                                            ${req.type === 'leave' ? 'bg-blue-50 text-blue-700 border border-blue-100' :
                                                            req.type === 'overtime' ? 'bg-purple-50 text-purple-700 border border-purple-100' :
                                                                'bg-gray-50 text-gray-700 border border-gray-100'}`}>
                                                        {req.type}
                                                    </span>
                                                </td>
                                                <td className="px-6 py-4">
                                                    <div className="text-sm font-medium text-[#462e37] line-clamp-1">{req.title || req.description}</div>
                                                    <div className="text-xs text-[#462e37]/60 mt-0.5">
                                                        {req.amount} Days • {req.start_date}
                                                    </div>
                                                </td>
                                                <td className="px-6 py-4 text-sm text-[#462e37]/50">
                                                    {new Date(req.submitted_at || '').toLocaleDateString('id-ID', { day: 'numeric', month: 'short' })}
                                                </td>
                                                <td className="px-6 py-4">
                                                    <button
                                                        onClick={() => router.push(`/approvals/${req.id}`)}
                                                        className="inline-flex items-center px-4 py-1.5 border border-[#462e37]/20 text-sm font-bold rounded-lg text-[#462e37] bg-white hover:bg-[#462e37] hover:text-white hover:border-[#462e37] transition-all shadow-sm hover:shadow-md"
                                                    >
                                                        Review
                                                    </button>
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
