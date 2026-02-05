'use client';

import { useState, useEffect } from 'react';
import DashboardLayout from '@/components/DashboardLayout';
import apiClient from '@/lib/api-client';
import { useRouter } from 'next/navigation';
import EditContractModal from '@/components/EditContractModal';

interface Employee {
    id: number;
    full_name: string;
    employee_code: string;
    position: string;
    department: string;
    contract_end_date: string | null;
    status: string;
    organization: {
        name: string;
    };
    track?: string;
}

export default function ContractsPage() {
    const router = useRouter();
    const [employees, setEmployees] = useState<Employee[]>([]);
    const [loading, setLoading] = useState(true);
    const [filter, setFilter] = useState<'all' | 'active' | 'expiring' | 'expired'>('all');
    const [searchTerm, setSearchTerm] = useState('');
    const [selectedDivision, setSelectedDivision] = useState<string>('all');
    const [selectedTrack, setSelectedTrack] = useState<string>('all');

    // Modal States
    const [isEditModalOpen, setIsEditModalOpen] = useState(false);
    const [selectedEmployee, setSelectedEmployee] = useState<Employee | null>(null);

    useEffect(() => {
        fetchEmployees();
    }, []);

    const fetchEmployees = async () => {
        try {
            setLoading(true);
            // Fetching page 1 with larger limit for now, or assume paginated results
            const response = await apiClient.get('/employees?per_page=100');
            setEmployees(response.data.data || []);
        } catch (error) {
            console.error('Failed to fetch employees:', error);
        } finally {
            setLoading(false);
        }
    };


    const handleEditContract = (employee: Employee) => {
        setSelectedEmployee(employee);
        setIsEditModalOpen(true);
    };

    const calculateDaysRemaining = (dateString: string | null) => {
        if (!dateString) return null;
        const end = new Date(dateString);
        const today = new Date();
        const diffTime = end.getTime() - today.getTime();
        return Math.ceil(diffTime / (1000 * 60 * 60 * 24));
    };

    const uniqueDivisions = Array.from(new Set(employees.map(e => e.department).filter(Boolean)))
        .filter(div => !['CEO', 'Chief Executive Officer', 'COO', 'CFO', 'CMO', 'CTO'].includes(div)) // Exclude C-Level
        .filter(div => !div.toLowerCase().startsWith('direktur')) // Exclude Directors
        .filter(div => !div.toLowerCase().includes('holding')); // Exclude Holding/Organization names
    const uniqueTracks = Array.from(new Set(employees.map(e => e.track).filter(Boolean)));

    const filteredEmployees = employees.filter(emp => {
        const matchesSearch = emp.full_name.toLowerCase().includes(searchTerm.toLowerCase()) ||
            emp.employee_code.toLowerCase().includes(searchTerm.toLowerCase());

        if (!matchesSearch) return false;

        // Filter by Division
        if (selectedDivision !== 'all' && emp.department !== selectedDivision) return false;

        // Filter by Track
        if (selectedTrack !== 'all' && emp.track !== selectedTrack) return false;

        const daysRemaining = calculateDaysRemaining(emp.contract_end_date);

        if (filter === 'all') return true;
        if (filter === 'active') return emp.status === 'active';
        if (filter === 'expiring') return daysRemaining !== null && daysRemaining <= 30 && daysRemaining > 0;
        if (filter === 'expired') return daysRemaining !== null && daysRemaining <= 0;

        return true;
    });

    const getStats = () => {
        let active = 0;
        let expiring = 0;
        let expired = 0;

        employees.forEach(emp => {
            if (emp.status === 'active') active++;
            const days = calculateDaysRemaining(emp.contract_end_date);
            if (days !== null) {
                if (days <= 30 && days > 0) expiring++;
                if (days <= 0) expired++;
            }
        });

        return { active, expiring, expired };
    };

    const stats = getStats();

    return (
        <DashboardLayout>
            <div className="p-8 space-y-8 min-h-screen bg-gray-50/50">

                {/* Header */}
                <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
                    <div>
                        <h1 className="text-2xl font-bold text-[#1C3ECA]">Digital Contracts</h1>
                        <p className="text-gray-500 mt-1">Manage employee contracts and renewals</p>
                    </div>
                    <div className="flex gap-3 flex-wrap items-center">
                        {/* Division Filter */}
                        <select
                            value={selectedDivision}
                            onChange={(e) => setSelectedDivision(e.target.value)}
                            className="px-4 py-2 bg-white border border-gray-200 text-[#1C3ECA] rounded-xl focus:outline-none focus:ring-2 focus:ring-[#1C3ECA]/20 text-sm"
                        >
                            <option value="all">All Divisions</option>
                            {uniqueDivisions.map(div => (
                                <option key={div} value={div}>{div}</option>
                            ))}
                        </select>

                        {/* Track Filter */}
                        <select
                            value={selectedTrack}
                            onChange={(e) => setSelectedTrack(e.target.value)}
                            className="px-4 py-2 bg-white border border-gray-200 text-[#1C3ECA] rounded-xl focus:outline-none focus:ring-2 focus:ring-[#1C3ECA]/20 text-sm"
                        >
                            <option value="all">All Tracks</option>
                            {uniqueTracks.map(track => (
                                <option key={track} value={track}>{track ? (track.charAt(0).toUpperCase() + track.slice(1)) : 'Unknown'}</option>
                            ))}
                        </select>

                        <div className="relative">
                            <input
                                type="text"
                                placeholder="Search employee..."
                                value={searchTerm}
                                onChange={(e) => setSearchTerm(e.target.value)}
                                className="pl-10 pr-4 py-2 rounded-xl border border-gray-200 focus:outline-none focus:ring-2 focus:ring-[#1C3ECA]/20 w-64"
                            />
                            <svg className="w-5 h-5 text-gray-400 absolute left-3 top-2.5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" /></svg>
                        </div>
                    </div>
                </div>

                {/* Stats Cards */}
                <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
                    <div className="glass-card p-6 bg-white flex items-center justify-between border-l-4 border-green-500">
                        <div>
                            <p className="text-sm text-gray-500 font-medium">Active Contracts</p>
                            <p className="text-3xl font-bold text-gray-800 mt-1">{stats.active}</p>
                        </div>
                        <div className="p-3 bg-green-50 text-green-600 rounded-xl">
                            <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" /></svg>
                        </div>
                    </div>
                    <div
                        onClick={() => setFilter('expiring')}
                        className={`glass-card p-6 bg-white flex items-center justify-between border-l-4 border-yellow-500 cursor-pointer transition-transform hover:scale-[1.02] ${filter === 'expiring' ? 'ring-2 ring-yellow-400' : ''}`}
                    >
                        <div>
                            <p className="text-sm text-gray-500 font-medium">Expiring Soon (30d)</p>
                            <p className="text-3xl font-bold text-gray-800 mt-1">{stats.expiring}</p>
                        </div>
                        <div className="p-3 bg-yellow-50 text-yellow-600 rounded-xl">
                            <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" /></svg>
                        </div>
                    </div>
                    <div
                        onClick={() => setFilter('expired')}
                        className={`glass-card p-6 bg-white flex items-center justify-between border-l-4 border-red-500 cursor-pointer transition-transform hover:scale-[1.02] ${filter === 'expired' ? 'ring-2 ring-red-400' : ''}`}
                    >
                        <div>
                            <p className="text-sm text-gray-500 font-medium">Expired</p>
                            <p className="text-3xl font-bold text-gray-800 mt-1">{stats.expired}</p>
                        </div>
                        <div className="p-3 bg-red-50 text-red-600 rounded-xl">
                            <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" /></svg>
                        </div>
                    </div>
                </div>

                {/* Filters */}
                <div className="flex gap-2 border-b border-gray-200 pb-1 overflow-x-auto">
                    {['all', 'active', 'expiring', 'expired'].map((f) => (
                        <button
                            key={f}
                            onClick={() => setFilter(f as any)}
                            className={`px-4 py-2 text-sm font-medium transition-colors relative ${filter === f ? 'text-[#1C3ECA]' : 'text-gray-400 hover:text-gray-600'
                                }`}
                        >
                            {f.charAt(0).toUpperCase() + f.slice(1)}
                            {filter === f && (
                                <div className="absolute bottom-0 left-0 w-full h-0.5 bg-[#1C3ECA] rounded-t-full"></div>
                            )}
                        </button>
                    ))}
                </div>

                {/* Table */}
                <div className="glass-card bg-white overflow-hidden">
                    {loading ? (
                        <div className="py-20 flex flex-col items-center justify-center text-gray-400">
                            <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-[#1C3ECA] mb-4"></div>
                            Loading contracts...
                        </div>
                    ) : filteredEmployees.length === 0 ? (
                        <div className="py-20 flex flex-col items-center justify-center text-gray-400">
                            <svg className="w-16 h-16 mb-4 opacity-20" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" /></svg>
                            <p>No employees found matching filter</p>
                        </div>
                    ) : (
                        <div className="overflow-x-auto">
                            <table className="w-full">
                                <thead className="bg-[#1C3ECA]/5 border-b border-[#1C3ECA]/10">
                                    <tr>
                                        <th className="px-6 py-4 text-left text-xs font-semibold text-[#1C3ECA] uppercase tracking-wider">Employee</th>
                                        <th className="px-6 py-4 text-left text-xs font-semibold text-[#1C3ECA] uppercase tracking-wider">Organization</th>
                                        <th className="px-6 py-4 text-left text-xs font-semibold text-[#1C3ECA] uppercase tracking-wider">Track</th>
                                        <th className="px-6 py-4 text-left text-xs font-semibold text-[#1C3ECA] uppercase tracking-wider">Contract End</th>
                                        <th className="px-6 py-4 text-left text-xs font-semibold text-[#1C3ECA] uppercase tracking-wider">Status</th>
                                        <th className="px-6 py-4 text-right text-xs font-semibold text-[#1C3ECA] uppercase tracking-wider">Action</th>
                                    </tr>
                                </thead>
                                <tbody className="divide-y divide-gray-100">
                                    {filteredEmployees.map((emp) => {
                                        const daysRemaining = calculateDaysRemaining(emp.contract_end_date);
                                        return (
                                            <tr key={emp.id} className="hover:bg-gray-50/50 transition-colors group">
                                                <td className="px-6 py-4">
                                                    <div className="flex items-center gap-3">
                                                        <div className="w-10 h-10 rounded-full bg-gradient-to-br from-[#1C3ECA] to-[#93C5FD] text-white flex items-center justify-center font-bold text-sm shadow-sm">
                                                            {emp.full_name.charAt(0)}
                                                        </div>
                                                        <div>
                                                            <p className="text-sm font-semibold text-gray-900">{emp.full_name}</p>
                                                            <p className="text-xs text-gray-500 font-mono">{emp.employee_code}</p>
                                                        </div>
                                                    </div>
                                                </td>
                                                <td className="px-6 py-4">
                                                    <p className="text-sm text-gray-700">{emp.position || '-'}</p>
                                                    <p className="text-xs text-gray-400">{emp.organization?.name || '-'}</p>
                                                    <p className="text-xs text-gray-500 mt-1">{emp.department || '-'}</p>
                                                </td>
                                                <td className="px-6 py-4">
                                                    <span className={`px-2 py-0.5 rounded text-xs font-medium ${emp.track === 'operational'
                                                        ? 'bg-blue-50 text-blue-700'
                                                        : emp.track === 'office'
                                                            ? 'bg-purple-50 text-purple-700'
                                                            : 'bg-gray-50 text-gray-600'
                                                        }`}>
                                                        {emp.track ? (emp.track.charAt(0).toUpperCase() + emp.track.slice(1)) : '-'}
                                                    </span>
                                                </td>
                                                <td className="px-6 py-4">
                                                    {emp.contract_end_date ? (
                                                        <div>
                                                            <p className="text-sm font-medium text-gray-900">
                                                                {new Date(emp.contract_end_date).toLocaleDateString('id-ID', { day: 'numeric', month: 'short', year: 'numeric' })}
                                                            </p>
                                                            {daysRemaining !== null && daysRemaining <= 60 && (
                                                                <p className={`text-xs font-medium mt-0.5 ${daysRemaining <= 30 ? 'text-red-500' : 'text-orange-500'}`}>
                                                                    {daysRemaining > 0 ? `${daysRemaining} days left` : `${Math.abs(daysRemaining)} days overdue`}
                                                                </p>
                                                            )}
                                                        </div>
                                                    ) : (
                                                        <span className="text-xs text-gray-400 italic">No contract date</span>
                                                    )}
                                                </td>
                                                <td className="px-6 py-4">
                                                    {(() => {
                                                        const days = calculateDaysRemaining(emp.contract_end_date);
                                                        if (days !== null && days <= 0) {
                                                            return <span className="px-2.5 py-1 rounded-full text-xs font-bold bg-red-100 text-red-700">EXPIRED</span>;
                                                        } else if (days !== null && days <= 30) {
                                                            return <span className="px-2.5 py-1 rounded-full text-xs font-bold bg-yellow-100 text-yellow-700">EXPIRING</span>;
                                                        } else if (emp.status === 'active') {
                                                            return <span className="px-2.5 py-1 rounded-full text-xs font-bold bg-green-100 text-green-700">ACTIVE</span>;
                                                        } else {
                                                            return <span className="px-2.5 py-1 rounded-full text-xs font-bold bg-gray-100 text-gray-600">{emp.status.toUpperCase()}</span>;
                                                        }
                                                    })()}
                                                </td>
                                                <td className="px-6 py-4 text-right">
                                                    <div className="flex justify-end gap-2">
                                                        <button
                                                            onClick={() => handleEditContract(emp)}
                                                            className="p-1.5 text-blue-600 hover:bg-blue-50 rounded-lg transition-colors"
                                                            title="Edit Contract"
                                                        >
                                                            <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15.232 5.232l3.536 3.536m-2.036-5.036a2.5 2.5 0 113.536 3.536L6.5 21.036H3v-3.572L16.732 3.732z" /></svg>
                                                        </button>

                                                    </div>
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

            {/* Modals */}
            <EditContractModal
                isOpen={isEditModalOpen}
                onClose={() => setIsEditModalOpen(false)}
                employee={selectedEmployee}
                onSuccess={fetchEmployees}
            />
        </DashboardLayout>
    );
}
