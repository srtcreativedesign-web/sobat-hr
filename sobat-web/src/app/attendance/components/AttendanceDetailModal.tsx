import React from 'react';
import { Attendance } from '../types';
import { getPhotoUrl, formatDate, getStatusBadge } from '../utils';

interface AttendanceDetailModalProps {
    selectedAttendance: Attendance | null;
    onClose: () => void;
    onApprove: (id: number, status: string) => void;
}

export default function AttendanceDetailModal({ selectedAttendance, onClose, onApprove }: AttendanceDetailModalProps) {
    if (!selectedAttendance) return null;

    return (
        <div className="fixed inset-0 z-50 overflow-y-auto" aria-labelledby="modal-title" role="dialog" aria-modal="true">
            <div className="flex items-end justify-center min-h-screen pt-4 px-4 pb-20 text-center sm:block sm:p-0">
                {/* Background overlay */}
                <div
                    className="fixed inset-0 bg-gray-500 bg-opacity-75 transition-opacity"
                    aria-hidden="true"
                    onClick={onClose}
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
                                            <div className="flex gap-2">
                                                <span className={`px-2 py-0.5 inline-flex text-xs leading-5 font-semibold rounded-full mt-1 ${selectedAttendance.attendance_type === 'field' ? 'bg-blue-100 text-blue-800' : 'bg-gray-100 text-gray-800'}`}>
                                                    {selectedAttendance.attendance_type === 'field' ? 'DINAS LUAR' : 'KANTOR'}
                                                </span>
                                                {selectedAttendance.is_offline && (
                                                    <span className="px-2 py-0.5 inline-flex text-xs leading-5 font-semibold rounded-full mt-1 bg-orange-100 text-orange-800 ring-1 ring-orange-200">
                                                        MODE OFFLINE
                                                    </span>
                                                )}
                                            </div>
                                        </div>
                                    </div>

                                    {/* Offline Metadata */}
                                    {selectedAttendance.is_offline && (
                                        <div className="bg-orange-50 border border-orange-100 rounded-lg p-3 text-xs">
                                            <p className="font-bold text-orange-800 mb-2 uppercase tracking-wider">Detail Sinkronisasi Offline</p>
                                            <div className="grid grid-cols-2 gap-2">
                                                <div>
                                                    <p className="text-orange-600 font-medium">Metode Validasi</p>
                                                    <p className="text-gray-900">{selectedAttendance.validation_method === 'qr_code' ? 'Scan QR Code' : 'Lokasi GPS'}</p>
                                                </div>
                                                <div>
                                                    <p className="text-orange-600 font-medium">ID Perangkat</p>
                                                    <p className="text-gray-900 font-mono">{selectedAttendance.device_id}</p>
                                                </div>
                                                <div>
                                                    <p className="text-orange-600 font-medium">Waktu Perangkat</p>
                                                    <p className="text-gray-900">{selectedAttendance.device_timestamp}</p>
                                                </div>
                                                <div>
                                                    <p className="text-orange-600 font-medium">Selisih Waktu</p>
                                                    <p className={`${Math.abs(selectedAttendance.time_discrepancy_seconds || 0) > 60 ? 'text-red-600 font-bold' : 'text-gray-900'}`}>
                                                        {selectedAttendance.time_discrepancy_seconds} detik
                                                    </p>
                                                </div>
                                            </div>
                                        </div>
                                    )}

                                    {/* Full Width Items */}
                                    <div>
                                        <p className="font-medium text-gray-500 text-sm">Lokasi</p>
                                        <p className="text-gray-900 text-sm">{selectedAttendance.location_address || '-'}</p>
                                        {selectedAttendance.latitude && selectedAttendance.longitude && (
                                            <a
                                                href={`https://www.google.com/maps?q=${selectedAttendance.latitude},${selectedAttendance.longitude}`}
                                                target="_blank"
                                                rel="noopener noreferrer"
                                                className="inline-flex items-center gap-1.5 mt-1 text-xs font-medium text-blue-600 hover:text-blue-800 transition-colors"
                                            >
                                                <svg className="w-3.5 h-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z" />
                                                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 11a3 3 0 11-6 0 3 3 0 016 0z" />
                                                </svg>
                                                {Number(selectedAttendance.latitude).toFixed(6)}, {Number(selectedAttendance.longitude).toFixed(6)}
                                            </a>
                                        )}
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
                            onClick={onClose}
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
                                        onClick={() => onApprove(selectedAttendance.id, 'late')}
                                        className="inline-flex justify-center rounded-md border border-transparent shadow-sm px-4 py-2 bg-yellow-600 text-base font-medium text-white hover:bg-yellow-700 focus:outline-none sm:text-sm"
                                    >
                                        Approve (Late)
                                    </button>
                                    <button
                                        onClick={() => onApprove(selectedAttendance.id, 'present')}
                                        className="inline-flex justify-center rounded-md border border-transparent shadow-sm px-4 py-2 bg-green-600 text-base font-medium text-white hover:bg-green-700 focus:outline-none sm:text-sm"
                                    >
                                        Approve (Present)
                                    </button>
                                    <button
                                        onClick={() => onApprove(selectedAttendance.id, 'absent')}
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
    );
}
