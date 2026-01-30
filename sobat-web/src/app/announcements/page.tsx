'use client';

import { useState, useEffect } from 'react';
import DashboardLayout from '@/components/DashboardLayout';
import apiClient from '@/lib/api-client';
import Image from 'next/image';

interface Announcement {
    id: number;
    title: string;
    description: string;
    image_path: string | null;
    category: 'news' | 'policy';
    attachment_url: string | null;
    is_banner: boolean;
    is_active: boolean;
    start_date: string | null;
    end_date: string | null;
    created_at: string;
}

export default function AnnouncementsPage() {
    const [announcements, setAnnouncements] = useState<Announcement[]>([]);
    const [isLoading, setIsLoading] = useState(true);
    const [showModal, setShowModal] = useState(false);
    const [formData, setFormData] = useState({
        title: '',
        description: '',
        image: null as File | null,
        category: 'news',
        attachment: null as File | null,
        is_banner: false,
        is_active: true,
        start_date: '',
        end_date: ''
    });
    const [isSubmitting, setIsSubmitting] = useState(false);

    useEffect(() => {
        fetchAnnouncements();
    }, []);

    const fetchAnnouncements = async () => {
        try {
            const response = await apiClient.get('/announcements');
            setAnnouncements(response.data.data);
        } catch (error) {
            console.error('Failed to fetch announcements', error);
        } finally {
            setIsLoading(false);
        }
    };

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();

        // If it's a banner, we probably want an image
        if (formData.is_banner && !formData.image) {
            if (!confirm('You are creating a Popup Banner without an image. Are you sure?')) {
                return;
            }
        }

        setIsSubmitting(true);
        const data = new FormData();
        data.append('title', formData.title);
        data.append('description', formData.description);
        if (formData.image) data.append('image', formData.image);
        data.append('category', formData.category);
        if (formData.attachment) data.append('attachment', formData.attachment);
        data.append('is_active', formData.is_active ? '1' : '0');
        data.append('is_banner', formData.is_banner ? '1' : '0');
        if (formData.start_date) data.append('start_date', formData.start_date);
        if (formData.end_date) data.append('end_date', formData.end_date);

        try {
            await apiClient.post('/announcements', data, {
                headers: { 'Content-Type': 'multipart/form-data' }
            });
            setShowModal(false);
            setFormData({
                title: '',
                description: '',
                image: null,
                category: 'news',
                attachment: null,
                is_banner: false,
                is_active: true,
                start_date: '',
                end_date: ''
            });
            fetchAnnouncements();
        } catch (error) {
            console.error('Failed to create announcement', error);
            alert('Failed to create announcement');
        } finally {
            setIsSubmitting(false);
        }
    };

    const handleToggleActive = async (id: number, currentStatus: boolean) => {
        try {
            // Optimistic update
            setAnnouncements(prev => prev.map(a => a.id === id ? { ...a, is_active: !currentStatus } : a));

            await apiClient.put(`/announcements/${id}`, {
                is_active: !currentStatus
            });
        } catch (error) {
            console.error('Failed to update status', error);
            fetchAnnouncements(); // Revert
        }
    };

    const handleDelete = async (id: number) => {
        if (!confirm('Are you sure you want to delete this announcement?')) return;
        try {
            await apiClient.delete(`/announcements/${id}`);
            setAnnouncements(prev => prev.filter(a => a.id !== id));
        } catch (error) {
            console.error('Failed to delete', error);
        }
    };

    return (
        <DashboardLayout>
            <div className="p-8">
                <div className="flex justify-between items-center mb-6">
                    <div>
                        <h1 className="text-2xl font-bold text-gray-800">Announcements</h1>
                        <p className="text-gray-500">Manage News, Policies, and Popup Banners</p>
                    </div>
                    <button
                        onClick={() => setShowModal(true)}
                        className="px-4 py-2 bg-[#462e37] text-white rounded-xl hover:bg-[#2d1e24] transition-colors flex items-center gap-2"
                    >
                        <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 4v16m8-8H4" /></svg>
                        New Announcement
                    </button>
                </div>

                {/* List */}
                <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
                    {isLoading ? (
                        <p>Loading...</p>
                    ) : announcements.map((announcement) => (
                        <div key={announcement.id} className="bg-white rounded-xl border border-gray-100 shadow-sm overflow-hidden group hover:shadow-md transition-all flex flex-col">
                            {/* Image Header or Placeholder */}
                            <div className="relative h-48 w-full bg-gray-100">
                                {announcement.image_path ? (
                                    <Image
                                        src={`${process.env.NEXT_PUBLIC_API_URL?.replace('/api', '')}/storage/${announcement.image_path}`}
                                        alt={announcement.title}
                                        fill
                                        className="object-cover"
                                    />
                                ) : (
                                    <div className="flex items-center justify-center h-full text-gray-300">
                                        <svg className="w-12 h-12" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z" /></svg>
                                    </div>
                                )}

                                {/* Status Badge */}
                                <div className="absolute top-2 right-2 flex gap-2">
                                    <span className={`px-2 py-1 rounded-full text-xs font-bold shadow-sm ${announcement.is_active ? 'bg-green-100 text-green-700' : 'bg-gray-100 text-gray-500'}`}>
                                        {announcement.is_active ? 'Active' : 'Inactive'}
                                    </span>
                                </div>

                                {/* Category Badge */}
                                <div className="absolute top-2 left-2">
                                    <span className={`px-2 py-1 rounded-full text-xs font-bold shadow-sm uppercase ${announcement.category === 'news' ? 'bg-blue-100 text-blue-700' : 'bg-orange-100 text-orange-700'}`}>
                                        {announcement.category}
                                    </span>
                                </div>

                                {/* Banner Indicator */}
                                {announcement.is_banner && (
                                    <div className="absolute bottom-2 right-2 bg-[#462e37] text-white p-1 rounded-full shadow-md" title="Popup Banner on Login">
                                        <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M11.049 2.927c.3-.921 1.603-.921 1.902 0l1.519 4.674a1 1 0 00.95.69h4.915c.969 0 1.371 1.24.588 1.81l-3.976 2.888a1 1 0 00-.363 1.118l1.518 4.674c.3.922-.755 1.688-1.538 1.118l-3.976-2.888a1 1 0 00-1.176 0l-3.976 2.888c-.783.57-1.838-.197-1.538-1.118l1.518-4.674a1 1 0 00-.363-1.118l-3.976-2.888c-.784-.57-.38-1.81.588-1.81h4.914a1 1 0 00.951-.69l1.519-4.674z" /></svg>
                                    </div>
                                )}
                            </div>

                            <div className="p-4 flex-1 flex flex-col">
                                <h3 className="font-bold text-gray-800 mb-1">{announcement.title}</h3>
                                <p className="text-sm text-gray-500 line-clamp-2 mb-2 flex-1">{announcement.description}</p>

                                {announcement.attachment_url && (
                                    <div className="flex items-center gap-2 text-xs text-blue-600 mb-4 bg-blue-50 p-2 rounded-lg">
                                        <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15.172 7l-6.586 6.586a2 2 0 102.828 2.828l6.414-6.586a4 4 0 00-5.656-5.656l-6.415 6.585a6 6 0 108.486 8.486L20.5 13" /></svg>
                                        <span className="truncate">Has Attachment</span>
                                    </div>
                                )}

                                <div className="flex justify-between items-center pt-4 border-t border-gray-50 mt-auto">
                                    <div className="flex items-center gap-2">
                                        <button
                                            onClick={() => handleToggleActive(announcement.id, announcement.is_active)}
                                            className={`p-2 rounded-lg transition-colors ${announcement.is_active ? 'text-green-600 bg-green-50 hover:bg-green-100' : 'text-gray-400 bg-gray-50 hover:bg-gray-100'}`}
                                            title="Toggle Active"
                                        >
                                            <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" /></svg>
                                        </button>
                                        <button
                                            onClick={() => handleDelete(announcement.id)}
                                            className="p-2 text-red-400 hover:text-red-600 bg-red-50 hover:bg-red-100 rounded-lg transition-colors"
                                            title="Delete"
                                        >
                                            <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" /></svg>
                                        </button>
                                    </div>
                                    <span className="text-xs text-gray-400">
                                        {new Date(announcement.created_at).toLocaleDateString()}
                                    </span>
                                </div>
                            </div>
                        </div>
                    ))}
                </div>

                {/* Modal */}
                {showModal && (
                    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50 backdrop-blur-sm animate-fade-in">
                        <div className="bg-white rounded-2xl w-full max-w-lg p-6 shadow-xl max-h-[90vh] overflow-y-auto">
                            <h2 className="text-xl font-bold text-gray-800 mb-4">New Announcement</h2>
                            <form onSubmit={handleSubmit} className="space-y-4">
                                <div>
                                    <label className="block text-sm font-medium text-gray-700 mb-1">Title</label>
                                    <input
                                        type="text"
                                        required
                                        className="w-full px-4 py-2 rounded-xl border border-gray-200 focus:outline-none focus:ring-2 focus:ring-[#462e37]/20"
                                        value={formData.title || ''}
                                        onChange={e => setFormData({ ...formData, title: e.target.value })}
                                    />
                                </div>

                                <div className="grid grid-cols-2 gap-4">
                                    <div>
                                        <label className="block text-sm font-medium text-gray-700 mb-1">Category</label>
                                        <select
                                            className="w-full px-4 py-2 rounded-xl border border-gray-200 focus:outline-none focus:ring-2 focus:ring-[#462e37]/20 bg-white"
                                            value={formData.category || 'news'}
                                            onChange={e => setFormData({ ...formData, category: e.target.value })}
                                        >
                                            <option value="news">News / Pengumuman</option>
                                            <option value="policy">HR Policy / Kebijakan</option>
                                        </select>
                                    </div>
                                </div>

                                <div>
                                    <label className="block text-sm font-medium text-gray-700 mb-1">Description</label>
                                    <textarea
                                        className="w-full px-4 py-2 rounded-xl border border-gray-200 focus:outline-none focus:ring-2 focus:ring-[#462e37]/20"
                                        rows={3}
                                        value={formData.description || ''}
                                        onChange={e => setFormData({ ...formData, description: e.target.value })}
                                    />
                                </div>

                                <div>
                                    <label className="block text-sm font-medium text-gray-700 mb-1">Banner Image (Optional)</label>
                                    <input
                                        type="file"
                                        accept="image/*"
                                        className="w-full px-4 py-2 rounded-xl border border-gray-200 focus:outline-none focus:ring-2 focus:ring-[#462e37]/20"
                                        onChange={e => setFormData({ ...formData, image: e.target.files?.[0] || null })}
                                    />
                                    <p className="text-xs text-gray-400 mt-1">Required if "Popup Banner" is checked.</p>
                                </div>

                                <div>
                                    <label className="block text-sm font-medium text-gray-700 mb-1">Attachment (Document/PDF)</label>
                                    <input
                                        type="file"
                                        accept=".pdf,.doc,.docx"
                                        className="w-full px-4 py-2 rounded-xl border border-gray-200 focus:outline-none focus:ring-2 focus:ring-[#462e37]/20"
                                        onChange={e => setFormData({ ...formData, attachment: e.target.files?.[0] || null })}
                                    />
                                </div>

                                <div className="grid grid-cols-2 gap-4">
                                    <div>
                                        <label className="block text-sm font-medium text-gray-700 mb-1">Start Date (Optional)</label>
                                        <input
                                            type="date"
                                            className="w-full px-4 py-2 rounded-xl border border-gray-200 focus:outline-none focus:ring-2 focus:ring-[#462e37]/20"
                                            value={formData.start_date || ''}
                                            onChange={e => setFormData({ ...formData, start_date: e.target.value })}
                                        />
                                    </div>
                                    <div>
                                        <label className="block text-sm font-medium text-gray-700 mb-1">End Date (Optional)</label>
                                        <input
                                            type="date"
                                            className="w-full px-4 py-2 rounded-xl border border-gray-200 focus:outline-none focus:ring-2 focus:ring-[#462e37]/20"
                                            value={formData.end_date || ''}
                                            onChange={e => setFormData({ ...formData, end_date: e.target.value })}
                                        />
                                    </div>
                                </div>

                                <div className="space-y-3 pt-2">
                                    <div className="flex items-center gap-3 p-3 bg-gray-50 rounded-xl border border-gray-100">
                                        <input
                                            type="checkbox"
                                            id="is_active"
                                            className="w-5 h-5 rounded text-[#462e37] focus:ring-[#462e37]"
                                            checked={formData.is_active}
                                            onChange={e => setFormData({ ...formData, is_active: e.target.checked })}
                                        />
                                        <div>
                                            <label htmlFor="is_active" className="text-sm font-bold text-gray-800">Active Status</label>
                                            <p className="text-xs text-gray-500">Visible in app list immediately</p>
                                        </div>
                                    </div>

                                    <div className="flex items-center gap-3 p-3 bg-[#462e37]/5 rounded-xl border border-[#462e37]/10">
                                        <input
                                            type="checkbox"
                                            id="is_banner"
                                            className="w-5 h-5 rounded text-[#462e37] focus:ring-[#462e37]"
                                            checked={formData.is_banner}
                                            onChange={e => setFormData({ ...formData, is_banner: e.target.checked })}
                                        />
                                        <div>
                                            <label htmlFor="is_banner" className="text-sm font-bold text-[#462e37]">Popup Banner</label>
                                            <p className="text-xs text-[#462e37]/70">Show full-screen popup on login</p>
                                        </div>
                                    </div>
                                </div>

                                <div className="flex justify-end gap-3 mt-6">
                                    <button
                                        type="button"
                                        onClick={() => setShowModal(false)}
                                        className="px-4 py-2 text-gray-600 hover:bg-gray-100 rounded-xl transition-colors"
                                    >
                                        Cancel
                                    </button>
                                    <button
                                        type="submit"
                                        disabled={isSubmitting}
                                        className="px-4 py-2 bg-[#462e37] text-white rounded-xl hover:bg-[#2d1e24] transition-colors disabled:opacity-50"
                                    >
                                        {isSubmitting ? 'Creating...' : 'Create Announcement'}
                                    </button>
                                </div>
                            </form>
                        </div>
                    </div>
                )}
            </div>
        </DashboardLayout>
    );
}
