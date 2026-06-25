'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { useAuthStore } from '@/store/auth-store';
import DashboardLayout from '@/components/DashboardLayout';
import apiClient from '@/lib/api-client';
import Swal from 'sweetalert2';
import { DataTable } from '@/components/ui/data-table';
import { User, Chip, Button, Dropdown, DropdownTrigger, DropdownMenu, DropdownItem, Input } from '@nextui-org/react';
import { Search } from 'lucide-react';

import { Employee } from './types';
import EmployeeDetailModal from './components/EmployeeDetailModal';
import EmployeeImportModal from './components/EmployeeImportModal';
import { formatDate, isExpiringSoon } from './utils';



export default function EmployeesPage() {
  const router = useRouter();
  const { isAuthenticated, checkAuth } = useAuthStore();
  const [employees, setEmployees] = useState<Employee[]>([]);
  const [divisions, setDivisions] = useState<{id: number; name: string}[]>([]);
  const [loading, setLoading] = useState(false);
  const [showModal, setShowModal] = useState(false);
  const [selectedEmployee, setSelectedEmployee] = useState<Employee | null>(null);
  const [searchTerm, setSearchTerm] = useState('');
  const [filterOrg, setFilterOrg] = useState('');
  const [filterStatus, setFilterStatus] = useState('');
  const [filterTrack, setFilterTrack] = useState('');
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
    fetchDivisions();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [currentPage]); // Re-fetch when currentPage changes

  const fetchEmployees = async () => {
    try {
      setLoading(true);
      const params = new URLSearchParams();
      params.append('page', currentPage.toString());
      if (searchTerm) params.append('search', searchTerm);
      if (filterOrg) params.append('division_id', filterOrg);
      if (filterStatus) params.append('status', filterStatus);
      if (filterTrack) params.append('track', filterTrack);

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

  const fetchDivisions = async () => {
    try {
      const response = await apiClient.get('/divisions');
      setDivisions(response.data.data || response.data || []);
    } catch (error) {
      console.error('Failed to fetch divisions:', error);
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

  const handleResetDevice = async (employeeId: number) => {
    try {
      const result = await Swal.fire({
        title: 'Reset Device Binding?',
        text: 'Ini akan mengizinkan karyawan untuk login kembali melalui perangkat baru. Lanjutkan?',
        icon: 'warning',
        showCancelButton: true,
        confirmButtonColor: '#1C3ECA',
        cancelButtonColor: '#d33',
        confirmButtonText: 'Ya, Reset',
        cancelButtonText: 'Batal'
      });

      if (result.isConfirmed) {
        setLoading(true);
        const response = await apiClient.post(`/employees/${employeeId}/reset-device`);
        
        Swal.fire({
          title: 'Berhasil!',
          text: response.data.message || 'Device berhasil direset.',
          icon: 'success',
          confirmButtonColor: '#1C3ECA',
        });
        
        fetchEmployees(); // refresh list
        setShowModal(false); // close modal or we could keep it open
      }
    } catch (error: any) {
      console.error('Reset Device Error:', error);
      Swal.fire({
        title: 'Error!',
        text: error.response?.data?.message || 'Gagal mereset device.',
        icon: 'error',
        confirmButtonColor: '#1C3ECA',
      });
    } finally {
      setLoading(false);
    }
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
      
      Swal.fire({
        title: 'Import Berhasil!',
        text: `Created: ${response.data.created}\nSkipped: ${response.data.skipped}`,
        icon: 'success',
        confirmButtonColor: '#1C3ECA',
      });

      setShowImportModal(false);
      setImportFile(null);
      fetchEmployees();
    } catch (error: any) {
      console.error('Import Error:', error);
      Swal.fire({
        title: 'Error!',
        text: error.response?.data?.message || 'Gagal mengimport data.',
        icon: 'error',
        confirmButtonColor: '#1C3ECA',
      });
    } finally {
      setUploading(false);
    }
  };



  const handleExport = async () => {
    try {
      const params = new URLSearchParams();
      if (filterOrg) params.append('division_id', filterOrg);
      if (filterStatus) params.append('status', filterStatus);
      if (filterTrack) params.append('track', filterTrack);

      const response = await apiClient.get(`/employees/export?${params.toString()}`, {
        responseType: 'blob'
      });

      // Create download link
      const url = window.URL.createObjectURL(new Blob([response.data]));
      const link = document.createElement('a');
      link.href = url;
      // Get filename from header if possible, or generate default
      const contentDisposition = response.headers['content-disposition'];
      let filename = 'Data_Karyawan.xlsx';
      if (contentDisposition) {
        const matches = /filename="?([^"]+)"?/.exec(contentDisposition);
        if (matches && matches[1]) filename = matches[1];
      }

      link.setAttribute('download', filename);
      document.body.appendChild(link);
      link.click();
      link.parentNode?.removeChild(link);
    } catch (error) {
      console.error('Export failed:', error);
      Swal.fire({
        title: 'Ekspor Gagal',
        text: 'Gagal mengexport data karyawan.',
        icon: 'error',
        confirmButtonColor: '#1C3ECA',
      });
    }
  };

    const columns = [
        { name: "KARYAWAN", uid: "employee" },
        { name: "JABATAN", uid: "position" },
        { name: "DIVISI", uid: "division" },
        { name: "TRACK", uid: "track" },
        { name: "KONTRAK BERAKHIR", uid: "contract" },
        { name: "STATUS", uid: "status" },
        { name: "AKSI", uid: "actions" },
    ];

  
  const handleImpersonate = async (employeeId: number) => {
    try {
      const response = await apiClient.post(`/admin/impersonate/${employeeId}`);
      if (response.data.success) {
        // Save current auth storage string to return later
        const authStorage = localStorage.getItem('auth-storage');
        if (authStorage) {
            localStorage.setItem('admin_auth_backup', authStorage);
        }
        
        // Update Zustand store directly
        useAuthStore.setState({
            token: response.data.data.access_token,
            user: response.data.data.user,
            isAuthenticated: true,
            lastActivity: Date.now()
        });
        
        Swal.fire({
          title: 'Success!',
          text: `Logged in as ${response.data.data.user.name}`,
          icon: 'success',
          timer: 1500,
          showConfirmButton: false
        }).then(() => {
            window.location.href = '/dashboard';
        });
      }
    } catch (error: any) {
      Swal.fire({
        title: 'Error',
        text: error.response?.data?.message || 'Failed to impersonate user.',
        icon: 'error'
      });
    }
  };

  const getChipColor = (status: string) => {
        const statusColorMap: Record<string, "success" | "danger" | "warning" | "default"> = {
            active: "success",
            resigned: "danger",
            inactive: "default",
        };
        return statusColorMap[status?.toLowerCase()] || "default";
    };


    const renderCell = (emp: any, columnKey: React.Key) => {
        switch (columnKey) {
            case "employee":
                return (
                    <User
                        avatarProps={{ radius: "lg", name: emp.full_name?.[0]?.toUpperCase() }}
                        description={emp.employee_code}
                        name={emp.full_name}
                    >
                        {emp.full_name}
                    </User>
                );
            case "position":
                return (
                    <div className="flex flex-col">
                        <p className="text-bold text-sm capitalize">{emp.position || '-'}</p>
                        {emp.level && <p className="text-bold text-sm capitalize text-default-400">{emp.level}</p>}
                    </div>
                );
            case "division":
                return <p className="text-sm">{emp.division?.name || '-'}</p>;
            case "track":
                return (
                    <Chip 
                        className="capitalize" 
                        color={emp.track === 'operational' ? "warning" : "primary"} 
                        size="sm" 
                        variant="flat"
                    >
                        {emp.track === 'operational' ? 'Operational' : 'Head Office'}
                    </Chip>
                );
            case "contract":
                return emp.contract_end_date ? (
                    <div className="flex flex-col">
                        <p className="text-sm">{formatDate(emp.contract_end_date)}</p>
                        {isExpiringSoon(emp.contract_end_date) && (
                            <Chip size="sm" color="danger" variant="flat" className="mt-1">
                                Expiring Soon
                            </Chip>
                        )}
                    </div>
                ) : <span className="text-default-400 italic text-sm">Permanent</span>;
            case "status":
                return (
                    <Chip className="capitalize" color={getChipColor(emp.status)} size="sm" variant="flat">
                        {emp.status === 'active' ? 'Aktif' : emp.status === 'inactive' ? 'Tidak Aktif' : 'Resign'}
                    </Chip>
                );
            case "actions":
                return (
                    <div className="flex items-center gap-2">
                        <Button color="primary" variant="light" size="sm" onPress={() => handleViewDetails(emp)}>
                            Detail
                        </Button>
                        <Dropdown>
                            <DropdownTrigger>
                                <Button isIconOnly size="sm" variant="light">
                                    <svg className="w-4 h-4 text-gray-500" fill="currentColor" viewBox="0 0 24 24"><path d="M12 8c1.1 0 2-.9 2-2s-.9-2-2-2-2 .9-2 2 .9 2 2 2zm0 2c-1.1 0-2 .9-2 2s.9 2 2 2 2-.9 2-2-.9-2-2-2zm0 6c-1.1 0-2 .9-2 2s.9 2 2 2 2-.9 2-2-.9-2-2-2z" /></svg>
                                </Button>
                            </DropdownTrigger>
                            <DropdownMenu aria-label="Employee Actions">
                                <DropdownItem 
                                    key="impersonate" 
                                    className="text-primary"
                                    color="primary"
                                    onPress={() => handleImpersonate(emp.user_id || emp.id)}
                                >
                                    Login As
                                </DropdownItem>
                            </DropdownMenu>
                        </Dropdown>
                    </div>
                );
            default:
                return null;
        }
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
          <div className="flex gap-3">
            <button
              onClick={handleExport}
              className="px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 transition-colors font-medium flex items-center gap-2"
            >
              <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-4l-4 4m0 0l-4-4m4 4V4" />
              </svg>
              Export Excel
            </button>
            <button
              onClick={() => setShowImportModal(true)}
              className="px-4 py-2 bg-[#1C3ECA] text-[#60A5FA] rounded-lg hover:bg-[#2d1e24] transition-colors font-medium flex items-center gap-2"
            >
              <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-8l-4-4m0 0L8 8m4-4v12" />
              </svg>
              Import Master Data
            </button>
          </div>
        </div>

        {/* Filters */}
        <div className="bg-white rounded-xl shadow-sm p-6 mb-6">
          <form onSubmit={handleSearch} className="space-y-4">
            <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Cari Karyawan
                </label>
                <Input
                  isClearable
                  classNames={{
                    inputWrapper: "border border-gray-300 bg-white hover:bg-gray-50 focus-within:ring-2 focus-within:ring-[#1C3ECA]",
                  }}
                  placeholder="Nama atau NIK..."
                  startContent={<Search className="text-gray-400" size={18} />}
                  value={searchTerm}
                  onClear={() => setSearchTerm('')}
                  onChange={(e) => setSearchTerm(e.target.value)}
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Divisi
                </label>
                <select
                  value={filterOrg}
                  onChange={(e) => setFilterOrg(e.target.value)}
                  className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-[#1C3ECA] focus:border-transparent"
                >
                  <option value="">Semua Divisi</option>
                  {divisions.map(div => (
                    <option key={div.id} value={div.id}>{div.name}</option>
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
                  className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-[#1C3ECA] focus:border-transparent"
                >
                  <option value="">Semua Status</option>
                  <option value="active">Aktif</option>
                  <option value="inactive">Tidak Aktif</option>
                  <option value="resigned">Resign</option>
                </select>
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Track
                </label>
                <select
                  value={filterTrack}
                  onChange={(e) => setFilterTrack(e.target.value)}
                  className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-[#1C3ECA] focus:border-transparent"
                >
                  <option value="">Semua Track</option>
                  <option value="office">Head Office</option>
                  <option value="operational">Operational</option>
                </select>
              </div>

              <div className="flex items-end">
                <button
                  type="submit"
                  className="w-full px-6 py-2 bg-[#60A5FA] text-[#1C3ECA] rounded-lg hover:bg-[#93C5FD] transition-colors"
                >
                  Cari
                </button>
              </div>
            </div>
          </form>
        </div>

        {/* Table */}
        <div className="bg-white rounded-xl shadow-sm border border-gray-100 overflow-hidden">
          <DataTable
            columns={columns}
            data={employees}
            isLoading={loading}
            renderCell={renderCell}
            primaryKey="id"
            page={currentPage}
            pages={totalPages}
            onPageChange={(page) => setCurrentPage(page)}
            emptyContent="Tidak ada data karyawan"
          />
        </div>

      </div>

      <EmployeeDetailModal
        employee={selectedEmployee}
        isOpen={showModal}
        onClose={handleCloseModal}
        onResetDevice={handleResetDevice}
      />

      <EmployeeImportModal
        isOpen={showImportModal}
        onClose={() => setShowImportModal(false)}
        importFile={importFile}
        setImportFile={setImportFile}
        uploading={uploading}
        onSubmit={handleImportSubmit}
      />
    </DashboardLayout >
  );
}
