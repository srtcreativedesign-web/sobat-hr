'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { useAuthStore } from '@/store/auth-store';
import DashboardLayout from '@/components/DashboardLayout';
import apiClient from '@/lib/api-client';

interface Attendance {
    id: number;
    employee_id: number;
    employee?: {
        full_name: string;
        employee_code: string;
    };
    date: string;
    check_in: string | null;
    check_out: string | null;
    status: 'present' | 'late' | 'absent' | 'leave' | 'sick';
    notes: string | null;
    photo_path: string | null;
    work_hours: number | null;
    location_address: string | null;
}

export default function AttendancePage() {
    const router = useRouter();
    const { isAuthenticated, checkAuth } = useAuthStore();
    const [attendances, setAttendances] = useState<Attendance[]>([]);
    const [loading, setLoading] = useState(false);
    const [filterDate, setFilterDate] = useState('');
    const [filterStatus, setFilterStatus] = useState('');

    useEffect(() => {
        checkAuth();
    }, [checkAuth]);

    useEffect(() => {
        if (!isAuthenticated) {
            router.push('/login');
            return;
        }

        fetchAttendances();
        // eslint-disable-next-line react-hooks/exhaustive-deps
    }, [isAuthenticated, router]);

    const fetchAttendances = async () => {
        try {
            setLoading(true);
            const params = new URLSearchParams();
            if (filterDate) params.append('date', filterDate);
            if (filterStatus) params.append('status', filterStatus);

            const response = await apiClient.get(`/attendances?${params.toString()}`);
            // Pagination handling might be needed, assuming API returns paginated data structure
            const data = response.data.data || response.data;
            setAttendances(Array.isArray(data) ? data : []);
        } catch (error) {
            console.error('Failed to fetch attendance:', error);
        } finally {
            setLoading(false);
        }
    };

    const handleFilter = (e: React.FormEvent) => {
        e.preventDefault();
        fetchAttendances();
    };

    const formatDate = (dateString: string) => {
        if (!dateString) return '-';
        return new Date(dateString).toLocaleDateString('id-ID', {
            weekday: 'long',
            day: 'numeric',
            month: 'long',
            year: 'numeric'
        });
    };

    const getStatusBadge = (status: string) => {
        switch (status) {
            case 'present': return 'bg-green-100 text-green-800';
            case 'late': return 'bg-yellow-100 text-yellow-800';
            case 'absent': return 'bg-red-100 text-red-800';
            case 'leave': return 'bg-blue-100 text-blue-800';
            case 'sick': return 'bg-orange-100 text-orange-800';
            default: return 'bg-gray-100 text-gray-800';
        }
    };

    return (
        <DashboardLayout>
            <div className="p-6">
                <div className="mb-6">
                    <h1 className="text-3xl font-bold text-gray-900 mb-2">Kehadiran</h1>
                    <p className="text-gray-600">Monitoring absensi karyawan</p>
                </div>

                {/* Filters */}
                <div className="bg-white rounded-xl shadow-sm p-6 mb-6">
                    <form onSubmit={handleFilter} className="flex flex-wrap gap-4 items-end">
                        <div>
                            <label className="block text-sm font-medium text-gray-700 mb-2">Tanggal</label>
                            <input
                                type="date"
                                value={filterDate}
                                onChange={(e) => setFilterDate(e.target.value)}
                                className="px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-[#462e37] focus:border-transparent"
                            />
                        </div>
                        <div>
                            <label className="block text-sm font-medium text-gray-700 mb-2">Status</label>
                            <select
                                value={filterStatus}
                                onChange={(e) => setFilterStatus(e.target.value)}
                                className="px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-[#462e37] focus:border-transparent"
                            >
                                <option value="">Semua Status</option>
                                <option value="present">Hadir</option>
                                <option value="late">Terlambat</option>
                                <option value="absent">Absen</option>
                                <option value="leave">Cuti</option>
                                <option value="sick">Sakit</option>
                            </select>
                        </div>
                        <button
                            type="submit"
                            className="px-6 py-2 bg-[#a9eae2] text-[#462e37] rounded-lg hover:bg-[#729892] transition-colors font-medium"
                        >
                            Filter
                        </button>
                    </form>
                </div>

                {/* Table */}
                <div className="bg-white rounded-xl shadow-sm overflow-hidden">
                    {loading ? (
                        <div className="p-12 text-center">
                            <div className="inline-block animate-spin rounded-full h-12 w-12 border-4 border-[#a9eae2] border-t-transparent"></div>
                            <p className="mt-4 text-gray-600">Memuat data...</p>
                        </div>
                    ) : attendances.length === 0 ? (
                        <div className="p-12 text-center">
                            <p className="text-gray-600">Tidak ada data kehadiran.</p>
                        </div>
                    ) : (
                        <div className="overflow-x-auto">
                            <table className="min-w-full divide-y divide-gray-200">
                                <thead className="bg-gray-50">
                                    <tr>
                                        <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Karyawan</th>
                                        <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Tanggal</th>
                                        <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Jam Masuk</th>
                                        <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Jam Keluar</th>
                                        <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Status</th>
                                        <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Lokasi</th>
                                    </tr>
                                </thead>
                                <tbody className="bg-white divide-y divide-gray-200">
                                    {attendances.map((att) => (
                                        <tr key={att.id} className="hover:bg-gray-50">
                                            <td className="px-6 py-4 whitespace-nowrap">
                                                <div className="text-sm font-medium text-gray-900">{att.employee?.full_name || '-'}</div>
                                                <div className="text-xs text-gray-500">{att.employee?.employee_code}</div>
                                            </td>
                                            <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                                                {formatDate(att.date)}
                                            </td>
                                            <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900 font-mono">
                                                {att.check_in ? att.check_in.substring(0, 5) : '-'}
                                            </td>
                                            <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900 font-mono">
                                                {att.check_out ? att.check_out.substring(0, 5) : '-'}
                                            </td>
                                            <td className="px-6 py-4 whitespace-nowrap">
                                                <span className={`px-3 py-1 inline-flex text-xs leading-5 font-semibold rounded-full ${getStatusBadge(att.status)}`}>
                                                    {att.status.toUpperCase()}
                                                </span>
                                                {att.notes && <div className="text-xs text-gray-500 mt-1 max-w-[150px] truncate">{att.notes}</div>}
                                            </td>
                                            <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500 max-w-[200px] truncate">
                                                {att.location_address || '-'}
                                            </td>
                                        </tr>
                                    ))}
                                </tbody>
                            </table>
                        </div>
                    )}
                </div>
            </div>
        </DashboardLayout>
    );
}
