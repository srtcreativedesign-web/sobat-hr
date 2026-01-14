'use client';

import { useState, useEffect } from 'react';
import apiClient from '@/lib/api-client';

interface Invitation {
    id: number;
    name: string;
    email: string;
    token: string;
    created_at: string;
}

export default function InvitationList({ refreshTrigger }: { refreshTrigger: number }) {
    const [invitations, setInvitations] = useState<Invitation[]>([]);
    const [loading, setLoading] = useState(true);
    const [copiedId, setCopiedId] = useState<number | null>(null);

    const fetchInvitations = async () => {
        setLoading(true);
        try {
            const response = await apiClient.get('/staff/invitations');
            setInvitations(response.data.data); // Assuming paginated response
        } catch (error) {
            console.error('Failed to fetch invitations:', error);
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        fetchInvitations();
    }, [refreshTrigger]);

    const handleCopyLink = (token: string, id: number) => {
        // Construct the registration link
        // Assuming the registration page is at /register
        const link = `${window.location.origin}/register?token=${token}`;

        navigator.clipboard.writeText(link).then(() => {
            setCopiedId(id);
            setTimeout(() => setCopiedId(null), 2000); // Reset after 2 seconds
        });
    };

    const handleExport = async () => {
        try {
            const response = await apiClient.get('/staff/invitations/export', {
                responseType: 'blob', // Important for file download
            });

            // Create a blob link to download
            const url = window.URL.createObjectURL(new Blob([response.data]));
            const link = document.createElement('a');
            link.href = url;
            link.setAttribute('download', 'pending_invitations.xlsx');
            document.body.appendChild(link);
            link.click();
            link.remove();
        } catch (error) {
            console.error('Export failed:', error);
            alert('Failed to export invitations.');
        }
    };

    if (loading && invitations.length === 0) {
        return (
            <div className="glass-card p-8 mt-8 text-center text-gray-500">
                Loading invitations...
            </div>
        );
    }

    if (invitations.length === 0) {
        return (
            <div className="glass-card p-8 mt-8 text-center">
                <h2 className="text-xl font-bold text-gray-800 mb-2">Pending Invitations</h2>
                <p className="text-gray-500">No pending invitations found.</p>
            </div>
        );
    }

    return (
        <div className="glass-card p-8 animate-fade-in-up mt-8">
            <div className="flex items-center justify-between mb-6">
                <h2 className="text-xl font-bold text-gray-800 flex items-center gap-2">
                    <div className="w-10 h-10 rounded-lg bg-yellow-100 flex items-center justify-center text-yellow-600">
                        <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" /></svg>
                    </div>
                    Pending Invitations (Manual Activation)
                </h2>
                <button
                    onClick={handleExport}
                    className="px-4 py-2 bg-[#462e37] text-white text-sm font-semibold rounded-lg hover:bg-[#143d24] transition-colors flex items-center gap-2"
                >
                    <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-4l-4 4m0 0l-4-4m4 4V4" /></svg>
                    Export to Excel
                </button>
            </div>

            <div className="overflow-x-auto border border-gray-100 rounded-xl">
                <table className="w-full">
                    <thead className="bg-gray-50/50">
                        <tr>
                            <th className="px-6 py-4 text-left text-xs font-bold text-gray-500 uppercase tracking-wider">Name</th>
                            <th className="px-6 py-4 text-left text-xs font-bold text-gray-500 uppercase tracking-wider">Email</th>
                            <th className="px-6 py-4 text-left text-xs font-bold text-gray-500 uppercase tracking-wider">Activation Link</th>
                        </tr>
                    </thead>
                    <tbody className="divide-y divide-gray-100">
                        {invitations.map((invite) => {
                            const link = typeof window !== 'undefined' ? `${window.location.origin}/register?token=${invite.token}` : '';

                            return (
                                <tr key={invite.id} className="hover:bg-gray-50/50 transition-colors">
                                    <td className="px-6 py-4 text-sm font-medium text-gray-900">{invite.name}</td>
                                    <td className="px-6 py-4 text-sm text-gray-500">{invite.email}</td>
                                    <td className="px-6 py-4">
                                        <div className="flex items-center gap-2">
                                            <input
                                                type="text"
                                                readOnly
                                                value={link}
                                                className="flex-1 bg-white border border-gray-200 text-gray-600 text-sm rounded-lg px-3 py-2 focus:outline-none focus:border-[#462e37] w-64"
                                            />
                                            <button
                                                onClick={() => handleCopyLink(invite.token, invite.id)}
                                                className={`p-2 rounded-lg transition-all ${copiedId === invite.id
                                                    ? 'bg-green-100 text-green-700'
                                                    : 'bg-gray-100 text-gray-600 hover:bg-[#462e37] hover:text-white'
                                                    }`}
                                                title="Copy Link"
                                            >
                                                {copiedId === invite.id ? (
                                                    <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" /></svg>
                                                ) : (
                                                    <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8 16H6a2 2 0 01-2-2V6a2 2 0 012-2h8a2 2 0 012 2v2m-6 12h8a2 2 0 002-2v-8a2 2 0 00-2-2h-8a2 2 0 00-2 2v8a2 2 0 002 2z" /></svg>
                                                )}
                                            </button>
                                        </div>
                                    </td>
                                </tr>
                            );
                        })}
                    </tbody>
                </table>
            </div>
        </div>
    );
}
