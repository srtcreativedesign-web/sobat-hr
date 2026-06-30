import React from 'react';
import { Attendance } from '../types';
import { getOutletNameDisplay, formatDate, formatDateTime, getPhotoUrl } from '../utils';

interface OperasionalDetailModalProps {
    selectedAttendance: Attendance | null;
    onClose: () => void;
    handleApprove: (id: number, status: string) => void;
    handleReview: (id: number, status: 'approved' | 'rejected') => void;
}

export default function OperasionalDetailModal({
    selectedAttendance,
    onClose,
    handleApprove,
    handleReview
}: OperasionalDetailModalProps) {
    if (!selectedAttendance) return null;

    return (
        <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4" onClick={onClose}>
            <div className="bg-white rounded-2xl max-w-2xl w-full max-h-[90vh] overflow-y-auto" onClick={e => e.stopPropagation()}>
                <div className="sticky top-0 bg-white border-b border-gray-100 px-6 py-4 flex items-center justify-between rounded-t-2xl">
                    <h2 className="text-lg font-bold text-gray-800">Detail Absensi Operasional</h2>
                    <button onClick={onClose} className="p-1 hover:bg-gray-100 rounded-lg">
                        <svg className="w-5 h-5 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                        </svg>
                    </button>
                </div>

                <div className="p-6 space-y-6">
                    <div className="grid grid-cols-2 gap-4">
                        <div>
                            <label className="text-xs font-medium text-gray-400 uppercase tracking-wider">Karyawan</label>
                            <p className="text-sm font-medium text-gray-800 mt-1">{selectedAttendance.employee?.full_name || '-'}</p>
                            <p className="text-xs text-gray-400">{selectedAttendance.employee?.employee_code || ''}</p>
                        </div>
                        <div>
                            <label className="text-xs font-medium text-gray-400 uppercase tracking-wider">Divisi</label>
                            <p className="text-sm font-medium text-gray-800 mt-1">{selectedAttendance.employee?.division?.name || '-'}</p>
                        </div>
                        <div>
                            <label className="text-xs font-medium text-gray-400 uppercase tracking-wider">Outlet</label>
                            <p className="text-sm font-medium text-gray-800 mt-1">{getOutletNameDisplay(selectedAttendance)}</p>
                            {selectedAttendance.floor_number && (
                                <p className="text-xs text-gray-400">Lantai {selectedAttendance.floor_number}</p>
                            )}
                        </div>
                        <div>
                            <label className="text-xs font-medium text-gray-400 uppercase tracking-wider">Metode Validasi</label>
                            <p className="text-sm font-medium text-gray-800 mt-1 capitalize">
                                {selectedAttendance.validation_method === 'qr_code' ? 'QR Code (Dua Layer)' : selectedAttendance.validation_method || '-'}
                            </p>
                        </div>
                        <div>
                            <label className="text-xs font-medium text-gray-400 uppercase tracking-wider">Jadwal Shift</label>
                            <p className="text-sm font-medium text-gray-800 mt-1">
                                {selectedAttendance.shift_start_time && selectedAttendance.shift_end_time
                                    ? `${selectedAttendance.shift_start_time.substring(0, 5)} - ${selectedAttendance.shift_end_time.substring(0, 5)}`
                                    : '-'}
                            </p>
                        </div>
                        <div>
                            <label className="text-xs font-medium text-gray-400 uppercase tracking-wider">Tanggal</label>
                            <p className="text-sm font-medium text-gray-800 mt-1">{formatDate(selectedAttendance)}</p>
                        </div>
                        <div>
                            <label className="text-xs font-medium text-gray-400 uppercase tracking-wider">Sumber</label>
                            <span className={`inline-flex items-center px-2 py-0.5 rounded text-xs font-medium mt-1 ${selectedAttendance.is_offline ? 'bg-orange-100 text-orange-700' : 'bg-blue-100 text-blue-700'
                                }`}>
                                {selectedAttendance.is_offline ? 'Offline Sync' : 'Online'}
                            </span>
                        </div>
                    </div>

                    {(selectedAttendance.qr_code_data || selectedAttendance.notes) && (
                        <div>
                            <label className="text-xs font-medium text-gray-400 uppercase tracking-wider">Data QR Code</label>
                            <p className="text-xs text-gray-600 mt-1 font-mono bg-gray-50 p-2 rounded-lg break-all">
                                {selectedAttendance.qr_code_data || selectedAttendance.notes}
                            </p>
                        </div>
                    )}

                    {(selectedAttendance.latitude || selectedAttendance.location_address) && (
                        <div>
                            <label className="text-xs font-medium text-gray-400 uppercase tracking-wider">Validasi GPS / Lokasi</label>
                            <div className="mt-1 bg-gray-50 p-3 rounded-lg text-sm text-gray-600 space-y-1">
                                <p><span className="font-medium">Koordinat:</span> {selectedAttendance.latitude || '-'}, {selectedAttendance.longitude || '-'}</p>
                                <p><span className="font-medium">Alamat:</span> {selectedAttendance.location_address || '-'}</p>
                            </div>
                        </div>
                    )}

                    <div className="grid grid-cols-2 gap-4">
                        <div>
                            <label className="text-xs font-medium text-gray-400 uppercase tracking-wider">Waktu Check In</label>
                            <p className="text-sm font-medium text-gray-800 mt-1">{formatDateTime(selectedAttendance.check_in || selectedAttendance.device_timestamp)}</p>
                        </div>
                        <div>
                            <label className="text-xs font-medium text-gray-400 uppercase tracking-wider">Waktu Check Out</label>
                            <p className="text-sm font-medium text-gray-800 mt-1">{formatDateTime(selectedAttendance.check_out) || '-'}</p>
                        </div>
                    </div>

                    {selectedAttendance.photo_path && (
                        <div>
                            <label className="text-xs font-medium text-gray-400 uppercase tracking-wider mb-2 block">Foto Check In (Wide)</label>
                            <img src={getPhotoUrl(selectedAttendance.photo_path) || ''}
                                alt="Check In"
                                className="w-full rounded-lg border border-gray-200"
                                onError={e => { (e.target as HTMLImageElement).style.display = 'none'; }} />
                        </div>
                    )}

                    {selectedAttendance.checkout_photo_path && (
                        <div>
                            <label className="text-xs font-medium text-gray-400 uppercase tracking-wider mb-2 block">Foto Check Out (Wide)</label>
                            <img src={getPhotoUrl(selectedAttendance.checkout_photo_path) || ''}
                                alt="Check Out"
                                className="w-full rounded-lg border border-gray-200"
                                onError={e => { (e.target as HTMLImageElement).style.display = 'none'; }} />
                        </div>
                    )}

                    {selectedAttendance.is_offline && (
                        <div className="bg-gray-50 rounded-lg p-4">
                            <h3 className="text-xs font-medium text-gray-400 uppercase tracking-wider mb-3">Informasi Perangkat</h3>
                            <div className="grid grid-cols-2 gap-3 text-sm">
                                <div>
                                    <span className="text-gray-400">Device ID:</span>
                                    <p className="font-mono text-xs text-gray-600 mt-0.5">{selectedAttendance.device_id || '-'}</p>
                                </div>
                                <div>
                                    <span className="text-gray-400">Selisih Waktu:</span>
                                    <p className={`font-medium mt-0.5 ${(selectedAttendance.time_discrepancy_seconds ?? 0) > 300 ? 'text-red-600' : 'text-green-600'}`}>
                                        {selectedAttendance.time_discrepancy_seconds != null ? `${selectedAttendance.time_discrepancy_seconds} detik` : '-'}
                                    </p>
                                </div>
                                <div>
                                    <span className="text-gray-400">Waktu Perangkat:</span>
                                    <p className="text-gray-600 mt-0.5">{formatDateTime(selectedAttendance.device_timestamp)}</p>
                                </div>
                                <div>
                                    <span className="text-gray-400">Lokasi:</span>
                                    <p className="text-gray-600 mt-0.5">{(selectedAttendance as any).location_address || '-'}</p>
                                </div>
                            </div>
                        </div>
                    )}

                    {selectedAttendance.review_notes && (
                        <div>
                            <label className="text-xs font-medium text-gray-400 uppercase tracking-wider">Catatan Review</label>
                            <p className="text-sm text-gray-600 mt-1 bg-gray-50 p-3 rounded-lg">{selectedAttendance.review_notes}</p>
                        </div>
                    )}

                    {selectedAttendance.status === 'pending' && (
                        <div className="flex gap-3 pt-4 border-t border-gray-100">
                            <button onClick={() => { handleApprove(selectedAttendance.id, 'present'); }}
                                className="flex-1 px-4 py-2.5 bg-green-600 text-white rounded-lg hover:bg-green-700 font-medium text-sm transition-colors">
                                Setujui (Hadir)
                            </button>
                            <button onClick={() => { handleApprove(selectedAttendance.id, 'late'); }}
                                className="flex-1 px-4 py-2.5 bg-yellow-600 text-white rounded-lg hover:bg-yellow-700 font-medium text-sm transition-colors">
                                Setujui (Terlambat)
                            </button>
                            <button onClick={() => { handleApprove(selectedAttendance.id, 'absent'); }}
                                className="flex-1 px-4 py-2.5 bg-red-600 text-white rounded-lg hover:bg-red-700 font-medium text-sm transition-colors">
                                Tolak
                            </button>
                        </div>
                    )}

                    {selectedAttendance.is_offline && selectedAttendance.review_status === 'pending' && (
                        <div className="flex gap-3 pt-4 border-t border-gray-100">
                            <button onClick={() => { handleReview(selectedAttendance.id, 'approved'); }}
                                className="flex-1 px-4 py-2.5 bg-green-600 text-white rounded-lg hover:bg-green-700 font-medium text-sm transition-colors">
                                Setujui
                            </button>
                            <button onClick={() => { handleReview(selectedAttendance.id, 'rejected'); }}
                                className="flex-1 px-4 py-2.5 bg-red-600 text-white rounded-lg hover:bg-red-700 font-medium text-sm transition-colors">
                                Tolak
                            </button>
                        </div>
                    )}
                </div>
            </div>
        </div>
    );
}
