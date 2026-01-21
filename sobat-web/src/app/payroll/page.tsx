'use client';

import { useEffect, useState, useRef } from 'react';
import { useRouter } from 'next/navigation';
import { useAuthStore } from '@/store/auth-store';
import DashboardLayout from '@/components/DashboardLayout';
import apiClient from '@/lib/api-client';
import SignatureCanvas from 'react-signature-canvas';

interface Payroll {
  id: number;
  employee: {
    employee_code: string;
    full_name: string;
  };
  period_start: string;
  period_end: string;
  basic_salary: number;
  allowances: any; // Allow object or number
  overtime_pay: number;
  deductions: any;
  total_deductions: number; // Added from backend calculation
  bpjs_health: number;
  bpjs_employment: number;
  tax: number;
  gross_salary: number;
  net_salary: number;
  details: any; // Flexible JSON
  status: 'draft' | 'pending' | 'approved' | 'paid';
  // FnB Specific Properties
  attendance?: Record<string, number>;
  ewa_amount?: number | string;
  approval_signature?: string;
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

  // Signature Modal State
  const [showSignatureModal, setShowSignatureModal] = useState(false);
  const [pendingApprovalId, setPendingApprovalId] = useState<number | null>(null);
  const [isBulkApproval, setIsBulkApproval] = useState(false);
  const [signerName, setSignerName] = useState('');
  const sigPad = useRef<SignatureCanvas>(null);

