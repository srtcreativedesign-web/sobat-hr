'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { useAuthStore } from '@/store/auth-store';
import DashboardLayout from '@/components/DashboardLayout';
import apiClient from '@/lib/api-client';
import { API_URL } from '@/lib/config';
import Swal from 'sweetalert2';
import { DataTable } from '@/components/ui/data-table';
import { User, Chip, Button } from '@nextui-org/react';

import { Attendance } from './types';
import { formatDate, getStatusColor, getStatusText } from './utils';
import AttendanceDetailModal from './components/AttendanceDetailModal';
import AttendanceBulkApprovalModal from './components/AttendanceBulkApprovalModal';

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
    const [filterOffline, setFilterOffline] = useState('');
    const [selectedAttendance, setSelectedAttendance] = useState<Attendance | null>(null);
    const [selectedIds, setSelectedIds] = useState<number[]>([]);
    const [showBulkModal, setShowBulkModal] = useState(false);
    const [bulkStatus, setBulkStatus] = useState<'late' | 'present'>('late');
    const [bulkNote, setBulkNote] = useState('');
    const [isBulkSubmitting, setIsBulkSubmitting] = useState(false);
    const [currentPage, setCurrentPage] = useState(1);
    const [lastPage, setLastPage] = useState(1);
    const [totalData, setTotalData] = useState(0);
    const [perPage, setPerPage] = useState(20);
    const [hasFiltered, setHasFiltered] = useState(false);

    useEffect(() => {
        checkAuth();
    }, [checkAuth]);

    useEffect(() => {
        fetchOrganizations();
        // eslint-disable-next-line react-hooks/exhaustive-deps
    }, []);

    const fetchOrganizations = async () => {
        try {
            const response = await apiClient.get('/divisions');
            const data = response.data.data || response.data;
            setOrganizations(Array.isArray(data) ? data : []);
        } catch (error) {
            console.error('Failed to fetch organizations:', error);
        }
    };

    const fetchAttendances = async (page = 1) => {
        try {
            setLoading(true);
            const params = new URLSearchParams({ track_type: 'head_office' });
            if (filterStartDate) params.append('start_date', filterStartDate);
            if (filterEndDate) params.append('end_date', filterEndDate);
            if (filterStatus) params.append('status', filterStatus);
            if (filterDivision) params.append('division_id', filterDivision);
            if (filterOffline) params.append('is_offline', filterOffline);
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
            console.error('Failed to fetch attendance:', error);
        } finally {
            setLoading(false);
        }
    };

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
            Swal.fire({
                title: 'Ekspor Gagal',
                text: 'Gagal mengexport data.',
                icon: 'error',
                confirmButtonColor: '#89b4e1',
            });
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

            Swal.fire({
                title: 'Berhasil!',
                text: 'Status kehadiran berhasil diperbarui.',
                icon: 'success',
                confirmButtonColor: '#89b4e1',
            });

            // Refresh data
            fetchAttendances();
            setSelectedAttendance(null);
        } catch (error) {
            console.error('Failed to approve attendance:', error);
            Swal.fire({
                title: 'Gagal!',
                text: 'Gagal memproses approval.',
                icon: 'error',
                confirmButtonColor: '#89b4e1',
            });
        }
    };

    const handleBulkApprove = async () => {
        if (selectedIds.length === 0) return;

        setIsBulkSubmitting(true);
        try {
            await apiClient.post('/attendances/bulk-approve', {
                ids: selectedIds,
                status: bulkStatus,
                admin_note: bulkNote
            });

            Swal.fire({
                title: 'Berhasil!',
                text: `${selectedIds.length} data absensi berhasil diproses.`,
                icon: 'success',
                confirmButtonColor: '#89b4e1',
            });

            setShowBulkModal(false);
            setSelectedIds([]);
            setBulkNote('');
            fetchAttendances();
        } catch (error) {
            console.error('Failed bulk approval:', error);
            Swal.fire({
                title: 'Gagal!',
                text: 'Terjadi kesalahan saat memproses bulk approval.',
                icon: 'error',
                confirmButtonColor: '#89b4e1',
            });
        } finally {
            setIsBulkSubmitting(false);
        }
    };

    const toggleSelectAll = () => {
        if (selectedIds.length === attendances.length) {
            setSelectedIds([]);
        } else {
            setSelectedIds(attendances.map(a => a.id));
        }
    };

    const toggleSelectOne = (id: number) => {
        setSelectedIds(prev =>
            prev.includes(id) ? prev.filter(i => i !== id) : [...prev, id]
        );
    };

    const smartSelectLate = () => {
        const targetIds = attendances
            .filter(att => {
                if (att.status !== 'pending') return false;
                if (!att.check_in) return false;
                // Criteria: office/field and > 08:05
                const [h, m] = att.check_in.split(':').map(Number);
                const isLate = h > 8 || (h === 8 && m > 5);
                return isLate;
            })
            .map(a => a.id);

        if (targetIds.length === 0) {
            Swal.fire({
                title: 'Info',
                text: 'Tidak ditemukan data pending dengan keterlambatan di atas 08:05.',
                icon: 'info',
                confirmButtonColor: '#89b4e1',
            });
            return;
        }

        setSelectedIds(targetIds);
        Swal.fire({
            title: 'Berhasil!',
            text: `${targetIds.length} data terpilih secara otomatis.`,
            icon: 'success',
            timer: 1500,
            showConfirmButton: false,
        });
    };



    const columns = [
        { name: "KARYAWAN", uid: "employee" },
        { name: "TANGGAL", uid: "date" },
        { name: "JAM MASUK", uid: "check_in" },
        { name: "JAM KELUAR", uid: "check_out" },
        { name: "TIPE/MODE", uid: "type" },
        { name: "STATUS", uid: "status" },
        { name: "LOKASI", uid: "location" },
        { name: "AKSI", uid: "actions" },
    ];

    const renderCell = (att: Attendance, columnKey: React.Key) => {
        switch (columnKey) {
            case "employee":
                return (
                    <User
                        avatarProps={{ radius: "lg", name: att.employee?.full_name?.[0]?.toUpperCase() }}
                        description={att.employee?.employee_code}
                        name={att.employee?.full_name || '-'}
                    >
                        {att.employee?.full_name || '-'}
                    </User>
                );
            case "date":
                return <p className="text-sm">{formatDate(att.date)}</p>;
            case "check_in":
                return <p className="text-sm font-mono">{att.check_in ? att.check_in.substring(0, 5) : '-'}</p>;
            case "check_out":
                return <p className="text-sm font-mono">{att.check_out ? att.check_out.substring(0, 5) : '-'}</p>;
            case "type":
                return (
                    <div className="flex flex-col gap-1">
                        <Chip size="sm" variant="flat" color={att.attendance_type === 'field' ? "primary" : "default"}>
                            {att.attendance_type === 'field' ? 'DINAS LUAR' : 'KANTOR'}
                        </Chip>
                        {att.is_offline && (
                            <Chip size="sm" variant="bordered" color="warning" className="border-warning text-warning-600">
                                OFFLINE
                            </Chip>
                        )}
                    </div>
                );
            case "status":
                return (
                    <Chip size="sm" variant="flat" color={getStatusColor(att.status)}>
                        {getStatusText(att.status)}
                    </Chip>
                );
            case "location":
                return (
                    <p className="text-xs text-gray-500 max-w-[200px] truncate" title={att.location_address || '-'}>
                        {att.location_address || '-'}
                    </p>
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

    const handleSelectionChange = (keys: "all" | Set<React.Key>) => {
        if (keys === "all") {
            setSelectedIds(attendances.map(a => a.id));
        } else {
            setSelectedIds(Array.from(keys).map(k => Number(k)));
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
                                    className="px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-[#419cc3] focus:border-transparent"
                                />
                            </div>
                            <div>
                                <label className="block text-sm font-medium text-gray-700 mb-2">Sampai Tanggal</label>
                                <input
                                    type="date"
                                    value={filterEndDate}
                                    onChange={(e) => setFilterEndDate(e.target.value)}
                                    className="px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-[#419cc3] focus:border-transparent"
                                />
                            </div>
                        </div>
                        <div>
                            <label className="block text-sm font-medium text-gray-700 mb-2">Divisi</label>
                            <select
                                value={filterDivision}
                                onChange={(e) => setFilterDivision(e.target.value)}
                                className="px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-[#419cc3] focus:border-transparent"
                            >
                                <option value="">Semua Divisi</option>
                                {organizations
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
                                className="px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-[#419cc3] focus:border-transparent"
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
                        <div>
                            <label className="block text-sm font-medium text-gray-700 mb-2">Sumber</label>
                            <select
                                value={filterOffline}
                                onChange={(e) => setFilterOffline(e.target.value)}
                                className="px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-[#419cc3] focus:border-transparent"
                            >
                                <option value="">Semua Sumber</option>
                                <option value="0">Online (Langsung)</option>
                                <option value="1">Offline (Ter-sync)</option>
                            </select>
                        </div>
                        <button
                            type="submit"
                            disabled={!filterStartDate}
                            className={`px-6 py-2 rounded-lg transition-colors font-medium ${!filterStartDate ? 'bg-gray-200 text-gray-400 cursor-not-allowed' : 'bg-[#89b4e1] text-[#419cc3] hover:bg-[#93C5FD]'}`}
                        >
                            Filter
                        </button>
                        <button
                            type="button"
                            onClick={handleExport}
                            className="px-6 py-2 bg-gray-600 text-white rounded-lg hover:bg-gray-700 transition-colors font-medium"
                        >
                            Export Excel
                        </button>
                        <button
                            type="button"
                            onClick={smartSelectLate}
                            className="px-6 py-2 bg-yellow-100 text-yellow-800 border border-yellow-200 rounded-lg hover:bg-yellow-200 transition-colors font-medium"
                        >
                            Pilih Terlambat ({" > "}08:05)
                        </button>
                        {selectedIds.length > 0 && (
                            <button
                                type="button"
                                onClick={() => setShowBulkModal(true)}
                                className="px-6 py-2 bg-[#419cc3] text-white rounded-lg hover:bg-[#419cc3]/90 transition-all font-bold animate-pulse shadow-lg ring-2 ring-white"
                            >
                                Approve Terpilih ({selectedIds.length})
                            </button>
                        )}
                    </form>
                </div>

                {/* Table */}
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
                        selectionMode="multiple"
                        onSelectionChange={handleSelectionChange}
                        emptyContent={
                            !hasFiltered ? (
                                <div className="p-8 flex flex-col items-center">
                                    <svg className="h-16 w-16 text-gray-300 mb-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1} d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z" />
                                    </svg>
                                    <p className="text-gray-500 text-lg font-medium mb-2">Belum ada data ditampilkan</p>
                                    <p className="text-gray-400">Silakan pilih rentang tanggal dan klik <strong>Filter</strong> untuk menampilkan data kehadiran.</p>
                                </div>
                            ) : "Tidak ada data kehadiran untuk rentang tanggal tersebut."
                        }
                    />
                </div>
            </div>

            <AttendanceDetailModal
                selectedAttendance={selectedAttendance}
                onClose={() => setSelectedAttendance(null)}
                onApprove={handleApprove}
            />

            <AttendanceBulkApprovalModal
                isOpen={showBulkModal}
                onClose={() => setShowBulkModal(false)}
                selectedIds={selectedIds}
                attendances={attendances}
                bulkStatus={bulkStatus}
                setBulkStatus={setBulkStatus}
                bulkNote={bulkNote}
                setBulkNote={setBulkNote}
                isBulkSubmitting={isBulkSubmitting}
                handleBulkApprove={handleBulkApprove}
            />
        </DashboardLayout>
    );
}
