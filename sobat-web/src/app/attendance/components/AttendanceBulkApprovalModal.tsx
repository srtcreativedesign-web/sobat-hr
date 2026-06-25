import React from 'react';
import { Attendance } from '../types';

interface AttendanceBulkApprovalModalProps {
    isOpen: boolean;
    onClose: () => void;
    selectedIds: number[];
    attendances: Attendance[];
    bulkStatus: 'late' | 'present';
    setBulkStatus: (status: 'late' | 'present') => void;
    bulkNote: string;
    setBulkNote: (note: string) => void;
    isBulkSubmitting: boolean;
    handleBulkApprove: () => void;
}

export default function AttendanceBulkApprovalModal({
    isOpen,
    onClose,
    selectedIds,
    attendances,
    bulkStatus,
    setBulkStatus,
    bulkNote,
    setBulkNote,
    isBulkSubmitting,
    handleBulkApprove
}: AttendanceBulkApprovalModalProps) {
    if (!isOpen) return null;

    return (
        <div className="fixed inset-0 z-50 overflow-y-auto" aria-labelledby="bulk-modal-title" role="dialog" aria-modal="true">
            <div className="flex items-center justify-center min-h-screen pt-4 px-4 pb-20 text-center sm:block sm:p-0">
                <div className="fixed inset-0 bg-gray-500 bg-opacity-75 transition-opacity" aria-hidden="true" onClick={onClose}></div>
                <span className="hidden sm:inline-block sm:align-middle sm:h-screen" aria-hidden="true">&#8203;</span>
                <div className="inline-block align-middle bg-white rounded-lg text-left overflow-hidden shadow-xl transform transition-all sm:my-8 sm:align-middle sm:max-w-xl sm:w-full">
                    <div className="bg-white px-4 pt-5 pb-4 sm:p-6 sm:pb-4">
                        <h3 className="text-lg leading-6 font-bold text-gray-900 mb-4" id="bulk-modal-title">
                            Konfirmasi Bulk Approval ({selectedIds.length} Data)
                        </h3>

                        <div className="mb-4 max-h-40 overflow-y-auto bg-gray-50 p-3 rounded-lg border border-gray-200">
                            <p className="text-xs font-bold text-gray-500 uppercase mb-2">Karyawan Terpilih:</p>
                            <div className="flex flex-wrap gap-2">
                                {attendances.filter(a => selectedIds.includes(a.id)).map(a => (
                                    <span key={a.id} className="px-2 py-1 bg-white text-gray-700 text-xs rounded border border-gray-200">
                                        {a.employee?.full_name}
                                    </span>
                                ))}
                            </div>
                        </div>

                        <div className="space-y-4">
                            <div>
                                <label className="block text-sm font-medium text-gray-700 mb-2">Set Status Kehadiran Menjadi:</label>
                                <div className="flex gap-4">
                                    <label className="flex items-center gap-2 cursor-pointer">
                                        <input
                                            type="radio"
                                            name="bulkStatus"
                                            value="present"
                                            checked={bulkStatus === 'present'}
                                            onChange={() => setBulkStatus('present')}
                                            className="w-4 h-4 text-green-600"
                                        />
                                        <span className="text-sm font-semibold text-green-700">HADIR (Sesuai)</span>
                                    </label>
                                    <label className="flex items-center gap-2 cursor-pointer">
                                        <input
                                            type="radio"
                                            name="bulkStatus"
                                            value="late"
                                            checked={bulkStatus === 'late'}
                                            onChange={() => setBulkStatus('late')}
                                            className="w-4 h-4 text-yellow-600"
                                        />
                                        <span className="text-sm font-semibold text-yellow-700">TERLAMBAT</span>
                                    </label>
                                </div>
                            </div>

                            <div>
                                <label className="block text-sm font-medium text-gray-700 mb-2">Catatan Admin (Opsional):</label>
                                <textarea
                                    value={bulkNote}
                                    onChange={(e) => setBulkNote(e.target.value)}
                                    className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-1 focus:ring-[#1C3ECA] outline-none text-sm"
                                    rows={3}
                                    placeholder="Masukkan alasan approval..."
                                ></textarea>
                            </div>
                        </div>
                    </div>
                    <div className="bg-gray-50 px-4 py-3 sm:px-6 sm:flex sm:flex-row-reverse gap-2">
                        <button
                            type="button"
                            disabled={isBulkSubmitting}
                            onClick={handleBulkApprove}
                            className="w-full inline-flex justify-center rounded-md border border-transparent shadow-sm px-4 py-2 bg-[#1C3ECA] text-base font-medium text-white hover:bg-[#1C3ECA]/90 focus:outline-none sm:w-auto sm:text-sm disabled:opacity-50"
                        >
                            {isBulkSubmitting ? 'Memproses...' : `Proses Approval (${selectedIds.length})`}
                        </button>
                        <button
                            type="button"
                            onClick={onClose}
                            className="mt-3 w-full inline-flex justify-center rounded-md border border-gray-300 shadow-sm px-4 py-2 bg-white text-base font-medium text-gray-700 hover:bg-gray-50 focus:outline-none sm:mt-0 sm:w-auto sm:text-sm"
                        >
                            Batal
                        </button>
                    </div>
                </div>
            </div>
        </div>
    );
}