  // Division selector
  const [selectedDivision, setSelectedDivision] = useState<'fnb' | 'minimarket' | 'reflexiology' | 'wrapping'>('fnb');

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
  }, [isAuthenticated, router, selectedMonth, selectedYear, selectedDivision]);

  const fetchPayrolls = async () => {
    try {
      setLoading(true);

      // Use division-specific endpoint
      let endpoint = '';
      if (selectedDivision === 'fnb') endpoint = '/payrolls/fnb';
      if (selectedDivision === 'minimarket') endpoint = '/payrolls/mm';
      if (selectedDivision === 'reflexiology') endpoint = '/payrolls/ref';
      if (selectedDivision === 'wrapping') endpoint = '/payrolls/wrapping';

      const response = await apiClient.get(endpoint, {
        params: {
          ...(selectedMonth !== 0 && { month: selectedMonth }),
          ...(selectedYear !== 0 && { year: selectedYear })
        }
      });

      // Handle different response structures
      if (endpoint) {
        setPayrolls(response.data.data || []);
      }
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

      // Use division-specific import endpoint
      let importEndpoint = '';
      if (selectedDivision === 'fnb') importEndpoint = '/payrolls/fnb/import';
      if (selectedDivision === 'minimarket') importEndpoint = '/payrolls/mm/import';
      if (selectedDivision === 'reflexiology') importEndpoint = '/payrolls/ref/import';
      if (selectedDivision === 'wrapping') importEndpoint = '/payrolls/wrapping/import';

      const response = await apiClient.post(importEndpoint, formData, {
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
        // Handle save response
        if (data.saved === 0 && data.errors && data.errors.length > 0) {
          alert('Gagal menyimpan data:\n' + data.errors.join('\n'));
        } else if (data.errors && data.errors.length > 0) {
          alert(`Berhasil menyimpan ${data.saved} data.\nAda beberapa error:\n` + data.errors.join('\n'));
        } else {
          alert(data.message || 'Import berhasil');
        }
        setShowUploadModal(false);
        setSelectedFile(null);
        fetchPayrolls();
      }
    } catch (error: any) {
      alert(error.response?.data?.message || 'Import gagal');
    }
  };

  const handleConfirmApproval = async () => {
    if (sigPad.current?.isEmpty()) {
      alert('Harap tanda tangan terlebih dahulu');
      return;
    }

    const signatureData = sigPad.current?.getCanvas().toDataURL('image/png');

    try {
      setLoading(true);
      if (isBulkApproval) {
        // Bulk Approve Logic with Signature
        const response = await apiClient.post('/payrolls/bulk-approve', {
          ids: selectedIds,
          approval_signature: signatureData,
          signer_name: signerName
        });
        alert(response.data.message);
        setSelectedIds([]);
      } else if (pendingApprovalId) {
        // Single Approve
        let endpoint = `/payrolls/${pendingApprovalId}/status`;
        if (selectedDivision === 'fnb') endpoint = `/payrolls/fnb/${pendingApprovalId}/status`;
        if (selectedDivision === 'minimarket') endpoint = `/payrolls/mm/${pendingApprovalId}/status`;
        if (selectedDivision === 'reflexiology') endpoint = `/payrolls/ref/${pendingApprovalId}/status`;
        if (selectedDivision === 'wrapping') endpoint = `/payrolls/wrapping/${pendingApprovalId}/status`;

        // Note: FNB uses updateStatus which takes 'status' and 'approval_signature'
        // Generic Controller might need update. Assuming Generic uses PATCH /payrolls/{id}/status

        console.log('Approving with Endpoint:', endpoint, 'ID:', pendingApprovalId); // DEBUG

        await apiClient.patch(endpoint, {
          status: 'approved',
          approval_signature: signatureData,
          signer_name: signerName
        });
      }

      fetchPayrolls();
      setShowSignatureModal(false);
      setPendingApprovalId(null);
      setIsBulkApproval(false);

    } catch (error: any) {
      alert(error.response?.data?.message || 'Approval failed');
    } finally {
      setLoading(false);
    }
  };

  const clearSignature = () => {
    sigPad.current?.clear();
  };

  const formatCurrency = (value: number) => {
    return new Intl.NumberFormat('id-ID', {
      style: 'currency',
      currency: 'IDR',
      minimumFractionDigits: 0,
    }).format(value);
  };

  // Helper to calculate total allowances for FnB/MM/Ref/Wrapping payroll
  const calculateTotalAllowances = (payroll: any) => {
    if (['fnb', 'minimarket', 'reflexiology', 'wrapping'].includes(selectedDivision)) {
      // FnB/MM/Ref backend returns structured allowances object
      if (payroll.allowances && typeof payroll.allowances === 'object') {
        const allowances = payroll.allowances;

        // Helper to parse value (handles both strings and numbers)
        const parseValue = (val: any) => {
          if (typeof val === 'object' && val?.amount !== undefined) {
            return parseFloat(val.amount) || 0;
          }
          return parseFloat(val) || 0;
        };

        // Common keys plus new ones for MM
        return (
          parseValue(allowances['Kehadiran']) +
          parseValue(allowances['Transport']) +
          parseValue(allowances['Tunjangan Kesehatan']) +
          parseValue(allowances['Tunjangan Jabatan']) +
          parseValue(allowances['Lembur']) +
          parseValue(allowances['Insentif Lebaran'] || allowances['THR']) +
          parseValue(allowances['Adjustment']) +
          parseValue(allowances['Kebijakan HO']) +
          // MM specific
          parseValue(allowances['Uang Makan']) +
          parseValue(allowances['Bonus']) +
          parseValue(allowances['Insentif'])
        );
      }
      // Fallback to direct fields if structured object not available
      return (
        (parseFloat(payroll.attendance_amount) || 0) +
        (parseFloat(payroll.transport_amount) || 0) +
        (parseFloat(payroll.health_allowance) || 0) +
        (parseFloat(payroll.position_allowance) || 0) +
        (parseFloat(payroll.overtime_amount) || 0) +
        (parseFloat(payroll.holiday_allowance) || 0) +
        (parseFloat(payroll.adjustment) || 0) +
        (parseFloat(payroll.policy_ho) || 0) +
        (parseFloat(payroll.meal_amount) || 0) +
        (parseFloat(payroll.bonus) || 0) +
        (parseFloat(payroll.incentive) || 0)
      );
    }
    // Generic payroll - allowances is a single number
    return parseFloat(payroll.allowances) || 0;
  };

  // Helper to calculate overtime pay for FnB/MM/Ref/Wrapping payroll
  const calculateOvertimePay = (payroll: any) => {
    if (['fnb', 'minimarket', 'reflexiology', 'wrapping'].includes(selectedDivision)) {
      // Check structured allowances first
      if (payroll.allowances?.Lembur) {
        const lembur = payroll.allowances.Lembur;
        if (typeof lembur === 'object' && lembur.amount !== undefined) {
          return parseFloat(lembur.amount) || 0;
        }
        return parseFloat(lembur) || 0;
      }
      return parseFloat(payroll.overtime_amount) || 0;
    }
    return parseFloat(payroll.overtime_pay) || 0;
  };

  // Helper to calculate total deductions for FnB/MM/Ref payroll
  const calculateTotalDeductions = (payroll: any) => {
    if (selectedDivision === 'minimarket' || selectedDivision === 'reflexiology' || selectedDivision === 'wrapping') {
      return parseFloat(payroll.deduction_total) || 0;
    }
    // Generic
    return parseFloat(payroll.total_deductions) || 0;
  };

  // Helper to calculate gross salary for FnB/MM/Ref/Wrapping payroll
  const calculateGrossSalary = (payroll: any) => {
    if (selectedDivision === 'wrapping') {
      return parseFloat(payroll.total_salary_gross) || 0;
    }
    if (['fnb', 'minimarket', 'reflexiology'].includes(selectedDivision)) {
      // For FnB/MM/Ref, use total_salary_2 which includes everything
      return parseFloat(payroll.total_salary_2) || 0;
    }
    return parseFloat(payroll.gross_salary) || 0;
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
          {/* Division Selector */}
          <div className="flex items-center gap-2">
            <span className="text-sm font-semibold text-gray-700">Divisi:</span>
            <select
              value={selectedDivision}
              onChange={(e) => setSelectedDivision(e.target.value as 'fnb' | 'minimarket' | 'reflexiology' | 'wrapping')}
              className="px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:border-[#462e37] text-sm font-medium"
            >
              <option value="fnb">FnB</option>
              <option value="minimarket">Minimarket</option>
              <option value="reflexiology">Reflexiology</option>
              <option value="wrapping">Wrapping</option>
            </select>
          </div>

          {/* Period Filter */}
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
                  setIsBulkApproval(true);
                  setShowSignatureModal(true);
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
                        {(payroll as any).period
                          ? new Date((payroll as any).period + '-01').toLocaleDateString('id-ID', { month: 'short', year: 'numeric' })
                          : new Date(payroll.period_start).toLocaleDateString('id-ID', { month: 'short', year: 'numeric' })
                        }
                      </td>
                      <td className="py-4 px-6 text-right text-sm text-gray-900">{formatCurrency(payroll.basic_salary)}</td>
                      <td className="py-4 px-6 text-right text-sm text-gray-900">{formatCurrency(calculateTotalAllowances(payroll))}</td>
                      <td className="py-4 px-6 text-right text-sm text-green-600">{formatCurrency(calculateOvertimePay(payroll))}</td>
                      <td className="py-4 px-6 text-right text-sm font-bold text-gray-800 bg-gray-50">{formatCurrency(calculateGrossSalary(payroll))}</td>
                      <td className="py-4 px-6 text-right text-sm font-bold text-red-600 bg-red-50">-{formatCurrency(calculateTotalDeductions(payroll))}</td>
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
                                const endpoint = selectedDivision === 'fnb'
                                  ? `/payrolls/fnb/${payroll.id}/slip`
                                  : selectedDivision === 'minimarket'
                                    ? `/payrolls/mm/${payroll.id}/slip`
                                    : selectedDivision === 'reflexiology'
                                      ? `/payrolls/ref/${payroll.id}/slip`
                                      : selectedDivision === 'wrapping'
                                        ? `/payrolls/wrapping/${payroll.id}/slip`
                                        : `/payrolls/${payroll.id}/slip`;

                                const response = await apiClient.get(endpoint, {
                                  responseType: 'blob',
                                });
                                const url = window.URL.createObjectURL(new Blob([response.data]));
                                const link = document.createElement('a');
                                link.href = url;
                                const periodStr = (payroll as any).period || payroll.period_start;
                                const dateStr = periodStr ? new Date(periodStr).toLocaleDateString('id-ID', { month: 'short', year: 'numeric' }) : 'Unknown';
                                link.setAttribute('download', `Slip_Gaji_${payroll.employee.full_name}_${dateStr}.pdf`);
                                document.body.appendChild(link);
                                link.click();
                                link.remove();
                              } catch (error) {
                                console.error(error);
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
                              onClick={() => {
                                setPendingApprovalId(Number(payroll.id));
                                setIsBulkApproval(false);
                                setShowSignatureModal(true);
                              }}
                              className="p-2 text-green-600 hover:bg-green-50 rounded-lg transition-colors ml-2"
                              title="Approve"
                            >
                              <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
                              </svg>
                            </button>
                          )}
                          {(payroll as any).status === 'draft' && (
                            <button
                              onClick={() => {/* handle edit */ }}
                              className="p-2 text-gray-600 hover:bg-gray-50 rounded-lg transition-colors ml-2"
                              title="Edit"
                            >
                              <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z" />
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
      {
        selectedPayroll && (
          <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4 overflow-y-auto">
            <div className="bg-white rounded-2xl shadow-2xl p-0 max-w-2xl w-full my-8 flex flex-col max-h-[90vh]">
              <div className="p-6 border-b border-gray-100 flex justify-between items-start sticky top-0 bg-white rounded-t-2xl z-10">
                <div>
                  <h3 className="text-2xl font-bold text-gray-900">{selectedPayroll.employee.full_name}</h3>
                  <p className="text-gray-500">
                    Periode: {(selectedPayroll as any).period || new Date(selectedPayroll.period_start).toLocaleDateString('id-ID', { month: 'long', year: 'numeric' })}
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
                {/* Attendance Summary (for FnB/MM/Ref/Wrapping) */}
                {['fnb', 'minimarket', 'reflexiology', 'wrapping'].includes(selectedDivision) && (selectedPayroll as any).attendance && (
                  <div className="mb-6 bg-blue-50 p-4 rounded-xl">
                    <h4 className="text-sm font-bold text-blue-700 uppercase tracking-wider mb-3">Data Kehadiran</h4>
                    <div className="grid grid-cols-4 gap-2 text-xs">
                      {Object.entries((selectedPayroll as any).attendance).map(([key, value]: [string, any]) => (
                        <div key={key} className="text-center">
                          <div className="font-semibold text-blue-900">{value}</div>
                          <div className="text-blue-600">{key}</div>
                        </div>
                      ))}
                    </div>
                  </div>
                )}

                <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
                  {/* Earnings */}
                  <div>
                    <h4 className="text-sm font-bold text-[#729892] uppercase tracking-wider mb-4 border-b border-[#a9eae2] pb-2">Pendapatan</h4>
                    <div className="space-y-3">
                      <div className="flex justify-between">
                        <span className="text-gray-600">Gaji Pokok</span>
                        <span className="font-semibold">{formatCurrency(selectedPayroll.basic_salary)}</span>
                      </div>

                      {/* FnB/MM/Ref/Wrapping Allowances Breakdown */}
                      {['fnb', 'minimarket', 'reflexiology', 'wrapping'].includes(selectedDivision) && selectedPayroll.allowances && (
                        <>
                          {Object.entries(selectedPayroll.allowances).map(([key, value]: [string, any]) => {
                            if (!value || value === 0 || value === '0.00') return null;

                            // Handle nested objects (like Kehadiran, Transport, Lembur)
                            if (typeof value === 'object' && value.amount) {
                              // Special handling for Lembur to show hours
                              if (key === 'Lembur') {
                                const hours = value.hours || 0;
                                return (
                                  <div key={key} className="flex justify-between text-sm">
                                    <span className="text-gray-600">Lembur {hours > 0 ? `(${hours} Jam)` : ''}</span>
                                    <span className="font-medium text-gray-800">{formatCurrency(parseFloat(value.amount))}</span>
                                  </div>
                                );
                              }

                              return (
                                <div key={key} className="flex justify-between text-sm">
                                  <span className="text-gray-600">{key}</span>
                                  <span className="font-medium text-gray-800">{formatCurrency(parseFloat(value.amount))}</span>
                                </div>
                              );
                            }

                            // Handle simple values
                            // Since we handled Lembur above (if it was an object), we check if it's simple Lembur (unlikely but safe)
                            if (key === 'Lembur') {
                              return (
                                <div key={key} className="flex justify-between text-sm">
                                  <span className="text-gray-600">Lembur</span>
                                  <span className="font-medium text-gray-800">{formatCurrency(parseFloat(value))}</span>
                                </div>
                              );
                            }

                            return (
                              <div key={key} className="flex justify-between text-sm">
                                <span className="text-gray-600">{key}</span>
                                <span className="font-medium text-gray-800">{formatCurrency(parseFloat(value))}</span>
                              </div>
                            );
                          })}
                        </>
                      )}

                      {/* Generic Payroll Allowances */}
                      {!['fnb', 'minimarket', 'reflexiology', 'wrapping'].includes(selectedDivision) && (
                        <>
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
                          {/* Add Generic Overtime if available in details */}
                          {selectedPayroll.details?.overtime_hours > 0 && (
                            <div className="flex justify-between text-sm">
                              <span className="text-gray-600">Lembur ({selectedPayroll.details.overtime_hours} Jam)</span>
                              <span className="font-medium text-gray-800">{formatCurrency(selectedPayroll.overtime_pay)}</span>
                            </div>
                          )}
                          {!selectedPayroll.details?.overtime_hours && selectedPayroll.overtime_pay > 0 && (
                            <div className="flex justify-between text-sm">
                              <span className="text-gray-600">Lembur</span>
                              <span className="font-medium text-gray-800">{formatCurrency(selectedPayroll.overtime_pay)}</span>
                            </div>
                          )}
                        </>
                      )}
                      {/* Deductions - FnB EWA */}

                      <div className="pt-2 border-t border-gray-100 flex justify-between font-bold text-gray-900 mt-2">
                        <span>Total Pendapatan</span>
                        <span>{formatCurrency(calculateGrossSalary(selectedPayroll))}</span>
                      </div>
                    </div>
                  </div>

                  {/* Deductions */}
                  <div>
                    <h4 className="text-sm font-bold text-red-500 uppercase tracking-wider mb-4 border-b border-red-100 pb-2">Potongan</h4>
                    <div className="space-y-3">
                      {/* FnB/MM/Ref/Wrapping Deductions Breakdown */}
                      {(selectedDivision === 'fnb' || selectedDivision === 'minimarket' || selectedDivision === 'reflexiology' || selectedDivision === 'wrapping') && selectedPayroll.deductions && (
                        <>
                          {Object.entries(selectedPayroll.deductions).map(([key, value]: [string, any]) => {
                            const numValue = parseFloat(value);
                            if (!numValue || numValue === 0) return null;

                            return (
                              <div key={key} className="flex justify-between text-sm">
                                <span className="text-gray-600">{key}</span>
                                <span className="font-medium text-red-600">-{formatCurrency(numValue)}</span>
                              </div>
                            );
                          })}
                        </>
                      )}

                      {/* Generic Payroll Deductions */}
                      {selectedDivision !== 'fnb' && selectedDivision !== 'minimarket' && selectedDivision !== 'reflexiology' && selectedDivision !== 'wrapping' && (
                        <>
                          {selectedPayroll.bpjs_health > 0 && (
                            <div className="flex justify-between text-sm">
                              <span className="text-gray-600">BPJS Kesehatan</span>
                              <span className="font-medium text-red-600">-{formatCurrency(selectedPayroll.bpjs_health)}</span>
                            </div>
                          )}
                          {selectedPayroll.tax > 0 && (
                            <div className="flex justify-between text-sm">
                              <span className="text-gray-600">PPh 21</span>
                              <span className="font-medium text-red-600">-{formatCurrency(selectedPayroll.tax)}</span>
                            </div>
                          )}
                        </>
                      )}

                      {/* EWA Display (for FnB/MM/Ref/Wrapping) */}
                      {(selectedDivision === 'fnb' || selectedDivision === 'minimarket' || selectedDivision === 'reflexiology' || selectedDivision === 'wrapping') && selectedPayroll.ewa_amount && (
                        <div className="bg-red-50 p-2 rounded-lg mt-2">
                          <div className="text-xs font-semibold text-red-700 mb-1">EWA (Kasbon)</div>
                          <div className="flex justify-between text-sm">
                            <span className="text-gray-600">Total EWA</span>
                            <span className="font-medium text-red-600">
                              -{formatCurrency(typeof selectedPayroll.ewa_amount === 'string' ? parseFloat(selectedPayroll.ewa_amount) : selectedPayroll.ewa_amount)}
                            </span>
                          </div>
                        </div>
                      )}

                      <div className="pt-2 border-t border-gray-100 flex justify-between font-bold text-gray-900 mt-2">
                        <span>Total Potongan</span>
                        <span className="text-red-600">
                          -{formatCurrency(
                            calculateTotalDeductions(selectedPayroll) +
                            ((selectedDivision === 'fnb' || selectedDivision === 'minimarket' || selectedDivision === 'reflexiology' || selectedDivision === 'wrapping') && selectedPayroll.ewa_amount ? (typeof selectedPayroll.ewa_amount === 'string' ? parseFloat(selectedPayroll.ewa_amount) : selectedPayroll.ewa_amount) : 0)
                          )}
                        </span>
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

              <div className="p-6 border-t border-gray-100 bg-gray-50 rounded-b-2xl flex justify-between items-center">
                <div className="flex gap-2">
                  {/* Download Payslip Button */}
                  <button
                    onClick={async () => {
                      try {
                        const endpoint = selectedDivision === 'fnb'
                          ? `/payrolls/fnb/${selectedPayroll.id}/slip`
                          : selectedDivision === 'minimarket'
                            ? `/payrolls/mm/${selectedPayroll.id}/slip`
                            : selectedDivision === 'reflexiology'
                              ? `/payrolls/ref/${selectedPayroll.id}/slip`
                              : `/payrolls/${selectedPayroll.id}/slip`;

                        const response = await apiClient.get(endpoint, {
                          responseType: 'blob',
                        });
                        const url = window.URL.createObjectURL(new Blob([response.data]));
                        const link = document.createElement('a');
                        link.href = url;
                        link.setAttribute('download', `payslip-${selectedPayroll.employee.full_name}.pdf`);
                        document.body.appendChild(link);
                        link.click();
                        link.remove();
                      } catch (error) {
                        console.error(error);
                        alert('Gagal download slip gaji');
                      }
                    }}
                    className="flex-1 bg-[#462e37] text-white px-4 py-3 rounded-xl font-semibold hover:bg-[#523640] transition-colors flex items-center justify-center gap-2"
                  >
                    <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-4l-4 4m0 0l-4-4m4 4V4" />
                    </svg>
                    Download Slip Gaji (PDF)
                  </button>

                  {/* Approve Button (only for draft/pending status) */}
                  {(selectedPayroll.status === 'draft' || selectedPayroll.status === 'pending') && (
                    <button
                      onClick={() => {
                        setPendingApprovalId(Number(selectedPayroll.id));
                        setIsBulkApproval(false);
                        setShowSignatureModal(true);
                      }}
                      className="flex-1 bg-green-600 text-white px-4 py-3 rounded-xl font-semibold hover:bg-green-700 transition-colors flex items-center justify-center gap-2"
                    >
                      <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
                      </svg>
                      Approve
                    </button>
                  )}

                  <button
                    onClick={() => setSelectedPayroll(null)}
                    className="px-6 py-3 border border-gray-300 rounded-xl font-semibold hover:bg-white transition-colors"
                  >
                    Tutup
                  </button>
                </div>
              </div>
            </div>
          </div>
        )
      }

      {/* Signature Modal */}
      {
        showSignatureModal && (
          <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-[60] p-4 text-black">
            <div className="bg-white rounded-2xl shadow-xl w-full max-w-md p-6">
              <div className="flex justify-between items-center mb-4">
                <h3 className="text-xl font-bold text-gray-900">Tanda Tangan Approval</h3>
                <button onClick={() => setShowSignatureModal(false)} className="text-gray-400 hover:text-gray-600">
                  <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                  </svg>
                </button>
              </div>

              <p className="text-sm text-gray-500 mb-4">
                Silakan tanda tangan di bawah ini untuk menyetujui payroll {isBulkApproval ? `(${selectedIds.length} items)` : ''}.
              </p>

              <div className="mb-4">
                <label className="block text-sm font-medium text-gray-700 mb-1">Nama Penanda Tangan</label>
                <input
                  type="text"
                  value={signerName}
                  onChange={(e) => setSignerName(e.target.value)}
                  placeholder="Masukkan nama lengkap (e.g. Budi Santoso, HRD)"
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-[#729892]"
                />
              </div>

              <div className="border-2 border-dashed border-gray-300 rounded-xl mb-4 bg-gray-50">
                <SignatureCanvas
                  ref={sigPad}
                  penColor="black"
                  canvasProps={{
                    className: 'w-full h-48 rounded-xl cursor-crosshair'
                  }}
                />
              </div>

              <div className="flex gap-3">
                <button
                  onClick={clearSignature}
                  className="flex-1 px-4 py-2 border border-gray-300 text-gray-700 rounded-xl font-medium hover:bg-gray-50 transition-colors"
                >
                  Hapus
                </button>
                <button
                  onClick={handleConfirmApproval}
                  disabled={loading}
                  className="flex-1 px-4 py-2 bg-[#462e37] text-white rounded-xl font-bold hover:bg-[#5e3d4a] transition-colors disabled:opacity-50"
                >
                  {loading ? 'Processing...' : 'Approve & Sign'}
                </button>
              </div>
            </div>
          </div>
        )
      }

      {/* Upload Modal */}
      {
        showUploadModal && (
          <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 text-black">
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
                            // Use division-specific save endpoint
                            let saveEndpoint = '/payrolls/import/save';
                            if (selectedDivision === 'fnb') saveEndpoint = '/payrolls/fnb/import/save';
                            if (selectedDivision === 'minimarket') saveEndpoint = '/payrolls/mm/import/save';
                            if (selectedDivision === 'reflexiology') saveEndpoint = '/payrolls/ref/import/save';
                            if (selectedDivision === 'wrapping') saveEndpoint = '/payrolls/wrapping/import/save';

                            const response = await apiClient.post(saveEndpoint, {
                              rows: parsedRows,
                            });
                            const data = response.data;

                            // Show detailed results
                            // Show detailed results
                            let message = `Import selesai!`;

                            if (data.summary) {
                              message += `\n\nTotal: ${data.summary.total}\nBerhasil: ${data.summary.saved}\nGagal: ${data.summary.failed}`;
                            }

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
                            if (data.summary && data.summary.saved > 0) {
                              setShowUploadModal(false);
                              setParsedRows([]);
                              setSelectedFile(null);
                              setUploadProgress(0);
                              fetchPayrolls();
                            }
                          } catch (error: any) {
                            alert(error.response?.data?.message || 'Gagal menyimpan data');
                            console.error('Save error details:', error);
                            if (error.response) {
                              console.error('Response data:', error.response.data);
                              console.error('Response status:', error.response.status);
                            }
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
        )
      }
    </DashboardLayout >
  );
}
