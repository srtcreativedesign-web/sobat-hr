'use client';

import { useEffect, useState, useCallback } from 'react';
import { useAuthStore } from '@/store/auth-store';
import DashboardLayout from '@/components/DashboardLayout';
import apiClient from '@/lib/api-client';
import Swal from 'sweetalert2';
import { DataTable } from '@/components/ui/data-table';
import { User, Chip, Button } from '@nextui-org/react';

// Imported Types and Components
import { Attendance } from './types';
import { getOutletNameDisplay, formatDate, formatDateTime, getChipColor } from './utils';
import OperasionalDetailModal from './components/OperasionalDetailModal';

export default function OperasionalAttendancePage() {
    const { isAuthenticated, checkAuth } = useAuthStore();
    const [attendances, setAttendances] = useState<Attendance[]>([]);
    const [divisions, setDivisions] = useState<{ id: number; name: string }[]>([]);
    const [loading, setLoading] = useState(false);
    const [startDate, setStartDate] = useState('');
    const [endDate, setEndDate] = useState('');
    const [filterDivision, setFilterDivision] = useState('');
    const [filterStatus, setFilterStatus] = useState('');
    const [selectedAttendance, setSelectedAttendance] = useState<Attendance | null>(null);
    const [currentPage, setCurrentPage] = useState(1);
    const [lastPage, setLastPage] = useState(1);
    const [totalData, setTotalData] = useState(0);
    const [perPage, setPerPage] = useState(20);
    const [hasFiltered, setHasFiltered] = useState(false);

    useEffect(() => {
        checkAuth();
    }, [checkAuth]);

    useEffect(() => {
        fetchDivisions();
    }, []);

    const fetchDivisions = async () => {
        try {
            const response = await apiClient.get('/divisions');
            const data = response.data.data || response.data;
            setDivisions(Array.isArray(data) ? data : []);
        } catch (error) {
            console.error('Failed to fetch divisions:', error);
        }
    };

    const fetchAttendances = useCallback(async (page = 1) => {
        try {
            setLoading(true);
            const params = new URLSearchParams({ track_type: 'operational' });
            if (startDate) params.append('start_date', startDate);
            if (endDate) params.append('end_date', endDate);
            if (filterDivision) params.append('division_id', filterDivision);
            if (filterStatus) params.append('status', filterStatus);
            params.append('page', String(page));
            params.append('per_page', '20');

            const response = await apiClient.get(`/attendances?${params.toString()}`);
            const res = response.data;
            setAttendances(Array.isArray(res.data) ? res.data : []);
            setCurrentPage(res.current_page || 1);
            setLastPage(res.last_page || 1);
            setTotalData(res.total || 0);
            setPerPage(res.per_page || 20);
            setHasFiltered(true);
        } catch (error) {
            console.error('Failed to fetch attendances:', error);
        } finally {
            setLoading(false);
        }
    }, [startDate, endDate, filterDivision, filterStatus]);

    const handleFilter = (e: React.FormEvent) => {
        e.preventDefault();
        setCurrentPage(1);
        fetchAttendances(1);
    };

    const goToPage = (page: number) => {
        if (page < 1 || page > lastPage) return;
        setCurrentPage(page);
        fetchAttendances(page);
    };

    const handleReview = async (id: number, reviewStatus: 'approved' | 'rejected') => {
        const label = reviewStatus === 'approved' ? 'setujui' : 'tolak';
        const result = await Swal.fire({
            title: reviewStatus === 'approved' ? 'Setujui Absensi Ini?' : 'Tolak Absensi Ini?',
            text: `Anda akan ${label} pengajuan absensi operasional ini.`,
            icon: 'question',
            showCancelButton: true,
            confirmButtonColor: reviewStatus === 'approved' ? '#22c55e' : '#ef4444',
            confirmButtonText: reviewStatus === 'approved' ? 'Ya, Setujui' : 'Ya, Tolak',
            cancelButtonText: 'Batal',
            input: 'textarea',
            inputPlaceholder: 'Catatan review (opsional)',
            inputAttributes: { maxlength: '1000' },
        });

        if (!result.isConfirmed) return;

        try {
            await apiClient.post(`/attendance/offline-submissions/${id}/review`, {
                review_status: reviewStatus,
                review_notes: result.value || '',
            });
            Swal.fire('Berhasil', `Absensi berhasil ${label}.`, 'success');
            fetchAttendances();
            setSelectedAttendance(null);
        } catch (error) {
            Swal.fire('Gagal', `Gagal ${label} absensi.`, 'error');
        }
    };

    const handleApprove = async (id: number, status: string) => {
        const result = await Swal.fire({
            title: 'Approve Absensi?',
            text: status === 'absent' ? 'Tolak absensi ini?' : `Set status menjadi ${status}?`,
            icon: 'question',
            showCancelButton: true,
            confirmButtonColor: status === 'absent' ? '#ef4444' : '#22c55e',
            confirmButtonText: status === 'absent' ? 'Ya, Tolak' : 'Ya, Setujui',
            cancelButtonText: 'Batal',
            input: 'textarea',
            inputPlaceholder: 'Catatan approval (opsional)',
            inputAttributes: { maxlength: '1000' },
        });

        if (!result.isConfirmed) return;

        try {
            await apiClient.post(`/attendances/${id}/approve`, {
                status,
                admin_note: result.value || '',
            });
            Swal.fire('Berhasil', 'Status kehadiran berhasil diperbarui.', 'success');
            fetchAttendances();
            setSelectedAttendance(null);
        } catch (error) {
            Swal.fire('Gagal', 'Gagal memproses approval.', 'error');
        }
    };

    const columns = [
        { name: "KARYAWAN", uid: "employee" },
        { name: "TANGGAL", uid: "date" },
        { name: "CHECK IN", uid: "check_in" },
        { name: "SHIFT", uid: "shift" },
        { name: "OUTLET", uid: "outlet" },
        { name: "VALIDASI", uid: "validation" },
        { name: "STATUS", uid: "status" },
        { name: "AKSI", uid: "actions" }
    ];

    const renderCell = (att: Attendance, columnKey: React.Key) => {
        switch (columnKey) {
            case "employee":
                return (
                    <User
                        avatarProps={{ radius: "lg", name: att.employee?.full_name?.[0]?.toUpperCase() }}
                        description={att.employee?.employee_code || '-'}
                        name={att.employee?.full_name || '-'}
                    >
                        {att.employee?.full_name || '-'}
                    </User>
                );
            case "date":
                return <p className="text-sm">{formatDate(att)}</p>;
            case "check_in":
                return <p className="text-sm font-mono">{formatDateTime(att.check_in || att.device_timestamp)}</p>;
            case "shift":
                return (
                    <p className="text-sm">
                        {att.shift_start_time && att.shift_end_time
                            ? `${att.shift_start_time.substring(0, 5)} - ${att.shift_end_time.substring(0, 5)}`
                            : '-'}
                    </p>
                );
            case "outlet":
                return (
                    <div className="flex flex-col">
                        <p className="text-sm font-medium">{getOutletNameDisplay(att)}</p>
                        {att.floor_number && <p className="text-xs text-default-400">LT-{att.floor_number}</p>}
                    </div>
                );
            case "validation":
                return att.validation_method ? (
                    <Chip size="sm" variant="flat" color={att.validation_method === 'qr_code' ? "secondary" : "primary"}>
                        {att.validation_method === 'qr_code' ? 'QR Code' : 'GPS'}
                    </Chip>
                ) : <span className="text-default-400">-</span>;
            case "status":
                return (
                    <Chip size="sm" variant="flat" color={getChipColor(att.status)} className="capitalize">
                        {att.status}
                    </Chip>
                );
            case "actions":
                return (
                    <Button color="primary" variant="light" size="sm" onPress={() => setSelectedAttendance(att)}>
                        Detail
                    </Button>
                );
            default:
                return null;
        }
    };

    return (
        <DashboardLayout>
            <div className="p-6">
                <div className="flex items-center justify-between mb-6">
                    <div>
                        <h1 className="text-2xl font-bold text-gray-800">Absensi Operasional</h1>
                        <p className="text-sm text-gray-500 mt-1">
                            Data absensi dua-layer QR & wide photo untuk outlet
                        </p>
                    </div>
                </div>

                <div className="bg-white rounded-xl shadow-sm border border-gray-200 p-4 mb-6">
                    <form onSubmit={handleFilter} className="flex flex-wrap items-end gap-4">
                        <div className="flex-1 min-w-[150px]">
                            <label className="block text-xs font-medium text-gray-500 mb-1">Dari Tanggal</label>
                            <input type="date" value={startDate} onChange={e => setStartDate(e.target.value)}
                                className="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm focus:ring-2 focus:ring-blue-500 focus:border-blue-500" />
                        </div>
                        <div className="flex-1 min-w-[150px]">
                            <label className="block text-xs font-medium text-gray-500 mb-1">Sampai Tanggal</label>
                            <input type="date" value={endDate} onChange={e => setEndDate(e.target.value)}
                                className="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm focus:ring-2 focus:ring-blue-500 focus:border-blue-500" />
                        </div>
                        <div className="w-44">
                            <label className="block text-xs font-medium text-gray-500 mb-1">Divisi</label>
                            <select value={filterDivision} onChange={e => setFilterDivision(e.target.value)}
                                className="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm focus:ring-2 focus:ring-blue-500 focus:border-blue-500">
                                <option value="">Semua Divisi</option>
                                {divisions.map(div => (
                                    <option key={div.id} value={div.id}>{div.name}</option>
                                ))}
                            </select>
                        </div>
                        <div className="w-40">
                            <label className="block text-xs font-medium text-gray-500 mb-1">Status</label>
                            <select value={filterStatus} onChange={e => setFilterStatus(e.target.value)}
                                className="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm focus:ring-2 focus:ring-blue-500 focus:border-blue-500">
                                <option value="">Semua</option>
                                <option value="present">Hadir</option>
                                <option value="late">Terlambat</option>
                                <option value="absent">Absen</option>
                                <option value="pending">Pending</option>
                            </select>
                        </div>
                        <button type="submit" disabled={!startDate}
                            className={`px-6 py-2 rounded-lg text-sm font-medium transition-colors ${!startDate ? 'bg-gray-200 text-gray-400 cursor-not-allowed' : 'bg-blue-600 text-white hover:bg-blue-700'}`}>
                            Filter
                        </button>
                    </form>
                </div>

                <div className="bg-white rounded-xl shadow-sm border border-gray-100 overflow-hidden">
                    <DataTable
                        columns={columns}
                        data={attendances}
                        isLoading={loading}
                        renderCell={renderCell}
                        primaryKey="id"
                        page={currentPage}
                        pages={lastPage}
                        onPageChange={(page) => goToPage(page)}
                        emptyContent={
                            !hasFiltered ? (
                                <div className="p-8 flex flex-col items-center">
                                    <svg className="h-16 w-16 text-gray-300 mb-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1} d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z" />
                                    </svg>
                                    <p className="text-gray-500 text-lg font-medium mb-2">Belum ada data ditampilkan</p>
                                    <p className="text-gray-400">Silakan pilih rentang tanggal dan klik <strong>Filter</strong> untuk menampilkan data absensi operasional.</p>
                                </div>
                            ) : "Tidak ada data absensi operasional untuk rentang tanggal tersebut."
                        }
                    />
                </div>
            </div>

            {/* Modal Detail Operational */}
            <OperasionalDetailModal 
                selectedAttendance={selectedAttendance}
                onClose={() => setSelectedAttendance(null)}
                handleApprove={handleApprove}
                handleReview={handleReview}
            />
        </DashboardLayout>
    );
}
