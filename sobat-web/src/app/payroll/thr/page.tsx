'use client';

import { useEffect, useState, useRef } from 'react';
import { useRouter } from 'next/navigation';
import { useAuthStore } from '@/store/auth-store';
import DashboardLayout from '@/components/DashboardLayout';
import apiClient from '@/lib/api-client';
import SignatureCanvas from 'react-signature-canvas';
import Swal from 'sweetalert2';

interface Thr {
    id: number;
    employee: {
        employee_code: string;
        full_name: string;
        join_date: string | null;
    };
    year: string;
    amount: number;
    status: 'draft' | 'approved' | 'paid';
    details: any;
}

export default function ThrPage() {
    const router = useRouter();
    const { isAuthenticated, checkAuth } = useAuthStore();

    const [thrs, setThrs] = useState<Thr[]>([]);
    const [loading, setLoading] = useState(false);
    const [showUploadModal, setShowUploadModal] = useState(false);
    const [selectedFile, setSelectedFile] = useState<File | null>(null);
    const [uploadProgress, setUploadProgress] = useState(0);
    const [parsedRows, setParsedRows] = useState<any[]>([]);
    const [selectedIds, setSelectedIds] = useState<number[]>([]);

    // Approval signature modal state
    const [showApprovalModal, setShowApprovalModal] = useState(false);
    const [approvalMode, setApprovalMode] = useState<'single' | 'bulk'>('single');
    const [approvalTargetId, setApprovalTargetId] = useState<number | null>(null);
    const [signerName, setSignerName] = useState('');
    const sigCanvasRef = useRef<SignatureCanvas>(null);

    const [selectedDivision, setSelectedDivision] = useState<'ho' | 'op'>('ho');
    const [selectedViewDivision, setSelectedViewDivision] = useState<string>('all');
    const [selectedYear, setSelectedYear] = useState(new Date().getFullYear());

    useEffect(() => {
        checkAuth();
    }, [checkAuth]);

    useEffect(() => {
        fetchThrs();
        // eslint-disable-next-line react-hooks/exhaustive-deps
    }, [selectedYear, selectedViewDivision]);

    const fetchThrs = async () => {
        try {
            setLoading(true);
            const response = await apiClient.get('/thrs', {
                params: {
                    year: selectedYear,
                    division: selectedViewDivision !== 'all' ? selectedViewDivision : undefined
                }
            });
            setThrs(response.data.data || []);
            setSelectedIds([]);
        } catch (error) {
            console.error('Failed to fetch THRs:', error);
        } finally {
            setLoading(false);
        }
    };

    const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
        if (e.target.files && e.target.files[0]) {
            setSelectedFile(e.target.files[0]);
        }
    };

    const handleUpload = async () => {
        if (!selectedFile) return;

        const formData = new FormData();
        formData.append('file', selectedFile);
        formData.append('year', selectedYear.toString());

        try {
            setUploadProgress(0);
            setParsedRows([]);

            const endpoint = selectedDivision === 'ho' ? '/thrs/ho/import' : '/thrs/op/import';

            const response = await apiClient.post(endpoint, formData, {
                headers: { 'Content-Type': 'multipart/form-data' },
                onUploadProgress: (progressEvent) => {
                    const progress = progressEvent.total
                        ? Math.round((progressEvent.loaded * 100) / progressEvent.total)
                        : 0;
                    setUploadProgress(progress);
                },
            });

            if (response.data.rows) {
                setParsedRows(response.data.rows);
                setUploadProgress(100);
            }
        } catch (error: any) {
            Swal.fire({
                title: 'Import Gagal',
                text: error.response?.data?.message || 'Import failed',
                icon: 'error',
                confirmButtonColor: '#06B6D4',
            });
        }
    };

    const handleSaveImport = async () => {
        try {
            setLoading(true);
            const response = await apiClient.post('/thrs/import/save', {
                rows: parsedRows,
                division: selectedDivision
            });

            Swal.fire({
                title: 'Berhasil!',
                text: response.data.message,
                icon: 'success',
                confirmButtonColor: '#06B6D4',
            });
            setShowUploadModal(false);
            setSelectedFile(null);
            setParsedRows([]);
            fetchThrs();
        } catch (error: any) {
            Swal.fire({
                title: 'Gagal Menyimpan',
                text: error.response?.data?.message || 'Failed to save data',
                icon: 'error',
                confirmButtonColor: '#06B6D4',
            });
        } finally {
            setLoading(false);
        }
    };

    // Open approval modal for single approve
    const openSingleApprove = (id: number) => {
        setApprovalMode('single');
        setApprovalTargetId(id);
        setSignerName('');
        sigCanvasRef.current?.clear();
        setShowApprovalModal(true);
    };

    // Open approval modal for bulk approve
    const openBulkApprove = () => {
        const draftCount = selectedIds.length > 0
            ? selectedIds.filter(id => thrs.find(t => t.id === id)?.status === 'draft').length
            : thrs.filter(t => t.status === 'draft').length;

        if (draftCount === 0) {
            Swal.fire({
                title: 'Informasi',
                text: 'Tidak ada THR draft untuk di-approve',
                icon: 'info',
                confirmButtonColor: '#06B6D4',
            });
            return;
        }

        setApprovalMode('bulk');
        setApprovalTargetId(null);
        setSignerName('');
        sigCanvasRef.current?.clear();
        setShowApprovalModal(true);
    };

    // Execute approval after signature
    const executeApproval = async () => {
        if (!signerName.trim()) {
            Swal.fire('Perhatian', 'Nama penandatangan harus diisi', 'warning');
            return;
        }

        if (sigCanvasRef.current?.isEmpty()) {
            Swal.fire('Perhatian', 'Tanda tangan harus diisi', 'warning');
            return;
        }

        const signature = sigCanvasRef.current?.toDataURL('image/png') || '';

        try {
            setLoading(true);

            if (approvalMode === 'single' && approvalTargetId) {
                await apiClient.post(`/thrs/${approvalTargetId}/approve`, {
                    signer_name: signerName,
                    signature: signature,
                });
            } else {
                const payload: any = {
                    signer_name: signerName,
                    signature: signature,
                };
                if (selectedIds.length > 0) {
                    payload.ids = selectedIds;
                } else {
                    payload.year = selectedYear;
                    payload.division = selectedViewDivision;
                }
                const response = await apiClient.post('/thrs/bulk-approve', payload);
                Swal.fire('Berhasil!', response.data.message, 'success');
            }

            setShowApprovalModal(false);
            fetchThrs();
        } catch (error: any) {
            Swal.fire('Gagal!', error.response?.data?.message || 'Gagal approve', 'error');
        } finally {
            setLoading(false);
        }
    };

    const handleDownloadSlip = async (id: number, employeeCode: string) => {
        try {
            const response = await apiClient.get(`/thrs/${id}/slip`, {
                responseType: 'blob',
            });
            const url = window.URL.createObjectURL(new Blob([response.data]));
            const link = document.createElement('a');
            link.href = url;
            link.setAttribute('download', `Slip_THR_${employeeCode}_${selectedYear}.pdf`);
            document.body.appendChild(link);
            link.click();
            link.remove();
        } catch (error) {
            Swal.fire('Error', 'Gagal download slip', 'error');
        }
    };

    const formatCurrency = (value: number) => {
        return new Intl.NumberFormat('id-ID', {
            style: 'currency',
            currency: 'IDR',
            minimumFractionDigits: 0,
        }).format(value);
    };

    const calculateMasaKerja = (joinDate: string | null): string => {
        if (!joinDate) return '-';
        const join = new Date(joinDate);
        const now = new Date();
        const diffMs = now.getTime() - join.getTime();
        const totalMonths = Math.floor(diffMs / (1000 * 60 * 60 * 24 * 30.44));
        const years = Math.floor(totalMonths / 12);
        const months = totalMonths % 12;
        if (years === 0) return `${months} bulan`;
        if (months === 0) return `${years} tahun`;
        return `${years} tahun ${months} bulan`;
    };

    const toggleSelectAll = () => {
        if (selectedIds.length === draftThrs.length) {
            setSelectedIds([]);
        } else {
            setSelectedIds(draftThrs.map(t => t.id));
        }
    };

    const toggleSelect = (id: number) => {
        setSelectedIds(prev =>
            prev.includes(id) ? prev.filter(i => i !== id) : [...prev, id]
        );
    };

    const draftThrs = thrs.filter(t => t.status === 'draft');
    const hasDrafts = draftThrs.length > 0;

    if (!isAuthenticated) return null;

    return (
        <DashboardLayout>
            {/* Header */}
            <div className="bg-white border-b border-gray-200 sticky top-0 z-10">
                <div className="px-8 py-6">
                    <div className="flex items-center justify-between">
                        <div>
                            <h1 className="text-3xl font-bold bg-gradient-to-r from-[#06B6D4] to-[#3B82F6] bg-clip-text text-transparent">
                                THR Management
                            </h1>
                            <p className="text-gray-600 mt-1">Kelola Tunjangan Hari Raya (THR) Tahunan</p>
                        </div>
                        <div className="flex items-center gap-3">
                            {hasDrafts && (
                                <button
                                    onClick={openBulkApprove}
                                    disabled={loading}
                                    className="flex items-center gap-2 px-5 py-3 bg-green-500 text-white rounded-xl font-semibold hover:bg-green-600 hover:shadow-lg transition-all transform hover:scale-[1.02] disabled:opacity-50"
                                >
                                    <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
                                    </svg>
                                    {selectedIds.length > 0
                                        ? `Approve (${selectedIds.length})`
                                        : `Approve Semua (${draftThrs.length})`
                                    }
                                </button>
                            )}
                            <button
                                onClick={() => setShowUploadModal(true)}
                                className="flex items-center gap-2 px-6 py-3 bg-gradient-to-r from-[#06B6D4] to-[#3B82F6] text-white rounded-xl font-semibold hover:shadow-lg transition-all transform hover:scale-[1.02]"
                            >
                                <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M7 16a4 4 0 01-.88-7.903A5 5 0 1115.9 6L16 6a5 5 0 011 9.9M15 13l-3-3m0 0l-3 3m3-3v12" />
                                </svg>
                                Import THR
                            </button>
                        </div>
                    </div>
                </div>
            </div>

            {/* Filter Section */}
            <div className="bg-white border-b border-gray-200 px-8 py-4 flex items-center gap-6">
                <div className="flex items-center gap-2">
                    <span className="text-sm font-semibold text-gray-700">Tahun:</span>
                    <select
                        value={selectedYear}
                        onChange={(e) => setSelectedYear(parseInt(e.target.value))}
                        className="px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:border-[#06B6D4] text-sm font-medium"
                    >
                        {[...Array(5)].map((_, i) => {
                            const year = new Date().getFullYear() - i;
                            return <option key={year} value={year}>{year}</option>;
                        })}
                    </select>
                </div>

                <div className="flex items-center gap-2">
                    <span className="text-sm font-semibold text-gray-700">Divisi:</span>
                    <select
                        value={selectedViewDivision}
                        onChange={(e) => setSelectedViewDivision(e.target.value)}
                        className="px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:border-[#06B6D4] text-sm font-medium"
                    >
                        <option value="all">Semua Divisi</option>
                        <option value="ho">Head Office</option>
                        <option value="op">Operational</option>
                    </select>
                </div>
            </div>

            {/* Main Content */}
            <div className="p-8">
                <div className="bg-white rounded-2xl shadow-sm border border-gray-100 overflow-hidden">
                    <table className="w-full text-left">
                        <thead className="bg-gray-50 border-b border-gray-100">
                            <tr>
                                <th className="px-4 py-4 w-10">
                                    {hasDrafts && (
                                        <input
                                            type="checkbox"
                                            checked={selectedIds.length === draftThrs.length && draftThrs.length > 0}
                                            onChange={toggleSelectAll}
                                            className="w-4 h-4 rounded border-gray-300 text-[#06B6D4] focus:ring-[#06B6D4] cursor-pointer"
                                        />
                                    )}
                                </th>
                                <th className="px-6 py-4 text-xs font-bold text-gray-500 uppercase tracking-wider">Karyawan</th>
                                <th className="px-6 py-4 text-xs font-bold text-gray-500 uppercase tracking-wider">Tahun</th>
                                <th className="px-6 py-4 text-xs font-bold text-gray-500 uppercase tracking-wider text-center">Masa Kerja</th>
                                <th className="px-6 py-4 text-xs font-bold text-gray-500 uppercase tracking-wider text-right">Jumlah THR</th>
                                <th className="px-6 py-4 text-xs font-bold text-gray-500 uppercase tracking-wider text-center">Status</th>
                                <th className="px-6 py-4 text-xs font-bold text-gray-500 uppercase tracking-wider text-center">Aksi</th>
                            </tr>
                        </thead>
                        <tbody className="divide-y divide-gray-50 text-sm">
                            {loading ? (
                                <tr><td colSpan={7} className="px-6 py-12 text-center text-gray-400">Loading data...</td></tr>
                            ) : thrs.length === 0 ? (
                                <tr><td colSpan={7} className="px-6 py-12 text-center text-gray-400">Tidak ada data THR ditemukan</td></tr>
                            ) : (
                                thrs.map((thr) => (
                                    <tr key={thr.id} className="hover:bg-gray-50/50 transition-colors">
                                        <td className="px-4 py-4">
                                            {thr.status === 'draft' && (
                                                <input
                                                    type="checkbox"
                                                    checked={selectedIds.includes(thr.id)}
                                                    onChange={() => toggleSelect(thr.id)}
                                                    className="w-4 h-4 rounded border-gray-300 text-[#06B6D4] focus:ring-[#06B6D4] cursor-pointer"
                                                />
                                            )}
                                        </td>
                                        <td className="px-6 py-4">
                                            <div className="font-semibold text-gray-900">{thr.employee.full_name}</div>
                                            <div className="text-xs text-gray-500">{thr.employee.employee_code}</div>
                                        </td>
                                        <td className="px-6 py-4 text-gray-600">{thr.year}</td>
                                        <td className="px-6 py-4 text-center text-gray-600 font-medium">{calculateMasaKerja(thr.employee.join_date)}</td>
                                        <td className="px-6 py-4 text-right font-bold text-[#06B6D4]">{formatCurrency(thr.amount)}</td>
                                        <td className="px-6 py-4 text-center">
                                            <span className={`px-3 py-1 rounded-full text-[10px] font-bold uppercase tracking-wider border ${thr.status === 'paid' ? 'bg-green-50 border-green-200 text-green-700' :
                                                thr.status === 'approved' ? 'bg-blue-50 border-blue-200 text-blue-700' :
                                                    'bg-yellow-50 border-yellow-200 text-yellow-700'
                                                }`}>
                                                {thr.status}
                                            </span>
                                        </td>
                                        <td className="px-6 py-4 text-center">
                                            <div className="flex items-center justify-center gap-2">
                                                {thr.status === 'draft' && (
                                                    <button
                                                        onClick={() => openSingleApprove(thr.id)}
                                                        className="text-green-600 hover:text-green-800 font-bold text-xs hover:underline"
                                                        title="Approve"
                                                    >
                                                        Approve
                                                    </button>
                                                )}
                                                {thr.status === 'draft' && (
                                                    <span className="text-gray-300">|</span>
                                                )}
                                                <button
                                                    onClick={() => handleDownloadSlip(thr.id, thr.employee.employee_code)}
                                                    className="text-[#06B6D4] hover:underline font-bold text-xs"
                                                >
                                                    Download PDF
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

            {/* Approval Signature Modal */}
            {showApprovalModal && (
                <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50 backdrop-blur-sm">
                    <div className="bg-white rounded-2xl shadow-2xl w-full max-w-lg overflow-hidden animate-in fade-in zoom-in duration-200">
                        <div className="p-6 border-b border-gray-100 bg-gradient-to-r from-green-500 to-emerald-600">
                            <h2 className="text-xl font-bold text-white flex items-center gap-2">
                                <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
                                </svg>
                                {approvalMode === 'single' ? 'Approve THR' : `Bulk Approve THR`}
                            </h2>
                            <p className="text-green-100 text-sm mt-1">
                                {approvalMode === 'single'
                                    ? 'Tandatangani untuk menyetujui slip THR ini'
                                    : `Tandatangani untuk menyetujui ${selectedIds.length > 0 ? selectedIds.length : draftThrs.length} slip THR`
                                }
                            </p>
                        </div>

                        <div className="p-6 space-y-6">
                            {/* Signer Name */}
                            <div>
                                <label className="block text-sm font-bold text-gray-700 mb-2">Nama Penandatangan</label>
                                <input
                                    type="text"
                                    value={signerName}
                                    onChange={(e) => setSignerName(e.target.value)}
                                    placeholder="Masukkan nama lengkap..."
                                    className="w-full px-4 py-3 border-2 border-gray-200 rounded-xl focus:outline-none focus:border-green-500 text-sm font-medium transition-colors"
                                />
                            </div>

                            {/* Signature Pad */}
                            <div>
                                <div className="flex items-center justify-between mb-2">
                                    <label className="block text-sm font-bold text-gray-700">Tanda Tangan Digital</label>
                                    <button
                                        onClick={() => sigCanvasRef.current?.clear()}
                                        className="text-xs text-red-500 font-bold hover:underline"
                                    >
                                        Hapus
                                    </button>
                                </div>
                                <div className="border-2 border-dashed border-gray-300 rounded-xl overflow-hidden bg-gray-50 relative">
                                    <SignatureCanvas
                                        ref={sigCanvasRef}
                                        penColor="#1a1a2e"
                                        canvasProps={{
                                            width: 440,
                                            height: 200,
                                            className: 'w-full bg-white cursor-crosshair',
                                            style: { width: '100%', height: '200px' },
                                        }}
                                    />
                                    <div className="absolute bottom-3 left-1/2 -translate-x-1/2 text-xs text-gray-300 font-medium pointer-events-none">
                                        Tanda tangan di sini
                                    </div>
                                </div>
                            </div>
                        </div>

                        <div className="p-6 bg-gray-50 border-t border-gray-100 flex justify-end gap-3">
                            <button
                                onClick={() => setShowApprovalModal(false)}
                                className="px-6 py-3 text-gray-500 font-bold hover:bg-gray-100 rounded-xl transition-all"
                            >
                                Batal
                            </button>
                            <button
                                onClick={executeApproval}
                                disabled={loading}
                                className="px-8 py-3 bg-green-500 text-white rounded-xl font-bold hover:bg-green-600 transition-all flex items-center gap-2 shadow-lg shadow-green-100 disabled:opacity-50"
                            >
                                {loading && <svg className="animate-spin h-4 w-4" viewBox="0 0 24 24"><circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle><path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path></svg>}
                                <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
                                </svg>
                                Approve & Tandatangan
                            </button>
                        </div>
                    </div>
                </div>
            )}

            {/* Upload Modal */}
            {showUploadModal && (
                <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50 backdrop-blur-sm">
                    <div className="bg-white rounded-2xl shadow-2xl w-full max-w-4xl max-h-[90vh] flex flex-col overflow-hidden animate-in fade-in zoom-in duration-200">
                        <div className="p-6 border-b border-gray-100 flex items-center justify-between bg-white sticky top-0 z-10">
                            <h2 className="text-xl font-bold text-gray-800">Import Data THR</h2>
                            <button onClick={() => { setShowUploadModal(false); setParsedRows([]); }} className="text-gray-400 hover:text-gray-600 p-2">
                                <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" /></svg>
                            </button>
                        </div>

                        <div className="p-8 overflow-y-auto">
                            <div className="grid grid-cols-2 gap-8 mb-8">
                                <div className="space-y-4">
                                    <label className="block text-sm font-bold text-gray-700 uppercase tracking-wider">1. Pilih Divisi</label>
                                    <div className="grid grid-cols-2 gap-3">
                                        <button
                                            onClick={() => setSelectedDivision('ho')}
                                            className={`px-4 py-8 rounded-xl border-2 transition-all flex flex-col items-center gap-2 ${selectedDivision === 'ho' ? 'border-[#06B6D4] bg-cyan-50 text-[#06B6D4]' : 'border-gray-100 hover:border-gray-200 text-gray-500'}`}
                                        >
                                            <svg className="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4" /></svg>
                                            <span className="font-bold">Head Office</span>
                                        </button>
                                        <button
                                            onClick={() => setSelectedDivision('op')}
                                            className={`px-4 py-8 rounded-xl border-2 transition-all flex flex-col items-center gap-2 ${selectedDivision === 'op' ? 'border-[#06B6D4] bg-cyan-50 text-[#06B6D4]' : 'border-gray-100 hover:border-gray-200 text-gray-500'}`}
                                        >
                                            <svg className="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13 10V3L4 14h7v7l9-11h-7z" /></svg>
                                            <span className="font-bold">Operational</span>
                                        </button>
                                    </div>
                                </div>

                                <div className="space-y-4">
                                    <label className="block text-sm font-bold text-gray-700 uppercase tracking-wider">2. Unggah File Excel</label>
                                    <div className={`relative border-2 border-dashed rounded-2xl p-8 flex flex-col items-center justify-center transition-all ${selectedFile ? 'border-green-200 bg-green-50' : 'border-gray-200 hover:border-[#06B6D4] bg-gray-50'}`}>
                                        <input type="file" onChange={handleFileChange} className="absolute inset-0 w-full h-full opacity-0 cursor-pointer" accept=".xlsx,.xls,.csv" />
                                        <svg className={`w-12 h-12 mb-4 ${selectedFile ? 'text-green-500' : 'text-gray-400'}`} fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" /></svg>
                                        <p className="text-sm font-bold text-gray-600 mb-1">{selectedFile ? selectedFile.name : 'Pilih file Excel yang akan diupload'}</p>
                                        <p className="text-xs text-gray-400">Hanya format XLSX, XLS, atau CSV yang didukung</p>
                                    </div>
                                </div>
                            </div>

                            {parsedRows.length > 0 ? (
                                <div className="space-y-4 animate-in slide-in-from-bottom-4 duration-300">
                                    <div className="flex items-center justify-between">
                                        <h3 className="text-sm font-bold text-gray-700 uppercase tracking-wider">Preview Data ({parsedRows.length} Karyawan)</h3>
                                        <button onClick={() => setParsedRows([])} className="text-xs text-red-500 font-bold hover:underline">Hapus Semua</button>
                                    </div>
                                    <div className="border rounded-xl overflow-hidden max-h-[400px] overflow-y-auto shadow-inner bg-gray-50/50">
                                        <table className="w-full text-xs">
                                            <thead className="bg-white border-b sticky top-0 z-10">
                                                <tr>
                                                    <th className="px-4 py-3 text-left font-bold text-gray-500 uppercase tracking-wider">Nama Karyawan</th>
                                                    <th className="px-4 py-3 text-center font-bold text-gray-500 uppercase tracking-wider">Tahun</th>
                                                    <th className="px-4 py-3 text-right font-bold text-gray-500 uppercase tracking-wider">Jumlah THR</th>
                                                </tr>
                                            </thead>
                                            <tbody className="divide-y divide-gray-100">
                                                {parsedRows.map((row, idx) => (
                                                    <tr key={idx} className="bg-white">
                                                        <td className="px-4 py-3 font-medium text-gray-700">{row.employee_name}</td>
                                                        <td className="px-4 py-3 text-center text-gray-600">{row.year}</td>
                                                        <td className="px-4 py-3 text-right font-mono font-bold text-[#06B6D4]">{formatCurrency(row.amount)}</td>
                                                    </tr>
                                                ))}
                                            </tbody>
                                        </table>
                                    </div>
                                </div>
                            ) : selectedFile && (
                                <div className="flex justify-center py-6">
                                    <button
                                        onClick={handleUpload}
                                        disabled={loading}
                                        className="flex items-center gap-2 px-8 py-4 bg-[#06B6D4] text-white rounded-xl font-bold hover:bg-[#0891b2] transition-all disabled:bg-gray-400 shadow-lg shadow-cyan-100"
                                    >
                                        {loading ? (
                                            <svg className="animate-spin h-5 w-5 mr-3" viewBox="0 0 24 24"><circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle><path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path></svg>
                                        ) : (
                                            <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M14.752 11.168l-3.197-2.132A1 1 0 0010 9.87v4.263a1 1 0 001.555.832l3.197-2.132a1 1 0 000-1.664z" /><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M21 12a9 9 0 11-18 0 9 9 0 0118 0z" /></svg>
                                        )}
                                        {loading ? 'Memproses...' : 'Pratinjau Data'}
                                    </button>
                                </div>
                            )}
                        </div>

                        <div className="p-6 bg-gray-50 border-t border-gray-100 flex justify-end gap-3 sticky bottom-0 z-10">
                            <button
                                onClick={() => { setShowUploadModal(false); setParsedRows([]); }}
                                className="px-6 py-3 text-gray-500 font-bold hover:bg-gray-100 rounded-xl transition-all"
                            >
                                Batal
                            </button>
                            {parsedRows.length > 0 && (
                                <button
                                    onClick={handleSaveImport}
                                    disabled={loading}
                                    className="px-10 py-3 bg-[#06B6D4] text-white rounded-xl font-bold hover:bg-[#0891b2] transition-all flex items-center gap-2 shadow-lg shadow-cyan-100"
                                >
                                    {loading && <svg className="animate-spin h-4 w-4" viewBox="0 0 24 24"><circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle><path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path></svg>}
                                    Simpan Permanen
                                </button>
                            )}
                        </div>
                    </div>
                </div>
            )}
        </DashboardLayout>
    );
}
