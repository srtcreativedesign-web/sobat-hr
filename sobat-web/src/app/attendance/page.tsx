'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { useAuthStore } from '@/store/auth-store';
import DashboardLayout from '@/components/DashboardLayout';
import apiClient from '@/lib/api-client';
import { API_URL } from '@/lib/config';

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
    status: 'present' | 'late' | 'absent' | 'leave' | 'sick' | 'pending';
    notes: string | null;
    photo_path: string | null;
    checkout_photo_path: string | null;
    work_hours: number | null;
    location_address: string | null;
    attendance_type?: 'office' | 'field';
    field_notes?: string | null;
}

export default function AttendancePage() {
    const router = useRouter();
    const { isAuthenticated, checkAuth } = useAuthStore();
    const [attendances, setAttendances] = useState<Attendance[]>([]);
    const [organizations, setOrganizations] = useState<{ id: number; name: string }[]>([]);
    const [loading, setLoading] = useState(false);
    const [filterStartDate, setFilterStartDate] = useState('');
    const [filterEndDate, setFilterEndDate] = useState('');
    const [filterStatus, setFilterStatus] = useState('');
    const [filterDivision, setFilterDivision] = useState('');
    const [selectedAttendance, setSelectedAttendance] = useState<Attendance | null>(null);

    useEffect(() => {
        checkAuth();
    }, [checkAuth]);

    useEffect(() => {
        // Only fetch if authenticated (guaranteed by layout, but good practice to keep logic clean)
        fetchOrganizations();
        fetchAttendances();
        // eslint-disable-next-line react-hooks/exhaustive-deps
    }, []);

    const fetchOrganizations = async () => {
        try {
            const response = await apiClient.get('/organizations');
            setOrganizations(response.data.data || response.data);
        } catch (error) {
            console.error('Failed to fetch organizations:', error);
        }
    };

    const fetchAttendances = async () => {
        try {
            setLoading(true);
            const params = new URLSearchParams();
            if (filterStartDate) params.append('start_date', filterStartDate);
            if (filterEndDate) params.append('end_date', filterEndDate);
            if (filterStatus) params.append('status', filterStatus);
            if (filterDivision) params.append('division_id', filterDivision);

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

    const handleExport = async () => {
        try {
            const params = new URLSearchParams();
            if (filterStartDate) params.append('start_date', filterStartDate);
            if (filterEndDate) params.append('end_date', filterEndDate);
            if (filterStatus) params.append('status', filterStatus);
            if (filterDivision) params.append('division_id', filterDivision);

            // Fetch as blob
            const response = await apiClient.get(`/attendances/export?${params.toString()}`, {
                responseType: 'blob',
            });

            // Create download link
            const url = window.URL.createObjectURL(new Blob([response.data]));
            const link = document.createElement('a');
            link.href = url;
            link.setAttribute('download', `Attendance_Export_${new Date().toISOString().split('T')[0]}.xlsx`);
            document.body.appendChild(link);
            link.click();
            link.parentNode?.removeChild(link);
        } catch (error) {
            console.error('Failed to export:', error);
            alert('Gagal mengexport data.');
        }
    };

    const handleApprove = async (id: number, status: string) => {
        try {
            const noteInput = document.getElementById('approvalNote') as HTMLInputElement;
            const note = noteInput?.value || '';

            await apiClient.post(`/attendances/${id}/approve`, {
                status,
                admin_note: note
            });

            // Refresh data
            fetchAttendances();
            setSelectedAttendance(null);
        } catch (error) {
            console.error('Failed to approve attendance:', error);
            alert('Gagal memproses approval.');
        }
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

    const getPhotoUrl = (path: string | null) => {
        if (!path) return null;

        // If path is already a full URL, return it
        if (path.startsWith('http')) return path;

        // Clean path if it starts with 'public/' (stored in db) or just appending to base
        // API_URL usually ends with /api. We need the base URL (without /api) for storage
        const baseUrl = API_URL.replace('/api', '');

        // Remove leading slash if exists to prevent double slash
        const cleanPath = path.startsWith('/') ? path.substring(1) : path;

        return `${baseUrl}/storage/${cleanPath}`;
    };

    const getStatusBadge = (status: string) => {
        switch (status) {
            case 'present': return 'bg-green-100 text-green-800';
            case 'late': return 'bg-yellow-100 text-yellow-800';
            case 'absent': return 'bg-red-100 text-red-800';
            case 'leave': return 'bg-blue-100 text-blue-800';
            case 'sick': return 'bg-orange-100 text-orange-800';
            case 'pending': return 'bg-orange-100 text-orange-800 ring-1 ring-orange-500';
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
                        <div className="flex gap-2">
                            <div>
                                <label className="block text-sm font-medium text-gray-700 mb-2">Dari Tanggal</label>
                                <input
                                    type="date"
                                    value={filterStartDate}
                                    onChange={(e) => setFilterStartDate(e.target.value)}
                                    className="px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-[#1C3ECA] focus:border-transparent"
                                />
                            </div>
                            <div>
                                <label className="block text-sm font-medium text-gray-700 mb-2">Sampai Tanggal</label>
                                <input
                                    type="date"
                                    value={filterEndDate}
                                    onChange={(e) => setFilterEndDate(e.target.value)}
                                    className="px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-[#1C3ECA] focus:border-transparent"
                                />
                            </div>
                        </div>
                        <div>
                            <label className="block text-sm font-medium text-gray-700 mb-2">Divisi</label>
                            <select
                                value={filterDivision}
                                onChange={(e) => setFilterDivision(e.target.value)}
                                className="px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-[#1C3ECA] focus:border-transparent"
                            >
                                <option value="">Semua Divisi</option>
                                {organizations
                                    .filter(org => !['CEO', 'Chief Executive Officer', 'COO', 'CFO', 'CMO', 'CTO'].includes(org.name))
                                    .filter(org => !org.name.toLowerCase().startsWith('direktur'))
                                    .filter(org => !org.name.toLowerCase().includes('holding'))
                                    .map((org) => (
                                        <option key={org.id} value={org.id}>
                                            {org.name}
                                        </option>
                                    ))}
                            </select>
                        </div>
                        <div>
                            <label className="block text-sm font-medium text-gray-700 mb-2">Status</label>
                            <select
                                value={filterStatus}
                                onChange={(e) => setFilterStatus(e.target.value)}
                                className="px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-[#1C3ECA] focus:border-transparent"
                            >
                                <option value="">Semua Status</option>
                                <option value="present">Hadir</option>
                                <option value="late">Terlambat</option>
                                <option value="absent">Absen</option>
                                <option value="leave">Cuti</option>
                                <option value="sick">Sakit</option>
                                <option value="pending">Menunggu Approval</option>
                            </select>
                        </div>
                        <button
                            type="submit"
                            className="px-6 py-2 bg-[#60A5FA] text-[#1C3ECA] rounded-lg hover:bg-[#93C5FD] transition-colors font-medium"
                        >
                            Filter
                        </button>
                        <button
                            type="button"
                            onClick={handleExport}
                            className="px-6 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 transition-colors font-medium"
                        >
                            Export Excel
                        </button>
                    </form>
                </div>

                {/* Table */}
                <div className="bg-white rounded-xl shadow-sm overflow-hidden">
                    {loading ? (
                        <div className="p-12 text-center">
                            <div className="inline-block animate-spin rounded-full h-12 w-12 border-4 border-[#60A5FA] border-t-transparent"></div>
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
                                        <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Tipe</th>
                                        <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Status</th>
                                        <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Lokasi</th>
                                        <th className="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">Aksi</th>
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
                                                <span className={`px-2 py-1 inline-flex text-xs leading-5 font-semibold rounded-full ${att.attendance_type === 'field' ? 'bg-blue-100 text-blue-800' : 'bg-gray-100 text-gray-800'}`}>
                                                    {att.attendance_type === 'field' ? 'DINAS LUAR' : 'KANTOR'}
                                                </span>
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
                                            <td className="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                                                <button
                                                    onClick={() => setSelectedAttendance(att)}
                                                    className="text-indigo-600 hover:text-indigo-900 bg-indigo-50 hover:bg-indigo-100 px-3 py-1 rounded-md transition-colors"
                                                >
                                                    Detail
                                                </button>
                                            </td>
                                        </tr>
                                    ))}
                                </tbody>
                            </table>
                        </div>
                    )}
                </div>
            </div>

            {/* Detail Modal */}
            {selectedAttendance && (
                <div className="fixed inset-0 z-50 overflow-y-auto" aria-labelledby="modal-title" role="dialog" aria-modal="true">
                    <div className="flex items-end justify-center min-h-screen pt-4 px-4 pb-20 text-center sm:block sm:p-0">
                        {/* Background overlay */}
                        <div
                            className="fixed inset-0 bg-gray-500 bg-opacity-75 transition-opacity"
                            aria-hidden="true"
                            onClick={() => setSelectedAttendance(null)}
                        ></div>

                        {/* Modal panel */}
                        <span className="hidden sm:inline-block sm:align-middle sm:h-screen" aria-hidden="true">&#8203;</span>
                        <div className="inline-block align-bottom bg-white rounded-lg text-left overflow-hidden shadow-xl transform transition-all sm:my-8 sm:align-middle sm:max-w-lg sm:w-full">
                            <div className="bg-white px-4 pt-5 pb-4 sm:p-6 sm:pb-4">
                                <div className="sm:flex sm:items-start">
                                    <div className="mt-3 text-center sm:mt-0 sm:ml-4 sm:text-left w-full">
                                        <h3 className="text-lg leading-6 font-medium text-gray-900" id="modal-title">
                                            Detail Kehadiran
                                        </h3>
                                        <div className="mt-4 space-y-4">
                                            {/* Photos Grid */}
                                            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                                                {/* Check In Photo */}
                                                <div>
                                                    <p className="text-sm font-medium text-gray-700 mb-2">Foto Check In</p>
                                                    <div className="aspect-w-16 aspect-h-9 bg-gray-100 rounded-lg overflow-hidden flex items-center justify-center border border-gray-200 h-48">
                                                        {selectedAttendance.photo_path ? (
                                                            // eslint-disable-next-line @next/next/no-img-element
                                                            <img
                                                                src={getPhotoUrl(selectedAttendance.photo_path) || ''}
                                                                alt="Foto Check In"
                                                                className="object-cover w-full h-full"
                                                            />
                                                        ) : (
                                                            <div className="flex flex-col items-center text-gray-400 p-4">
                                                                <svg className="h-8 w-8 mb-1" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                                                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3 9a2 2 0 012-2h.93a2 2 0 001.664-.89l.812-1.22A2 2 0 0110.07 4h3.86a2 2 0 011.664.89l.812 1.22A2 2 0 0018.07 7H19a2 2 0 012 2v9a2 2 0 01-2 2H5a2 2 0 01-2-2V9z" />
                                                                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 13a3 3 0 11-6 0 3 3 0 016 0z" />
                                                                </svg>
                                                                <span className="text-xs">Tidak ada foto</span>
                                                            </div>
                                                        )}
                                                    </div>
                                                </div>

                                                {/* Check Out Photo */}
                                                <div>
                                                    <p className="text-sm font-medium text-gray-700 mb-2">Foto Check Out</p>
                                                    <div className="aspect-w-16 aspect-h-9 bg-gray-100 rounded-lg overflow-hidden flex items-center justify-center border border-gray-200 h-48">
                                                        {selectedAttendance.checkout_photo_path ? (
                                                            // eslint-disable-next-line @next/next/no-img-element
                                                            <img
                                                                src={getPhotoUrl(selectedAttendance.checkout_photo_path) || ''}
                                                                alt="Foto Check Out"
                                                                className="object-cover w-full h-full"
                                                            />
                                                        ) : (
                                                            <div className="flex flex-col items-center text-gray-400 p-4">
                                                                <svg className="h-8 w-8 mb-1" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                                                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3 9a2 2 0 012-2h.93a2 2 0 001.664-.89l.812-1.22A2 2 0 0110.07 4h3.86a2 2 0 011.664.89l.812 1.22A2 2 0 0018.07 7H19a2 2 0 012 2v9a2 2 0 01-2 2H5a2 2 0 01-2-2V9z" />
                                                                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 13a3 3 0 11-6 0 3 3 0 016 0z" />
                                                                </svg>
                                                                <span className="text-xs">Belum Checkout / Tanpa Foto</span>
                                                            </div>
                                                        )}
                                                    </div>
                                                </div>
                                            </div>

                                            {/* Details Grid */}
                                            <div className="grid grid-cols-2 gap-4 text-sm mt-6">
                                                <div>
                                                    <p className="font-medium text-gray-500">Nama Karyawan</p>
                                                    <p className="text-gray-900 font-semibold">{selectedAttendance.employee?.full_name}</p>
                                                    <p className="text-gray-500 text-xs">{selectedAttendance.employee?.employee_code}</p>
                                                </div>
                                                <div>
                                                    <p className="font-medium text-gray-500">Tanggal</p>
                                                    <p className="text-gray-900">{formatDate(selectedAttendance.date)}</p>
                                                </div>
                                                <div>
                                                    <p className="font-medium text-gray-500">Jam Masuk</p>
                                                    <p className="text-gray-900 font-mono">{selectedAttendance.check_in?.substring(0, 5) || '-'}</p>
                                                </div>
                                                <div>
                                                    <p className="font-medium text-gray-500">Jam Keluar</p>
                                                    <p className="text-gray-900 font-mono">{selectedAttendance.check_out?.substring(0, 5) || '-'}</p>
                                                </div>
                                                <div>
                                                    <p className="font-medium text-gray-500">Total Jam Kerja</p>
                                                    <p className="text-gray-900">{selectedAttendance.work_hours ? `${selectedAttendance.work_hours} Jam` : '-'}</p>
                                                </div>
                                                <div>
                                                    <p className="font-medium text-gray-500">Status</p>
                                                    <span className={`px-2 py-0.5 inline-flex text-xs leading-5 font-semibold rounded-full mt-1 ${getStatusBadge(selectedAttendance.status)}`}>
                                                        {selectedAttendance.status.toUpperCase()}
                                                    </span>
                                                </div>
                                                <div>
                                                    <p className="font-medium text-gray-500">Tipe Absensi</p>
                                                    <span className={`px-2 py-0.5 inline-flex text-xs leading-5 font-semibold rounded-full mt-1 ${selectedAttendance.attendance_type === 'field' ? 'bg-blue-100 text-blue-800' : 'bg-gray-100 text-gray-800'}`}>
                                                        {selectedAttendance.attendance_type === 'field' ? 'DINAS LUAR' : 'KANTOR'}
                                                    </span>
                                                </div>
                                            </div>

                                            {/* Full Width Items */}
                                            <div>
                                                <p className="font-medium text-gray-500 text-sm">Lokasi</p>
                                                <p className="text-gray-900 text-sm">{selectedAttendance.location_address || '-'}</p>
                                            </div>

                                            {selectedAttendance.field_notes && (
                                                <div>
                                                    <p className="font-medium text-gray-500 text-sm">Catatan Dinas (Wajib)</p>
                                                    <p className="text-gray-900 text-sm bg-blue-50 p-2 rounded mt-1 border border-blue-100">{selectedAttendance.field_notes}</p>
                                                </div>
                                            )}

                                            {selectedAttendance.notes && (
                                                <div>
                                                    <p className="font-medium text-gray-500 text-sm">Catatan</p>
                                                    <p className="text-gray-900 text-sm bg-gray-50 p-2 rounded mt-1">{selectedAttendance.notes}</p>
                                                </div>
                                            )}
                                        </div>
                                    </div>
                                </div>
                            </div>
                            <div className="bg-gray-50 px-4 py-3 sm:px-6 sm:flex sm:flex-row-reverse justify-between items-center">
                                <button
                                    type="button"
                                    className="mt-3 w-full inline-flex justify-center rounded-md border border-gray-300 shadow-sm px-4 py-2 bg-white text-base font-medium text-gray-700 hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 sm:mt-0 sm:ml-3 sm:w-auto sm:text-sm"
                                    onClick={() => setSelectedAttendance(null)}
                                >
                                    Tutup
                                </button>

                                {selectedAttendance.status === 'pending' && (
                                    <div className="w-full sm:w-auto mt-3 sm:mt-0 flex flex-col sm:flex-row gap-2">
                                        <div className="flex-grow">
                                            <input
                                                type="text"
                                                placeholder="Catatan Approval..."
                                                className="w-full px-3 py-2 border border-gray-300 rounded-md text-sm focus:outline-none focus:ring-1 focus:ring-indigo-500"
                                                id="approvalNote"
                                            />
                                        </div>
                                        <div className="flex gap-2">
                                            <button
                                                onClick={() => handleApprove(selectedAttendance.id, 'late')}
                                                className="inline-flex justify-center rounded-md border border-transparent shadow-sm px-4 py-2 bg-yellow-600 text-base font-medium text-white hover:bg-yellow-700 focus:outline-none sm:text-sm"
                                            >
                                                Approve (Late)
                                            </button>
                                            <button
                                                onClick={() => handleApprove(selectedAttendance.id, 'present')}
                                                className="inline-flex justify-center rounded-md border border-transparent shadow-sm px-4 py-2 bg-green-600 text-base font-medium text-white hover:bg-green-700 focus:outline-none sm:text-sm"
                                            >
                                                Approve (Present)
                                            </button>
                                            <button
                                                onClick={() => handleApprove(selectedAttendance.id, 'absent')}
                                                className="inline-flex justify-center rounded-md border border-transparent shadow-sm px-4 py-2 bg-red-600 text-base font-medium text-white hover:bg-red-700 focus:outline-none sm:text-sm"
                                            >
                                                Reject
                                            </button>
                                        </div>
                                    </div>
                                )}
                            </div>
                        </div>
                    </div>
                </div>
            )}
        </DashboardLayout>
    );
}
