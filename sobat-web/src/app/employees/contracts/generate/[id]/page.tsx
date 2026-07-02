'use client';

import { useState, useEffect, use } from 'react';
import DashboardLayout from '@/components/DashboardLayout';
import apiClient from '@/lib/api-client';
import { useRouter } from 'next/navigation';

export default function GenerateContractPage({ params }: { params: Promise<{ id: string }> }) {
    const router = useRouter();
    const unwrappedParams = use(params);
    const employeeId = unwrappedParams.id;
    
    const [employee, setEmployee] = useState<any>(null);
    const [loading, setLoading] = useState(true);
    const [generating, setGenerating] = useState(false);
    
    const [formData, setFormData] = useState({
        contract_number: '',
        duration_months: 12,
        start_date: '',
        end_date: '',
    });

    useEffect(() => {
        if (employeeId) fetchEmployee();
    }, [employeeId]);

    const fetchEmployee = async () => {
        try {
            setLoading(true);
            const response = await apiClient.get(`/employees/${employeeId}`);
            const empData = response.data;
            setEmployee(empData);
            
            // Calculate defaults
            const currentYear = new Date().getFullYear();
            const currentEnd = empData.contract_end_date ? new Date(empData.contract_end_date) : new Date();
            
            const startD = new Date(currentEnd);
            startD.setDate(startD.getDate() + 1);
            
            const endD = new Date(startD);
            endD.setMonth(endD.getMonth() + 12);
            endD.setDate(endD.getDate() - 1);
            
            setFormData({
                contract_number: `PKWT/${currentYear}/${empData.employee_code || 'EMP'}`,
                duration_months: 12,
                start_date: startD.toISOString().split('T')[0],
                end_date: endD.toISOString().split('T')[0],
            });
            
        } catch (error) {
            console.error('Failed to load employee:', error);
            alert('Failed to load employee details');
        } finally {
            setLoading(false);
        }
    };
    
    // Auto calculate end date when duration or start date changes
    useEffect(() => {
        if (formData.start_date && formData.duration_months) {
            const startD = new Date(formData.start_date);
            const endD = new Date(startD);
            endD.setMonth(endD.getMonth() + Number(formData.duration_months));
            endD.setDate(endD.getDate() - 1);
            
            setFormData(prev => ({
                ...prev,
                end_date: endD.toISOString().split('T')[0]
            }));
        }
    }, [formData.start_date, formData.duration_months]);

    const handleGenerate = async () => {
        try {
            setGenerating(true);
            
            const payload = {
                contract_number: formData.contract_number,
                duration_months: formData.duration_months,
                start_date: formData.start_date,
                end_date: formData.end_date,
            };
            
            const response = await apiClient.post(`/contracts/generate-pdf/${employeeId}`, payload, {
                responseType: 'blob'
            });

            // Trigger download
            const url = window.URL.createObjectURL(new Blob([response.data]));
            const link = document.createElement('a');
            link.href = url;
            link.setAttribute('download', `Kontrak_${employee.full_name.replace(/\s+/g, '_')}.pdf`);
            document.body.appendChild(link);
            link.click();
            link.parentNode?.removeChild(link);
            
            alert('Contract generated and database updated successfully!');
            router.push('/employees/contracts');
            
        } catch (error) {
            console.error('Failed to generate contract:', error);
            alert('Failed to generate contract PDF');
        } finally {
            setGenerating(false);
        }
    };

    if (loading) {
        return (
            <DashboardLayout>
                <div className="p-8 flex justify-center">
                    <p className="text-gray-500 font-medium">Loading...</p>
                </div>
            </DashboardLayout>
        );
    }

    return (
        <DashboardLayout>
            <div className="p-8 max-w-3xl mx-auto">
                <div className="flex items-center gap-4 mb-8">
                    <button onClick={() => router.back()} className="p-2 hover:bg-gray-100 rounded-full transition-colors">
                        <svg className="w-6 h-6 text-gray-500" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 19l-7-7 7-7" /></svg>
                    </button>
                    <div>
                        <h1 className="text-2xl font-bold text-[#419cc3]">Generate Digital Contract</h1>
                        <p className="text-gray-500 mt-1">Configure contract parameters before generating PDF</p>
                    </div>
                </div>

                <div className="bg-white rounded-2xl shadow-sm border border-gray-100 overflow-hidden">
                    {/* Employee Profile Header */}
                    <div className="p-6 bg-gray-50 border-b border-gray-100 flex gap-4 items-center">
                        <div className="w-16 h-16 rounded-full bg-[#419cc3]/10 flex items-center justify-center text-[#419cc3] font-bold text-xl">
                            {employee?.full_name?.charAt(0)}
                        </div>
                        <div>
                            <h2 className="text-lg font-bold text-gray-900">{employee?.full_name}</h2>
                            <p className="text-sm text-gray-500">{employee?.employee_code} • {employee?.position}</p>
                            {employee?.contract_end_date && (
                                <p className="text-xs text-orange-600 mt-1 font-medium bg-orange-50 inline-block px-2 py-1 rounded">
                                    Current End Date: {new Date(employee.contract_end_date).toLocaleDateString('id-ID')}
                                </p>
                            )}
                        </div>
                    </div>

                    <div className="p-6 space-y-6">
                        <div>
                            <label className="block text-sm font-bold text-gray-700 mb-2">Contract Number</label>
                            <input 
                                type="text"
                                value={formData.contract_number}
                                onChange={(e) => setFormData({...formData, contract_number: e.target.value})}
                                className="w-full px-4 py-3 bg-gray-50 border border-gray-200 rounded-xl focus:ring-2 focus:ring-[#419cc3]/20 focus:border-[#419cc3] outline-none"
                            />
                        </div>

                        <div className="grid grid-cols-2 gap-6">
                            <div>
                                <label className="block text-sm font-bold text-gray-700 mb-2">Start Date</label>
                                <input 
                                    type="date"
                                    value={formData.start_date}
                                    onChange={(e) => setFormData({...formData, start_date: e.target.value})}
                                    className="w-full px-4 py-3 bg-gray-50 border border-gray-200 rounded-xl focus:ring-2 focus:ring-[#419cc3]/20 focus:border-[#419cc3] outline-none"
                                />
                            </div>
                            
                            <div>
                                <label className="block text-sm font-bold text-gray-700 mb-2">Duration (Months)</label>
                                <input 
                                    type="number"
                                    value={formData.duration_months}
                                    onChange={(e) => setFormData({...formData, duration_months: parseInt(e.target.value) || 0})}
                                    className="w-full px-4 py-3 bg-gray-50 border border-gray-200 rounded-xl focus:ring-2 focus:ring-[#419cc3]/20 focus:border-[#419cc3] outline-none"
                                />
                            </div>
                        </div>

                        <div>
                            <label className="block text-sm font-bold text-gray-700 mb-2">Calculated End Date</label>
                            <input 
                                type="date"
                                value={formData.end_date}
                                onChange={(e) => setFormData({...formData, end_date: e.target.value})}
                                className="w-full px-4 py-3 bg-gray-50 border border-gray-200 rounded-xl focus:ring-2 focus:ring-[#419cc3]/20 focus:border-[#419cc3] outline-none"
                            />
                            <p className="text-xs text-gray-500 mt-2">
                                Note: Generating this contract will automatically update the employee's contract end date in the system to this date.
                            </p>
                        </div>
                    </div>

                    <div className="p-6 bg-gray-50 border-t border-gray-100 flex justify-end gap-3">
                        <button 
                            onClick={() => router.back()}
                            className="px-6 py-2.5 bg-white border border-gray-200 text-gray-600 rounded-xl font-bold hover:bg-gray-100 transition-colors"
                        >
                            Cancel
                        </button>
                        <button 
                            onClick={handleGenerate}
                            disabled={generating}
                            className="px-6 py-2.5 bg-[#419cc3] text-white rounded-xl font-bold hover:bg-[#2d1e24] transition-colors shadow-lg shadow-[#419cc3]/20 flex items-center gap-2"
                        >
                            {generating ? 'Generating PDF...' : 'Generate & Update Database'}
                        </button>
                    </div>
                </div>
            </div>
        </DashboardLayout>
    );
}
