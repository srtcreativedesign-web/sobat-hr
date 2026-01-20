import { useState, useEffect } from 'react';
import apiClient from '@/lib/api-client';

interface EditContractModalProps {
    isOpen: boolean;
    onClose: () => void;
    employee: any;
    onSuccess: () => void;
}

export default function EditContractModal({ isOpen, onClose, employee, onSuccess }: EditContractModalProps) {
    const [formData, setFormData] = useState({
        contract_end_date: '',
        status: 'active',
    });
    const [loading, setLoading] = useState(false);

    useEffect(() => {
        if (employee) {
            setFormData({
                contract_end_date: employee.contract_end_date ? employee.contract_end_date.split('T')[0] : '',
                status: employee.status || 'active',
            });
        }
    }, [employee]);

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();
        try {
            setLoading(true);
            await apiClient.put(`/employees/${employee.id}`, {
                contract_end_date: formData.contract_end_date,
                status: formData.status,
            });
            alert('Contract updated successfully');
            onSuccess();
            onClose();
        } catch (error) {
            console.error('Failed to update contract:', error);
            alert('Failed to update contract');
        } finally {
            setLoading(false);
        }
    };

    if (!isOpen) return null;

    return (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50 backdrop-blur-sm">
            <div className="bg-white rounded-2xl w-full max-w-md shadow-2xl overflow-hidden animate-fade-in-up">
                <div className="p-6 border-b border-gray-100 flex justify-between items-center bg-gray-50/50">
                    <h2 className="text-xl font-bold text-[#462e37]">Edit Contract</h2>
                    <button onClick={onClose} className="p-2 hover:bg-gray-100 rounded-lg transition-colors">
                        <svg className="w-5 h-5 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" /></svg>
                    </button>
                </div>

                <form onSubmit={handleSubmit} className="p-6 space-y-6">
                    <div>
                        <label className="block text-xs font-bold text-gray-500 uppercase tracking-wider mb-2">Employee</label>
                        <div className="p-3 bg-gray-50 rounded-xl border border-gray-200">
                            <p className="font-bold text-[#462e37]">{employee?.full_name}</p>
                            <p className="text-xs text-gray-500">{employee?.employee_code}</p>
                        </div>
                    </div>

                    <div>
                        <label className="block text-xs font-bold text-gray-500 uppercase tracking-wider mb-2">Contract End Date</label>
                        <input
                            type="date"
                            required
                            value={formData.contract_end_date}
                            onChange={(e) => setFormData({ ...formData, contract_end_date: e.target.value })}
                            className="w-full px-4 py-3 bg-gray-50 border border-gray-200 rounded-xl focus:ring-2 focus:ring-[#462e37]/20 focus:border-[#462e37] outline-none transition-all"
                        />
                    </div>

                    <div>
                        <label className="block text-xs font-bold text-gray-500 uppercase tracking-wider mb-2">Status</label>
                        <div className="flex gap-2">
                            {['active', 'inactive'].map((s) => (
                                <button
                                    key={s}
                                    type="button"
                                    onClick={() => setFormData({ ...formData, status: s })}
                                    className={`flex-1 py-2 rounded-lg text-sm font-bold border transition-all ${formData.status === s
                                            ? 'bg-[#462e37] text-white border-[#462e37]'
                                            : 'bg-white text-gray-500 border-gray-200 hover:border-gray-300'
                                        }`}
                                >
                                    {s.toUpperCase()}
                                </button>
                            ))}
                        </div>
                    </div>

                    <div className="pt-4 flex gap-3">
                        <button
                            type="button"
                            onClick={onClose}
                            className="flex-1 py-3 bg-white border border-gray-200 text-gray-600 rounded-xl font-bold hover:bg-gray-50 transition-colors"
                        >
                            Cancel
                        </button>
                        <button
                            type="submit"
                            disabled={loading}
                            className="flex-1 py-3 bg-[#462e37] text-white rounded-xl font-bold hover:bg-[#2d1e24] transition-colors shadow-lg shadow-[#462e37]/20"
                        >
                            {loading ? 'Saving...' : 'Save Changes'}
                        </button>
                    </div>
                </form>
            </div>
        </div>
    );
}
