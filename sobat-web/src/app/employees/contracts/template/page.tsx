'use client';

import { useState, useEffect, useMemo } from 'react';
import DashboardLayout from '@/components/DashboardLayout';
import apiClient from '@/lib/api-client';
import { useRouter } from 'next/navigation';
import dynamic from 'next/dynamic';
import 'react-quill-new/dist/quill.snow.css';

// Dynamically import ReactQuill to avoid SSR issues
const ReactQuill = dynamic(
    async () => {
        const { default: RQ, Quill } = await import('react-quill-new');

        // Add custom fonts
        var Font = Quill.import('attributors/style/font');
        (Font as any).whitelist = ['sans-serif', 'serif', 'monospace', 'times-new-roman'];
        Quill.register(Font as any, true);

        return ({ forwardedRef, ...props }: any) => <RQ ref={forwardedRef} {...props} />;
    },
    { ssr: false }
);

export default function ContractTemplatePage() {
    const router = useRouter();
    const [content, setContent] = useState('');
    const [variables, setVariables] = useState<Record<string, string>>({});
    const [loading, setLoading] = useState(false);

    useEffect(() => {
        fetchTemplate();
    }, []);

    const fetchTemplate = async () => {
        try {
            setLoading(true);
            const response = await apiClient.get('/contract-templates');
            setContent(response.data.content);
            setVariables(response.data.variables);
        } catch (error) {
            console.error('Failed to fetch template:', error);
            alert('Failed to load template');
        } finally {
            setLoading(false);
        }
    };

    const handleSave = async () => {
        try {
            setLoading(true);
            await apiClient.put('/contract-templates', { content });
            alert('Template updated successfully');
        } catch (error) {
            console.error('Failed to update template:', error);
            alert('Failed to update template');
        } finally {
            setLoading(false);
        }
    };

    const handleRestore = async () => {
        if (!confirm('Are you sure you want to restore the default template? This will overwrite your changes.')) return;

        try {
            setLoading(true);
            const response = await apiClient.post('/contract-templates/restore');
            setContent(response.data.content);
            alert('Template restored to default');
        } catch (error) {
            console.error('Failed to restore template:', error);
            alert('Failed to restore template');
        } finally {
            setLoading(false);
        }
    };

    const modules = useMemo(() => ({
        toolbar: [
            [{ 'header': [1, 2, 3, false] }],
            [{ 'font': [] }],
            [{ 'size': ['small', false, 'large', 'huge'] }],
            ['bold', 'italic', 'underline', 'strike'],
            [{ 'color': [] }, { 'background': [] }],
            [{ 'list': 'ordered' }, { 'list': 'bullet' }],
            [{ 'align': [] }],
            ['clean']
        ],
    }), []);

    return (
        <DashboardLayout>
            <div className="h-[calc(100vh-64px)] flex flex-col bg-gray-50/50">

                {/* Header */}
                <div className="px-8 py-6 border-b border-gray-200 bg-white flex justify-between items-center shadow-sm">
                    <div className="flex items-center gap-4">
                        <button
                            onClick={() => router.back()}
                            className="p-2 hover:bg-gray-100 rounded-full transition-colors text-gray-500"
                        >
                            <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 19l-7-7 7-7" /></svg>
                        </button>
                        <div>
                            <h1 className="text-2xl font-bold text-[#462e37]">Contract Template Editor</h1>
                            <p className="text-sm text-gray-500">Customize the layout using the rich text editor below.</p>
                        </div>
                    </div>
                    <div className="flex gap-3">
                        <button
                            onClick={handleRestore}
                            disabled={loading}
                            className="px-4 py-2 text-sm font-medium text-red-600 bg-red-50 hover:bg-red-100 rounded-xl transition-colors"
                        >
                            Restore Default
                        </button>
                        <button
                            onClick={handleSave}
                            disabled={loading}
                            className="px-6 py-2 bg-[#462e37] hover:bg-[#2d1e24] text-white text-sm font-bold rounded-xl shadow-lg shadow-[#462e37]/20 transition-all transform active:scale-95 disabled:opacity-50 disabled:cursor-not-allowed flex items-center gap-2"
                        >
                            <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8 7H5a2 2 0 00-2 2v9a2 2 0 002 2h14a2 2 0 002-2V9a2 2 0 00-2-2h-3m-1 4l-3 3m0 0l-3-3m3 3V4" /></svg>
                            {loading ? 'Saving...' : 'Save Template'}
                        </button>
                    </div>
                </div>

                {/* Editor Area */}
                <div className="flex-1 flex overflow-hidden">

                    {/* Main Editor */}
                    <div className="flex-1 p-8 flex flex-col gap-4 overflow-y-auto">
                        <div className="bg-white rounded-2xl shadow-sm border border-gray-200 flex-1 flex flex-col overflow-hidden">
                            <ReactQuill
                                theme="snow"
                                value={content}
                                onChange={setContent}
                                modules={modules}
                                className="h-full flex flex-col [&_.ql-container]:flex-1 [&_.ql-container]:overflow-y-auto [&_.ql-editor]:h-full [&_.ql-editor]:text-base [&_.ql-editor]:font-serif [&_.ql-editor]:text-[#462e37]"

                            />
                        </div>
                    </div>

                    {/* Sidebar: Variables */}
                    <div className="w-96 bg-white border-l border-gray-200 flex flex-col">
                        <div className="p-6 border-b border-gray-100">
                            <h3 className="text-sm font-bold text-[#462e37] uppercase tracking-wider">Variables Reference</h3>
                            <p className="text-xs text-gray-500 mt-1">Click to copy placeholder to clipboard.</p>
                        </div>

                        <div className="flex-1 overflow-y-auto p-6 space-y-3">
                            {Object.entries(variables).map(([key, desc]) => (
                                <div key={key}
                                    className="group p-3 rounded-xl border border-gray-100 hover:border-[#462e37]/30 hover:bg-gray-50 cursor-pointer transition-all"
                                    onClick={() => {
                                        navigator.clipboard.writeText(key);
                                    }}
                                >
                                    <div className="flex items-center justify-between mb-1">
                                        <code className="text-xs font-bold text-[#462e37] bg-gray-100 px-2 py-1 rounded-md group-hover:bg-[#462e37] group-hover:text-white transition-colors">
                                            {key}
                                        </code>
                                        <svg className="w-4 h-4 text-gray-300 group-hover:text-[#462e37] opacity-0 group-hover:opacity-100 transition-all" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8 16H6a2 2 0 01-2-2V6a2 2 0 012-2h8a2 2 0 012 2v2m-6 12h8a2 2 0 002-2v-8a2 2 0 00-2-2h-8a2 2 0 00-2 2v8a2 2 0 002 2z" /></svg>
                                    </div>
                                    <p className="text-xs text-gray-500 ml-1">{desc}</p>
                                </div>
                            ))}
                        </div>

                        <div className="p-6 bg-gray-50 border-t border-gray-100">
                            <div className="p-4 bg-blue-50 text-blue-700 text-xs rounded-xl border border-blue-100">
                                <p className="font-bold mb-1 flex items-center gap-1">
                                    <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" /></svg>
                                    Pro Tip
                                </p>
                                Use the toolbar above to style your contract. The variables will be replaced with real data.
                            </div>
                        </div>
                    </div>
                </div>

            </div>
        </DashboardLayout>
    );
}
