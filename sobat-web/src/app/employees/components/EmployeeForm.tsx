'use client';

import { useState, useEffect } from 'react';
import apiClient from '@/lib/api-client';

interface EmployeeFormProps {
    isOpen: boolean;
    onClose: () => void;
    onSuccess: () => void;
    initialData?: any;
    organizations: any[];
}

export default function EmployeeForm({ isOpen, onClose, onSuccess, initialData, organizations }: EmployeeFormProps) {
    const [loading, setLoading] = useState(false);
    const [activeTab, setActiveTab] = useState('personal');
    const [formData, setFormData] = useState<any>({});
    const [roles, setRoles] = useState<any[]>([]);

    useEffect(() => {
        if (initialData) {
            setFormData({
                ...initialData,
                // Ensure dates are formatted for input type="date"
                join_date: initialData.join_date ? initialData.join_date.split('T')[0] : '',
                birth_date: initialData.birth_date ? initialData.birth_date.split('T')[0] : '',
                contract_end_date: initialData.contract_end_date ? initialData.contract_end_date.split('T')[0] : '',
            });
        } else {
            setFormData({
                status: 'active',
                employment_status: 'probation',
            });
        }
        fetchRoles();
    }, [initialData]);

    const fetchRoles = async () => {
        try {
            // Only fetch if not already loaded or if needed
            // Assuming we might need roles for some assignments, otherwise ignore
        } catch (error) {
            console.error('Failed to fetch roles', error);
        }
    };

    const handleChange = (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement | HTMLTextAreaElement>) => {
        const { name, value } = e.target;
        setFormData((prev: any) => ({ ...prev, [name]: value }));
    };

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();
        setLoading(true);

        try {
            if (initialData?.id) {
                await apiClient.put(`/employees/${initialData.id}`, formData);
            } else {
                await apiClient.post('/employees', formData);
            }
            onSuccess();
            onClose();
        } catch (error: any) {
            alert(error.response?.data?.message || 'Failed to save employee data');
        } finally {
            setLoading(false);
        }
    };

    if (!isOpen) return null;

    return (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
            <div className="bg-white rounded-xl w-full max-w-4xl max-h-[90vh] overflow-hidden flex flex-col">
                {/* Header */}
                <div className="px-6 py-4 border-b border-gray-200 flex justify-between items-center bg-gray-50">
                    <h2 className="text-xl font-bold text-gray-800">
                        {initialData ? 'Edit Master Data Karyawan' : 'Tambah Karyawan Baru'}
                    </h2>
                    <button onClick={onClose} className="text-gray-400 hover:text-gray-600">
                        <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" /></svg>
                    </button>
                </div>

                {/* Tabs */}
                <div className="flex border-b border-gray-200 overflow-x-auto">
                    {['personal', 'employment', 'identity_finance', 'family', 'address'].map((tab) => (
                        <button
                            key={tab}
                            onClick={() => setActiveTab(tab)}
                            className={`px-6 py-3 text-sm font-medium whitespace-nowrap transition-colors ${activeTab === tab
                                ? 'border-b-2 border-[#a9eae2] text-[#462e37] bg-gray-50'
                                : 'text-gray-500 hover:text-gray-700 hover:bg-gray-50'
                                }`}
                        >
                            {tab === 'personal' && 'Data Pribadi'}
                            {tab === 'employment' && 'Kepegawaian'}
                            {tab === 'identity_finance' && 'Identitas & Keuangan'}
                            {tab === 'family' && 'Keluarga'}
                            {tab === 'address' && 'Alamat'}
                        </button>
                    ))}
                </div>

                {/* Form Content */}
                <div className="flex-1 overflow-y-auto p-6 bg-gray-50/50">
                    <form id="employee-form" onSubmit={handleSubmit} className="space-y-6">
                        {activeTab === 'personal' && (
                            <div className="grid grid-cols-1 md:grid-cols-2 gap-6 animate-fade-in-up">
                                <div>
                                    <label className="block text-sm font-medium text-gray-700 mb-1">Nama Lengkap *</label>
                                    <input type="text" name="full_name" required value={formData.full_name || ''} onChange={handleChange} className="w-full px-4 py-2 border rounded-lg focus:ring-2 focus:ring-[#a9eae2] outline-none text-gray-900" />
                                </div>
                                <div>
                                    <label className="block text-sm font-medium text-gray-700 mb-1">Email</label>
                                    <input type="email" name="email" value={formData.email || ''} onChange={handleChange} className="w-full px-4 py-2 border rounded-lg focus:ring-2 focus:ring-[#a9eae2] outline-none text-gray-900" />
                                </div>
                                <div>
                                    <label className="block text-sm font-medium text-gray-700 mb-1">No. Telepon</label>
                                    <input type="text" name="phone" value={formData.phone || ''} onChange={handleChange} className="w-full px-4 py-2 border rounded-lg focus:ring-2 focus:ring-[#a9eae2] outline-none text-gray-900" />
                                </div>
                                <div>
                                    <label className="block text-sm font-medium text-gray-700 mb-1">Tempat Lahir</label>
                                    <input type="text" name="place_of_birth" value={formData.place_of_birth || ''} onChange={handleChange} className="w-full px-4 py-2 border rounded-lg focus:ring-2 focus:ring-[#a9eae2] outline-none text-gray-900" />
                                </div>
                                <div>
                                    <label className="block text-sm font-medium text-gray-700 mb-1">Tanggal Lahir</label>
                                    <input type="date" name="birth_date" value={formData.birth_date || ''} onChange={handleChange} className="w-full px-4 py-2 border rounded-lg focus:ring-2 focus:ring-[#a9eae2] outline-none text-gray-900" />
                                </div>
                                <div>
                                    <label className="block text-sm font-medium text-gray-700 mb-1">Jenis Kelamin</label>
                                    <select name="gender" value={formData.gender || ''} onChange={handleChange} className="w-full px-4 py-2 border rounded-lg focus:ring-2 focus:ring-[#a9eae2] outline-none text-gray-900">
                                        <option value="">Pilih...</option>
                                        <option value="male">Laki-laki</option>
                                        <option value="female">Perempuan</option>
                                    </select>
                                </div>
                                <div>
                                    <label className="block text-sm font-medium text-gray-700 mb-1">Agama</label>
                                    <select name="religion" value={formData.religion || ''} onChange={handleChange} className="w-full px-4 py-2 border rounded-lg focus:ring-2 focus:ring-[#a9eae2] outline-none text-gray-900">
                                        <option value="">Pilih...</option>
                                        <option value="Islam">Islam</option>
                                        <option value="Kristen">Kristen</option>
                                        <option value="Katolik">Katolik</option>
                                        <option value="Hindu">Hindu</option>
                                        <option value="Buddha">Buddha</option>
                                        <option value="Konghucu">Konghucu</option>
                                    </select>
                                </div>
                                <div>
                                    <label className="block text-sm font-medium text-gray-700 mb-1">Status Perkawinan</label>
                                    <select name="marital_status" value={formData.marital_status || ''} onChange={handleChange} className="w-full px-4 py-2 border rounded-lg focus:ring-2 focus:ring-[#a9eae2] outline-none text-gray-900">
                                        <option value="">Pilih...</option>
                                        <option value="Single">Single</option>
                                        <option value="Married">Menikah</option>
                                        <option value="Divorced">Cerai</option>
                                    </select>
                                </div>
                                <div>
                                    <label className="block text-sm font-medium text-gray-700 mb-1">Pendidikan Terakhir</label>
                                    {typeof formData.education === 'object' && formData.education !== null ? (
                                        <div className="w-full px-4 py-2 border rounded-lg bg-gray-50 text-gray-900">
                                            <ul className="list-disc list-inside space-y-1 text-sm">
                                                {formData.education.sd && <li><span className="font-medium">SD:</span> {formData.education.sd}</li>}
                                                {formData.education.smp && <li><span className="font-medium">SMP:</span> {formData.education.smp}</li>}
                                                {formData.education.sma && <li><span className="font-medium">SMA:</span> {formData.education.sma}</li>}
                                                {formData.education.smk && <li><span className="font-medium">SMK:</span> {formData.education.smk}</li>}
                                                {formData.education.d3 && <li><span className="font-medium">D3:</span> {formData.education.d3}</li>}
                                                {formData.education.s1 && <li><span className="font-medium">S1:</span> {formData.education.s1}</li>}
                                                {formData.education.s2 && <li><span className="font-medium">S2:</span> {formData.education.s2}</li>}
                                                {formData.education.s3 && <li><span className="font-medium">S3:</span> {formData.education.s3}</li>}
                                            </ul>
                                        </div>
                                    ) : (
                                        <select name="education" value={formData.education || ''} onChange={handleChange} className="w-full px-4 py-2 border rounded-lg focus:ring-2 focus:ring-[#a9eae2] outline-none text-gray-900">
                                            <option value="">Pilih...</option>
                                            <option value="SD">SD</option>
                                            <option value="SMP">SMP</option>
                                            <option value="SMA">SMA</option>
                                            <option value="SMK">SMK</option>
                                            <option value="D3">D3</option>
                                            <option value="S1">S1</option>
                                            <option value="S2">S2</option>
                                            <option value="S3">S3</option>
                                        </select>
                                    )}
                                </div>
                            </div>
                        )}

                        {activeTab === 'employment' && (
                            <div className="grid grid-cols-1 md:grid-cols-2 gap-6 animate-fade-in-up">
                                <div>
                                    <label className="block text-sm font-medium text-gray-700 mb-1">Nomor Induk Karyawan (NIK Internal)</label>
                                    <input type="text" name="employee_code" value={formData.employee_code || ''} onChange={handleChange} className="w-full px-4 py-2 border rounded-lg focus:ring-2 focus:ring-[#a9eae2] outline-none text-gray-900 bg-gray-100" />
                                    <p className="text-xs text-gray-500 mt-1">Kosongkan untuk generate otomatis</p>
                                </div>
                                <div>
                                    <label className="block text-sm font-medium text-gray-700 mb-1">Status Karyawan *</label>
                                    <select name="status" required value={formData.status || 'active'} onChange={handleChange} className="w-full px-4 py-2 border rounded-lg focus:ring-2 focus:ring-[#a9eae2] outline-none text-gray-900">
                                        <option value="active">Aktif</option>
                                        <option value="inactive">Non-Aktif (Cuti Panjang/Suspend)</option>
                                        <option value="resigned">Resign / Keluar</option>
                                    </select>
                                </div>
                                <div>
                                    <label className="block text-sm font-medium text-gray-700 mb-1">Divisi / Organisasi</label>
                                    <select name="organization_id" value={formData.organization_id || ''} onChange={handleChange} className="w-full px-4 py-2 border rounded-lg focus:ring-2 focus:ring-[#a9eae2] outline-none text-gray-900">
                                        <option value="">Pilih Divisi...</option>
                                        {organizations.map(org => (
                                            <option key={org.id} value={org.id}>{org.name}</option>
                                        ))}
                                    </select>
                                </div>
                                <div>
                                    <label className="block text-sm font-medium text-gray-700 mb-1">Jabatan (Position)</label>
                                    <input type="text" name="position" value={formData.position || ''} onChange={handleChange} className="w-full px-4 py-2 border rounded-lg focus:ring-2 focus:ring-[#a9eae2] outline-none text-gray-900" />
                                </div>
                                <div>
                                    <label className="block text-sm font-medium text-gray-700 mb-1">Status Kepegawaian</label>
                                    <select name="employment_status" value={formData.employment_status || ''} onChange={handleChange} className="w-full px-4 py-2 border rounded-lg focus:ring-2 focus:ring-[#a9eae2] outline-none text-gray-900">
                                        <option value="permanent">Tetap (Permanent)</option>
                                        <option value="contract">Kontrak</option>
                                        <option value="probation">Probation</option>
                                    </select>
                                </div>
                                <div>
                                    <label className="block text-sm font-medium text-gray-700 mb-1">Tanggal Bergabung</label>
                                    <input type="date" name="join_date" value={formData.join_date || ''} onChange={handleChange} className="w-full px-4 py-2 border rounded-lg focus:ring-2 focus:ring-[#a9eae2] outline-none text-gray-900" />
                                </div>
                                <div>
                                    <label className="block text-sm font-medium text-gray-700 mb-1">Tanggal Berakhir Kontrak</label>
                                    <input type="date" name="contract_end_date" value={formData.contract_end_date || ''} onChange={handleChange} className="w-full px-4 py-2 border rounded-lg focus:ring-2 focus:ring-[#a9eae2] outline-none text-gray-900" />
                                </div>
                                <div>
                                    <label className="block text-sm font-medium text-gray-700 mb-1">Gaji Pokok</label>
                                    <input type="number" name="basic_salary" value={formData.basic_salary || ''} onChange={handleChange} className="w-full px-4 py-2 border rounded-lg focus:ring-2 focus:ring-[#a9eae2] outline-none text-gray-900" />
                                </div>
                                <div>
                                    <label className="block text-sm font-medium text-gray-700 mb-1">Nama Atasan Langsung</label>
                                    <input type="text" name="supervisor_name" value={formData.supervisor_name || ''} onChange={handleChange} className="w-full px-4 py-2 border rounded-lg focus:ring-2 focus:ring-[#a9eae2] outline-none text-gray-900" />
                                </div>
                            </div>
                        )}

                        {activeTab === 'identity_finance' && (
                            <div className="grid grid-cols-1 md:grid-cols-2 gap-6 animate-fade-in-up">
                                <div>
                                    <label className="block text-sm font-medium text-gray-700 mb-1">NIK (KTP)</label>
                                    <input type="text" name="nik" value={formData.nik || ''} onChange={handleChange} className="w-full px-4 py-2 border rounded-lg focus:ring-2 focus:ring-[#a9eae2] outline-none text-gray-900" maxLength={16} />
                                </div>
                                <div>
                                    <label className="block text-sm font-medium text-gray-700 mb-1">NPWP</label>
                                    <input type="text" name="npwp" value={formData.npwp || ''} onChange={handleChange} className="w-full px-4 py-2 border rounded-lg focus:ring-2 focus:ring-[#a9eae2] outline-none text-gray-900" />
                                </div>
                                <div>
                                    <label className="block text-sm font-medium text-gray-700 mb-1">Status PTKP</label>
                                    <select name="ptkp_status" value={formData.ptkp_status || ''} onChange={handleChange} className="w-full px-4 py-2 border rounded-lg focus:ring-2 focus:ring-[#a9eae2] outline-none text-gray-900">
                                        <option value="">Pilih...</option>
                                        <option value="TK/0">TK/0</option>
                                        <option value="TK/1">TK/1</option>
                                        <option value="K/0">K/0</option>
                                        <option value="K/1">K/1</option>
                                        <option value="K/2">K/2</option>
                                        <option value="K/3">K/3</option>
                                    </select>
                                </div>
                                <div>
                                    <label className="block text-sm font-medium text-gray-700 mb-1">Nama Bank</label>
                                    <input type="text" name="bank_name" placeholder="BCA/Mandiri/dll" className="w-full px-4 py-2 border rounded-lg focus:ring-2 focus:ring-[#a9eae2] outline-none text-gray-900" />
                                </div>
                                <div>
                                    <label className="block text-sm font-medium text-gray-700 mb-1">Nomor Rekening</label>
                                    <input type="text" name="bank_account_number" value={formData.bank_account_number || ''} onChange={handleChange} className="w-full px-4 py-2 border rounded-lg focus:ring-2 focus:ring-[#a9eae2] outline-none text-gray-900" />
                                </div>
                                <div>
                                    <label className="block text-sm font-medium text-gray-700 mb-1">Nama Pemilik Rekening</label>
                                    <input type="text" name="bank_account_name" value={formData.bank_account_name || ''} onChange={handleChange} className="w-full px-4 py-2 border rounded-lg focus:ring-2 focus:ring-[#a9eae2] outline-none text-gray-900" />
                                </div>
                            </div>
                        )}

                        {activeTab === 'family' && (
                            <div className="grid grid-cols-1 md:grid-cols-2 gap-6 animate-fade-in-up">
                                <div>
                                    <label className="block text-sm font-medium text-gray-700 mb-1">Nama Ayah Kandung</label>
                                    <input type="text" name="father_name" value={formData.father_name || ''} onChange={handleChange} className="w-full px-4 py-2 border rounded-lg focus:ring-2 focus:ring-[#a9eae2] outline-none text-gray-900" />
                                </div>
                                <div>
                                    <label className="block text-sm font-medium text-gray-700 mb-1">Nama Ibu Kandung</label>
                                    <input type="text" name="mother_name" value={formData.mother_name || ''} onChange={handleChange} className="w-full px-4 py-2 border rounded-lg focus:ring-2 focus:ring-[#a9eae2] outline-none text-gray-900" />
                                </div>
                                <div>
                                    <label className="block text-sm font-medium text-gray-700 mb-1">Nama Pasangan (Suami/Istri)</label>
                                    <input type="text" name="spouse_name" value={formData.spouse_name || ''} onChange={handleChange} className="w-full px-4 py-2 border rounded-lg focus:ring-2 focus:ring-[#a9eae2] outline-none text-gray-900" />
                                </div>
                                <div>
                                    <label className="block text-sm font-medium text-gray-700 mb-1">Kontak Darurat / Keluarga</label>
                                    <input type="text" name="family_contact_number" value={formData.family_contact_number || ''} onChange={handleChange} className="w-full px-4 py-2 border rounded-lg focus:ring-2 focus:ring-[#a9eae2] outline-none text-gray-900" />
                                </div>
                            </div>
                        )}

                        {activeTab === 'address' && (
                            <div className="space-y-6 animate-fade-in-up">
                                <div>
                                    <label className="block text-sm font-medium text-gray-700 mb-1">Alamat Sesuai KTP</label>
                                    <textarea name="ktp_address" rows={3} value={formData.ktp_address || ''} onChange={handleChange} className="w-full px-4 py-2 border rounded-lg focus:ring-2 focus:ring-[#a9eae2] outline-none text-gray-900"></textarea>
                                </div>
                                <div>
                                    <label className="block text-sm font-medium text-gray-700 mb-1">Alamat Domisili Saat Ini</label>
                                    <textarea name="current_address" rows={3} value={formData.current_address || ''} onChange={handleChange} className="w-full px-4 py-2 border rounded-lg focus:ring-2 focus:ring-[#a9eae2] outline-none text-gray-900"></textarea>
                                </div>
                            </div>
                        )}
                    </form>
                </div>

                {/* Footer */}
                <div className="px-6 py-4 border-t border-gray-200 bg-gray-50 flex justify-end gap-3">
                    <button onClick={onClose} type="button" className="px-6 py-2 bg-white text-gray-700 font-medium rounded-lg border border-gray-200 hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-gray-200">
                        Batal
                    </button>
                    <button
                        type="submit"
                        form="employee-form"
                        disabled={loading}
                        className="px-6 py-2 bg-[#462e37] text-white font-medium rounded-lg hover:bg-[#2d1e24] focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-[#462e37] disabled:opacity-50"
                    >
                        {loading ? 'Menyimpan...' : 'Simpan Data'}
                    </button>
                </div>
            </div>
        </div>
    );
}
