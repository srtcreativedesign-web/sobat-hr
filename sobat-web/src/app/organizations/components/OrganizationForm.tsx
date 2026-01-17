'use client';

import { useState, useEffect } from 'react';
import apiClient from '@/lib/api-client';

interface Organization {
    id: number;
    name: string;
    code: string;
    type: string;
    parent_id?: number | null;
    address?: string;
    phone?: string;
    email?: string;
    line_style?: string;
    description?: string;
}

interface OrganizationFormProps {
    isOpen: boolean;
    onClose: () => void;
    onSuccess: (org?: Organization) => void;
    initialData?: Organization | null;
    organizations: Organization[]; // For parent dropdown
    defaultParentId?: number | null;
}

export default function OrganizationForm({ isOpen, onClose, onSuccess, initialData, organizations, defaultParentId }: OrganizationFormProps) {
    const [formData, setFormData] = useState({
        name: '',
        code: '',
        type: 'department',
        parent_id: '',
        address: '',
        phone: '',
        email: '',
        line_style: 'solid',
        description: '',
    });
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState('');

    useEffect(() => {
        if (initialData) {
            setFormData({
                name: initialData.name || '',
                code: initialData.code || '',
                type: initialData.type || 'department',
                parent_id: initialData.parent_id?.toString() || '',
                address: initialData.address || '',
                phone: initialData.phone || '',
                email: initialData.email || '',
                line_style: initialData.line_style || 'solid',
                description: initialData.description || '',
            });
        } else {
            setFormData({
                name: '',
                code: '',
                type: 'department',
                parent_id: defaultParentId?.toString() || '',
                address: '',
                phone: '',
                email: '',
                line_style: 'solid',
                description: '',
            });
        }
        setError('');
    }, [initialData, isOpen, defaultParentId]);

    const handleSubmit = async (e: React.FormEvent) => {
        // ... (pre-submission)
        e.preventDefault();
        setLoading(true);
        setError('');

        const payload = {
            ...formData,
            parent_id: formData.parent_id ? parseInt(formData.parent_id) : null,
            email: formData.email || null,
            phone: formData.phone || null,
            address: formData.address || null,
            description: formData.description || null,
        };

        try {
            let response;
            if (initialData) {
                response = await apiClient.put(`/organizations/${initialData.id}`, payload);
            } else {
                response = await apiClient.post('/organizations', payload);
            }

            // Assume response.data.data is the Organization object (Laravel Resource standard)
            // Or response.data if it returns model directly.
            // Let's pass response.data for now, checking structure later if needed.
            // Safest to pass response.data or response.data.data
            const savedOrg = response.data.data || response.data;
            onSuccess(savedOrg);
            onClose();
        } catch (err: any) {
            console.error('Save Error:', err);
            console.log('Failed Payload:', payload);
            if (err.response) {
                console.error('Validation Response:', JSON.stringify(err.response.data, null, 2));
                console.error('Validation Errors:', err.response.data?.errors);
            }

            // Handle Laravel Validation Errors
            if (err.response?.status === 422 && err.response?.data?.errors) {
                const validationErrors = Object.values(err.response.data.errors).flat().join('\n');
                setError(validationErrors);
            } else {
                setError(err.response?.data?.message || 'Failed to save organization');
            }
        } finally {
            setLoading(false);
        }
    };

    if (!isOpen) return null;

    return (
        <div className="fixed inset-0 bg-black/50 backdrop-blur-sm z-50 flex items-center justify-center p-4">
            <div className="bg-white rounded-2xl shadow-2xl w-full max-w-lg border border-gray-100 animate-fade-in-up max-h-[90vh] overflow-y-auto">
                <div className="p-6 border-b border-gray-100 flex justify-between items-center sticky top-0 bg-white z-10">
                    <h2 className="text-xl font-bold text-[#462e37]">
                        {initialData ? 'Edit Organization' : 'New Organization'}
                    </h2>
                    <button onClick={onClose} className="text-gray-400 hover:text-[#462e37]">
                        <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" /></svg>
                    </button>
                </div>

                <form onSubmit={handleSubmit} className="p-6 space-y-4">
                    {error && (
                        <div className="p-3 bg-red-50 text-red-600 rounded-lg text-sm">
                            {error}
                        </div>
                    )}

                    <div className="grid grid-cols-2 gap-4">
                        <div>
                            <label className="block text-sm font-semibold text-[#462e37] mb-1">Name</label>
                            <input
                                type="text"
                                required
                                className="w-full px-4 py-2 border border-gray-200 rounded-lg focus:ring-2 focus:ring-[#a9eae2] focus:border-[#462e37] outline-none transition-all"
                                value={formData.name}
                                onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                                placeholder="e.g. Finance Dept"
                            />
                        </div>
                        <div>
                            <label className="block text-sm font-semibold text-[#462e37] mb-1">Code</label>
                            <input
                                type="text"
                                required
                                className="w-full px-4 py-2 border border-gray-200 rounded-lg focus:ring-2 focus:ring-[#a9eae2] focus:border-[#462e37] outline-none transition-all uppercase"
                                value={formData.code}
                                onChange={(e) => setFormData({ ...formData, code: e.target.value })}
                                placeholder="e.g. FIN-01"
                            />
                        </div>
                    </div>

                    <div className="grid grid-cols-2 gap-4">
                        <div>
                            <label className="block text-sm font-semibold text-[#462e37] mb-1">Type</label>
                            <select
                                className="w-full px-4 py-2 border border-gray-200 rounded-lg focus:ring-2 focus:ring-[#a9eae2] focus:border-[#462e37] outline-none transition-all"
                                value={formData.type}
                                onChange={(e) => setFormData({ ...formData, type: e.target.value })}
                            >
                                <option value="headquarters">Headquarters</option>
                                <option value="branch">Branch</option>
                                <option value="division">Division</option>
                                <option value="department">Department</option>
                            </select>
                        </div>
                    </div>

                    <div className="grid grid-cols-2 gap-4">
                        <div>
                            <label className="block text-sm font-semibold text-[#462e37] mb-1">Parent</label>
                            <select
                                className="w-full px-4 py-2 border border-gray-200 rounded-lg focus:ring-2 focus:ring-[#a9eae2] focus:border-[#462e37] outline-none transition-all"
                                value={formData.parent_id}
                                onChange={(e) => setFormData({ ...formData, parent_id: e.target.value })}
                            >
                                <option value="">None (Top Level)</option>
                                {organizations
                                    .filter(o => o.id !== initialData?.id) // Prevent self-parenting
                                    .map((org) => (
                                        <option key={org.id} value={org.id}>{org.name} ({org.type})</option>
                                    ))}
                            </select>
                        </div>
                        <div>
                            <label className="block text-sm font-semibold text-[#462e37] mb-1">Connector Style</label>
                            <select
                                className="w-full px-4 py-2 border border-gray-200 rounded-lg focus:ring-2 focus:ring-[#a9eae2] focus:border-[#462e37] outline-none transition-all"
                                value={formData.line_style}
                                onChange={(e) => setFormData({ ...formData, line_style: e.target.value })}
                            >
                                <option value="solid">Solid Line</option>
                                <option value="dashed">Dashed Line</option>
                                <option value="dotted">Dotted Line</option>
                            </select>
                        </div>
                    </div>

                    {/* Job Description / Uraian Jabatan */}
                    <div>
                        <label className="block text-sm font-semibold text-[#462e37] mb-1">Uraian Jabatan / Description</label>
                        <textarea
                            className="w-full px-4 py-2 border border-gray-200 rounded-lg focus:ring-2 focus:ring-[#a9eae2] focus:border-[#462e37] outline-none transition-all"
                            rows={4}
                            value={formData.description}
                            onChange={(e) => setFormData({ ...formData, description: e.target.value })}
                            placeholder="Deskripsikan tugas dan tanggung jawab bagian ini..."
                        />
                    </div>

                    <div>
                        <label className="block text-sm font-semibold text-[#462e37] mb-1">Phone & Email</label>
                        <div className="grid grid-cols-2 gap-4">
                            <input
                                type="text"
                                className="w-full px-4 py-2 border border-gray-200 rounded-lg focus:ring-2 focus:ring-[#a9eae2] focus:border-[#462e37] outline-none transition-all"
                                value={formData.phone}
                                onChange={(e) => setFormData({ ...formData, phone: e.target.value })}
                                placeholder="Phone"
                            />
                            <input
                                type="email"
                                className="w-full px-4 py-2 border border-gray-200 rounded-lg focus:ring-2 focus:ring-[#a9eae2] focus:border-[#462e37] outline-none transition-all"
                                value={formData.email}
                                onChange={(e) => setFormData({ ...formData, email: e.target.value })}
                                placeholder="Email"
                            />
                        </div>
                    </div>

                    <div>
                        <label className="block text-sm font-semibold text-[#462e37] mb-1">Address</label>
                        <textarea
                            className="w-full px-4 py-2 border border-gray-200 rounded-lg focus:ring-2 focus:ring-[#a9eae2] focus:border-[#462e37] outline-none transition-all"
                            rows={3}
                            value={formData.address}
                            onChange={(e) => setFormData({ ...formData, address: e.target.value })}
                            placeholder="Full address..."
                        />
                    </div>

                    <div className="flex gap-3 pt-4 border-t border-gray-100">
                        <button
                            type="button"
                            onClick={onClose}
                            className="flex-1 px-4 py-2 border border-gray-300 text-gray-700 font-semibold rounded-lg hover:bg-gray-50 transition-colors"
                        >
                            Cancel
                        </button>
                        <button
                            type="submit"
                            disabled={loading}
                            className="flex-1 px-4 py-2 bg-[#a9eae2] text-[#462e37] font-bold rounded-lg hover:shadow-lg hover:scale-[1.02] transform transition-all disabled:opacity-50"
                        >
                            {loading ? 'Saving...' : 'Save Organization'}
                        </button>
                    </div>
                </form>
            </div>
        </div>
    );
}
