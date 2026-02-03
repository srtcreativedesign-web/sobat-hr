'use client';

import DashboardLayout from '@/components/DashboardLayout';
import { STORAGE_KEYS } from '@/lib/config';
import { useRouter } from 'next/navigation';
import { useEffect, useState } from 'react';

interface ResetRequest {
    id: number;
    phone: string;
    status: string;
    created_at: string;
    user: {
        id: number;
        name: string;
        employee?: {
            full_name: string;
            position: string;
        }
    };
}

export default function ResetRequestsPage() {
    const router = useRouter();
    const [requests, setRequests] = useState<ResetRequest[]>([]);
    const [isLoading, setIsLoading] = useState(true);
    const [actionLoading, setActionLoading] = useState<number | null>(null);

    // Dialog state
    const [successDialog, setSuccessDialog] = useState<{ open: boolean; tempPass: string; phone: string; name: string } | null>(null);

    const fetchRequests = async () => {
        setIsLoading(true);
        try {
            const token = localStorage.getItem(STORAGE_KEYS.TOKEN);
            const response = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/admin/password-requests`, {
                headers: {
                    'Authorization': `Bearer ${token}`
                }
            });

            if (response.ok) {
                const data = await response.json();
                setRequests(data.data || []);
            }
        } catch (error) {
            console.error("Failed to fetch requests", error);
        } finally {
            setIsLoading(false);
        }
    };

    useEffect(() => {
        fetchRequests();
    }, []);

    const handleApprove = async (id: number) => {
        setActionLoading(id);
        try {
            const token = localStorage.getItem(STORAGE_KEYS.TOKEN);
            const response = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/admin/password-requests/${id}/approve`, {
                method: 'POST',
                headers: {
                    'Authorization': `Bearer ${token}`,
                    'Content-Type': 'application/json'
                }
            });

            if (response.ok) {
                const data = await response.json();
                setSuccessDialog({
                    open: true,
                    tempPass: data.temp_password,
                    phone: data.phone,
                    name: data.user_name
                });
                fetchRequests(); // Refresh list
            } else {
                alert('Failed to approve request');
            }
        } catch (error) {
            console.error(error);
            alert('Error processing request');
        } finally {
            setActionLoading(null);
        }
    };

    const handleReject = async (id: number) => {
        if (!confirm('Are you sure you want to reject this request?')) return;

        setActionLoading(id);
        try {
            const token = localStorage.getItem(STORAGE_KEYS.TOKEN);
            const response = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/admin/password-requests/${id}/reject`, {
                method: 'POST',
                headers: {
                    'Authorization': `Bearer ${token}`,
                    'Content-Type': 'application/json'
                }
            });

            if (response.ok) {
                fetchRequests();
            }
        } catch (error) {
            console.error(error);
        } finally {
            setActionLoading(null);
        }
    };

    const sendWhatsApp = () => {
        if (!successDialog) return;

        // Format phone (remove leading 0 or +62, ensure 62 prefix)
        let phone = successDialog.phone.replace(/\D/g, '');
        if (phone.startsWith('0')) {
            phone = '62' + phone.substring(1);
        }

        const message = `Halo ${successDialog.name}, permintaan reset password Anda telah disetujui. Password sementara Anda adalah: *${successDialog.tempPass}* . Silakan login dan segera ganti password Anda.`;
        const url = `https://wa.me/${phone}?text=${encodeURIComponent(message)}`;

        window.open(url, '_blank');
    };

    return (
        <DashboardLayout>
            <div className="p-6 md:p-8">
                <div className="mb-6">
                    <h1 className="text-2xl font-bold text-[#462e37]">Password Reset Requests</h1>
                    <p className="text-[#462e37]/70">Approve requests and send temporary passwords.</p>
                </div>

                <div className="bg-white rounded-3xl shadow-[0_2px_20px_rgba(0,0,0,0.04)] border border-gray-100 overflow-hidden min-h-[400px]">
                    {isLoading ? (
                        <div className="flex flex-col items-center justify-center h-[400px] gap-3">
                            <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-[#462e37]"></div>
                            <p className="text-gray-500 text-sm">Loading requests...</p>
                        </div>
                    ) : requests.length === 0 ? (
                        <div className="flex flex-col items-center justify-center h-[400px] text-center p-8 bg-gray-50/50">
                            <div className="w-20 h-20 bg-white rounded-full flex items-center justify-center shadow-[0_4px_20px_rgba(0,0,0,0.05)] mb-6">
                                <span className="text-3xl">🔐</span>
                            </div>
                            <h3 className="text-xl font-bold text-[#462e37] mb-2">No Pending Requests</h3>
                            <p className="text-[#462e37]/60">There are no password reset requests at the moment.</p>
                        </div>
                    ) : (
                        <div className="overflow-x-auto">
                            <table className="w-full">
                                <thead className="bg-[#462e37]/5 border-b border-[#462e37]/10">
                                    <tr>
                                        <th className="px-6 py-4 text-left text-xs font-bold text-[#462e37]/70 uppercase tracking-wider">User</th>
                                        <th className="px-6 py-4 text-left text-xs font-bold text-[#462e37]/70 uppercase tracking-wider">Phone</th>
                                        <th className="px-6 py-4 text-left text-xs font-bold text-[#462e37]/70 uppercase tracking-wider">Requested At</th>
                                        <th className="px-6 py-4 text-left text-xs font-bold text-[#462e37]/70 uppercase tracking-wider">Action</th>
                                    </tr>
                                </thead>
                                <tbody className="divide-y divide-[#462e37]/5">
                                    {requests.map((req) => (
                                        <tr key={req.id} className="hover:bg-[#462e37]/[0.02] transition-colors">
                                            <td className="px-6 py-4">
                                                <div className="font-bold text-[#462e37]">{req.user?.employee?.full_name || req.user?.name}</div>
                                                <div className="text-xs text-[#462e37]/60">{req.user?.employee?.position || 'User'}</div>
                                            </td>
                                            <td className="px-6 py-4 text-sm font-medium text-[#462e37]">{req.phone}</td>
                                            <td className="px-6 py-4 text-sm text-[#462e37]/60">
                                                {new Date(req.created_at).toLocaleString('id-ID')}
                                            </td>
                                            <td className="px-6 py-4">
                                                <div className="flex gap-2">
                                                    <button
                                                        onClick={() => handleApprove(req.id)}
                                                        disabled={actionLoading === req.id}
                                                        className="px-4 py-1.5 bg-green-600 text-white text-sm font-bold rounded-lg hover:bg-green-700 shadow-sm disabled:opacity-50"
                                                    >
                                                        {actionLoading === req.id ? '...' : 'Approve'}
                                                    </button>
                                                    <button
                                                        onClick={() => handleReject(req.id)}
                                                        disabled={actionLoading === req.id}
                                                        className="px-4 py-1.5 border border-red-200 text-red-600 text-sm font-bold rounded-lg hover:bg-red-50 disabled:opacity-50"
                                                    >
                                                        Reject
                                                    </button>
                                                </div>
                                            </td>
                                        </tr>
                                    ))}
                                </tbody>
                            </table>
                        </div>
                    )}
                </div>
            </div>

            {/* Success Dialog */}
            {successDialog && (
                <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
                    <div className="bg-white rounded-2xl w-full max-w-md p-6 shadow-xl transform transition-all">
                        <div className="text-center mb-6">
                            <div className="w-16 h-16 bg-green-100 rounded-full flex items-center justify-center mx-auto mb-4">
                                <span className="text-2xl">✅</span>
                            </div>
                            <h3 className="text-xl font-bold text-[#462e37]">Password Reset Successful</h3>
                            <p className="text-[#462e37]/70 mt-2">Temporary password generated for {successDialog.name}</p>
                        </div>

                        <div className="bg-gray-50 p-4 rounded-xl text-center mb-6 border border-gray-100">
                            <p className="text-xs text-gray-500 mb-1">Temporary Password</p>
                            <p className="text-2xl font-mono font-bold text-[#462e37] tracking-wider select-all">{successDialog.tempPass}</p>
                        </div>

                        <div className="flex flex-col gap-3">
                            <button
                                onClick={sendWhatsApp}
                                className="w-full py-3 bg-[#25D366] text-white font-bold rounded-xl hover:bg-[#128C7E] transition-colors shadow-lg shadow-green-200 flex items-center justify-center gap-2"
                            >
                                <span>📱</span> Send via WhatsApp
                            </button>
                            <button
                                onClick={() => setSuccessDialog(null)}
                                className="w-full py-3 text-[#462e37]/70 font-bold hover:text-[#462e37] transition-colors"
                            >
                                Close
                            </button>
                        </div>
                    </div>
                </div>
            )}
        </DashboardLayout>
    );
}
