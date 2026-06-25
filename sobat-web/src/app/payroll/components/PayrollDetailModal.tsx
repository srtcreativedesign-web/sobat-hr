import React from 'react';
import apiClient from '@/lib/api-client';
import { Payroll } from '../types';
import { 
    formatCurrency, 
    formatSmartValue, 
    getStatusBadge, 
    calculateGrossSalary, 
    calculateTotalDeductions 
} from '../utils';

interface PayrollDetailModalProps {
    selectedPayroll: Payroll | null;
    selectedDivision: string;
    onClose: () => void;
    onApprove: (id: number) => void;
}

export default function PayrollDetailModal({
    selectedPayroll,
    selectedDivision,
    onClose,
    onApprove
}: PayrollDetailModalProps) {
    if (!selectedPayroll) return null;

    const handleDownload = async () => {
        try {
            const endpoint = selectedDivision === 'maximum'
                ? `/payrolls/maximum/${selectedPayroll.id}/slip`
                : selectedDivision === 'tungtau'
                ? `/payrolls/tungtau/${selectedPayroll.id}/slip`
                : selectedDivision === 'fnb'
                ? `/payrolls/fnb/${selectedPayroll.id}/slip`
                : selectedDivision === 'office'
                ? `/payrolls/ho/${selectedPayroll.id}/slip`
                : ['minimarket', 'reflexiology', 'wrapping', 'hans', 'cellular', 'money_changer'].includes(selectedDivision)
                ? `/payrolls/retail/${selectedPayroll.id}/slip?division_type=${selectedDivision}`
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
    };

    return (
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
                        onClick={onClose}
                        className="text-gray-400 hover:text-gray-600 p-2 hover:bg-gray-100 rounded-lg transition-colors"
                        title="Close"
                    >
                        <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                        </svg>
                    </button>
                </div>

                <div className="p-6 overflow-y-auto flex-1">
                    {/* Attendance Summary (for FnB/MM/Ref/Wrapping/Cellular) */}
                    {['fnb', 'tungtau', 'maximum', 'minimarket', 'reflexiology', 'wrapping', 'hans', 'cellular', 'money_changer'].includes(selectedDivision) && (selectedPayroll as any).attendance && (
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
                            <h4 className="text-sm font-bold text-[#93C5FD] uppercase tracking-wider mb-4 border-b border-[#60A5FA] pb-2">Pendapatan</h4>
                            <div className="space-y-3">
                                <div className="flex justify-between">
                                    <span className="text-gray-600">Gaji Pokok</span>
                                    <span className="font-semibold">{formatCurrency(selectedPayroll.basic_salary)}</span>
                                </div>

                                {/* FnB/MM/Ref/Wrapping/Cellular Allowances Breakdown */}
                                {['fnb', 'tungtau', 'maximum', 'minimarket', 'reflexiology', 'wrapping', 'hans', 'cellular', 'money_changer'].includes(selectedDivision) && selectedPayroll.allowances && (
                                    <>
                                        {Object.entries(selectedPayroll.allowances).map(([key, value]: [string, any]) => {
                                            if (!value || value === 0 || value === '0.00') return null;

                                            // Handle nested objects (like Kehadiran, Transport, Lembur)
                                            if (typeof value === 'object' && value !== null) {
                                                const amount = parseFloat(value.amount || 0);
                                                if (isNaN(amount) || amount === 0) return null;

                                                return (
                                                    <div key={key} className="flex justify-between text-sm">
                                                        <span className="text-gray-600">
                                                            {key} {value.rate ? `(${formatCurrency(parseFloat(value.rate))} /hari)` : ''}
                                                            {value.hours ? `(${value.hours} Jam)` : ''}
                                                        </span>
                                                        <span className="font-medium text-gray-800">{formatCurrency(amount)}</span>
                                                    </div>
                                                );
                                            }

                                            // Handle simple values
                                            const numValue = parseFloat(value);
                                            if (isNaN(numValue) || numValue === 0) return null;

                                            return (
                                                <div key={key} className="flex justify-between text-sm">
                                                    <span className="text-gray-600">{key}</span>
                                                    <span className="font-medium text-gray-800">{formatCurrency(numValue)}</span>
                                                </div>
                                            );
                                        })}
                                    </>
                                )}

                                {/* Generic Payroll Allowances */}
                                {!['fnb', 'tungtau', 'maximum', 'minimarket', 'reflexiology', 'wrapping', 'hans'].includes(selectedDivision) && (
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
                                        {selectedPayroll.details?.position_allowance > 0 && (
                                            <div className="flex justify-between text-sm">
                                                <span className="text-gray-600">Tunj. Jabatan</span>
                                                <span className="font-medium text-gray-800">{formatCurrency(selectedPayroll.details.position_allowance)}</span>
                                            </div>
                                        )}
                                        {selectedPayroll.details?.attendance_allowance > 0 && (
                                            <div className="flex justify-between text-sm">
                                                <span className="text-gray-600">Tunj. Kehadiran</span>
                                                <span className="font-medium text-gray-800">{formatCurrency(selectedPayroll.details.attendance_allowance)}</span>
                                            </div>
                                        )}
                                        {selectedPayroll.details?.insentif_kehadiran > 0 && (
                                            <div className="flex justify-between text-sm">
                                                <span className="text-gray-600">Insentif Kehadiran</span>
                                                <span className="font-medium text-gray-800">{formatCurrency(selectedPayroll.details.insentif_kehadiran)}</span>
                                            </div>
                                        )}
                                        {selectedPayroll.details?.insentif_luar_kota > 0 && (
                                            <div className="flex justify-between text-sm">
                                                <span className="text-gray-600">Insentif Luar Kota</span>
                                                <span className="font-medium text-gray-800">{formatCurrency(selectedPayroll.details.insentif_luar_kota)}</span>
                                            </div>
                                        )}
                                        {selectedPayroll.details?.piket_um_sabtu > 0 && (
                                            <div className="flex justify-between text-sm">
                                                <span className="text-gray-600">Piket & UM Sabtu</span>
                                                <span className="font-medium text-gray-800">{formatCurrency(selectedPayroll.details.piket_um_sabtu)}</span>
                                            </div>
                                        )}
                                        {selectedPayroll.details?.adjustment && selectedPayroll.details?.adjustment !== 0 ? (
                                            <div className="flex justify-between text-sm">
                                                <span className="text-gray-600">Adj Gaji</span>
                                                <span className="font-medium text-gray-800">{formatCurrency(selectedPayroll.details.adjustment)}</span>
                                            </div>
                                        ) : null}
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

                                {selectedDivision === 'cellular' && selectedPayroll.details?.subtotal_1 > 0 && (
                                    <div className="flex justify-between text-sm italic font-medium pt-1 border-t border-dashed border-gray-100">
                                        <span className="text-gray-500">Subtotal Gaji Rutin</span>
                                        <span className="text-gray-700">{formatCurrency(parseFloat(selectedPayroll.details.subtotal_1))}</span>
                                    </div>
                                )}

                                <div className="pt-2 border-t border-gray-100 flex justify-between font-bold text-gray-900 mt-2">
                                    <span>{selectedDivision === 'cellular' ? 'Total Gaji & Bonus (Gross)' : 'Total Pendapatan'}</span>
                                    <span>{formatCurrency(calculateGrossSalary(selectedPayroll, selectedDivision))}</span>
                                </div>
                            </div>
                        </div>

                        {/* Deductions */}
                        <div>
                            <h4 className="text-sm font-bold text-red-500 uppercase tracking-wider mb-4 border-b border-red-100 pb-2">Potongan</h4>
                            <div className="space-y-3">
                                {/* FnB/MM/Ref/Wrapping/Hans/Office/Cellular Deductions Breakdown */}
                                {(selectedDivision === 'tungtau' || selectedDivision === 'maximum' || selectedDivision === 'fnb' || selectedDivision === 'minimarket' || selectedDivision === 'reflexiology' || selectedDivision === 'wrapping' || selectedDivision === 'hans' || selectedDivision === 'office' || selectedDivision === 'cellular' || selectedDivision === 'money_changer') && selectedPayroll.deductions && (
                                    <>
                                        {Object.entries(selectedPayroll.deductions).map(([key, value]: [string, any]) => {
                                            const numValue = parseFloat(value);
                                            if (!numValue || numValue === 0) return null;

                                            // Skip EWA/Stafbook from general deductions as it's shown at the end (except for office where it's part of regular deductions)
                                            if (selectedDivision !== 'office' && (key.toLowerCase().includes('ewa') || key.toLowerCase().includes('stafbook'))) return null;

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
                                {selectedDivision !== 'tungtau' && selectedDivision !== 'fnb' && selectedDivision !== 'minimarket' && selectedDivision !== 'reflexiology' && selectedDivision !== 'wrapping' && selectedDivision !== 'hans' && selectedDivision !== 'cellular' && selectedDivision !== 'money_changer' && (
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

                                <div className="pt-2 border-t border-gray-100 flex justify-between font-bold text-gray-900 mt-2">
                                    <span>Total Potongan</span>
                                    <span className="text-red-600">
                                        -{formatCurrency(calculateTotalDeductions(selectedPayroll, selectedDivision))}
                                    </span>
                                </div>
                            </div>
                        </div>
                    </div>

                    {/* Net Salary Summary */}
                    <div className="mt-8 bg-[#1C3ECA] text-white p-6 rounded-xl space-y-4 shadow-lg">
                        {selectedDivision !== 'office' && selectedDivision !== 'all' && selectedPayroll.thp !== undefined ? (
                            <>
                                <div className="flex items-center justify-between border-b border-white/20 pb-4">
                                    <div>
                                        <p className="text-indigo-100 text-xs font-medium uppercase tracking-wider">Total Pendapatan (THP)</p>
                                        <p className="text-2xl font-bold">{formatCurrency(Number(
                                            selectedDivision === 'cellular'
                                                ? (selectedPayroll.net_salary || selectedPayroll.thp || 0)
                                                : (selectedPayroll.thp || 0)
                                        ))}</p>
                                    </div>
                                </div>
                                {parseFloat(String(selectedPayroll.ewa_amount || 0)) > 0 && (
                                    <div className="flex items-center justify-between border-b border-white/20 pb-4 text-red-200">
                                        <div>
                                            <p className="text-xs font-medium uppercase tracking-wider">Potongan Stafbook (EWA)</p>
                                            <p className="text-2xl font-bold">-{formatCurrency(typeof selectedPayroll.ewa_amount === 'string' ? (parseFloat(selectedPayroll.ewa_amount) || 0) : (selectedPayroll.ewa_amount || 0))}</p>
                                        </div>
                                    </div>
                                )}
                            </>
                        ) : (
                            <div className="flex items-center justify-between border-b border-white/20 pb-4">
                                <div>
                                    <p className="text-indigo-100 text-xs font-medium uppercase tracking-wider">Grand Total</p>
                                    <p className="text-2xl font-bold">{formatCurrency(selectedPayroll.gross_salary || selectedPayroll.net_salary)}</p>
                                </div>
                            </div>
                        )}

                        <div className="flex items-center justify-between">
                            <div>
                                <p className="text-indigo-100 text-sm font-medium">TOTAL DITRANSFER (PAYROLL)</p>
                                <p className="text-4xl font-black">
                                    {formatCurrency(
                                        selectedDivision === 'cellular' && Number(selectedPayroll.final_payment) > 0
                                            ? selectedPayroll.final_payment
                                            : selectedPayroll.net_salary
                                    )}
                                </p>
                            </div>
                            <div className="text-right">
                                <p className="text-xs text-indigo-200">Ditransfer ke</p>
                                <p className="font-semibold">Rekening Karyawan</p>
                                {selectedPayroll.account_number && (
                                    <p className="text-xs opacity-80">{selectedPayroll.account_number}</p>
                                )}
                            </div>
                        </div>
                    </div>
                </div>

                <div className="p-6 border-t border-gray-100 bg-gray-50 rounded-b-2xl flex justify-between items-center">
                    <div className="flex gap-2 w-full">
                        {/* Download Payslip Button */}
                        <button
                            onClick={handleDownload}
                            className="flex-1 bg-[#1C3ECA] text-white px-4 py-3 rounded-xl font-semibold hover:bg-[#523640] transition-colors flex items-center justify-center gap-2"
                        >
                            <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-4l-4 4m0 0l-4-4m4 4V4" />
                            </svg>
                            Download Slip Gaji (PDF)
                        </button>

                        {/* Approve Button (only for draft/pending status) */}
                        {(selectedPayroll.status === 'draft' || selectedPayroll.status === 'pending') && (
                            <button
                                onClick={() => onApprove(selectedPayroll.id)}
                                className="flex-1 bg-green-600 text-white px-4 py-3 rounded-xl font-semibold hover:bg-green-700 transition-colors flex items-center justify-center gap-2"
                            >
                                <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
                                </svg>
                                Approve
                            </button>
                        )}

                        <button
                            onClick={onClose}
                            className="px-6 py-3 border border-gray-300 rounded-xl font-semibold hover:bg-white transition-colors"
                        >
                            Tutup
                        </button>
                    </div>
                </div>
            </div>
        </div>
    );
}
