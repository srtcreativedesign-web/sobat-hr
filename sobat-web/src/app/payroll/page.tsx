'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { useAuthStore } from '@/store/auth-store';
import DashboardLayout from '@/components/DashboardLayout';
import apiClient from '@/lib/api-client';

interface Payroll {
  id: number;
  employee: {
    employee_code: string;
    full_name: string;
  };
  period_start: string;
  period_end: string;
  basic_salary: number;
  allowances: number;
  overtime_pay: number;
  deductions: number;
  total_deductions: number; // Added from backend calculation
  bpjs_health: number;
  bpjs_employment: number;
  tax: number;
  gross_salary: number;
  net_salary: number;
  details: any; // Flexible JSON
  status: 'pending' | 'approved' | 'paid';
}

export default function PayrollPage() {
  const router = useRouter();
  const { isAuthenticated, checkAuth } = useAuthStore();
  const [payrolls, setPayrolls] = useState<Payroll[]>([]);
  const [loading, setLoading] = useState(false);
  const [showUploadModal, setShowUploadModal] = useState(false);
  const [selectedFile, setSelectedFile] = useState<File | null>(null);
  const [uploadProgress, setUploadProgress] = useState(0);

  const [parsedRows, setParsedRows] = useState<any[]>([]);
  const [selectedIds, setSelectedIds] = useState<number[]>([]);
  const [selectedPayroll, setSelectedPayroll] = useState<Payroll | null>(null);

  // Filter States
  const [selectedMonth, setSelectedMonth] = useState(0); // 0 = Semua
  const [selectedYear, setSelectedYear] = useState(0); // 0 = Semua

  const months = [
    { value: 1, label: 'Januari' }, { value: 2, label: 'Februari' }, { value: 3, label: 'Maret' },
    { value: 4, label: 'April' }, { value: 5, label: 'Mei' }, { value: 6, label: 'Juni' },
    { value: 7, label: 'Juli' }, { value: 8, label: 'Agustus' }, { value: 9, label: 'September' },
    { value: 10, label: 'Oktober' }, { value: 11, label: 'November' }, { value: 12, label: 'Desember' }
  ];

  useEffect(() => {
    checkAuth();
  }, [checkAuth]);

  useEffect(() => {
    if (!isAuthenticated) {
      router.push('/login');
      return;
    }

    fetchPayrolls();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [isAuthenticated, router, selectedMonth, selectedYear]);

  const fetchPayrolls = async () => {
    try {
      setLoading(true);
      setLoading(true);
      const response = await apiClient.get('/payrolls', {
        params: {
          ...(selectedMonth !== 0 && { month: selectedMonth }),
          ...(selectedYear !== 0 && { year: selectedYear })
        }
      });
      setPayrolls(response.data.data || []);
    } catch (error) {
      console.error('Failed to fetch payrolls:', error);
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

    try {
      setUploadProgress(0);
      setParsedRows([]);
      const response = await apiClient.post('/payrolls/import', formData, {
        headers: {
          'Content-Type': 'multipart/form-data',
        },
        onUploadProgress: (progressEvent) => {
          const progress = progressEvent.total
            ? Math.round((progressEvent.loaded * 100) / progressEvent.total)
            : 0;
          setUploadProgress(progress);
        },
      });

      const data = response.data;
      if (data && Array.isArray(data.rows)) {
        setParsedRows(data.rows);
        setUploadProgress(100);
      } else {
        alert(data.message || 'Import berhasil');
        setShowUploadModal(false);
        setSelectedFile(null);
        fetchPayrolls();
      }
    } catch (error: any) {
      alert(error.response?.data?.message || 'Import gagal');
    }
  };

  const formatCurrency = (amount: number) => {
    if (amount === undefined || amount === null || isNaN(amount)) return 'Rp 0';
    return new Intl.NumberFormat('id-ID', {
      style: 'currency',
      currency: 'IDR',
      minimumFractionDigits: 0,
    }).format(amount);
  };

  const formatSmartValue = (amount: number, unit: string = '') => {
    if (amount === undefined || amount === null || isNaN(amount)) return '0';
    // If small value (assuming day/unit) and not 0, display as unit
    if (Math.abs(amount) < 1000 && amount !== 0) {
      return `${amount} ${unit}`;
    }
    return formatCurrency(amount);
  };

  const getStatusBadge = (status: string) => {
    const styles = {
      pending: 'bg-yellow-100 text-yellow-700 border-yellow-200',
      approved: 'bg-blue-100 text-blue-700 border-blue-200',
      paid: 'bg-green-100 text-green-700 border-green-200',
    };
    return styles[status as keyof typeof styles] || styles.pending;
  };

  if (!isAuthenticated) {
    return null;
  }

  return (
    <DashboardLayout>
      {/* Header */}
      <div className="bg-white border-b border-gray-200 sticky top-0 z-10">
        <div className="px-8 py-6">
          <div className="flex items-center justify-between">
            <div>
              <h1 className="text-3xl font-bold bg-gradient-to-r from-[#462e37] to-[#729892] bg-clip-text text-transparent">
                Payroll Management
              </h1>
              <p className="text-gray-600 mt-1">Kelola data payroll dan slip gaji karyawan</p>
            </div>
            <div className="flex gap-3">
              <button
                onClick={async () => {
                  try {
                    const response = await apiClient.get('/payrolls/template/download', {
                      responseType: 'blob',
                    });
                    const url = window.URL.createObjectURL(new Blob([response.data]));
                    const link = document.createElement('a');
                    link.href = url;
                    link.setAttribute('download', `Template_Import_Payroll_${new Date().toISOString().split('T')[0]}.xlsx`);
                    document.body.appendChild(link);
                    link.click();
                    link.remove();
                  } catch (error) {
                    alert('Gagal download template');
                  }
                }}
                className="flex items-center gap-2 px-6 py-3 bg-white border-2 border-[#a9eae2] text-[#462e37] rounded-xl font-semibold hover:bg-[#a9eae2] hover:text-[#462e37] transition-all transform hover:scale-[1.02]"
              >
                <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 10v6m0 0l-3-3m3 3l3-3m2 8H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
                </svg>
                Download Template
              </button>
              <button
                onClick={() => setShowUploadModal(true)}
                className="flex items-center gap-2 px-6 py-3 bg-gradient-to-r from-[#a9eae2] to-[#729892] text-[#462e37] rounded-xl font-semibold hover:shadow-lg transition-all transform hover:scale-[1.02]"
              >
                <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M7 16a4 4 0 01-.88-7.903A5 5 0 1115.9 6L16 6a5 5 0 011 9.9M15 13l-3-3m0 0l-3 3m3-3v12" />
                </svg>
                Import Excel
              </button>
            </div>
          </div>
        </div>
      </div>

      {/* Filter Section */}
      <div className="bg-white border-b border-gray-200 px-8 py-4">
        <div className="flex items-center justify-between gap-4">
          <div className="flex items-center gap-2">
            <span className="text-sm font-semibold text-gray-700">Periode:</span>
            <select
              value={selectedMonth}
              onChange={(e) => setSelectedMonth(Number(e.target.value))}
              className="px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:border-[#462e37] text-sm"
            >
              <option value={0}>Semua Bulan</option>
              {months.map((m) => (
                <option key={m.value} value={m.value}>{m.label}</option>
              ))}
            </select>
            <select
              value={selectedYear}
              onChange={(e) => setSelectedYear(Number(e.target.value))}
              className="px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:border-[#462e37] text-sm"
            >
              <option value={0}>Semua Tahun</option>
              {[2024, 2025, 2026, 2027].map((y) => (
                <option key={y} value={y}>{y}</option>
              ))}
            </select>
          </div>

          {/* Bulk Actions */}
          <div className="flex gap-2">
            {selectedIds.length > 0 && (
              <button
                onClick={async () => {
                  if (!confirm(`Approve ${selectedIds.length} selected payrolls?`)) return;
                  try {
                    setLoading(true);
                    const response = await apiClient.post('/payrolls/bulk-approve', {
                      ids: selectedIds
                    });
                    alert(response.data.message);
                    setSelectedIds([]);
                    fetchPayrolls();
                  } catch (error: any) {
                    alert(error.response?.data?.message || 'Failed to approve selected');
                  } finally {
                    setLoading(false);
                  }
                }}
                className="flex items-center gap-2 px-6 py-2 bg-blue-600 text-white rounded-lg font-bold hover:bg-blue-700 transition-colors shadow-sm animate-fade-in-up"
              >
                <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
                </svg>
                Approve Selected ({selectedIds.length})
              </button>
            )}

            {/* Approve All Button if Drafts Exist */}
            {payrolls.some(p => p.status === 'pending') && (
              <button
                onClick={async () => {
                  if (!confirm('Are you sure you want to approve all pending payrolls for this period?')) return;

                  try {
                    setLoading(true);
                    // If no period selected, warn user? Or use current year/month? 
                    // API requires month/year.
                    if (selectedMonth === 0 || selectedYear === 0) {
                      alert('Please select specific Month and Year to approve all.');
                      setLoading(false);
                      return;
                    }

                    const response = await apiClient.post('/payrolls/approve-all', {
                      month: selectedMonth,
                      year: selectedYear
                    });

                    alert(response.data.message);
                    fetchPayrolls();
                  } catch (error: any) {
                    alert(error.response?.data?.message || 'Failed to approve payrolls');
                  } finally {
                    setLoading(false);
                  }
                }}
                className="flex items-center gap-2 px-6 py-2 bg-green-500 text-white rounded-lg font-bold hover:bg-green-600 transition-colors shadow-sm"
              >
                <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
                </svg>
                Approve All Drafts
              </button>
            )}
          </div>
        </div>
      </div>

      {/* Main Content */}
      <div className="p-8">
        {/* Payroll Table */}
        <div className="bg-white rounded-2xl shadow-sm border border-gray-100">
          <div className="p-6 border-b border-gray-200">
            <h2 className="text-lg font-bold text-gray-900">Data Payroll</h2>
          </div>

          {loading ? (
            <div className="flex items-center justify-center py-12">
              <div className="w-8 h-8 border-4 border-[#a9eae2] border-t-transparent rounded-full animate-spin"></div>
            </div>
          ) : payrolls.length === 0 ? (
            <div className="text-center py-12">
              <p className="text-gray-500">Belum ada data payroll</p>
              <p className="text-gray-400 text-sm mt-1">Upload file Excel untuk memulai</p>
            </div>
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full">
                <thead>
                  <tr className="border-b border-gray-200 bg-gray-50">
                    <th className="py-4 px-6 w-10">
                      <input
                        type="checkbox"
                        className="rounded border-gray-300 text-[#462e37] focus:ring-[#462e37] cursor-pointer"
                        checked={
                          payrolls.length > 0 &&
                          payrolls.some(p => p.status === 'pending') &&
                          payrolls.filter(p => p.status === 'pending').every(p => selectedIds.includes(Number(p.id)))
                        }
                        onChange={(e) => {
                          if (e.target.checked) {
                            // Select all PENDING only
                            const pendingIds = payrolls
                              .filter(p => p.status === 'pending')
                              .map(p => Number(p.id));
                            setSelectedIds(pendingIds);
                          } else {
                            setSelectedIds([]);
                          }
                        }}
                      />
                    </th>
                    <th className="text-left py-4 px-6 text-sm font-semibold text-gray-600">Employee</th>
                    <th className="text-left py-4 px-6 text-sm font-semibold text-gray-600">Period</th>
                    <th className="text-right py-4 px-6 text-sm font-semibold text-gray-600">Basic Salary</th>
                    <th className="text-right py-4 px-6 text-sm font-semibold text-gray-600">Total Allowances</th>
                    <th className="text-right py-4 px-6 text-sm font-semibold text-gray-600">Overtime</th>
                    <th className="text-right py-4 px-6 text-sm font-bold text-gray-700 bg-gray-100">Gross Salary</th>
                    <th className="text-right py-4 px-6 text-sm font-bold text-red-600 bg-red-50">Total Deductions</th>
                    <th className="text-right py-4 px-6 text-sm font-bold text-[#462e37]">Net Salary</th>
                    <th className="text-center py-4 px-6 text-sm font-semibold text-gray-600">Status</th>
                    <th className="text-center py-4 px-6 text-sm font-semibold text-gray-600">Actions</th>
                  </tr>
                </thead>
                <tbody>
                  {payrolls.map((payroll) => (
                    <tr key={payroll.id} className={`border-b border-gray-100 hover:bg-gray-50 transition-colors ${selectedIds.includes(payroll.id) ? 'bg-blue-50' : ''}`}>
                      <td className="py-4 px-6">
                        {payroll.status === 'pending' && (
                          <input
                            type="checkbox"
                            className="rounded border-gray-300 text-[#462e37] focus:ring-[#462e37] cursor-pointer"
                            checked={selectedIds.includes(Number(payroll.id))}
                            onChange={(e) => {
                              const id = Number(payroll.id);
                              if (e.target.checked) {
                                setSelectedIds(prev => [...prev, id]);
                              } else {
                                setSelectedIds(prev => prev.filter(selectedId => selectedId !== id));
                              }
                            }}
                          />
                        )}
                      </td>
                      <td className="py-4 px-6">
                        <p className="text-sm font-semibold text-gray-900">{payroll.employee.full_name}</p>
                        <p className="text-xs text-gray-500">{payroll.employee.employee_code}</p>
                      </td>
                      <td className="py-4 px-6 text-sm text-gray-900">
                        {new Date(payroll.period_start).toLocaleDateString('id-ID', { month: 'short', year: 'numeric' })}
                      </td>
                      <td className="py-4 px-6 text-right text-sm text-gray-900">{formatCurrency(payroll.basic_salary)}</td>
                      <td className="py-4 px-6 text-right text-sm text-gray-900">{formatCurrency(payroll.allowances)}</td>
                      <td className="py-4 px-6 text-right text-sm text-green-600">{formatCurrency(payroll.overtime_pay || 0)}</td>
                      <td className="py-4 px-6 text-right text-sm font-bold text-gray-800 bg-gray-50">{formatCurrency(payroll.gross_salary)}</td>
                      <td className="py-4 px-6 text-right text-sm font-bold text-red-600 bg-red-50">-{formatCurrency(payroll.total_deductions)}</td>
                      <td className="py-4 px-6 text-right text-sm font-bold text-[#462e37]">{formatCurrency(payroll.net_salary)}</td>
                      <td className="py-4 px-6 text-center">
                        <span className={`inline-flex items-center px-3 py-1 rounded-full text-xs font-semibold border ${getStatusBadge(payroll.status)}`}>
                          {payroll.status.charAt(0).toUpperCase() + payroll.status.slice(1)}
                        </span>
                      </td>
                      <td className="py-4 px-6 text-center">
                        <div className="flex items-center justify-center gap-1">
                          {/* View Detail Button */}
                          <button
                            onClick={() => setSelectedPayroll(payroll)}
                            className="p-2 text-indigo-600 hover:bg-indigo-50 rounded-lg transition-colors"
                            title="Lihat Detail"
                          >
                            <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
                              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z" />
                            </svg>
                          </button>

                          <button
                            onClick={async () => {
                              try {
                                const response = await apiClient.get(`/payrolls/${payroll.id}/slip`, {
                                  responseType: 'blob',
                                });
                                const url = window.URL.createObjectURL(new Blob([response.data]));
                                const link = document.createElement('a');
                                link.href = url;
                                link.setAttribute('download', `Slip_Gaji_${payroll.employee.full_name}_${new Date(payroll.period_start).toLocaleDateString('id-ID', { month: 'short', year: 'numeric' })}.pdf`);
                                document.body.appendChild(link);
                                link.click();
                                link.remove();
                              } catch (error) {
                                alert('Gagal download slip gaji');
                              }
                            }}
                            className="p-2 text-blue-600 hover:bg-blue-50 rounded-lg transition-colors"
                            title="Download Slip Gaji (AI-Enhanced)"
                          >
                            <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 10v6m0 0l-3-3m3 3l3-3m2 8H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
                            </svg>
                          </button>

                          {payroll.status === 'pending' && (
                            <button
                              onClick={async () => {
                                if (!confirm(`Approve payroll for ${payroll.employee.full_name}?`)) return;
                                try {
                                  setLoading(true);
                                  await apiClient.patch(`/payrolls/${payroll.id}/status`, {
                                    status: 'approved'
                                  });
                                  fetchPayrolls();
                                } catch (error: any) {
                                  alert('Failed to approve');
                                } finally {
                                  setLoading(false);
                                }
                              }}
                              className="p-2 text-green-600 hover:bg-green-50 rounded-lg transition-colors ml-2"
                              title="Approve"
                            >
                              <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
                              </svg>
                            </button>
                          )}
                        </div>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </div>
      </div>

      {/* Detail Modal */}
      {selectedPayroll && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4 overflow-y-auto">
          <div className="bg-white rounded-2xl shadow-2xl p-0 max-w-2xl w-full my-8 flex flex-col max-h-[90vh]">
            <div className="p-6 border-b border-gray-100 flex justify-between items-start sticky top-0 bg-white rounded-t-2xl z-10">
              <div>
                <h3 className="text-2xl font-bold text-gray-900">{selectedPayroll.employee.full_name}</h3>
                <p className="text-gray-500">
                  Periode: {new Date(selectedPayroll.period_start).toLocaleDateString('id-ID', { month: 'long', year: 'numeric' })}
                </p>
                <span className={`inline-block mt-2 px-3 py-1 rounded-full text-xs font-semibold border ${getStatusBadge(selectedPayroll.status)}`}>
                  {selectedPayroll.status.toUpperCase()}
                </span>
              </div>
              <button
                onClick={() => setSelectedPayroll(null)}
                className="text-gray-400 hover:text-gray-600 p-2 hover:bg-gray-100 rounded-lg transition-colors"
                title="Close"
              >
                <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                </svg>
              </button>
            </div>

            <div className="p-6 overflow-y-auto flex-1">
              <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
                {/* Earnings */}
                <div>
                  <h4 className="text-sm font-bold text-[#729892] uppercase tracking-wider mb-4 border-b border-[#a9eae2] pb-2">Pendapatan</h4>
                  <div className="space-y-3">
                    <div className="flex justify-between">
                      <span className="text-gray-600">Gaji Pokok</span>
                      <span className="font-semibold">{formatCurrency(selectedPayroll.basic_salary)}</span>
                    </div>
                    {/* Dynamic Allowances */}
                    {selectedPayroll.details?.transport_allowance > 0 && (
                      <div className="flex justify-between text-sm">
                        <span className="text-gray-600">Transportasi</span>
                        <span className="font-medium text-gray-800">{formatSmartValue(selectedPayroll.details.transport_allowance, 'Hari')}</span>
                      </div>
                    )}
                    {selectedPayroll.details?.health_allowance > 0 && (
                      <div className="flex justify-between text-sm">
                        <span className="text-gray-600">Tunj. Kesehatan</span>
                        <span className="font-medium text-gray-800">{formatCurrency(selectedPayroll.details.health_allowance)}</span>
                      </div>
                    )}
                    {selectedPayroll.details?.position_allowance > 0 && (
                      <div className="flex justify-between text-sm">
                        <span className="text-gray-600">Tunj. Jabatan</span>
                        <span className="font-medium text-gray-800">{formatCurrency(selectedPayroll.details.position_allowance)}</span>
                      </div>
                    )}
                    {selectedPayroll.details?.attendance_allowance > 0 && (
                      <div className="flex justify-between text-sm">
                        <span className="text-gray-600">Tunj. Kehadiran</span>
                        <span className="font-medium text-gray-800">{formatSmartValue(selectedPayroll.details.attendance_allowance, 'Hari')}</span>
                      </div>
                    )}
                    {selectedPayroll.details?.holiday_allowance > 0 && (
                      <div className="flex justify-between text-sm">
                        <span className="text-gray-600">THR / Insentif</span>
                        <span className="font-medium text-gray-800">{formatCurrency(selectedPayroll.details.holiday_allowance)}</span>
                      </div>
                    )}
                    {selectedPayroll.overtime_pay > 0 && (
                      <div className="flex justify-between text-sm">
                        <span className="text-gray-600">Lembur</span>
                        <span className="font-medium text-green-600">{formatSmartValue(selectedPayroll.overtime_pay, 'Jam')}</span>
                      </div>
                    )}
                    <div className="pt-2 border-t border-gray-100 flex justify-between font-bold text-gray-900 mt-2">
                      <span>Total Pendapatan</span>
                      <span>{formatCurrency(selectedPayroll.gross_salary)}</span>
                    </div>
                  </div>
                </div>

                {/* Deductions */}
                <div>
                  <h4 className="text-sm font-bold text-red-500 uppercase tracking-wider mb-4 border-b border-red-100 pb-2">Potongan</h4>
                  <div className="space-y-3">
                    {selectedPayroll.bpjs_health > 0 && (
                      <div className="flex justify-between text-sm">
                        <span className="text-gray-600">BPJS Kesehatan</span>
                        <span className="font-medium text-red-600">-{formatCurrency(selectedPayroll.bpjs_health)}</span>
                      </div>
                    )}
                    {selectedPayroll.details?.deductions?.bpjs_tk > 0 && (
                      <div className="flex justify-between text-sm">
                        <span className="text-gray-600">BPJS TK</span>
                        <span className="font-medium text-red-600">-{formatCurrency(selectedPayroll.details.deductions.bpjs_tk)}</span>
                      </div>
                    )}
                    {selectedPayroll.tax > 0 && (
                      <div className="flex justify-between text-sm">
                        <span className="text-gray-600">PPh 21</span>
                        <span className="font-medium text-red-600">-{formatCurrency(selectedPayroll.tax)}</span>
                      </div>
                    )}

                    {/* Detailed Deductions */}
                    {selectedPayroll.details?.deductions?.absent > 0 && (
                      <div className="flex justify-between text-sm">
                        <span className="text-gray-600">Absen</span>
                        <span className="font-medium text-red-600">-{formatSmartValue(selectedPayroll.details.deductions.absent, 'x')}</span>
                      </div>
                    )}
                    {selectedPayroll.details?.deductions?.late > 0 && (
                      <div className="flex justify-between text-sm">
                        <span className="text-gray-600">Terlambat</span>
                        <span className="font-medium text-red-600">-{formatSmartValue(selectedPayroll.details.deductions.late, 'x')}</span>
                      </div>
                    )}

                    {/* EWA Display */}
                    {(selectedPayroll.details?.deductions?.loan > 0 || selectedPayroll.details?.deductions?.bank_fee > 0) && (
                      <div className="bg-red-50 p-2 rounded-lg mt-2">
                        <div className="text-xs font-semibold text-red-700 mb-1">KASBON / EWA</div>
                        {selectedPayroll.details?.deductions?.loan > 0 && (
                          <div className="flex justify-between text-sm">
                            <span className="text-gray-600">Pinjaman Pokok</span>
                            <span className="font-medium text-red-600">-{formatCurrency(selectedPayroll.details.deductions.loan)}</span>
                          </div>
                        )}
                        {selectedPayroll.details?.deductions?.bank_fee > 0 && (
                          <div className="flex justify-between text-sm">
                            <span className="text-gray-600">Biaya Admin</span>
                            <span className="font-medium text-red-600">-{formatCurrency(selectedPayroll.details.deductions.bank_fee)}</span>
                          </div>
                        )}
                      </div>
                    )}

                    <div className="pt-2 border-t border-gray-100 flex justify-between font-bold text-gray-900 mt-2">
                      <span>Total Potongan</span>
                      <span className="text-red-600">-{formatCurrency(selectedPayroll.total_deductions || selectedPayroll.deductions)}</span>
                    </div>
                  </div>
                </div>
              </div>

              {/* Net Salary Summary */}
              <div className="mt-8 bg-[#462e37] text-white p-6 rounded-xl flex items-center justify-between shadow-lg">
                <div>
                  <p className="text-indigo-100 text-sm font-medium">TAKE HOME PAY (THP)</p>
                  <p className="text-3xl font-bold">{formatCurrency(selectedPayroll.net_salary)}</p>
                </div>
                <div className="text-right">
                  <p className="text-xs text-indigo-200">Ditransfer ke</p>
                  {/* If we had account number we would show it here */}
                  <p className="font-semibold">Rekening Karyawan</p>
                </div>
              </div>
            </div>

            <div className="p-6 border-t border-gray-100 bg-gray-50 rounded-b-2xl flex justify-end gap-3">
              <button
                onClick={() => setSelectedPayroll(null)}
                className="px-6 py-2 border border-gray-300 rounded-xl font-semibold hover:bg-white transition-colors"
              >
                Tutup
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Upload Modal */}
      {showUploadModal && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
          <div className="bg-white rounded-2xl shadow-2xl p-8 max-w-md w-full mx-4">
            <div className="flex items-center justify-between mb-6">
              <h3 className="text-2xl font-bold text-gray-900">Import Excel</h3>
              <button
                onClick={() => {
                  setShowUploadModal(false);
                  setSelectedFile(null);
                  setUploadProgress(0);
                }}
                className="text-gray-400 hover:text-gray-600 transition-colors"
              >
                <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                </svg>
              </button>
            </div>

            <div className="space-y-6">
              {/* File Input */}
              <div>
                <label className="block text-sm font-semibold text-gray-700 mb-2">
                  Pilih File Excel
                </label>
                <div className="border-2 border-dashed border-gray-300 rounded-xl p-6 text-center hover:border-[#a9eae2] transition-colors">
                  <input
                    type="file"
                    accept=".xlsx,.xls,.csv"
                    onChange={handleFileChange}
                    className="hidden"
                    id="file-upload"
                  />
                  <label htmlFor="file-upload" className="cursor-pointer">
                    <svg className="w-12 h-12 mx-auto text-gray-400 mb-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M7 16a4 4 0 01-.88-7.903A5 5 0 1115.9 6L16 6a5 5 0 011 9.9M15 13l-3-3m0 0l-3 3m3-3v12" />
                    </svg>
                    {selectedFile ? (
                      <p className="text-sm text-gray-900 font-semibold">{selectedFile.name}</p>
                    ) : (
                      <>
                        <p className="text-sm text-gray-600">Click to upload or drag and drop</p>
                        <p className="text-xs text-gray-400 mt-1">Excel/CSV files (.xlsx, .xls, .csv)</p>
                      </>
                    )}
                  </label>
                </div>
              </div>

              {/* Upload Progress */}
              {uploadProgress > 0 && uploadProgress < 100 && (
                <div>
                  <div className="flex justify-between text-sm mb-2">
                    <span className="text-gray-600">Uploading...</span>
                    <span className="text-[#462e37] font-semibold">{uploadProgress}%</span>
                  </div>
                  <div className="w-full bg-gray-200 rounded-full h-2">
                    <div
                      className="bg-gradient-to-r from-[#a9eae2] to-[#729892] h-2 rounded-full transition-all duration-300"
                      style={{ width: `${uploadProgress}%` }}
                    />
                  </div>
                </div>
              )}

              {/* Action Buttons */}
              <div className="flex gap-3">
                <button
                  onClick={() => {
                    setShowUploadModal(false);
                    setSelectedFile(null);
                    setUploadProgress(0);
                  }}
                  className="flex-1 px-4 py-3 border-2 border-gray-300 text-gray-700 rounded-xl font-semibold hover:bg-gray-50 transition-colors"
                >
                  Cancel
                </button>
                <button
                  onClick={handleUpload}
                  disabled={!selectedFile || uploadProgress > 0}
                  className="flex-1 px-4 py-3 bg-gradient-to-r from-[#a9eae2] to-[#729892] text-[#462e37] rounded-xl font-semibold hover:shadow-lg disabled:opacity-50 disabled:cursor-not-allowed transition-all"
                >
                  Upload
                </button>
              </div>

              {/* Parsed Preview */}
              {parsedRows.length > 0 && (
                <div className="mt-6">
                  <h4 className="text-sm font-semibold mb-2">Preview Data ({parsedRows.length} baris)</h4>
                  <div className="max-h-64 overflow-auto border rounded-lg">
                    <table className="w-full text-sm">
                      <thead className="bg-gray-50">
                        <tr>
                          {Object.keys(parsedRows[0]).map((col) => (
                            <th key={col} className="text-left p-2 font-medium text-gray-600 whitespace-nowrap">{col}</th>
                          ))}
                        </tr>
                      </thead>
                      <tbody>
                        {parsedRows.map((row: any, idx: number) => (
                          <tr key={idx} className="even:bg-white odd:bg-gray-50">
                            {Object.keys(parsedRows[0]).map((col) => (
                              <td key={col} className="p-2 whitespace-nowrap">
                                {typeof row[col] === 'object' && row[col] !== null
                                  ? JSON.stringify(row[col])
                                  : row[col]}
                              </td>
                            ))}
                          </tr>
                        ))}
                      </tbody>
                    </table>
                  </div>
                  <div className="mt-4 flex gap-3">
                    <button
                      onClick={() => {
                        setParsedRows([]);
                        setSelectedFile(null);
                        setUploadProgress(0);
                      }}
                      className="px-4 py-2 border rounded-lg"
                    >
                      Clear
                    </button>
                    <button
                      onClick={async () => {
                        try {
                          const response = await apiClient.post('/payrolls/import/save', {
                            rows: parsedRows,
                          });
                          const data = response.data;

                          // Show detailed results
                          let message = `Import selesai!\n\nTotal: ${data.summary.total}\nBerhasil: ${data.summary.saved}\nGagal: ${data.summary.failed}`;

                          if (data.failed && data.failed.length > 0) {
                            message += '\n\nBaris yang gagal:';
                            data.failed.slice(0, 5).forEach((fail: any) => {
                              message += `\n- Row ${fail.row}: ${fail.employee_name} - ${fail.reason}`;
                            });
                            if (data.failed.length > 5) {
                              message += `\n... dan ${data.failed.length - 5} lainnya (lihat console)`;
                            }
                            console.log('All failed rows:', data.failed);
                          }

                          alert(message);

                          // Close modal and refresh only if some succeeded
                          if (data.summary.saved > 0) {
                            setShowUploadModal(false);
                            setParsedRows([]);
                            setSelectedFile(null);
                            setUploadProgress(0);
                            fetchPayrolls();
                          }
                        } catch (error: any) {
                          alert(error.response?.data?.message || 'Gagal menyimpan data');
                          console.error('Save error:', error.response?.data);
                        }
                      }}
                      className="px-4 py-2 bg-gradient-to-r from-[#a9eae2] to-[#729892] text-[#462e37] rounded-lg"
                    >
                      Save to DB
                    </button>
                  </div>
                </div>
              )}
            </div>
          </div>
        </div>
      )}
    </DashboardLayout>
  );
}
