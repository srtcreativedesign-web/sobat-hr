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
  education?: string;
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

  useEffect(() => {
    checkAuth();
  }, [checkAuth]);

  useEffect(() => {
    if (!isAuthenticated) {
      router.push('/login');
      return;
    }

    fetchEmployees();
    fetchOrganizations();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [isAuthenticated, router]);

  const fetchEmployees = async () => {
    try {
      setLoading(true);
      const params = new URLSearchParams();
      if (searchTerm) params.append('search', searchTerm);
      if (filterOrg) params.append('organization_id', filterOrg);
      if (filterStatus) params.append('status', filterStatus);

      const response = await apiClient.get(`/employees?${params.toString()}`);
      setEmployees(response.data.data || response.data || []);
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

  return (
    <DashboardLayout>
      <div className="p-6">
        {/* Header */}
        <div className="mb-6">
          <h1 className="text-3xl font-bold text-gray-900 mb-2">Data Karyawan</h1>
          <p className="text-gray-600">Kelola data karyawan dan informasi kepegawaian</p>
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
      </div>

      {/* Detail Modal */}
      {showModal && selectedEmployee && (
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
              <div className="bg-gradient-to-r from-[#a9eae2] to-[#729892] rounded-lg p-6 text-[#462e37]">>
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
                    <p className="font-medium">{selectedEmployee.email || '-'}</p>
                  </div>
                  <div>
                    <label className="text-sm text-gray-500">No. Telepon</label>
                    <p className="font-medium">{selectedEmployee.phone || '-'}</p>
                  </div>
                  <div>
                    <label className="text-sm text-gray-500">Tempat Lahir</label>
                    <p className="font-medium">{selectedEmployee.place_of_birth || '-'}</p>
                  </div>
                  <div>
                    <label className="text-sm text-gray-500">Tanggal Lahir</label>
                    <p className="font-medium">{formatDate(selectedEmployee.birth_date)}</p>
                  </div>
                  <div>
                    <label className="text-sm text-gray-500">Jenis Kelamin</label>
                    <p className="font-medium">{getGenderLabel(selectedEmployee.gender)}</p>
                  </div>
                  <div>
                    <label className="text-sm text-gray-500">Agama</label>
                    <p className="font-medium">{selectedEmployee.religion || '-'}</p>
                  </div>
                  <div>
                    <label className="text-sm text-gray-500">Status Perkawinan</label>
                    <p className="font-medium">{selectedEmployee.marital_status || '-'}</p>
                  </div>
                  <div>
                    <label className="text-sm text-gray-500">Status PTKP</label>
                    <p className="font-medium">{selectedEmployee.ptkp_status || '-'}</p>
                  </div>
                </div>
              </div>

              {/* Address */}
              <div>
                <h4 className="text-lg font-semibold text-gray-900 mb-4">Alamat</h4>
                <div className="grid grid-cols-1 gap-4">
                  <div>
                    <label className="text-sm text-gray-500">Alamat KTP</label>
                    <p className="font-medium">{selectedEmployee.ktp_address || '-'}</p>
                  </div>
                  <div>
                    <label className="text-sm text-gray-500">Alamat Domisili</label>
                    <p className="font-medium">{selectedEmployee.current_address || '-'}</p>
                  </div>
                </div>
              </div>

              {/* Identity & Finance */}
              <div>
                <h4 className="text-lg font-semibold text-gray-900 mb-4">Data Identitas & Keuangan</h4>
                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                  <div>
                    <label className="text-sm text-gray-500">NIK (KTP)</label>
                    <p className="font-medium">{selectedEmployee.nik || '-'}</p>
                  </div>
                  <div>
                    <label className="text-sm text-gray-500">NPWP</label>
                    <p className="font-medium">{selectedEmployee.npwp || '-'}</p>
                  </div>
                  <div>
                    <label className="text-sm text-gray-500">No. Rekening</label>
                    <p className="font-medium">{selectedEmployee.bank_account_number || '-'}</p>
                  </div>
                  <div>
                    <label className="text-sm text-gray-500">Nama Pemilik Rekening</label>
                    <p className="font-medium">{selectedEmployee.bank_account_name || '-'}</p>
                  </div>
                </div>
              </div>

              {/* Family */}
              <div>
                <h4 className="text-lg font-semibold text-gray-900 mb-4">Data Keluarga</h4>
                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                  <div>
                    <label className="text-sm text-gray-500">Nama Ayah</label>
                    <p className="font-medium">{selectedEmployee.father_name || '-'}</p>
                  </div>
                  <div>
                    <label className="text-sm text-gray-500">Nama Ibu</label>
                    <p className="font-medium">{selectedEmployee.mother_name || '-'}</p>
                  </div>
                  <div>
                    <label className="text-sm text-gray-500">Nama Pasangan</label>
                    <p className="font-medium">{selectedEmployee.spouse_name || '-'}</p>
                  </div>
                  <div>
                    <label className="text-sm text-gray-500">Kontak Keluarga</label>
                    <p className="font-medium">{selectedEmployee.family_contact_number || '-'}</p>
                  </div>
                </div>
              </div>

              {/* Employment */}
              <div>
                <h4 className="text-lg font-semibold text-gray-900 mb-4">Data Kepegawaian</h4>
                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                  <div>
                    <label className="text-sm text-gray-500">Tanggal Bergabung</label>
                    <p className="font-medium">{formatDate(selectedEmployee.join_date)}</p>
                  </div>
                  <div>
                    <label className="text-sm text-gray-500">Pendidikan</label>
                    <p className="font-medium">{selectedEmployee.education || '-'}</p>
                  </div>
                  <div>
                    <label className="text-sm text-gray-500">Divisi/Departemen</label>
                    <p className="font-medium">{selectedEmployee.level || '-'}</p>
                  </div>
                  <div>
                    <label className="text-sm text-gray-500">Status Kepegawaian</label>
                    <p className="font-medium">{selectedEmployee.employment_status || '-'}</p>
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
                    <p className="font-medium">{formatCurrency(selectedEmployee.basic_salary)}</p>
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
      )}
    </DashboardLayout>
  );
}
