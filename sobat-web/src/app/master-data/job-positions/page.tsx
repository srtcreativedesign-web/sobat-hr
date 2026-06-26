'use client';

import { useState, useEffect } from 'react';
import { useAuthStore } from '@/store/auth-store';
import apiClient from '@/lib/api-client';
import Swal from 'sweetalert2';
import { Input } from '@nextui-org/react';
import { Search } from 'lucide-react';
import JobPositionModal, { JobPositionPayload, Division } from './components/JobPositionModal';

interface JobPosition {
    id: number;
    name: string;
    code: string | null;
    division_id: number | null;
    level: number;
    track: 'office' | 'operational';
    parent_position_id: number | null;
    division?: Division;
    parent_position?: JobPosition;
    created_at?: string;
}

export default function ManageJobPositionsPage() {
    const { user } = useAuthStore();
    const [jobPositions, setJobPositions] = useState<JobPosition[]>([]);
    const [divisions, setDivisions] = useState<Division[]>([]);
    const [isLoading, setIsLoading] = useState(true);
    const [search, setSearch] = useState('');
    const [filterDivision, setFilterDivision] = useState('');
    const [filterTrack, setFilterTrack] = useState('');

    // Modal state
    const [isModalOpen, setIsModalOpen] = useState(false);
    const [isSaving, setIsSaving] = useState(false);
    const [editingId, setEditingId] = useState<number | null>(null);
    const [initialData, setInitialData] = useState<JobPositionPayload | null>(null);

    const tracks = [
        { value: 'office', label: 'Office' },
        { value: 'operational', label: 'Operational' },
    ];
    
    const officeLevels = [
        { value: 0, label: 'Staff' },
        { value: 1, label: 'Supervisor (SPV)' },
        { value: 2, label: 'Manager' },
        { value: 3, label: 'General Manager (GM)' },
        { value: 4, label: 'Director' },
    ];

    const operationalLevels = [
        { value: 0, label: 'Crew' },
        { value: 1, label: 'Supervisor' },
        { value: 2, label: 'Manager' },
    ];

    useEffect(() => {
        fetchData();
        fetchDivisions();
        // eslint-disable-next-line react-hooks/exhaustive-deps
    }, [search, filterDivision, filterTrack]);

    const fetchData = async () => {
        setIsLoading(true);
        try {
            const params: any = {};
            if (search) params.search = search;
            if (filterDivision) params.division_id = filterDivision;
            if (filterTrack) params.track = filterTrack;

            const { data } = await apiClient.get('/job-positions', { params });
            setJobPositions(data);
        } catch (error) {
            console.error('Error fetching job positions:', error);
            Swal.fire('Error', 'Gagal mengambil data jabatan', 'error');
        } finally {
            setIsLoading(false);
        }
    };

    const fetchDivisions = async () => {
        try {
            const { data } = await apiClient.get('/divisions');
            setDivisions(data);
        } catch (error) {
            console.error('Error fetching divisions:', error);
        }
    };

    const resetFilters = () => {
        setSearch('');
        setFilterDivision('');
        setFilterTrack('');
    };

    const handleOpenModal = (position?: JobPosition) => {
        if (position) {
            setEditingId(position.id);
            setInitialData({
                name: position.name,
                code: position.code || '',
                division_id: position.division_id ? position.division_id.toString() : '',
                level: position.level,
                track: position.track || 'office'
            });
        } else {
            setEditingId(null);
            setInitialData(null);
        }
        setIsModalOpen(true);
    };

    const handleSubmit = async (payload: JobPositionPayload, id: number | null) => {
        setIsSaving(true);
        try {
            const submitPayload = {
                ...payload,
                division_id: payload.division_id ? parseInt(payload.division_id) : null,
            };

            if (id) {
                await apiClient.put(`/job-positions/${id}`, submitPayload);
                Swal.fire('Sukses', 'Jabatan berhasil diperbarui', 'success');
            } else {
                await apiClient.post('/job-positions', submitPayload);
                Swal.fire('Sukses', 'Jabatan berhasil ditambahkan', 'success');
            }
            setIsModalOpen(false);
            fetchData();
        } catch (error: any) {
            console.error('Error saving job position:', error);
            Swal.fire('Error', error.response?.data?.message || 'Gagal menyimpan data', 'error');
        } finally {
            setIsSaving(false);
        }
    };

    const handleDelete = async (id: number) => {
        const result = await Swal.fire({
            title: 'Apakah Anda yakin?',
            text: "Data yang dihapus tidak dapat dikembalikan!",
            icon: 'warning',
            showCancelButton: true,
            confirmButtonColor: '#d33',
            cancelButtonColor: '#3085d6',
            confirmButtonText: 'Ya, hapus!',
            cancelButtonText: 'Batal'
        });

        if (result.isConfirmed) {
            try {
                await apiClient.delete(`/job-positions/${id}`);
                Swal.fire('Terhapus!', 'Jabatan berhasil dihapus.', 'success');
                fetchData();
            } catch (error) {
                console.error('Error deleting job position:', error);
                Swal.fire('Error', 'Gagal menghapus jabatan', 'error');
            }
        }
    };

    const getLevelLabel = (level: number, track: string = 'office') => {
        const levels = track === 'operational' ? operationalLevels : officeLevels;
        const found = levels.find(l => l.value === level);
        return found ? found.label : 'Unknown';
    };

    const getTrackLabel = (track: string) => {
        const found = tracks.find(t => t.value === track);
        return found ? found.label : track;
    };

    return (
        <div className="p-6">
            <div className="flex justify-between items-center mb-6">
                <h1 className="text-2xl font-bold text-gray-800">Manajemen Jabatan</h1>
                <button
                    onClick={() => handleOpenModal()}
                    className="bg-blue-600 hover:bg-blue-700 text-white px-4 py-2 rounded-lg flex items-center gap-2"
                >
                    <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 4v16m8-8H4" />
                    </svg>
                    Tambah Jabatan
                </button>
            </div>

            <div className="bg-white rounded-xl shadow-sm border border-gray-100 overflow-hidden">
                <div className="p-4 border-b border-gray-100 flex gap-3 flex-wrap items-end">
                    <div className="w-full md:w-64">
                        <Input
                            isClearable
                            classNames={{
                                inputWrapper: "border border-gray-300 bg-white hover:bg-gray-50 focus-within:ring-2 focus-within:ring-[#419cc3]",
                            }}
                            placeholder="Cari Jabatan..."
                            startContent={<Search className="text-gray-400" size={18} />}
                            value={search}
                            onClear={() => setSearch('')}
                            onChange={(e) => setSearch(e.target.value)}
                        />
                    </div>

                    <div className="min-w-[180px]">
                        <select
                            className="w-full px-3 py-2 border rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 text-sm"
                            value={filterDivision}
                            onChange={(e) => setFilterDivision(e.target.value)}
                        >
                            <option value="">Semua Divisi</option>
                            {divisions.map(div => (
                                <option key={div.id} value={div.id}>
                                    {div.name} {div.department ? `(${div.department.name})` : ''}
                                </option>
                            ))}
                        </select>
                    </div>

                    <div className="min-w-[140px]">
                        <select
                            className="w-full px-3 py-2 border rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 text-sm"
                            value={filterTrack}
                            onChange={(e) => setFilterTrack(e.target.value)}
                        >
                            <option value="">Semua Track</option>
                            <option value="office">Office</option>
                            <option value="operational">Operational</option>
                        </select>
                    </div>

                    {(search || filterDivision || filterTrack) && (
                        <button
                            onClick={resetFilters}
                            className="px-3 py-2 text-sm text-gray-600 hover:text-gray-900 hover:bg-gray-100 rounded-lg transition-colors"
                        >
                            Reset Filter
                        </button>
                    )}
                </div>

                <div className="overflow-x-auto">
                    <table className="w-full text-left text-sm">
                        <thead className="bg-gray-50 border-b border-gray-100">
                            <tr>
                                <th className="px-6 py-4 font-semibold text-gray-700">Nama Jabatan</th>
                                <th className="px-6 py-4 font-semibold text-gray-700">Track</th>
                                <th className="px-6 py-4 font-semibold text-gray-700">Departemen</th>
                                <th className="px-6 py-4 font-semibold text-gray-700">Divisi</th>
                                <th className="px-6 py-4 font-semibold text-gray-700">Level Approval</th>
                                <th className="px-6 py-4 font-semibold text-gray-700 text-right">Aksi</th>
                            </tr>
                        </thead>
                        <tbody className="divide-y divide-gray-100">
                            {isLoading ? (
                                <tr>
                                    <td colSpan={6} className="px-6 py-8 text-center text-gray-500">
                                        Memuat data...
                                    </td>
                                </tr>
                            ) : jobPositions.length === 0 ? (
                                <tr>
                                    <td colSpan={6} className="px-6 py-8 text-center text-gray-500">
                                        Belum ada data jabatan.
                                    </td>
                                </tr>
                            ) : (
                                jobPositions.map((item) => (
                                    <tr key={item.id} className="hover:bg-gray-50 transition-colors">
                                        <td className="px-6 py-4 font-medium text-gray-900">
                                            {item.name}
                                            {item.code && <span className="ml-2 text-xs text-gray-500">({item.code})</span>}
                                        </td>
                                        <td className="px-6 py-4">
                                            <span className={`px-2 py-1 rounded-full text-xs font-medium ${item.track === 'operational'
                                                ? 'bg-orange-100 text-orange-800'
                                                : 'bg-teal-100 text-teal-800'
                                                }`}>
                                                {getTrackLabel(item.track || 'office')}
                                            </span>
                                        </td>
                                        <td className="px-6 py-4 text-gray-600">
                                            {item.division?.department?.name || '-'}
                                        </td>
                                        <td className="px-6 py-4 text-gray-600">{item.division?.name || '-'}</td>
                                        <td className="px-6 py-4">
                                            <span className={`px-2 py-1 rounded-full text-xs font-medium ${item.level === 0 ? 'bg-gray-100 text-gray-800' :
                                                item.level === 1 ? 'bg-blue-100 text-blue-800' :
                                                    item.level === 2 ? 'bg-indigo-100 text-indigo-800' :
                                                        'bg-purple-100 text-purple-800'
                                                }`}>
                                                {getLevelLabel(item.level, item.track)}
                                            </span>
                                        </td>
                                        <td className="px-6 py-4 text-right">
                                            <div className="flex justify-end gap-2">
                                                <button
                                                    onClick={() => handleOpenModal(item)}
                                                    className="text-blue-600 hover:text-blue-800 p-1 rounded hover:bg-blue-50"
                                                    title="Edit"
                                                >
                                                    <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z" />
                                                    </svg>
                                                </button>
                                                <button
                                                    onClick={() => handleDelete(item.id)}
                                                    className="text-red-600 hover:text-red-800 p-1 rounded hover:bg-red-50"
                                                    title="Hapus"
                                                >
                                                    <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
                                                    </svg>
                                                </button>
                                            </div>
                                        </td>
                                    </tr>
                                ))
                            )}
                        </tbody>
                    </table>
                </div>
            </div>

            <JobPositionModal
                isOpen={isModalOpen}
                onClose={() => setIsModalOpen(false)}
                onSubmit={handleSubmit}
                isSaving={isSaving}
                initialData={initialData}
                editingId={editingId}
                divisions={divisions}
            />
        </div>
    );
}
