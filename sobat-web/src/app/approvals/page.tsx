'use client';

import DashboardLayout from '@/components/DashboardLayout';
import { STORAGE_KEYS } from '@/lib/config';
import apiClient from '@/lib/api-client';
import { useAuthStore } from '@/store/auth-store';
import { Approval } from '@/types';
import { format, differenceInDays } from 'date-fns';
import { DataTable } from '@/components/ui/data-table';
import { User, Chip, Button } from '@nextui-org/react';
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
                // We will fetch approvals.
                // Note: The ApprovalController needs to support filtering by "my pending action".
                const query = new URLSearchParams();
                query.append('page', currentPage.toString());
                
                let fetchStatus = 'pending,pending_final';
                if (activeTab === 'history') fetchStatus = 'approved,rejected';
                if (activeTab === 'spl_open') fetchStatus = 'spl_approved,spl_open';
                
                query.append('status', fetchStatus);

                if (activeType !== 'all') {
                    query.append('type', activeType);
                }

                const endpoint = `/requests?${query.toString()}`;

                const response = await apiClient.get(endpoint);
                const data = response.data;
                
                if (Array.isArray(data)) {
                    setApprovals(data);
                } else if (data.data && Array.isArray(data.data)) {
                    setApprovals(data.data);
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

    const columns = [
        { name: "REQUESTER", uid: "requester" },
        { name: "REQUEST TYPE", uid: "type" },
        { name: "DETAILS", uid: "details" },
        { name: "SUBMITTED", uid: "submitted" },
        { name: "STATUS", uid: "status" },
        { name: "ACTION", uid: "action" }
    ];

    const getTypeColor = (type: string) => {
        const map: Record<string, "primary" | "secondary" | "success" | "warning" | "danger" | "default"> = {
            leave: "primary",
            overtime: "secondary",
            business_trip: "warning",
            sick_leave: "danger",
            reimbursement: "success",
            asset: "default",
            resignation: "danger"
        };
        return map[type] || "default";
    };

    const getStatusColor = (status: string) => {
        const map: Record<string, "success" | "danger" | "warning" | "primary" | "default"> = {
            approved: "success",
            spl_open: "primary",
            spl_approved: "primary",
            rejected: "danger",
            pending: "warning",
            pending_final: "warning"
        };
        return map[status] || "default";
    };

    const getStatusLabel = (status: string) => {
        if (status === 'spl_open') return 'Lembur Berjalan';
        if (status === 'spl_approved') return 'Menunggu Mulai';
        return status;
    };

    const renderCell = (req: any, columnKey: React.Key) => {
        switch (columnKey) {
            case "requester":
                return (
                    <User
                        avatarProps={{ radius: "lg", name: req.employee?.full_name?.charAt(0) || '?' }}
                        description={req.employee?.position || 'Staff'}
                        name={req.employee?.full_name || 'Unknown'}
                    >
                        {req.employee?.full_name}
                    </User>
                );
            case "type":
                return (
                    <Chip size="sm" variant="flat" color={getTypeColor(req.type)} className="capitalize">
                        {req.type?.replace(/_/g, ' ')}
                    </Chip>
                );
            case "details":
                return (
                    <div className="flex flex-col">
                        <p className="text-sm font-medium line-clamp-1">{req.title || req.description}</p>
                        <p className="text-xs text-default-400 mt-0.5">
                            {['asset', 'reimbursement'].includes(req.type)
                                ? `IDR ${Number(req.amount).toLocaleString('id-ID')}`
                                : req.type === 'resignation'
                                    ? `${req.detail?.last_working_date ? format(new Date(req.detail.last_working_date), 'dd MMM yyyy') : req.start_date ? format(new Date(req.start_date), 'dd MMM yyyy') : '-'}`
                                    : `${req.amount || (req.start_date && req.end_date ? differenceInDays(new Date(req.end_date), new Date(req.start_date)) + 1 : 1)} ${['leave', 'business_trip', 'sick_leave'].includes(req.type) ? 'Days' : req.type === 'overtime' ? 'Hours' : 'Units'} • ${req.start_date ? format(new Date(req.start_date), 'dd MMM yyyy') : '-'}`
                            }
                        </p>
                    </div>
                );
            case "submitted":
                return (
                    <p className="text-sm text-default-500">
                        {req.submitted_at ? new Date(req.submitted_at).toLocaleDateString('id-ID', { day: 'numeric', month: 'short' }) : '-'}
                    </p>
                );
            case "status":
                return (
                    <Chip size="sm" variant="flat" color={getStatusColor(req.status)} className="capitalize">
                        {getStatusLabel(req.status)}
                    </Chip>
                );
            case "action":
                return req.id ? (
                    <Button color="primary" variant="light" size="sm" onPress={() => router.push(`/approvals/${req.id}`)}>
                        Review
                    </Button>
                ) : null;
            default:
                return null;
        }
    };

    return (
        <DashboardLayout>
            <div className="p-6 md:p-8">
                <div className="mb-6">
                    <h1 className="text-2xl font-bold text-[#419cc3]">Approval Inbox</h1>
                    <p className="text-[#419cc3]/70">Manage requests awaiting your review.</p>
                </div>

                <div className="mb-6">
                    <div className="inline-flex bg-gray-100 p-1 rounded-xl">
                        <button
                            onClick={() => { setActiveTab('pending'); setCurrentPage(1); }}
                            className={`px-6 py-2 rounded-lg text-sm font-bold transition-all ${activeTab === 'pending'
                                ? 'bg-white text-[#419cc3] shadow-sm'
                                : 'text-gray-500 hover:text-gray-700'
                                }`}
                        >
                            Pending
                        </button>
                        <button
                            onClick={() => { setActiveTab('history'); setCurrentPage(1); }}
                            className={`px-6 py-2 rounded-lg text-sm font-bold transition-all ${activeTab === 'history'
                                ? 'bg-white text-[#419cc3] shadow-sm'
                                : 'text-gray-500 hover:text-gray-700'
                                }`}
                        >
                            History
                        </button>
                        <button
                            onClick={() => { setActiveTab('spl_open'); setCurrentPage(1); }}
                            className={`px-6 py-2 rounded-lg text-sm font-bold transition-all ${activeTab === 'spl_open'
                                ? 'bg-white text-[#419cc3] shadow-sm'
                                : 'text-gray-500 hover:text-gray-700'
                                }`}
                        >
                            SPL Open
                        </button>
                    </div>
                </div>

                {/* Type Filters / Sub-menus */}
                <div className="flex overflow-x-auto pb-4 gap-2 no-scrollbar mb-2">
                    {[
                        { id: 'all', label: 'All' },
                        { id: 'business_trip', label: 'Business Trip' },
                        { id: 'reimbursement', label: 'Reimbursement' },
                        { id: 'asset', label: 'Asset' },
                        { id: 'leave', label: 'Leave' },
                        { id: 'overtime', label: 'Overtime' },
                        { id: 'sick_leave', label: 'Sick' },
                        { id: 'resignation', label: 'Resignation' },
                    ].map((type) => (
                        <button
                            key={type.id}
                            onClick={() => { setActiveType(type.id); setCurrentPage(1); }}
                            className={`px-4 py-2 rounded-full text-sm font-medium whitespace-nowrap transition-all
                            ${activeType === type.id
                                    ? 'bg-[#419cc3] text-white shadow-md'
                                    : 'bg-white text-gray-600 border border-gray-200 hover:bg-gray-50'}`}
                        >
                            {type.label}
                        </button>
                    ))}
                </div>

                <div className="bg-white rounded-3xl shadow-[0_2px_20px_rgba(0,0,0,0.04)] border border-gray-100 overflow-hidden min-h-[400px]">
                    <DataTable
                        columns={columns}
                        data={approvals}
                        isLoading={isLoading}
                        renderCell={renderCell}
                        primaryKey="id"
                        page={currentPage}
                        pages={1}
                        emptyContent={
                            <div className="flex flex-col items-center justify-center p-8 text-center">
                                <div className="w-20 h-20 bg-default-100 rounded-full flex items-center justify-center mb-6">
                                    <span className="text-3xl">📭</span>
                                </div>
                                <h3 className="text-xl font-bold text-default-900 mb-2">No Approvals Pending</h3>
                                <p className="text-default-500">You&apos;re all caught up! There are no requests awaiting your review.</p>
                            </div>
                        }
                    />
                </div>
            </div>
        </DashboardLayout>
    );
}
