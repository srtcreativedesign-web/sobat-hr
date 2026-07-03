'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { useAuthStore } from '@/store/auth-store';
import DashboardLayout from '@/components/DashboardLayout';
import apiClient from '@/lib/api-client';
import { NavTabs } from '@/components/ui/tabs';

// Refactored Components
import { Payroll } from '../types';
import { 
  formatCurrency, 
  calculateTotalAllowances, 
  calculateOvertimePay, 
  calculateTotalDeductions, 
  calculateGrossSalary 
} from '../utils';
import SignatureModal from '../components/SignatureModal';
import ImportMappingUI from './components/ImportMappingUI';

export default function ImportPayrollPage() {
  const router = useRouter();
  const { isAuthenticated, checkAuth } = useAuthStore();
  const [payrolls, setPayrolls] = useState<Payroll[]>([]);
  const [loading, setLoading] = useState(false);
  const [showUploadModal, setShowUploadModal] = useState(false);
  const [selectedFile, setSelectedFile] = useState<File | null>(null);
  const [uploadProgress, setUploadProgress] = useState(0);

  const [parsedRows, setParsedRows] = useState<any[]>([]);
  const [selectedIds, setSelectedIds] = useState<number[]>([]);

  // Mapping UI State
  const [showMappingUI, setShowMappingUI] = useState(false);
  const [excelHeaders, setExcelHeaders] = useState<Record<string, string>>({});
  const [columnMapping, setColumnMapping] = useState<Record<string, string>>({});
  const [headerRowIndex, setHeaderRowIndex] = useState<number>(0);

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

  const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    if (e.target.files && e.target.files[0]) {
      setSelectedFile(e.target.files[0]);
    }
  };

  const handleUpload = async () => {
    if (!selectedFile) return;

    const formData = new FormData();
    formData.append('file', selectedFile);

    // If month and year are selected, send it as period
    if (selectedMonth !== 0 && selectedYear !== 0) {
      const period = `${selectedYear}-${String(selectedMonth).padStart(2, '0')}`;
      formData.append('period', period);
    }

    try {
      setUploadProgress(0);
      setParsedRows([]);

      let importEndpoint = '';
      if (selectedDivision === 'office') {
        importEndpoint = '/payrolls/ho/import/parse-headers';
      } else if (['minimarket', 'reflexiology', 'wrapping', 'hans', 'cellular', 'money_changer', 'fnb'].includes(selectedDivision)) {
        importEndpoint = ['fnb'].includes(selectedDivision) ? '/payrolls/fnb/import/parse-headers' : '/payrolls/retail/import/parse-headers';
        formData.append('division_type', selectedDivision);
      }

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

      let data = response.data;
      
      if (data && data.requiresMapping) {
        setExcelHeaders(data.headers || {});
        setColumnMapping(data.default_mapping || {});
        setHeaderRowIndex(data.headerRowIndex || 0);
        setShowMappingUI(true);
        setUploadProgress(100);
        return; // Stop upload flow and wait for manual mapping
      }

      if (data && Array.isArray(data.rows)) {
        setParsedRows(data.rows);
        setUploadProgress(100);
      } else {
        // Handle save response
        if (data.saved === 0 && data.errors && data.errors.length > 0) {
          alert(`Gagal menyimpan data:\n` + data.errors.join(`\n`));
        } else if (data.errors && data.errors.length > 0) {
          alert(`Berhasil menyimpan ${data.saved} data.\nAda beberapa error:\n` + data.errors.join(`\n`));
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

  const handleSimulate = async () => {
    if (!selectedFile) return;
    try {
      setLoading(true);
      const simFormData = new FormData();
      simFormData.append('file', selectedFile);
      simFormData.append('mapping', JSON.stringify(columnMapping));
      simFormData.append('headerRowIndex', headerRowIndex.toString());
      if (selectedMonth !== 0 && selectedYear !== 0) {
        const period = `${selectedYear}-${String(selectedMonth).padStart(2, '0')}`;
        simFormData.append('period', period);
      }
      
      simFormData.append('division_type', selectedDivision);
      let simulateEndpoint = '/payrolls/retail/import/simulate';
      if (selectedDivision === 'office') {
          simulateEndpoint = '/payrolls/ho/import/simulate';
      } else if (selectedDivision === 'fnb') {
          simulateEndpoint = '/payrolls/fnb/import/simulate';
      }
      const simulateResponse = await apiClient.post(simulateEndpoint, simFormData, {
        headers: { 'Content-Type': 'multipart/form-data' }
      });
      const data = simulateResponse.data;
      if (data && Array.isArray(data.rows)) {
        setParsedRows(data.rows);
        setShowMappingUI(false);
      }
    } catch (simError: any) {
      alert(simError.response?.data?.message || 'Gagal simulasi data');
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
        
        
        if (selectedDivision === 'minimarket') endpoint = `/payrolls/mm/${pendingApprovalId}/status`;
        if (selectedDivision === 'reflexiology') endpoint = `/payrolls/ref/${pendingApprovalId}/status`;
        if (selectedDivision === 'wrapping') endpoint = `/payrolls/wrapping/${pendingApprovalId}/status`;
        if (selectedDivision === 'hans') endpoint = `/payrolls/hans/${pendingApprovalId}/status`;
        if (selectedDivision === 'office') endpoint = `/payrolls/ho/${pendingApprovalId}/status`;
        if (selectedDivision === 'cellular') endpoint = `/payroll-cellullers/${pendingApprovalId}/status`;
        if (selectedDivision === 'money_changer') endpoint = `/payrolls/money-changer/${pendingApprovalId}/status`;

        await apiClient.patch(endpoint, {
          status: 'approved',
          approval_signature: signatureData,
          signer_name: signerName,
          notes: approvalNotes
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
              
            </div>
          </div>
        </div>
      </div>

      {/* Sub Navigation Tabs */}
      <div className="px-8 pt-4 pb-2">
        <div className="w-[400px]">
          <NavTabs 
            activeValue="import" 
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
              <option value="office">Office (Pusat)</option>
              <option value="fnb">FnB</option>
                                          <option value="minimarket">Minimarket</option>
              <option value="reflexiology">Reflexiology</option>
              <option value="wrapping">Wrapping</option>
              <option value="hans">Hans</option>
              <option value="cellular">Cellular</option>
              <option value="money_changer">Money Changer</option>
            </select>
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

      {/* Upload Modal Content area inline in main page */}
      <div className="p-8 max-w-5xl mx-auto">
        <div className="bg-white rounded-2xl shadow-sm border border-gray-200 p-8">
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
              <div className="border-2 border-dashed border-gray-300 rounded-xl p-6 text-center hover:border-[#89b4e1] transition-colors">
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
                  <span className="text-[#419cc3] font-semibold">{uploadProgress}%</span>
                </div>
                <div className="w-full bg-gray-200 rounded-full h-2">
                  <div
                    className="bg-gradient-to-r from-[#89b4e1] to-[#93C5FD] h-2 rounded-full transition-all duration-300"
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
                className="flex-1 px-4 py-3 bg-gradient-to-r from-[#89b4e1] to-[#93C5FD] text-[#419cc3] rounded-xl font-semibold hover:shadow-lg disabled:opacity-50 disabled:cursor-not-allowed transition-all"
              >
                Upload
              </button>
            </div>

            {/* Mapping UI */}
            {showMappingUI && Object.keys(excelHeaders).length > 0 && (
              <ImportMappingUI
                  columnMapping={columnMapping}
                  setColumnMapping={setColumnMapping}
                  excelHeaders={excelHeaders}
                  onSimulate={handleSimulate}
                  onCancel={() => {
                      setShowMappingUI(false);
                      setSelectedFile(null);
                      setUploadProgress(0);
                  }}
              />
            )}

            {/* Parsed Preview */}
            {parsedRows.length > 0 && (
              <div className="mt-6">
                <h4 className="text-sm font-semibold mb-2">Preview Data ({parsedRows.length} baris)</h4>
                <div className="max-h-64 overflow-auto border rounded-lg">
                  <table className="w-full">
                    <thead>
                      <tr className="border-b border-gray-200 bg-gray-50 text-left text-sm font-semibold text-gray-600">
                        <th className="py-3 px-4">Employee</th>
                        <th className="py-3 px-4">Period</th>
                        <th className="text-right py-3 px-4">Basic Salary</th>
                        <th className="text-right py-3 px-4">Total Allowances</th>
                        <th className="text-right py-3 px-4">Overtime</th>
                        <th className="text-right py-3 px-4 font-bold text-gray-700 bg-gray-100">Gross Salary</th>
                        <th className="text-right py-3 px-4 font-bold text-red-600 bg-red-50">Total Deductions</th>
                        <th className="text-right py-3 px-4 font-bold text-[#419cc3]">Net Salary</th>
                        <th className="text-center py-3 px-4">Status</th>
                      </tr>
                    </thead>
                    <tbody>
                      {parsedRows.map((row: any, idx: number) => (
                        <tr key={idx} className="border-b border-gray-100 hover:bg-gray-50 transition-colors">
                          <td className="py-3 px-4">
                            <p className="text-sm font-semibold text-gray-900">{row.employee_name || row.employee?.full_name}</p>
                          </td>
                          <td className="py-3 px-4 text-sm text-gray-900">
                            {row.period
                              ? new Date(row.period + '-01').toLocaleDateString('id-ID', { month: 'short', year: 'numeric' })
                              : new Date().toLocaleDateString('id-ID', { month: 'short', year: 'numeric' })
                            }
                          </td>
                          <td className="py-3 px-4 text-right text-sm text-gray-900">{formatCurrency(row.basic_salary || 0)}</td>
                          <td className="py-3 px-4 text-right text-sm text-gray-900">{formatCurrency(calculateTotalAllowances(row, selectedDivision))}</td>
                          <td className="py-3 px-4 text-right text-sm text-green-600">{formatCurrency(calculateOvertimePay(row, selectedDivision))}</td>
                          <td className="py-3 px-4 text-right text-sm font-bold text-gray-800 bg-gray-50">{formatCurrency(calculateGrossSalary(row, selectedDivision))}</td>
                          <td className="py-3 px-4 text-right text-sm font-bold text-red-600 bg-red-50">-{formatCurrency(calculateTotalDeductions(row, selectedDivision))}</td>
                          <td className="py-3 px-4 text-right text-sm font-bold text-[#419cc3]">{formatCurrency(row.net_salary || 0)}</td>
                          <td className="py-3 px-4 text-center">
                            <span className="inline-flex items-center px-3 py-1 rounded-full text-xs font-semibold border bg-yellow-100 text-yellow-700 border-yellow-200">
                              Preview
                            </span>
                          </td>
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
                        let saveEndpoint = '/payrolls/import/save';
                        if (selectedDivision === 'office') saveEndpoint = '/payrolls/ho/import/save';
                        if (['fnb'].includes(selectedDivision)) saveEndpoint = '/payrolls/fnb/import/save';
                        
                        
                        if (['minimarket', 'reflexiology', 'wrapping', 'hans', 'cellular', 'money_changer'].includes(selectedDivision)) { saveEndpoint = '/payrolls/retail/import/save'; }

                        const response = await apiClient.post(saveEndpoint, {
                          division_type: selectedDivision,
                          rows: parsedRows,
                        });
                        const data = response.data;

                        let message = `Import selesai!`;

                        if (data.summary) {
                          message += `\n\nTotal: ${data.summary.total}\nBerhasil: ${data.summary.saved}\nGagal: ${data.summary.failed}`;
                        }

                        if (data.failed && data.failed.length > 0) {
                          message += `\n\nBaris yang gagal:`;
                          data.failed.slice(0, 5).forEach((fail: any) => {
                            message += `\n- Row ${fail.row}: ${fail.employee_name} - ${fail.reason}`;
                          });
                          if (data.failed.length > 5) {
                            message += `\n... dan ${data.failed.length - 5} lainnya (lihat console)`;
                          }
                        }

                        alert(message);

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
                      }
                    }}
                    className="px-4 py-2 bg-gradient-to-r from-[#89b4e1] to-[#93C5FD] text-[#419cc3] rounded-lg"
                  >
                    Save to DB
                  </button>
                </div>
              </div>
            )}
          </div>
        </div>
      </div>

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
