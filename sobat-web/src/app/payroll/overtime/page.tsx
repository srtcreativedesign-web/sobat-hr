'use client';

import { useState, useEffect } from 'react';
import DashboardLayout from '@/components/DashboardLayout';
import { useAuthStore } from '@/store/auth-store';
import React from 'react';
import { STORAGE_KEYS } from '@/lib/config';

interface Request {
    id: number;
    employee_id: number;
    employee: {
        id: number;
        full_name: string;
        organization?: {
            name: string;
        }
    };
    date: string; // The dedicated overtime record date
    start_time: string;
    end_time: string;
    duration: number; // minutes
    reason: string;
    // OvertimeRecord doesn't have 'status' usually, but if it does, keep it. 
    // Assuming we want to show it's 'approved' (since it exists here).
    status?: string;
    overtime_detail?: {
        start_time: string;
        end_time: string;
    }
}

interface Organization {
    id: number;
    name: string;
}

import { useRouter } from 'next/navigation';

export default function OvertimePage() {
    const { user } = useAuthStore();
    const router = useRouter();
    const [requests, setRequests] = useState<Request[]>([]);
    const [isLoading, setIsLoading] = useState(true);
    const [organizations, setOrganizations] = useState<Organization[]>([]);

    // Filters
    const [search, setSearch] = useState('');
    const [selectedOrg, setSelectedOrg] = useState('');

    const fetchOvertime = async () => {
        setIsLoading(true);
        try {
            const token = localStorage.getItem(STORAGE_KEYS.TOKEN);
            // Fetch from new dedicated endpoint
            let url = `${process.env.NEXT_PUBLIC_API_URL}/overtime-records?page=1`; // Start with page 1

            if (search) {
                url += `&search=${search}`;
            }
            if (selectedOrg) {
                url += `&organization_id=${selectedOrg}`;
            }

            const response = await fetch(url, {
                headers: {
                    'Authorization': `Bearer ${token}`,
                    'Accept': 'application/json'
                }
            });
            if (response.ok) {
                const data = await response.json();
                // Pagination handling if needed, assuming data.data if paginated
                setRequests(data.data || data);
            }
        } catch (error) {
            console.error('Failed to fetch overtime requests', error);
        } finally {
            setIsLoading(false);
        }
    };

    const handleExport = async () => {
        try {
            const token = localStorage.getItem(STORAGE_KEYS.TOKEN);
            let url = `${process.env.NEXT_PUBLIC_API_URL}/requests/export/overtime`; // Keep logic simple
            // Better trigger download via blob

            if (search) url += `?search=${search}`;
            if (selectedOrg) url += `${search ? '&' : '?'}organization_id=${selectedOrg}`;

            const response = await fetch(url, {
                headers: {
                    'Authorization': `Bearer ${token}`,
                    'Accept': 'application/json'
                }
            });

            if (response.ok) {
                const blob = await response.blob();
                const downloadUrl = window.URL.createObjectURL(blob);
                const a = document.createElement('a');
                a.href = downloadUrl;
                a.download = `overtime-report-${new Date().toISOString().split('T')[0]}.xlsx`;
                document.body.appendChild(a);
                a.click();
                a.remove();
            } else {
                console.error("Export failed");
                alert("Export failed");
            }

        } catch (error) {
            console.error("Export error", error);
        }
    };

    const fetchOrganizations = async () => {
        try {
            const token = localStorage.getItem(STORAGE_KEYS.TOKEN);
            const response = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/organizations`, {
                headers: {
                    'Authorization': `Bearer ${token}`,
                    'Accept': 'application/json'
                }
            });
            if (response.ok) {
                const data = await response.json();
                setOrganizations(data.data || data);
            }
        } catch (error) {
            console.error("Failed to fetch organizations", error);
        }
    }

    useEffect(() => {
        const token = localStorage.getItem(STORAGE_KEYS.TOKEN);
        if (!token) {
            router.push('/login');
            return;
        }
        fetchOrganizations();
    }, []);

    useEffect(() => {
        // Debounce search
        const timer = setTimeout(() => {
            fetchOvertime();
        }, 500);
        return () => clearTimeout(timer);
    }, [search, selectedOrg]);

    return (
        <DashboardLayout>
            <div className="p-6">
                <div className="flex justify-between items-center mb-6">
                    <h1 className="text-2xl font-bold text-[#462e37]">Overtime Records</h1>
                    <button
                        onClick={handleExport}
                        className="px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 transition flex items-center gap-2 text-sm font-medium shadow-md"
                    >
                        <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 16v1a3 3 0 0 0 3 3h10a3 3 0 0 0 3-3v-1m-4-4l-4 4m0 0l-4-4m4 4V4" />
                        </svg>
                        Export to Excel
                    </button>
                </div>

                {/* Filters */}
                <div className="bg-white p-4 rounded-xl shadow-sm border border-[#462e37]/10 mb-6 flex gap-4 flex-wrap">
                    <div className="flex-1 min-w-[200px]">
                        <label className="block text-sm font-medium text-[#462e37]/70 mb-1">Search Employee</label>
                        <input
                            type="text"
                            placeholder="Search by name..."
                            className="w-full px-4 py-2 rounded-lg border border-[#462e37]/20 focus:outline-none focus:border-[#462e37]"
                            value={search}
                            onChange={(e) => setSearch(e.target.value)}
                        />
                    </div>
                    <div className="flex-1 min-w-[200px]">
                        <label className="block text-sm font-medium text-[#462e37]/70 mb-1">Division</label>
                        <select
                            className="w-full px-4 py-2 rounded-lg border border-[#462e37]/20 focus:outline-none focus:border-[#462e37]"
                            value={selectedOrg}
                            onChange={(e) => setSelectedOrg(e.target.value)}
                        >
                            <option value="">All Divisions</option>
                            {organizations.map(org => (
                                <option key={org.id} value={org.id}>{org.name}</option>
                            ))}
                        </select>
                    </div>
                </div>

                {/* Table */}
                <div className="bg-white rounded-xl shadow-sm border border-[#462e37]/10 overflow-hidden">
                    <div className="overflow-x-auto">
                        <table className="w-full">
                            <thead className="bg-[#462e37]/5 border-b border-[#462e37]/10">
                                <tr>
                                    <th className="px-6 py-4 text-left text-xs font-semibold text-[#462e37] uppercase tracking-wider">Employee</th>
                                    <th className="px-6 py-4 text-left text-xs font-semibold text-[#462e37] uppercase tracking-wider">Division</th>
                                    <th className="px-6 py-4 text-left text-xs font-semibold text-[#462e37] uppercase tracking-wider">Date</th>
                                    <th className="px-6 py-4 text-left text-xs font-semibold text-[#462e37] uppercase tracking-wider">Time</th>
                                    <th className="px-6 py-4 text-left text-xs font-semibold text-[#462e37] uppercase tracking-wider">Duration</th>
                                    <th className="px-6 py-4 text-left text-xs font-semibold text-[#462e37] uppercase tracking-wider">Reason</th>
                                    <th className="px-6 py-4 text-center text-xs font-semibold text-[#462e37] uppercase tracking-wider">Status</th>
                                </tr>
                            </thead>
                            <tbody className="divide-y divide-[#462e37]/10">
                                {isLoading ? (
                                    <tr>
                                        <td colSpan={7} className="px-6 py-8 text-center text-[#462e37]/50">
                                            Loading records...
                                        </td>
                                    </tr>
                                ) : requests.length === 0 ? (
                                    <tr>
                                        <td colSpan={7} className="px-6 py-8 text-center text-[#462e37]/50">
                                            No overtime records found
                                        </td>
                                    </tr>
                                ) : (
                                    requests.map((req) => (
                                        <tr key={req.id} className="hover:bg-[#462e37]/5 transition-colors">
                                            <td className="px-6 py-4 text-sm font-medium text-[#462e37]">
                                                {req.employee?.full_name}
                                            </td>
                                            <td className="px-6 py-4 text-sm text-[#462e37]/70">
                                                {req.employee?.organization?.name || '-'}
                                            </td>
                                            <td className="px-6 py-4 text-sm text-[#462e37]/70">
                                                {new Date(req.date).toLocaleDateString('id-ID', {
                                                    day: 'numeric',
                                                    month: 'long',
                                                    year: 'numeric'
                                                })}
                                            </td>
                                            <td className="px-6 py-4 text-sm text-[#462e37]/70">
                                                {/* Fallback to start_date time parsing if overtime_detail not eager loaded properly or implemented yet */}
                                                {/* Assuming RequestController index doesn't load detail by default, we'll see */}
                                                {/* For now, leaving blank if not available in top level for simplicity, assuming start_date contains time or plain date */}
                                                {req.start_time && req.end_time ? `${req.start_time} - ${req.end_time}` : '-'}
                                            </td>
                                            <td className="px-6 py-4 text-sm text-[#462e37]/70">
                                                {req.duration ? `${req.duration} mins` : '-'}
                                            </td>
                                            <td className="px-6 py-4 text-sm text-[#462e37]/70 max-w-xs truncate">
                                                {req.reason}
                                            </td>
                                            <td className="px-6 py-4 text-center">
                                                <span className="inline-flex px-3 py-1 rounded-full text-xs font-medium bg-green-100 text-green-800">
                                                    approved
                                                </span>
                                            </td>
                                        </tr>
                                    ))
                                )}
                            </tbody>
                        </table>
                    </div>
                </div>
            </div>
        </DashboardLayout>
    );
}
