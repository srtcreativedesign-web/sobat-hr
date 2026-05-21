'use client';

import { useEffect, useState, useCallback } from 'react';
import { useAuthStore } from '@/store/auth-store';
import DashboardLayout from '@/components/DashboardLayout';
import apiClient from '@/lib/api-client';
import { API_URL } from '@/lib/config';
import Swal from 'sweetalert2';

interface Attendance {
  id: number;
  employee_id: number;
  employee: {
    full_name: string;
    employee_code: string;
    division?: { id: number; name: string };
  } | null;
  outlet: { id: number; name: string } | null;
  date: string;
  check_in: string | null;
  check_out: string | null;
  status: string;
  review_status: 'pending' | 'approved' | 'rejected' | null;
  review_notes: string | null;
  validation_method: 'qr_code' | 'gps' | 'online_gps' | null;
  track_type: string;
  qr_code_data: string | null;
  floor_number: number | null;
  photo_path: string | null;
  checkout_photo_path: string | null;
  device_id: string | null;
  device_timestamp: string | null;
  time_discrepancy_seconds: number | null;
  is_offline: boolean;
  location_address: string | null;
}

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

  useEffect(() => {
    checkAuth();
  }, [checkAuth]);

  useEffect(() => {
    fetchDivisions();
    fetchAttendances();
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

  const fetchAttendances = useCallback(async () => {
    try {
      setLoading(true);
      const params = new URLSearchParams({ track_type: 'operational' });
      if (startDate) params.append('start_date', startDate);
      if (endDate) params.append('end_date', endDate);
      if (filterDivision) params.append('division_id', filterDivision);
      if (filterStatus) params.append('status', filterStatus);

      const response = await apiClient.get(`/attendances?${params.toString()}`);
      const data = response.data.data || response.data;
      setAttendances(Array.isArray(data) ? data : []);
    } catch (error) {
      console.error('Failed to fetch attendances:', error);
    } finally {
      setLoading(false);
    }
  }, [startDate, endDate, filterDivision, filterStatus]);

  const handleFilter = (e: React.FormEvent) => {
    e.preventDefault();
    fetchAttendances();
  };

  const getPhotoUrl = (path: string | null) => {
    if (!path) return null;
    if (path.startsWith('http')) return path;
    const baseUrl = API_URL.replace(/\/api\/?$/, '');
    let cleanPath = path;
    if (cleanPath.startsWith('/')) cleanPath = cleanPath.substring(1);
    if (cleanPath.startsWith('public/')) cleanPath = cleanPath.substring(7);
    return `${baseUrl}/storage/${cleanPath}`;
  };

  const getStatusBadge = (status: string) => {
    switch (status) {
      case 'present': return 'bg-green-100 text-green-800';
      case 'late': return 'bg-yellow-100 text-yellow-800';
      case 'absent': return 'bg-red-100 text-red-800';
      case 'pending': return 'bg-orange-100 text-orange-800 ring-1 ring-orange-500';
      default: return 'bg-gray-100 text-gray-800';
    }
  };

  const getReviewBadge = (status: string | null) => {
    switch (status) {
      case 'approved': return 'bg-green-100 text-green-800';
      case 'rejected': return 'bg-red-100 text-red-800';
      case 'pending': return 'bg-yellow-100 text-yellow-800';
      default: return 'bg-gray-100 text-gray-400';
    }
  };

  const parseDate = (dt: string) => {
    const d = dt.includes('T') ? new Date(dt) : new Date(dt.replace(' ', 'T'));
    return isNaN(d.getTime()) ? null : d;
  };

  const formatDateTime = (dt: string | null) => {
    if (!dt) return '-';
    const d = parseDate(dt);
    if (!d) return dt;
    return d.toLocaleString('id-ID', {
      year: 'numeric', month: 'short', day: 'numeric',
      hour: '2-digit', minute: '2-digit',
    });
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

  const formatDate = (att: Attendance) => {
    if (att.date) {
      const d = parseDate(att.date);
      if (!d) return att.date;
      return d.toLocaleDateString('id-ID', { year: 'numeric', month: 'short', day: 'numeric' });
    }
    return '-';
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
            <button type="submit"
              className="px-6 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 text-sm font-medium transition-colors">
              Filter
            </button>
          </form>
        </div>

        <div className="bg-white rounded-xl shadow-sm border border-gray-200 overflow-hidden">
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead className="bg-gray-50 border-b border-gray-200">
                <tr>
                  <th className="text-left px-4 py-3 font-semibold text-gray-600">Karyawan</th>
                  <th className="text-left px-4 py-3 font-semibold text-gray-600">Tanggal</th>
                  <th className="text-left px-4 py-3 font-semibold text-gray-600">Check In</th>
                  <th className="text-left px-4 py-3 font-semibold text-gray-600">Outlet</th>
                  <th className="text-left px-4 py-3 font-semibold text-gray-600">Validasi</th>
                  <th className="text-left px-4 py-3 font-semibold text-gray-600">Status</th>
                  <th className="text-left px-4 py-3 font-semibold text-gray-600">Aksi</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-100">
                {loading ? (
                  <tr><td colSpan={7} className="text-center py-12 text-gray-400">Memuat data...</td></tr>
                ) : attendances.length === 0 ? (
                  <tr><td colSpan={7} className="text-center py-12 text-gray-400">Tidak ada data absensi operasional</td></tr>
                ) : attendances.map(att => (
                  <tr key={att.id} className="hover:bg-gray-50 transition-colors">
                    <td className="px-4 py-3">
                      <div className="font-medium text-gray-800">{att.employee?.full_name || '-'}</div>
                      <div className="text-xs text-gray-400">{att.employee?.employee_code || ''}</div>
                    </td>
                    <td className="px-4 py-3 text-gray-600">{formatDate(att)}</td>
                    <td className="px-4 py-3 text-gray-600">{formatDateTime(att.check_in || att.device_timestamp)}</td>
                    <td className="px-4 py-3">
                      <div className="text-gray-800">{att.outlet?.name || '-'}</div>
                      {att.floor_number && <div className="text-xs text-gray-400">LT-{att.floor_number}</div>}
                    </td>
                    <td className="px-4 py-3">
                      {att.validation_method ? (
                        <span className={`inline-flex items-center px-2 py-0.5 rounded text-xs font-medium ${
                          att.validation_method === 'qr_code' ? 'bg-purple-100 text-purple-700' : 'bg-blue-100 text-blue-700'
                        }`}>
                          {att.validation_method === 'qr_code' ? 'QR Code' : 'GPS'}
                        </span>
                      ) : (
                        <span className="text-xs text-gray-400">-</span>
                      )}
                    </td>
                    <td className="px-4 py-3">
                      <span className={`inline-flex items-center px-2 py-0.5 rounded text-xs font-medium ${getStatusBadge(att.status)}`}>
                        {att.status}
                      </span>
                    </td>
                    <td className="px-4 py-3">
                      <button onClick={() => setSelectedAttendance(att)}
                        className="px-3 py-1.5 text-xs font-medium text-blue-600 hover:bg-blue-50 rounded-lg transition-colors">
                        Detail
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      </div>

      {selectedAttendance && (
        <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4" onClick={() => setSelectedAttendance(null)}>
          <div className="bg-white rounded-2xl max-w-2xl w-full max-h-[90vh] overflow-y-auto" onClick={e => e.stopPropagation()}>
            <div className="sticky top-0 bg-white border-b border-gray-100 px-6 py-4 flex items-center justify-between rounded-t-2xl">
              <h2 className="text-lg font-bold text-gray-800">Detail Absensi Operasional</h2>
              <button onClick={() => setSelectedAttendance(null)} className="p-1 hover:bg-gray-100 rounded-lg">
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
                  <p className="text-sm font-medium text-gray-800 mt-1">{selectedAttendance.outlet?.name || '-'}</p>
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
                  <label className="text-xs font-medium text-gray-400 uppercase tracking-wider">Tanggal</label>
                  <p className="text-sm font-medium text-gray-800 mt-1">{formatDate(selectedAttendance)}</p>
                </div>
                <div>
                  <label className="text-xs font-medium text-gray-400 uppercase tracking-wider">Sumber</label>
                  <span className={`inline-flex items-center px-2 py-0.5 rounded text-xs font-medium mt-1 ${
                    selectedAttendance.is_offline ? 'bg-orange-100 text-orange-700' : 'bg-blue-100 text-blue-700'
                  }`}>
                    {selectedAttendance.is_offline ? 'Offline Sync' : 'Online'}
                  </span>
                </div>
              </div>

              {selectedAttendance.qr_code_data && (
                <div>
                  <label className="text-xs font-medium text-gray-400 uppercase tracking-wider">Data QR Code</label>
                  <p className="text-xs text-gray-600 mt-1 font-mono bg-gray-50 p-2 rounded-lg break-all">
                    {selectedAttendance.qr_code_data}
                  </p>
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
                      <p className="text-gray-600 mt-0.5">{selectedAttendance.location_address || '-'}</p>
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
      )}
    </DashboardLayout>
  );
}
