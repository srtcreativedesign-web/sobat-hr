import React from 'react';

interface ThrUploadModalProps {
    show: boolean;
    onClose: () => void;
    selectedDivision: 'ho' | 'op';
    setSelectedDivision: (div: 'ho' | 'op') => void;
    selectedFile: File | null;
    handleFileChange: (e: React.ChangeEvent<HTMLInputElement>) => void;
    parsedRows: any[];
    setParsedRows: (rows: any[]) => void;
    loading: boolean;
    onUpload: () => void;
    onSave: () => void;
}

export default function ThrUploadModal({
    show,
    onClose,
    selectedDivision,
    setSelectedDivision,
    selectedFile,
    handleFileChange,
    parsedRows,
    setParsedRows,
    loading,
    onUpload,
    onSave
}: ThrUploadModalProps) {
    if (!show) return null;

    const formatCurrency = (value: number) => {
        return new Intl.NumberFormat('id-ID', {
            style: 'currency',
            currency: 'IDR',
            minimumFractionDigits: 0,
        }).format(value);
    };

    return (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50 backdrop-blur-sm">
            <div className="bg-white rounded-2xl shadow-2xl w-full max-w-4xl max-h-[90vh] flex flex-col overflow-hidden animate-in fade-in zoom-in duration-200">
                <div className="p-6 border-b border-gray-100 flex items-center justify-between bg-white sticky top-0 z-10">
                    <h2 className="text-xl font-bold text-gray-800">Import Data THR</h2>
                    <button onClick={onClose} className="text-gray-400 hover:text-gray-600 p-2">
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
                                onClick={onUpload}
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
                        onClick={onClose}
                        className="px-6 py-3 text-gray-500 font-bold hover:bg-gray-100 rounded-xl transition-all"
                    >
                        Batal
                    </button>
                    {parsedRows.length > 0 && (
                        <button
                            onClick={onSave}
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
    );
}
