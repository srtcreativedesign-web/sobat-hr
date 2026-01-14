'use client';

import { useState, useEffect } from 'react';
import apiClient from '@/lib/api-client';

interface PolicyFormProps {
    isOpen: boolean;
    onClose: () => void;
    onSuccess: () => void;
    initialData?: any;
}

export default function PolicyForm({ isOpen, onClose, onSuccess, initialData }: PolicyFormProps) {
    const [loading, setLoading] = useState(false);
    const [title, setTitle] = useState('');
    const [content, setContent] = useState('');
    const [isPublished, setIsPublished] = useState(false);
    const [file, setFile] = useState<File | null>(null);

    useEffect(() => {
        if (initialData) {
            setTitle(initialData.title);
            setContent(initialData.content);
            setIsPublished(initialData.is_published);
            setFile(null);
        } else {
            setTitle('');
            setContent('');
            setIsPublished(false);
            setFile(null);
        }
    }, [initialData, isOpen]);

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();
        setLoading(true);

        try {
            const formData = new FormData();
            formData.append('title', title);
            formData.append('content', content);
            formData.append('is_published', isPublished ? '1' : '0');
            if (file) {
                formData.append('attachment', file);
            }

            // Important: For PUT requests with FormData (file upload), Laravel/PHP often requires
            // POST method with _method=PUT to handle multipart/form-data correctly.
            if (initialData?.id) {
                formData.append('_method', 'PUT');
                await apiClient.post(`/policies/${initialData.id}`, formData, {
                    headers: { 'Content-Type': 'multipart/form-data' }
                });
            } else {
                await apiClient.post('/policies', formData, {
                    headers: { 'Content-Type': 'multipart/form-data' }
                });
            }

            onSuccess();
            onClose();
        } catch (error: any) {
            alert(error.response?.data?.message || 'Failed to save policy');
        } finally {
            setLoading(false);
        }
    };

    if (!isOpen) return null;

    return (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
            <div className="bg-white rounded-xl max-w-2xl w-full p-6 animate-fade-in-up">
                <div className="flex justify-between items-center mb-6">
                    <h2 className="text-xl font-bold text-gray-900">{initialData ? 'Edit Policy' : 'New Policy'}</h2>
                    <button onClick={onClose} className="text-gray-400 hover:text-gray-600">
                        <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" /></svg>
                    </button>
                </div>

                <form onSubmit={handleSubmit} className="space-y-6">
                    <div>
                        <label className="block text-sm font-medium text-gray-700 mb-1">Judul Kebijakan</label>
                        <input
                            type="text"
                            required
                            className="w-full px-4 py-2 border border-gray-200 rounded-lg focus:ring-2 focus:ring-[#a9eae2] outline-none"
                            placeholder="e.g. Kebijakan Cuti Tahunan 2026"
                            value={title}
                            onChange={(e) => setTitle(e.target.value)}
                        />
                    </div>

                    <div>
                        <label className="block text-sm font-medium text-gray-700 mb-1">Konten / Isi Pengumuman</label>
                        <textarea
                            required
                            rows={6}
                            className="w-full px-4 py-2 border border-gray-200 rounded-lg focus:ring-2 focus:ring-[#a9eae2] outline-none"
                            placeholder="Tulis detail kebijakan di sini..."
                            value={content}
                            onChange={(e) => setContent(e.target.value)}
                        ></textarea>
                    </div>

                    <div>
                        <label className="block text-sm font-medium text-gray-700 mb-1">Lampiran (PDF/Doc/Image) - Optional</label>
                        <input
                            type="file"
                            className="w-full text-sm text-gray-500 file:mr-4 file:py-2 file:px-4 file:rounded-full file:border-0 file:text-sm file:font-semibold file:bg-[#a9eae2]/20 file:text-[#462e37] hover:file:bg-[#a9eae2]/30"
                            onChange={(e) => setFile(e.target.files ? e.target.files[0] : null)}
                        />
                        {initialData?.attachment_url && !file && (
                            <p className="mt-2 text-xs text-blue-600">
                                <a href={initialData.attachment_url} target="_blank" rel="noopener noreferrer" className="hover:underline">
                                    Current Attachment: View
                                </a>
                            </p>
                        )}
                    </div>

                    <div className="flex items-center gap-2">
                        <input
                            type="checkbox"
                            id="is_published"
                            className="w-4 h-4 text-[#462e37] border-gray-300 rounded focus:ring-[#a9eae2]"
                            checked={isPublished}
                            onChange={(e) => setIsPublished(e.target.checked)}
                        />
                        <label htmlFor="is_published" className="text-sm font-medium text-gray-700">
                            Langsung Publish?
                            <span className="text-xs text-gray-500 ml-1">(Akan muncul di Mobile App user)</span>
                        </label>
                    </div>

                    <div className="flex justify-end gap-3 pt-4 border-t border-gray-100">
                        <button
                            type="button"
                            onClick={onClose}
                            className="px-6 py-2 bg-gray-100 text-gray-700 font-medium rounded-lg hover:bg-gray-200 transition-colors"
                        >
                            Batal
                        </button>
                        <button
                            type="submit"
                            disabled={loading}
                            className="px-6 py-2 bg-[#462e37] text-white font-bold rounded-lg hover:bg-[#2d1e24] transition-colors disabled:opacity-50"
                        >
                            {loading ? 'Saving...' : 'Simpan Kebijakan'}
                        </button>
                    </div>
                </form>
            </div>
        </div>
    );
}
