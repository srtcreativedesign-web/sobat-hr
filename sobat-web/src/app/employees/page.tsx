'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { useAuthStore } from '@/store/auth-store';
import DashboardLayout from '@/components/DashboardLayout';
import apiClient from '@/lib/api-client';

interface Employee {
  id: number;
  employee_code: string;
  full_name: string;
  email: string;
  phone: string;
  position: string;
  level?: string;
  organization?: {
    id: number;
    name: string;
  };
  status: 'active' | 'inactive' | 'resigned';
  join_date: string;
  birth_date?: string;
  place_of_birth?: string;
  gender?: 'male' | 'female';
  religion?: string;
  marital_status?: string;
  ptkp_status?: string;
  nik?: string;
  npwp?: string;
  bank_account_number?: string;
  bank_account_name?: string;
  ktp_address?: string;
  current_address?: string;
  father_name?: string;
  mother_name?: string;
  spouse_name?: string;
  family_contact_number?: string;
  education?: any;
  supervisor_name?: string;
  supervisor_position?: string;
  basic_salary?: number;
  employment_status?: string;
}

interface Organization {
  id: number;
  name: string;
}

export default function EmployeesPage() {
  const router = useRouter();
  const { isAuthenticated, checkAuth } = useAuthStore();
  const [employees, setEmployees] = useState<Employee[]>([]);
  const [organizations, setOrganizations] = useState<Organization[]>([]);
  const [loading, setLoading] = useState(false);
  const [showModal, setShowModal] = useState(false);
  const [selectedEmployee, setSelectedEmployee] = useState<Employee | null>(null);
  const [searchTerm, setSearchTerm] = useState('');
  const [filterOrg, setFilterOrg] = useState('');
  const [filterStatus, setFilterStatus] = useState('');
  const [currentPage, setCurrentPage] = useState(1);
  const [totalPages, setTotalPages] = useState(1);
  const [totalItems, setTotalItems] = useState(0);

  // Import State
  const [showImportModal, setShowImportModal] = useState(false);
  const [importFile, setImportFile] = useState<File | null>(null);
  const [uploading, setUploading] = useState(false);

  useEffect(() => {
    checkAuth();
  }, [checkAuth]);

  useEffect(() => {
    fetchEmployees();
    fetchOrganizations();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [currentPage]); // Re-fetch when currentPage changes

  const fetchEmployees = async () => {
    try {
      setLoading(true);
      const params = new URLSearchParams();
      params.append('page', currentPage.toString());
      if (searchTerm) params.append('search', searchTerm);
      if (filterOrg) params.append('organization_id', filterOrg);
      if (filterStatus) params.append('status', filterStatus);

      const response = await apiClient.get(`/employees?${params.toString()}`);
      setEmployees(response.data.data || []);
      // API Paginated Response (Laravel default)
      if (response.data.current_page) {
        setCurrentPage(response.data.current_page);
        setTotalPages(response.data.last_page);
        setTotalItems(response.data.total);
      }
    } catch (error) {
      console.error('Failed to fetch employees:', error);
    } finally {
      setLoading(false);
    }
  };

  const fetchOrganizations = async () => {
    try {
      const response = await apiClient.get('/organizations');
      setOrganizations(response.data.data || response.data || []);
    } catch (error) {
      console.error('Failed to fetch organizations:', error);
    }
  };

  const handleSearch = (e: React.FormEvent) => {
    e.preventDefault();
    setCurrentPage(1); // Reset to page 1 on search
    fetchEmployees();
  };

  const handleViewDetails = (employee: Employee) => {
    setSelectedEmployee(employee);
    setShowModal(true);
  };

  const handleCloseModal = () => {
    setShowModal(false);
    setSelectedEmployee(null);
  };

  const handleImportSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!importFile) return;

    const formData = new FormData();
    formData.append('file', importFile);

    try {
      setUploading(true);
      const response = await apiClient.post('/employees/import-master', formData, {
        headers: { 'Content-Type': 'multipart/form-data' }
      });
      alert(`Import Berhasil! \nCreated: ${response.data.created}\nSkipped: ${response.data.skipped}`);
      setShowImportModal(false);
      setImportFile(null);
      fetchEmployees();
    } catch (error: any) {
      console.error('Import Error:', error);
      alert(error.response?.data?.message || 'Gagal mengimport data.');
    } finally {
      setUploading(false);
    }
  };

  const formatDate = (dateString: string | undefined) => {
    if (!dateString) return '-';
    return new Date(dateString).toLocaleDateString('id-ID', {
      day: 'numeric',
      month: 'long',
      year: 'numeric'
    });
  };

  const formatCurrency = (amount: number | undefined) => {
    if (!amount) return '-';
    return new Intl.NumberFormat('id-ID', {
      style: 'currency',
      currency: 'IDR',
      minimumFractionDigits: 0
    }).format(amount);
  };

  const getStatusBadge = (status: string) => {
    const styles = {
      active: 'bg-green-100 text-green-800',
      inactive: 'bg-gray-100 text-gray-800',
      resigned: 'bg-red-100 text-red-800'
    };
    return styles[status as keyof typeof styles] || styles.inactive;
  };

  const getGenderLabel = (gender: string | undefined) => {
    if (gender === 'male') return 'Laki-laki';
    if (gender === 'female') return 'Perempuan';
    return '-';
  };

  const formatEducation = (edu: any) => {
    if (!edu) return '-';
    if (typeof edu === 'string') return edu;
    if (typeof edu === 'object') {
      if (edu.s3) return `S3`;
      if (edu.s2) return `S2`;
      if (edu.s1) return `S1`;
      if (edu.smk) return `SMA/SMK`;
      if (edu.smp) return `SMP`;
      if (edu.sd) return `SD`;
      return '-';
    }
    return '-';
  };

  const renderEducationDetails = (edu: any) => {
    if (!edu) return '-';
    if (typeof edu === 'string') return edu;
    if (typeof edu === 'object') {
      const levels = [
        { key: 's3', label: 'S3' },
        { key: 's2', label: 'S2' },
        { key: 's1', label: 'S1' },
        { key: 'smk', label: 'SMA/SMK' },
        { key: 'smp', label: 'SMP' },
        { key: 'sd', label: 'SD' },
      ];

      const filledLevels = levels.filter(l => edu[l.key]);

      if (filledLevels.length === 0) return '-';

      return (
        <div className="flex flex-col gap-1 mt-1">
          {filledLevels.map(l => (
            <div key={l.key} className="text-sm">
              <span className="font-semibold text-gray-600 mr-2">{l.label}:</span>
              <span>{edu[l.key]}</span>
            </div>
          ))}
        </div>
      );
    }
    return '-';
  };

  return (
    <DashboardLayout>
      <div className="p-6">
        {/* Header */}
        <div className="mb-6 flex justify-between items-end">
          <div>
            <h1 className="text-3xl font-bold text-gray-900 mb-2">Data Karyawan</h1>
            <p className="text-gray-600">Kelola data karyawan dan informasi kepegawaian</p>
          </div>
          <button
            onClick={() => setShowImportModal(true)}
            className="px-4 py-2 bg-[#462e37] text-[#a9eae2] rounded-lg hover:bg-[#2d1e24] transition-colors font-medium flex items-center gap-2"
          >
            <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-8l-4-4m0 0L8 8m4-4v12" />
            </svg>
            Import Master Data
          </button>
        </div>

        {/* Filters */}
        <div className="bg-white rounded-xl shadow-sm p-6 mb-6">
          <form onSubmit={handleSearch} className="space-y-4">
            <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Cari Karyawan
                </label>
                <input
                  type="text"
                  placeholder="Nama atau NIK..."
                  value={searchTerm}
                  onChange={(e) => setSearchTerm(e.target.value)}
                  className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-[#462e37] focus:border-transparent"
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Divisi
                </label>
                <select
                  value={filterOrg}
                  onChange={(e) => setFilterOrg(e.target.value)}
                  className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-[#462e37] focus:border-transparent"
                >
                  <option value="">Semua Divisi</option>
                  {organizations.map(org => (
                    <option key={org.id} value={org.id}>{org.name}</option>
                  ))}
                </select>
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Status
                </label>
                <select
                  value={filterStatus}
                  onChange={(e) => setFilterStatus(e.target.value)}
                  className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-[#462e37] focus:border-transparent"
                >
                  <option value="">Semua Status</option>
                  <option value="active">Aktif</option>
                  <option value="inactive">Tidak Aktif</option>
                  <option value="resigned">Resign</option>
                </select>
              </div>

              <div className="flex items-end">
                <button
                  type="submit"
                  className="w-full px-6 py-2 bg-[#a9eae2] text-[#462e37] rounded-lg hover:bg-[#729892] transition-colors"
                >
                  Cari
                </button>
              </div>
            </div>
          </form>
        </div>

        {/* Table */}
        <div className="bg-white rounded-xl shadow-sm overflow-hidden">
          {loading ? (
            <div className="p-12 text-center">
              <div className="inline-block animate-spin rounded-full h-12 w-12 border-4 border-[#a9eae2] border-t-transparent"></div>
              <p className="mt-4 text-gray-600">Memuat data...</p>
            </div>
          ) : employees.length === 0 ? (
            <div className="p-12 text-center">
              <svg className="mx-auto h-12 w-12 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z" />
              </svg>
              <p className="mt-4 text-gray-600">Tidak ada data karyawan</p>
            </div>
          ) : (
            <div className="overflow-x-auto">
              <table className="min-w-full divide-y divide-gray-200">
                <thead className="bg-gray-50">
                  <tr>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      NIK
                    </th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Nama Lengkap
                    </th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Jabatan
                    </th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Divisi
                    </th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Status
                    </th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Aksi
                    </th>
                  </tr>
                </thead>
                <tbody className="bg-white divide-y divide-gray-200">
                  {employees.map((employee) => (
                    <tr key={employee.id} className="hover:bg-gray-50">
                      <td className="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900">
                        {employee.employee_code}
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        <div className="text-sm font-medium text-gray-900">{employee.full_name}</div>
                        <div className="text-sm text-gray-500">{employee.email}</div>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                        {employee.position}
                        {employee.level && <div className="text-xs text-gray-500">{employee.level}</div>}
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                        {employee.organization?.name || '-'}
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        <span className={`px-3 py-1 inline-flex text-xs leading-5 font-semibold rounded-full ${getStatusBadge(employee.status)}`}>
                          {employee.status === 'active' ? 'Aktif' : employee.status === 'inactive' ? 'Tidak Aktif' : 'Resign'}
                        </span>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-sm font-medium">
                        <button
                          onClick={() => handleViewDetails(employee)}
                          className="text-[#462e37] hover:text-[#2d1e24] font-medium"
                        >
                          Detail
                        </button>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </div>

        {/* Pagination Controls */}
        {!loading && employees.length > 0 && (
          <div className="bg-white px-4 py-3 flex items-center justify-between border-t border-gray-200 sm:px-6">
            <div className="hidden sm:flex-1 sm:flex sm:items-center sm:justify-between">
              <div>
                <p className="text-sm text-gray-700">
                  Menampilkan <span className="font-medium">{(currentPage - 1) * 20 + 1}</span> sampai <span className="font-medium">{Math.min(currentPage * 20, totalItems)}</span> dari <span className="font-medium">{totalItems}</span> hasil
                </p>
              </div>
              <div>
                <nav className="relative z-0 inline-flex rounded-md shadow-sm -space-x-px" aria-label="Pagination">
                  <button
                    onClick={() => setCurrentPage(prev => Math.max(prev - 1, 1))}
                    disabled={currentPage === 1}
                    className="relative inline-flex items-center px-2 py-2 rounded-l-md border border-gray-300 bg-white text-sm font-medium text-gray-500 hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed"
                  >
                    <span className="sr-only">Previous</span>
                    <svg className="h-5 w-5" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor" aria-hidden="true">
                      <path fillRule="evenodd" d="M12.707 5.293a1 1 0 010 1.414L9.414 10l3.293 3.293a1 1 0 01-1.414 1.414l-4-4a1 1 0 010-1.414l4-4a1 1 0 011.414 0z" clipRule="evenodd" />
                    </svg>
                  </button>
                  <span className="relative inline-flex items-center px-4 py-2 border border-gray-300 bg-white text-sm font-medium text-gray-700">
                    Hal. {currentPage} dari {totalPages}
                  </span>
                  <button
                    onClick={() => setCurrentPage(prev => Math.min(prev + 1, totalPages))}
                    disabled={currentPage === totalPages}
                    className="relative inline-flex items-center px-2 py-2 rounded-r-md border border-gray-300 bg-white text-sm font-medium text-gray-500 hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed"
                  >
                    <span className="sr-only">Next</span>
                    <svg className="h-5 w-5" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor" aria-hidden="true">
                      <path fillRule="evenodd" d="M7.293 14.707a1 1 0 010-1.414L10.586 10 7.293 6.707a1 1 0 011.414-1.414l4 4a1 1 0 010 1.414l-4 4a1 1 0 01-1.414 0z" clipRule="evenodd" />
                    </svg>
                  </button>
                </nav>
              </div>
            </div>
          </div>
        )}
      </div>

      {/* Detail Modal */}
      {
        showModal && selectedEmployee && (
          <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
            <div className="bg-white rounded-xl max-w-4xl w-full max-h-[90vh] overflow-y-auto">
              {/* Modal Header */}
              <div className="sticky top-0 bg-white border-b border-gray-200 px-6 py-4 flex items-center justify-between">
                <h2 className="text-2xl font-bold text-gray-900">Detail Karyawan</h2>
                <button
                  onClick={handleCloseModal}
                  className="text-gray-400 hover:text-gray-600"
                >
                  <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                  </svg>
                </button>
              </div>

              {/* Modal Content */}
              <div className="p-6 space-y-6">
                {/* Basic Info */}
                <div className="bg-gradient-to-r from-[#a9eae2] to-[#729892] rounded-lg p-6 text-[#462e37]">
                  <div className="flex items-center gap-4">
                    <div className="w-20 h-20 rounded-full bg-white/20 flex items-center justify-center text-3xl font-bold">
                      {selectedEmployee.full_name.charAt(0).toUpperCase()}
                    </div>
                    <div>
                      <h3 className="text-2xl font-bold">{selectedEmployee.full_name}</h3>
                      <p className="text-[#462e37] font-semibold">{selectedEmployee.employee_code}</p>
                      <p className="text-sm mt-1">{selectedEmployee.position} • {selectedEmployee.organization?.name}</p>
                    </div>
                  </div>
                </div>

                {/* Personal Data */}
                <div>
                  <h4 className="text-lg font-semibold text-gray-900 mb-4">Data Pribadi</h4>
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                    <div>
                      <label className="text-sm text-gray-500">Email</label>
                      <p className="font-medium text-gray-900">{selectedEmployee.email || '-'}</p>
                    </div>
                    <div>
                      <label className="text-sm text-gray-500">No. Telepon</label>
                      <p className="font-medium text-gray-900">{selectedEmployee.phone || '-'}</p>
                    </div>
                    <div>
                      <label className="text-sm text-gray-500">Tempat Lahir</label>
                      <p className="font-medium text-gray-900">{selectedEmployee.place_of_birth || '-'}</p>
                    </div>
                    <div>
                      <label className="text-sm text-gray-500">Tanggal Lahir</label>
                      <p className="font-medium text-gray-900">{formatDate(selectedEmployee.birth_date)}</p>
                    </div>
                    <div>
                      <label className="text-sm text-gray-500">Jenis Kelamin</label>
                      <p className="font-medium text-gray-900">{getGenderLabel(selectedEmployee.gender)}</p>
                    </div>
                    <div>
                      <label className="text-sm text-gray-500">Agama</label>
                      <p className="font-medium text-gray-900">{selectedEmployee.religion || '-'}</p>
                    </div>
                    <div>
                      <label className="text-sm text-gray-500">Status Perkawinan</label>
                      <p className="font-medium text-gray-900">{selectedEmployee.marital_status || '-'}</p>
                    </div>
                    <div>
                      <label className="text-sm text-gray-500">Status PTKP</label>
                      <p className="font-medium text-gray-900">{selectedEmployee.ptkp_status || '-'}</p>
                    </div>
                  </div>
                </div>

                {/* Address */}
                <div>
                  <h4 className="text-lg font-semibold text-gray-900 mb-4">Alamat</h4>
                  <div className="grid grid-cols-1 gap-4">
                    <div>
                      <label className="text-sm text-gray-500">Alamat KTP</label>
                      <p className="font-medium text-gray-900">{selectedEmployee.ktp_address || '-'}</p>
                    </div>
                    <div>
                      <label className="text-sm text-gray-500">Alamat Domisili</label>
                      <p className="font-medium text-gray-900">{selectedEmployee.current_address || '-'}</p>
                    </div>
                  </div>
                </div>

                {/* Identity & Finance */}
                <div>
                  <h4 className="text-lg font-semibold text-gray-900 mb-4">Data Identitas & Keuangan</h4>
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                    <div>
                      <label className="text-sm text-gray-500">NIK (KTP)</label>
                      <p className="font-medium text-gray-900">{selectedEmployee.nik || '-'}</p>
                    </div>
                    <div>
                      <label className="text-sm text-gray-500">NPWP</label>
                      <p className="font-medium text-gray-900">{selectedEmployee.npwp || '-'}</p>
                    </div>
                    <div>
                      <label className="text-sm text-gray-500">No. Rekening</label>
                      <p className="font-medium text-gray-900">{selectedEmployee.bank_account_number || '-'}</p>
                    </div>
                    <div>
                      <label className="text-sm text-gray-500">Nama Pemilik Rekening</label>
                      <p className="font-medium text-gray-900">{selectedEmployee.bank_account_name || '-'}</p>
                    </div>
                  </div>
                </div>

                {/* Family */}
                <div>
                  <h4 className="text-lg font-semibold text-gray-900 mb-4">Data Keluarga</h4>
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                    <div>
                      <label className="text-sm text-gray-500">Nama Ayah</label>
                      <p className="font-medium text-gray-900">{selectedEmployee.father_name || '-'}</p>
                    </div>
                    <div>
                      <label className="text-sm text-gray-500">Nama Ibu</label>
                      <p className="font-medium text-gray-900">{selectedEmployee.mother_name || '-'}</p>
                    </div>
                    <div>
                      <label className="text-sm text-gray-500">Nama Pasangan</label>
                      <p className="font-medium text-gray-900">{selectedEmployee.spouse_name || '-'}</p>
                    </div>
                    <div>
                      <label className="text-sm text-gray-500">Kontak Keluarga</label>
                      <p className="font-medium text-gray-900">{selectedEmployee.family_contact_number || '-'}</p>
                    </div>
                  </div>
                </div>

                {/* Employment */}
                <div>
                  <h4 className="text-lg font-semibold text-gray-900 mb-4">Data Kepegawaian</h4>
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                    <div>
                      <label className="text-sm text-gray-500">Tanggal Bergabung</label>
                      <p className="font-medium text-gray-900">{formatDate(selectedEmployee.join_date)}</p>
                    </div>
                    <div>
                      <label className="text-sm text-gray-500">Pendidikan</label>
                      <div className="font-medium text-gray-900">{renderEducationDetails(selectedEmployee.education)}</div>
                    </div>
                    <div>
                      <label className="text-sm text-gray-500">Divisi/Departemen</label>
                      <p className="font-medium text-gray-900">{selectedEmployee.level || '-'}</p>
                    </div>
                    <div>
                      <label className="text-sm text-gray-500">Status Kepegawaian</label>
                      <p className="font-medium text-gray-900">{selectedEmployee.employment_status || '-'}</p>
                    </div>
                    <div>
                      <label className="text-sm text-gray-500">Nama Atasan</label>
                      <p className="font-medium">{selectedEmployee.supervisor_name || '-'}</p>
                    </div>
                    <div>
                      <label className="text-sm text-gray-500">Jabatan Atasan</label>
                      <p className="font-medium">{selectedEmployee.supervisor_position || '-'}</p>
                    </div>
                    <div>
                      <label className="text-sm text-gray-500">Gaji Pokok</label>
                      <p className="font-medium text-gray-900">{formatCurrency(selectedEmployee.basic_salary)}</p>
                    </div>
                    <div>
                      <label className="text-sm text-gray-500">Status</label>
                      <span className={`px-3 py-1 inline-flex text-xs leading-5 font-semibold rounded-full ${getStatusBadge(selectedEmployee.status)}`}>
                        {selectedEmployee.status === 'active' ? 'Aktif' : selectedEmployee.status === 'inactive' ? 'Tidak Aktif' : 'Resign'}
                      </span>
                    </div>
                  </div>
                </div>
              </div>

              {/* Modal Footer */}
              <div className="sticky bottom-0 bg-gray-50 border-t border-gray-200 px-6 py-4 flex justify-end">
                <button
                  onClick={handleCloseModal}
                  className="px-6 py-2 bg-gray-600 text-white rounded-lg hover:bg-gray-700 transition-colors"
                >
                  Tutup
                </button>
              </div>
            </div>
          </div>
        )
      }
      {/* Import Modal */}
      {
        showImportModal && (
          <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
            <div className="bg-white rounded-xl max-w-md w-full p-6">
              <h3 className="text-xl font-bold text-gray-900 mb-4">Import Master Data Karyawan</h3>
              <p className="text-sm text-gray-600 mb-4">
                Upload file Excel (.xlsx) berisi data master karyawan.
                Pastikan ada kolom: <b>Nama, NIK, Divisi, Jabatan, No HP</b>.
              </p>

              <form onSubmit={handleImportSubmit}>
                <div className="mb-4">
                  <label className="block text-sm font-medium text-gray-700 mb-2">File Excel</label>
                  <input
                    type="file"
                    accept=".xlsx, .xls"
                    onChange={(e) => setImportFile(e.target.files ? e.target.files[0] : null)}
                    className="w-full border border-gray-300 rounded-lg p-2"
                    required
                  />
                </div>

                <div className="flex justify-end gap-2 mt-6">
                  <button
                    type="button"
                    onClick={() => setShowImportModal(false)}
                    className="px-4 py-2 text-gray-600 hover:text-gray-800"
                    disabled={uploading}
                  >
                    Batal
                  </button>
                  <button
                    type="submit"
                    disabled={!importFile || uploading}
                    className="px-4 py-2 bg-[#462e37] text-[#a9eae2] rounded-lg hover:bg-[#2d1e24] disabled:opacity-50 flex items-center gap-2"
                  >
                    {uploading ? (
                      <>
                        <div className="w-4 h-4 border-2 border-[#a9eae2] border-t-transparent rounded-full animate-spin"></div>
                        Memproses...
                      </>
                    ) : 'Upload & Import'}
                  </button>
                </div>
              </form>
            </div>
          </div>
        )
      }
    </DashboardLayout >
  );
}
