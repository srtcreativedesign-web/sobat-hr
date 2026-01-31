'use client';

import { useState, useEffect } from 'react';
import DashboardLayout from '@/components/DashboardLayout';
import apiClient from '@/lib/api-client';
import PolicyForm from './components/PolicyForm';

export default function HrPoliciesPage() {
    const [items, setItems] = useState<any[]>([]);
    const [loading, setLoading] = useState(true);
    const [showForm, setShowForm] = useState(false);
    const [selectedItem, setSelectedItem] = useState<any>(null);


    useEffect(() => {
        fetchItems();
    }, []);

    const fetchItems = async () => {
        setLoading(true);
        try {
            // Fetch ALL announcements but verify if backend supports filtering or we filter frontend
            const response = await apiClient.get('/announcements');
            // Strict FILTER: Only show 'policy'
            const allItems = response.data.data || response.data || [];
            const policyItems = allItems.filter((item: any) => item.category === 'policy');
            setItems(policyItems);
        } catch (error) {
            console.error('Failed to fetch policies', error);
        } finally {
            setLoading(false);
        }
    };

    const handleEdit = (item: any) => {
        setSelectedItem(item);
        setShowForm(true);
    };

    const handleDelete = async (id: number) => {
        if (!confirm('Hapus item ini?')) return;
        try {
            await apiClient.delete(`/announcements/${id}`);
            fetchItems();
        } catch (error) {
            console.error('Failed to delete', error);
        }
    };

    const handleFormSuccess = () => {
        fetchItems();
    };

    // Items are already filtered in fetchItems

    return (
        <DashboardLayout>
            <div className="p-6">
                <div className="flex justify-between items-start mb-6">
                    <div>
                        <h1 className="text-3xl font-bold text-[#462e37]">Informasi & Regulasi</h1>
                        <p className="text-gray-500 mt-1">Kelola Pengumuman (News) dan Kebijakan HR (Policy).</p>
                    </div>
                    <button
                        onClick={() => { setSelectedItem(null); setShowForm(true); }}
                        className="px-6 py-2.5 bg-[#462e37] text-white rounded-xl hover:bg-[#2d1e24] transition-all shadow-lg shadow-[#462e37]/20 flex items-center gap-2 font-medium"
                    >
                        <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 4v16m8-8H4" /></svg>
                        Buat Baru
                    </button>
                </div>

                {/* Header Section Only - No Tabs */}

                <div className="grid grid-cols-1 gap-6">
                    {loading ? (
                        <div className="p-12 text-center">
                            <div className="inline-block animate-spin rounded-full h-8 w-8 border-4 border-[#a9eae2] border-t-transparent"></div>
                        </div>
                    ) : items.length === 0 ? (
                        <div className="text-center py-20 bg-gray-50 rounded-2xl border-2 border-dashed border-gray-200">
                            <p className="text-gray-500 font-medium">Belum ada data.</p>
                            <p className="text-sm text-gray-400 mt-1">Buat kebijakan baru.</p>
                        </div>
                    ) : (
                        items.map((item) => (
                            <div key={item.id} className="bg-white p-6 rounded-2xl shadow-sm border border-gray-100 hover:shadow-md transition-shadow relative group">
                                <div className="flex justify-between items-start">
                                    <div className="flex-1 pr-8">
                                        <div className="flex items-center gap-3 mb-2">
                                            {/* Category Badge */}
                                            <span className={`px-2 py-0.5 text-xs font-bold rounded-full uppercase tracking-wide ${item.category === 'news' ? 'bg-blue-100 text-blue-700' : 'bg-orange-100 text-orange-700'}`}>
                                                {item.category === 'news' ? 'NEWS' : 'POLICY'}
                                            </span>

                                            <h3 className="text-xl font-bold text-gray-900">{item.title}</h3>

                                            {item.is_published ? (
                                                <span className="px-2 py-0.5 bg-green-100 text-green-700 text-xs font-bold rounded-full uppercase tracking-wide">
                                                    Published
                                                </span>
                                            ) : (
                                                <span className="px-2 py-0.5 bg-yellow-100 text-yellow-700 text-xs font-bold rounded-full uppercase tracking-wide">
                                                    Draft
                                                </span>
                                            )}
                                        </div>
                                        <p className="text-gray-600 mb-4 whitespace-pre-wrap line-clamp-2">{item.content}</p>

                                        <div className="flex items-center gap-6 text-sm text-gray-500">
                                            <span>Date: <span className="font-semibold text-gray-700">{new Date(item.created_at).toLocaleDateString('id-ID', { day: 'numeric', month: 'long', year: 'numeric' })}</span></span>
                                            {item.attachment_url && (
                                                <a href={item.attachment_url} target="_blank" rel="noopener noreferrer" className="flex items-center gap-1 text-blue-600 hover:text-blue-800 font-medium">
                                                    <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15.172 7l-6.586 6.586a2 2 0 102.828 2.828l6.414-6.586a4 4 0 00-5.656-5.656l-6.415 6.585a6 6 0 108.486 8.486L20.5 13" /></svg>
                                                    View Attachment
                                                </a>
                                            )}
                                        </div>
                                    </div>

                                    <div className="flex gap-2 opacity-0 group-hover:opacity-100 transition-opacity absolute top-6 right-6">
                                        <button
                                            onClick={() => handleEdit(item)}
                                            className="p-2 text-gray-500 hover:text-indigo-600 hover:bg-indigo-50 rounded-lg transition-colors"
                                            title="Edit"
                                        >
                                            <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15.232 5.232l3.536 3.536m-2.036-5.036a2.5 2.5 0 113.536 3.536L6.5 21.036H3v-3.572L16.732 3.732z" /></svg>
                                        </button>
                                        <button
                                            onClick={() => handleDelete(item.id)}
                                            className="p-2 text-gray-500 hover:text-red-600 hover:bg-red-50 rounded-lg transition-colors"
                                            title="Delete"
                                        >
                                            <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" /></svg>
                                        </button>
                                    </div>
                                </div>
                            </div>
                        ))
                    )}
                </div>
            </div>

            <PolicyForm
                isOpen={showForm}
                onClose={() => setShowForm(false)}
                onSuccess={handleFormSuccess}
                initialData={selectedItem}
            />
        </DashboardLayout>
    );
}
