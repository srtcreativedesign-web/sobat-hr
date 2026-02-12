'use client';

import { useState, useEffect } from 'react';
import { useAuthStore } from '@/store/auth-store';
import apiClient from '@/lib/api-client';
import Swal from 'sweetalert2';

interface Division {
    id: number;
    name: string;
    department?: {
        id: number;
        name: string;
    };
}

interface JobPosition {
    id: number;
    name: string;
    code: string | null;
    division_id: number | null;
    level: number;
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

    // Modal state
    const [isModalOpen, setIsModalOpen] = useState(false);
    const [isSaving, setIsSaving] = useState(false);
    const [editingId, setEditingId] = useState<number | null>(null);
    const [formData, setFormData] = useState({
        name: '',
        code: '',
        division_id: '',
        level: 0
    });

    const levels = [
        { value: 0, label: 'Staff' },
        { value: 1, label: 'Supervisor (SPV)' },
        { value: 2, label: 'Manager' },
        { value: 3, label: 'General Manager (GM)' },
        { value: 4, label: 'Director' },
    ];

    useEffect(() => {
        fetchData();
        fetchDivisions();
    }, [search]);

    const fetchData = async () => {
        setIsLoading(true);
        try {
            const params = search ? { search } : {};
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

    const resetForm = () => {
        setFormData({ name: '', code: '', division_id: '', level: 0 });
        setEditingId(null);
    };

    const handleOpenModal = (position?: JobPosition) => {
        if (position) {
            setEditingId(position.id);
            setFormData({
                name: position.name,
                code: position.code || '',
                division_id: position.division_id ? position.division_id.toString() : '',
                level: position.level
            });
        } else {
            resetForm();
        }
        setIsModalOpen(true);
    };

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();
        setIsSaving(true);

        try {
            const payload = {
                ...formData,
                division_id: formData.division_id ? parseInt(formData.division_id) : null,
            };

            if (editingId) {
                await apiClient.put(`/job-positions/${editingId}`, payload);
                Swal.fire('Sukses', 'Jabatan berhasil diperbarui', 'success');
            } else {
                await apiClient.post('/job-positions', payload);
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

    const getLevelLabel = (level: number) => {
        const found = levels.find(l => l.value === level);
        return found ? found.label : 'Unknown';
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
                <div className="p-4 border-b border-gray-100 flex gap-4">
                    <div className="relative flex-1 max-w-md">
                        <span className="absolute inset-y-0 left-0 pl-3 flex items-center text-gray-400">
                            <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
                            </svg>
                        </span>
                        <input
                            type="text"
                            placeholder="Cari Jabatan..."
                            className="w-full pl-10 pr-4 py-2 border rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                            value={search}
                            onChange={(e) => setSearch(e.target.value)}
                        />
                    </div>
                </div>

                <div className="overflow-x-auto">
                    <table className="w-full text-left text-sm">
                        <thead className="bg-gray-50 border-b border-gray-100">
                            <tr>
                                <th className="px-6 py-4 font-semibold text-gray-700">Nama Jabatan</th>
                                <th className="px-6 py-4 font-semibold text-gray-700">Departemen</th>
                                <th className="px-6 py-4 font-semibold text-gray-700">Divisi</th>
                                <th className="px-6 py-4 font-semibold text-gray-700">Level Approval</th>
                                <th className="px-6 py-4 font-semibold text-gray-700 text-right">Aksi</th>
                            </tr>
                        </thead>
                        <tbody className="divide-y divide-gray-100">
                            {isLoading ? (
                                <tr>
                                    <td colSpan={5} className="px-6 py-8 text-center text-gray-500">
                                        Memuat data...
                                    </td>
                                </tr>
                            ) : jobPositions.length === 0 ? (
                                <tr>
                                    <td colSpan={5} className="px-6 py-8 text-center text-gray-500">
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
                                                {getLevelLabel(item.level)}
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

            {/* Modal */}
            {isModalOpen && (
                <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black bg-opacity-50">
                    <div className="bg-white rounded-xl shadow-xl w-full max-w-lg overflow-hidden">
                        <div className="px-6 py-4 border-b border-gray-100 flex justify-between items-center">
                            <h3 className="text-lg font-semibold text-gray-900">
                                {editingId ? 'Edit Jabatan' : 'Tambah Jabatan'}
                            </h3>
                            <button onClick={() => setIsModalOpen(false)} className="text-gray-400 hover:text-gray-600">
                                <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                                </svg>
                            </button>
                        </div>

                        <form onSubmit={handleSubmit} className="p-6 space-y-4">
                            <div>
                                <label className="block text-sm font-medium text-gray-700 mb-1">Nama Jabatan <span className="text-red-500">*</span></label>
                                <input
                                    type="text"
                                    required
                                    className="w-full px-3 py-2 border rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 outline-none transition-all"
                                    value={formData.name}
                                    onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                                    placeholder="Contoh: Senior Backend Developer"
                                />
                            </div>

                            <div className="grid grid-cols-2 gap-4">
                                <div>
                                    <label className="block text-sm font-medium text-gray-700 mb-1">Kode</label>
                                    <input
                                        type="text"
                                        className="w-full px-3 py-2 border rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 outline-none transition-all"
                                        value={formData.code}
                                        onChange={(e) => setFormData({ ...formData, code: e.target.value })}
                                        placeholder="Contoh: DEV-SR"
                                    />
                                </div>
                                <div>
                                    <label className="block text-sm font-medium text-gray-700 mb-1">Level Approval <span className="text-red-500">*</span></label>
                                    <select
                                        className="w-full px-3 py-2 border rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 outline-none transition-all"
                                        value={formData.level}
                                        onChange={(e) => setFormData({ ...formData, level: parseInt(e.target.value) })}
                                    >
                                        {levels.map(l => (
                                            <option key={l.value} value={l.value}>{l.label}</option>
                                        ))}
                                    </select>
                                </div>
                            </div>

                            <div>
                                <label className="block text-sm font-medium text-gray-700 mb-1">Divisi</label>
                                <select
                                    className="w-full px-3 py-2 border rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 outline-none transition-all"
                                    value={formData.division_id}
                                    onChange={(e) => setFormData({ ...formData, division_id: e.target.value })}
                                >
                                    <option value="">-- Pilih Divisi --</option>
                                    {divisions.map(div => (
                                        <option key={div.id} value={div.id}>
                                            {div.name} {div.department ? `(${div.department.name})` : ''}
                                        </option>
                                    ))}
                                </select>
                            </div>

                            <div className="pt-4 flex justify-end gap-3">
                                <button
                                    type="button"
                                    onClick={() => setIsModalOpen(false)}
                                    className="px-4 py-2 text-gray-700 hover:bg-gray-100 rounded-lg transition-colors"
                                >
                                    Batal
                                </button>
                                <button
                                    type="submit"
                                    disabled={isSaving}
                                    className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-all disabled:opacity-50 disabled:cursor-not-allowed flex items-center gap-2"
                                >
                                    {isSaving && (
                                        <svg className="animate-spin h-4 w-4 text-white" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                                            <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
                                            <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                                        </svg>
                                    )}
                                    {isSaving ? 'Menyimpan...' : 'Simpan'}
                                </button>
                            </div>
                        </form>
                    </div>
                </div>
            )}
        </div>
    );
}
