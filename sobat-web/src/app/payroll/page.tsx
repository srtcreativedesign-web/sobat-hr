'use client';

import { useEffect, useState, useMemo } from 'react';
import { useRouter } from 'next/navigation';
import { useAuthStore } from '@/store/auth-store';
import DashboardLayout from '@/components/DashboardLayout';
import apiClient from '@/lib/api-client';
import { NavTabs } from '@/components/ui/tabs';
import { DataTable } from '@/components/ui/data-table';
import { Input } from '@nextui-org/react';
import { Search } from 'lucide-react';

// Refactored Components & Types
import { Payroll } from './types';
import { 
  formatCurrency, 
  calculateTotalAllowances, 
  calculateOvertimePay, 
  calculateTotalDeductions, 
  calculateGrossSalary, 
  getStatusBadge 
} from './utils';
import PayrollDetailModal from './components/PayrollDetailModal';
import SignatureModal from './components/SignatureModal';

export default function PayrollPage() {
  const router = useRouter();
  const { isAuthenticated, checkAuth, user } = useAuthStore();
  const isAdminHr = user?.role === 'admin_hr' || (user?.role as any)?.name === 'admin_hr';
  
  const [payrolls, setPayrolls] = useState<Payroll[]>([]);
  const [loading, setLoading] = useState(false);

  const [selectedIds, setSelectedIds] = useState<number[]>([]);
  const [selectedPayroll, setSelectedPayroll] = useState<Payroll | null>(null);

  // Signature Modal State
  const [showSignatureModal, setShowSignatureModal] = useState(false);
  const [pendingApprovalId, setPendingApprovalId] = useState<number | null>(null);
  const [isBulkApproval, setIsBulkApproval] = useState(false);

  // Division selector
  const [selectedDivision, setSelectedDivision] = useState<'all' | 'office' | 'fnb' | 'minimarket' | 'reflexiology' | 'wrapping' | 'hans' | 'cellular' | 'money_changer'>('fnb');

  // Filter States
  const [selectedMonth, setSelectedMonth] = useState(new Date().getMonth() + 1); // Default current month
  const [selectedYear, setSelectedYear] = useState(new Date().getFullYear()); // Default current year
  const [searchQuery, setSearchQuery] = useState('');
  const [debouncedSearch, setDebouncedSearch] = useState('');
  const [currentPage, setCurrentPage] = useState(1);
  const [lastPage, setLastPage] = useState(1);
  const [totalItems, setTotalItems] = useState(0);

  const months = [
    { value: 1, label: 'Januari' }, { value: 2, label: 'Februari' }, { value: 3, label: 'Maret' },
    { value: 4, label: 'April' }, { value: 5, label: 'Mei' }, { value: 6, label: 'Juni' },
    { value: 7, label: 'Juli' }, { value: 8, label: 'Agustus' }, { value: 9, label: 'September' },
    { value: 10, label: 'Oktober' }, { value: 11, label: 'November' }, { value: 12, label: 'Desember' }
  ];

  useEffect(() => {
    checkAuth();
  }, [checkAuth]);

  // Debounce search effect
  useEffect(() => {
    const handler = setTimeout(() => {
      setDebouncedSearch(searchQuery);
      setCurrentPage(1); // Reset to page 1 on search
    }, 500);
    return () => clearTimeout(handler);
  }, [searchQuery]);

  useEffect(() => {
    fetchPayrolls();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [selectedMonth, selectedYear, selectedDivision, currentPage, debouncedSearch]);

  const fetchPayrolls = async () => {
    try {
      setLoading(true);

      if (selectedDivision === 'all') {
        setPayrolls([]); // Clear table for 'All' view as it aggregates different structures
        setLoading(false);
        return;
      }

      // Use division-specific endpoint
      let endpoint = '';
      if (selectedDivision === 'office') endpoint = '/payrolls/ho';
      if (['fnb'].includes(selectedDivision)) endpoint = '/payrolls/fnb';
      if (['minimarket', 'reflexiology', 'wrapping', 'hans', 'cellular', 'money_changer'].includes(selectedDivision)) endpoint = '/payrolls/retail';

      const response = await apiClient.get(endpoint, {
        params: {
          page: currentPage,
          ...(selectedMonth !== 0 && { month: selectedMonth }),
          ...(selectedYear !== 0 && { year: selectedYear }),
          ...(debouncedSearch && { search: debouncedSearch }),
          ...(['minimarket', 'reflexiology', 'wrapping', 'hans', 'cellular', 'money_changer'].includes(selectedDivision) && { division_type: selectedDivision })
        }
      });

      // Handle different response structures
      if (endpoint) {
        const data = response.data;
        if (data.data && Array.isArray(data.data)) {
          setPayrolls(data.data);
          setLastPage(data.last_page || 1);
          setTotalItems(data.total || 0);
        } else {
          setPayrolls(data || []);
          setLastPage(1);
          setTotalItems(data.length || 0);
        }
      }
    } catch (error) {
      console.error('Failed to fetch payrolls:', error);
      setPayrolls([]);
    } finally {
      setLoading(false);
    }
  };

  const handleBulkDownload = async () => {
    if (selectedMonth === 0 || selectedYear === 0) {
      alert('Harap pilih Bulan dan Tahun spesifik untuk mengunduh semua slip gaji.');
      return;
    }

    try {
      setLoading(true);
      const period = `${selectedYear}-${String(selectedMonth).padStart(2, '0')}`;

      const response = await apiClient.post('/payrolls/bulk-download', {
        period,
        division: selectedDivision
      }, {
        responseType: 'blob'
      });

      const url = window.URL.createObjectURL(new Blob([response.data]));
      const link = document.createElement('a');
      link.href = url;
      link.setAttribute('download', `Payrolls_${selectedDivision}_${period}.zip`);
      document.body.appendChild(link);
      link.click();
      link.remove();
    } catch (error: any) {
      console.error('Download failed:', error);
      // Try to read blob error message
      if (error.response?.data instanceof Blob) {
        const text = await error.response.data.text();
        try {
          const json = JSON.parse(text);
          alert(json.message || 'Download gagal');
        } catch (e) {
          alert('Gagal mengunduh file ZIP');
        }
      } else {
        alert('Gagal mengunduh file ZIP');
      }
    } finally {
      setLoading(false);
    }
  };

  const handleConfirmApproval = async (signatureData: string, signerName: string, approvalNotes: string) => {
    try {
      if (isBulkApproval) {
        // Bulk Approve Logic with Signature
        const response = await apiClient.post('/payrolls/bulk-approve', {
          ids: selectedIds,
          approval_signature: signatureData,
          signer_name: signerName,
          notes: approvalNotes,
          division: selectedDivision
        });
        alert(response.data.message);
        setSelectedIds([]);
      } else if (pendingApprovalId) {
        // Single Approve
        let endpoint = `/payrolls/${pendingApprovalId}/status`;
        if (['fnb'].includes(selectedDivision)) endpoint = `/payrolls/fnb/${pendingApprovalId}/status`;
        if (['minimarket', 'reflexiology', 'wrapping', 'hans', 'cellular', 'money_changer'].includes(selectedDivision)) {
          endpoint = `/payrolls/retail/${pendingApprovalId}/status`;
        }
        if (selectedDivision === 'office') endpoint = `/payrolls/ho/${pendingApprovalId}/status`;

        await apiClient.patch(endpoint, {
          status: 'approved',
          approval_signature: signatureData,
          signer_name: signerName,
          notes: approvalNotes,
          division_type: selectedDivision
        });
      }

      fetchPayrolls();
      setShowSignatureModal(false);
      setPendingApprovalId(null);
      setIsBulkApproval(false);

    } catch (error: any) {
      alert(error.response?.data?.message || 'Approval failed');
    }
  };

  const columns = [
    { name: "EMPLOYEE", uid: "employee" },
    { name: "PERIOD", uid: "period" },
    { name: "BASIC SALARY", uid: "basic_salary" },
    { name: "TOTAL ALLOWANCES", uid: "allowances" },
    { name: "OVERTIME", uid: "overtime" },
    { name: "GROSS SALARY", uid: "gross_salary" },
    { name: "TOTAL DEDUCTIONS", uid: "deductions" },
    { name: "NET SALARY", uid: "net_salary" },
    { name: "STATUS", uid: "status" },
    { name: "ACTIONS", uid: "actions" },
  ];

  const disabledKeys = useMemo(() => new Set(
    payrolls.filter(p => !['pending', 'draft'].includes(p.status)).map(p => String(p.id))
  ), [payrolls]);

  const renderCell = (payroll: any, columnKey: React.Key) => {
    switch (columnKey) {
      case "employee":
        return (
          <div>
            <p className="text-sm font-semibold text-gray-900">{payroll.employee?.full_name}</p>
            <p className="text-xs text-gray-500">{payroll.employee?.employee_code}</p>
          </div>
        );
      case "period":
        return (
          <div className="text-sm text-gray-900">
            {payroll.period
              ? new Date(payroll.period + '-01').toLocaleDateString('id-ID', { month: 'short', year: 'numeric' })
              : new Date(payroll.period_start).toLocaleDateString('id-ID', { month: 'short', year: 'numeric' })
            }
          </div>
        );
      case "basic_salary":
        return <div className="text-right text-sm text-gray-900">{formatCurrency(payroll.basic_salary)}</div>;
      case "allowances":
        return <div className="text-right text-sm text-gray-900">{formatCurrency(calculateTotalAllowances(payroll, selectedDivision))}</div>;
      case "overtime":
        return <div className="text-right text-sm text-green-600">{formatCurrency(calculateOvertimePay(payroll, selectedDivision))}</div>;
      case "gross_salary":
        return <div className="text-right text-sm font-bold text-gray-800">{formatCurrency(calculateGrossSalary(payroll, selectedDivision))}</div>;
      case "deductions":
        return <div className="text-right text-sm font-bold text-red-600">-{formatCurrency(calculateTotalDeductions(payroll, selectedDivision))}</div>;
      case "net_salary":
        return <div className="text-right text-sm font-bold text-[#419cc3]">{formatCurrency(payroll.net_salary)}</div>;
      case "status":
        return (
          <div className="flex justify-center">
            <span className={`inline-flex items-center px-3 py-1 rounded-full text-xs font-semibold border ${getStatusBadge(payroll.status)}`}>
              {payroll.status.charAt(0).toUpperCase() + payroll.status.slice(1)}
            </span>
          </div>
        );
      case "actions":
        return (
          <div className="flex items-center justify-center gap-1">
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
                  const endpoint = ['fnb'].includes(selectedDivision)
                    ? `/payrolls/fnb/${payroll.id}/slip`
                    : ['minimarket', 'reflexiology', 'wrapping', 'hans', 'cellular', 'money_changer'].includes(selectedDivision)
                      ? `/payrolls/retail/${payroll.id}/slip?division_type=${selectedDivision}`
                      : selectedDivision === 'office'
                        ? `/payrolls/ho/${payroll.id}/slip`
                        : `/payrolls/${payroll.id}/slip`;

                  const response = await apiClient.get(endpoint, {
                    responseType: 'blob',
                  });
                  const url = window.URL.createObjectURL(new Blob([response.data]));
                  const link = document.createElement('a');
                  link.href = url;
                  const periodStr = payroll.period || payroll.period_start;
                  const dateStr = periodStr ? new Date(periodStr).toLocaleDateString('id-ID', { month: 'short', year: 'numeric' }) : 'Unknown';
                  link.setAttribute('download', `Slip_Gaji_${payroll.employee?.full_name}_${dateStr}.pdf`);
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

            {['pending', 'draft'].includes(payroll.status) && (
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
            {payroll.status === 'draft' && (
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
        );
      default:
        return null;
    }
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
              <h1 className="text-3xl font-bold bg-gradient-to-r from-[#419cc3] to-[#93C5FD] bg-clip-text text-transparent">
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
                className="flex items-center gap-2 px-6 py-3 bg-white border-2 border-[#89b4e1] text-[#419cc3] rounded-xl font-semibold hover:bg-[#89b4e1] hover:text-[#419cc3] transition-all transform hover:scale-[1.02]"
              >
                <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 10v6m0 0l-3-3m3 3l3-3m2 8H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
                </svg>
                Download Template
              </button>
              <button
                onClick={() => router.push('/payroll/import')}
                className="flex items-center gap-2 px-6 py-3 bg-gradient-to-r from-[#89b4e1] to-[#93C5FD] text-[#419cc3] rounded-xl font-semibold hover:shadow-lg transition-all transform hover:scale-[1.02]"
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

      <div className="px-8 pt-4 pb-2">
        <div className="w-[400px]">
          <NavTabs 
            activeValue="data" 
            tabs={[
              { label: "Data Payroll", value: "data", href: "/payroll" },
              { label: "Import / Export", value: "import", href: "/payroll/import" }
            ]} 
          />
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
              onChange={(e) => setSelectedDivision(e.target.value as any)}
              className="px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:border-[#419cc3] text-sm font-medium"
            >
              <option value="all">Semua Divisi (Bulk Download)</option>
              {!isAdminHr && <option value="office">Office (Pusat)</option>}
              <option value="fnb">FnB</option>
                                          <option value="minimarket">Minimarket</option>
              <option value="reflexiology">Reflexiology</option>
              <option value="wrapping">Wrapping</option>
              <option value="hans">Hans</option>
              <option value="cellular">Cellular</option>
              <option value="money_changer">Money Changer</option>
            </select>
          </div>

          <div className="flex items-center gap-2 flex-grow max-w-sm px-4">
             <div className="w-full">
                <Input
                  isClearable
                  classNames={{
                    inputWrapper: "border border-gray-300 bg-white hover:bg-gray-50 focus-within:ring-2 focus-within:ring-[#419cc3]",
                  }}
                  placeholder="Cari nama karyawan..."
                  startContent={<Search className="text-gray-400" size={18} />}
                  value={searchQuery}
                  onClear={() => setSearchQuery('')}
                  onChange={(e) => setSearchQuery(e.target.value)}
                />
             </div>
          </div>

          {/* Period Filter */}
          <div className="flex items-center gap-2">
            <span className="text-sm font-semibold text-gray-700">Periode:</span>
            <select
              value={selectedMonth}
              onChange={(e) => setSelectedMonth(Number(e.target.value))}
              className="px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:border-[#419cc3] text-sm"
            >
              <option value={0}>Semua Bulan</option>
              {months.map((m) => (
                <option key={m.value} value={m.value}>{m.label}</option>
              ))}
            </select>
            <select
              value={selectedYear}
              onChange={(e) => setSelectedYear(Number(e.target.value))}
              className="px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:border-[#419cc3] text-sm"
            >
              <option value={0}>Semua Tahun</option>
              {[2024, 2025, 2026, 2027].map((y) => (
                <option key={y} value={y}>{y}</option>
              ))}
            </select>
            {/* Bulk Download Button */}
            <button
              onClick={handleBulkDownload}
              className="ml-2 flex items-center gap-2 px-4 py-2 bg-[#419cc3] text-white rounded-lg hover:bg-[#2d1e24] transition-colors"
              title="Download All Payslips as ZIP"
            >
              <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-4l-4 4m0 0l-4-4m4 4V4" />
              </svg>
              ZIP
            </button>
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
            {payrolls.some(p => ['pending', 'draft'].includes(p.status)) && (
              <button
                onClick={async () => {
                  if (!confirm('Are you sure you want to approve all pending payrolls for this period?')) return;

                  try {
                    setLoading(true);
                    if (selectedMonth === 0 || selectedYear === 0) {
                      alert('Please select specific Month and Year to approve all.');
                      setLoading(false);
                      return;
                    }

                    const response = await apiClient.post('/payrolls/approve-all', {
                      month: selectedMonth,
                      year: selectedYear,
                      division: selectedDivision === 'all' ? 'office' : selectedDivision
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
              <div className="w-8 h-8 border-4 border-[#89b4e1] border-t-transparent rounded-full animate-spin"></div>
            </div>
          ) : payrolls.length === 0 ? (
            <div className="text-center py-12">
              <p className="text-gray-500">Belum ada data payroll</p>
              <p className="text-gray-400 text-sm mt-1">Upload file Excel untuk memulai</p>
            </div>
          ) : (
            <div className="p-4">
              <DataTable
                columns={columns}
                data={payrolls}
                renderCell={renderCell}
                page={currentPage}
                pages={lastPage}
                onPageChange={(page) => setCurrentPage(page)}
                selectionMode="multiple"
                selectedKeys={new Set(selectedIds.map(String))}
                onSelectionChange={(keys) => {
                  if (keys === "all") {
                    const pendingIds = payrolls
                      .filter(p => ['pending', 'draft'].includes(p.status))
                      .map(p => Number(p.id));
                    setSelectedIds(pendingIds);
                  } else {
                    setSelectedIds(Array.from(keys).map(Number));
                  }
                }}
                disabledKeys={disabledKeys}
              />
            </div>
          )}
        </div>
      </div>

      {/* Detail Modal */}
      <PayrollDetailModal
        selectedPayroll={selectedPayroll}
        selectedDivision={selectedDivision}
        isOpen={!!selectedPayroll}
        onClose={() => setSelectedPayroll(null)}
        onApprove={(id) => {
            setPendingApprovalId(Number(id));
            setIsBulkApproval(false);
            setShowSignatureModal(true);
        }}
      />

      {/* Signature Modal */}
      <SignatureModal
        show={showSignatureModal}
        onClose={() => setShowSignatureModal(false)}
        isBulkApproval={isBulkApproval}
        selectedIdsLength={selectedIds.length}
        onApprove={handleConfirmApproval}
      />
    </DashboardLayout>
  );
}
