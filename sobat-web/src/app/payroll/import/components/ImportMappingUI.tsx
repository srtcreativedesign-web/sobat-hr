import React from 'react';

interface ImportMappingUIProps {
    columnMapping: Record<string, string>;
    setColumnMapping: (mapping: Record<string, string>) => void;
    excelHeaders: Record<string, string>;
    onSimulate: () => void;
    onCancel: () => void;
}

export default function ImportMappingUI({
    columnMapping,
    setColumnMapping,
    excelHeaders,
    onSimulate,
    onCancel
}: ImportMappingUIProps) {
    return (
        <div className="mt-6 border-t pt-6">
            <div className="flex items-center justify-between mb-4">
                <h4 className="text-lg font-bold text-gray-900">Pemetaan Kolom (Hybrid Smart Default)</h4>
            </div>
            <p className="text-sm text-gray-600 mb-6">
                Sistem telah menjodohkan kolom Excel Anda dengan variabel sistem secara otomatis.
                Silakan periksa dan pilih <span className="font-semibold italic">Abaikan / Kosong</span> jika ada kolom yang memang tidak relevan.
            </p>
            <div className="border rounded-xl p-6 bg-gray-50 grid grid-cols-1 md:grid-cols-2 gap-x-8 gap-y-4 max-h-[400px] overflow-y-auto">
                {[
                    { key: 'employee_name', label: 'Nama Karyawan' },
                    { key: 'basic_salary', label: 'Gaji Pokok' },
                    { key: 'days_present', label: 'Total Hadir (Hari)' },
                    { key: 'meal_rate', label: 'Rate Uang Makan (/ Hari)' },
                    { key: 'meal_amount', label: 'Uang Makan (Total)' },
                    { key: 'transport_rate', label: 'Rate Transport (/ Hari)' },
                    { key: 'transport_amount', label: 'Uang Transport' },
                    { key: 'attendance_rate', label: 'Rate Tunj. Kehadiran (/ Hari)' },
                    { key: 'attendance_allowance', label: 'Tunj. Kehadiran (Total)' },
                    { key: 'overtime_rate', label: 'Rate Lembur (/ Jam)' },
                    { key: 'overtime_amount', label: 'Uang Lembur (Total)' },
                    { key: 'mandatory_overtime_rate', label: 'Rate Lembur Wajib (/ Hari)' },
                    { key: 'mandatory_overtime_amount', label: 'Uang Lembur Wajib (Total)' },
                    { key: 'bonus', label: 'Bonus / Insentif / THR' },
                    { key: 'target_koli', label: 'Target Koli' },
                    { key: 'accessory_fee', label: 'Fee Aksesoris' },
                    { key: 'total_salary_gross', label: 'Total Gaji & Bonus' },
                    { key: 'deduction_late', label: 'Potongan Terlambat' },
                    { key: 'shortage_deduction', label: 'Selisih SO' },
                    { key: 'deduction_loan', label: 'Kasbon / Pinjaman' },
                    { key: 'total_deduction', label: 'Total Potongan' },
                    { key: 'thp', label: 'Grand Total (Sblm EWA)' },
                    { key: 'ewa_amount', label: 'Pinjaman Stafbook (EWA)' },
                    { key: 'net_salary', label: 'Payroll (THP Akhir)' },
                ].map(field => (
                    <div key={field.key} className="flex flex-col gap-1">
                        <div className="flex justify-between items-center">
                            <span className="text-sm font-semibold text-gray-700">{field.label}</span>
                            {columnMapping[field.key] ? (
                                <span className="text-xs font-semibold text-green-600 bg-green-100 px-2 py-0.5 rounded-full flex items-center gap-1"><svg className="w-3 h-3" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" /></svg> Sesuai</span>
                            ) : (
                                <span className="text-xs font-semibold text-red-600 bg-red-100 px-2 py-0.5 rounded-full flex items-center gap-1"><svg className="w-3 h-3" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" /></svg> Tidak Sesuai</span>
                            )}
                        </div>
                        <select
                            value={columnMapping[field.key] || ''}
                            onChange={(e) => setColumnMapping({ ...columnMapping, [field.key]: e.target.value })}
                            className={`w-full text-sm p-2.5 border rounded-lg focus:ring-2 focus:ring-[#419cc3] focus:outline-none transition-all ${columnMapping[field.key] ? 'border-green-300 bg-white' : 'border-red-300 bg-red-50'}`}
                        >
                            <option value="">-- [ Abaikan / Kosong ] --</option>
                            {Object.entries(excelHeaders).map(([col, title]) => (
                                <option key={col} value={col}>Kolom {col} - {title}</option>
                            ))}
                        </select>
                    </div>
                ))}
            </div>

            <div className="mt-6 flex justify-end gap-3">
                <button
                    onClick={onCancel}
                    className="px-6 py-3 border-2 border-gray-300 text-gray-700 rounded-xl font-semibold hover:bg-gray-50 transition-colors"
                >
                    Batal
                </button>
                <button
                    onClick={onSimulate}
                    className="px-8 py-3 bg-gradient-to-r from-[#89b4e1] to-[#93C5FD] text-[#419cc3] rounded-xl font-bold hover:shadow-lg transition-all"
                >
                    Upload (Simulasikan Data)
                </button>
            </div>
        </div>
    );
}
