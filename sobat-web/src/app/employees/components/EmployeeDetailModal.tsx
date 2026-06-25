import React from 'react';
import { Employee } from '../types';
import { formatDate, formatCurrency, getGenderLabel, renderEducationDetails, getStatusBadge } from '../utils';

interface EmployeeDetailModalProps {
  employee: Employee | null;
  isOpen: boolean;
  onClose: () => void;
  onResetDevice: (employeeId: number) => void;
}

export default function EmployeeDetailModal({ employee, isOpen, onClose, onResetDevice }: EmployeeDetailModalProps) {
  if (!isOpen || !employee) return null;

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
      <div className="bg-white rounded-xl max-w-4xl w-full max-h-[90vh] overflow-y-auto">
        {/* Modal Header */}
        <div className="sticky top-0 bg-white border-b border-gray-200 px-6 py-4 flex items-center justify-between">
          <h2 className="text-2xl font-bold text-gray-900">Detail Karyawan</h2>
          <button
            onClick={onClose}
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
          <div className="bg-gradient-to-r from-[#60A5FA] to-[#93C5FD] rounded-lg p-6 text-[#1C3ECA]">
            <div className="flex items-center gap-4">
              <div className="w-20 h-20 rounded-full bg-white/20 flex items-center justify-center text-3xl font-bold">
                {employee.full_name.charAt(0).toUpperCase()}
              </div>
              <div>
                <h3 className="text-2xl font-bold">{employee.full_name}</h3>
                <p className="text-[#1C3ECA] font-semibold">{employee.employee_code}</p>
                <p className="text-sm mt-1">{employee.position} • {employee.division?.name}</p>
              </div>
            </div>
          </div>

          {/* Personal Data */}
          <div>
            <h4 className="text-lg font-semibold text-gray-900 mb-4">Data Pribadi</h4>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <label className="text-sm text-gray-500">Email</label>
                <p className="font-medium text-gray-900">{employee.email || '-'}</p>
              </div>
              <div>
                <label className="text-sm text-gray-500">No. Telepon</label>
                <p className="font-medium text-gray-900">{employee.phone || '-'}</p>
              </div>
              <div>
                <label className="text-sm text-gray-500">Tempat Lahir</label>
                <p className="font-medium text-gray-900">{employee.place_of_birth || '-'}</p>
              </div>
              <div>
                <label className="text-sm text-gray-500">Tanggal Lahir</label>
                <p className="font-medium text-gray-900">{formatDate(employee.birth_date)}</p>
              </div>
              <div>
                <label className="text-sm text-gray-500">Jenis Kelamin</label>
                <p className="font-medium text-gray-900">{getGenderLabel(employee.gender)}</p>
              </div>
              <div>
                <label className="text-sm text-gray-500">Agama</label>
                <p className="font-medium text-gray-900">{employee.religion || '-'}</p>
              </div>
              <div>
                <label className="text-sm text-gray-500">Status Perkawinan</label>
                <p className="font-medium text-gray-900">{employee.marital_status || '-'}</p>
              </div>
              <div>
                <label className="text-sm text-gray-500">Status PTKP</label>
                <p className="font-medium text-gray-900">{employee.ptkp_status || '-'}</p>
              </div>
            </div>
          </div>

          {/* Address */}
          <div>
            <h4 className="text-lg font-semibold text-gray-900 mb-4">Alamat</h4>
            <div className="grid grid-cols-1 gap-4">
              <div>
                <label className="text-sm text-gray-500">Alamat KTP</label>
                <p className="font-medium text-gray-900">{employee.ktp_address || '-'}</p>
              </div>
              <div>
                <label className="text-sm text-gray-500">Alamat Domisili</label>
                <p className="font-medium text-gray-900">{employee.current_address || '-'}</p>
              </div>
            </div>
          </div>

          {/* Identity & Finance */}
          <div>
            <h4 className="text-lg font-semibold text-gray-900 mb-4">Data Identitas & Keuangan</h4>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <label className="text-sm text-gray-500">NIK (KTP)</label>
                <p className="font-medium text-gray-900">{employee.nik || '-'}</p>
              </div>
              <div>
                <label className="text-sm text-gray-500">NPWP</label>
                <p className="font-medium text-gray-900">{employee.npwp || '-'}</p>
              </div>
              <div>
                <label className="text-sm text-gray-500">No. Rekening</label>
                <p className="font-medium text-gray-900">{employee.bank_account_number || '-'}</p>
              </div>
              <div>
                <label className="text-sm text-gray-500">Nama Pemilik Rekening</label>
                <p className="font-medium text-gray-900">{employee.bank_account_name || '-'}</p>
              </div>
            </div>
          </div>

          {/* Family */}
          <div>
            <h4 className="text-lg font-semibold text-gray-900 mb-4">Data Keluarga</h4>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <label className="text-sm text-gray-500">Nama Ayah</label>
                <p className="font-medium text-gray-900">{employee.father_name || '-'}</p>
              </div>
              <div>
                <label className="text-sm text-gray-500">Nama Ibu</label>
                <p className="font-medium text-gray-900">{employee.mother_name || '-'}</p>
              </div>
              <div>
                <label className="text-sm text-gray-500">Nama Pasangan</label>
                <p className="font-medium text-gray-900">{employee.spouse_name || '-'}</p>
              </div>
              <div>
                <label className="text-sm text-gray-500">Kontak Keluarga</label>
                <p className="font-medium text-gray-900">{employee.family_contact_number || '-'}</p>
              </div>
            </div>
          </div>

          {/* Employment */}
          <div>
            <h4 className="text-lg font-semibold text-gray-900 mb-4">Data Kepegawaian</h4>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <label className="text-sm text-gray-500">Tanggal Bergabung</label>
                <p className="font-medium text-gray-900">{formatDate(employee.join_date)}</p>
              </div>
              <div>
                <label className="text-sm text-gray-500">Pendidikan</label>
                <div className="font-medium text-gray-900">{renderEducationDetails(employee.education)}</div>
              </div>
              <div>
                <label className="text-sm text-gray-500">Divisi/Departemen</label>
                <p className="font-medium text-gray-900">{employee.level || '-'}</p>
              </div>
              <div>
                <label className="text-sm text-gray-500">Status Kepegawaian</label>
                <p className="font-medium text-gray-900">{employee.employment_status || '-'}</p>
              </div>
              <div>
                <label className="text-sm text-gray-500">Nama Atasan</label>
                <p className="font-medium">{employee.supervisor_name || '-'}</p>
              </div>
              <div>
                <label className="text-sm text-gray-500">Jabatan Atasan</label>
                <p className="font-medium">{employee.supervisor_position || '-'}</p>
              </div>
              <div>
                <label className="text-sm text-gray-500">Gaji Pokok</label>
                <p className="font-medium text-gray-900">{formatCurrency(employee.basic_salary)}</p>
              </div>
              <div>
                <label className="text-sm text-gray-500">Lembur Wajib (Nominal)</label>
                <p className="font-medium text-gray-900">{formatCurrency(employee.mandatory_overtime_amount)}</p>
              </div>
              <div>
                <label className="text-sm text-gray-500">Status</label>
                <div className="mt-1">
                  <span className={`px-3 py-1 inline-flex text-xs leading-5 font-semibold rounded-full ${getStatusBadge(employee.status)}`}>
                    {employee.status === 'active' ? 'Aktif' : employee.status === 'inactive' ? 'Tidak Aktif' : 'Resign'}
                  </span>
                </div>
              </div>
              <div>
                <label className="text-sm text-gray-500">Track</label>
                <p className="font-medium text-gray-900 mt-1">{employee.track === 'operational' ? 'Operational' : 'Head Office'}</p>
              </div>
            </div>
          </div>
        </div>

        {/* Modal Footer */}
        <div className="sticky bottom-0 bg-gray-50 border-t border-gray-200 px-6 py-4 flex justify-between items-center">
          <button
            onClick={() => onResetDevice(employee.id)}
            className="px-4 py-2 bg-red-50 text-red-600 border border-red-200 rounded-lg hover:bg-red-100 focus:ring-2 focus:ring-red-500 focus:outline-none transition-colors"
          >
            Reset Device
          </button>
          <button
            onClick={onClose}
            className="px-6 py-2 bg-gray-600 text-white rounded-lg hover:bg-gray-700 transition-colors"
          >
            Tutup
          </button>
        </div>
      </div>
    </div>
  );
}
