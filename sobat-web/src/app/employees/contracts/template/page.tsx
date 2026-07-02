'use client';

import { useState, useEffect, useMemo, useRef } from 'react';
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
        (Font as any).whitelist = ['Arial'];
        Quill.register(Font as any, true);

        // Add custom sizes (numeric)
        var Size = Quill.import('attributors/style/size');
        Size.whitelist = ['10px', '11px', '12px', '14px', '16px', '18px', '20px', '24px', '32px', '48px'];
        Quill.register(Size, true);

        return ({ forwardedRef, ...props }: any) => <RQ ref={forwardedRef} {...props} />;
    },
    { ssr: false }
);

const PAPER_SIZES = {
    A4: { width: '21cm', height: '29.7cm', name: 'A4' },
    F4: { width: '21.5cm', height: '33cm', name: 'F4 (Folio)' },
    Letter: { width: '21.59cm', height: '27.94cm', name: 'Letter' },
    Legal: { width: '21.59cm', height: '35.56cm', name: 'Legal' },
};

export default function ContractTemplatePage() {
    const router = useRouter();
    const [content, setContent] = useState('');
    const [variables, setVariables] = useState<Record<string, string>>({});
    const [loading, setLoading] = useState(false);
    const [isExtracting, setIsExtracting] = useState(false);
    const [isFullscreen, setIsFullscreen] = useState(false);
    const [showSettingsModal, setShowSettingsModal] = useState(false);
    const [paperSize, setPaperSize] = useState<keyof typeof PAPER_SIZES>('A4');
    const [margins, setMargins] = useState({ top: 2, right: 2, bottom: 2, left: 2 });
    const fileInputRef = useRef<HTMLInputElement>(null);
    const reactQuillRef = useRef<any>(null);

    const handleInsertVariable = (variable: string) => {
        if (reactQuillRef.current) {
            const editor = reactQuillRef.current.getEditor();
            // Focus if not already focused
            editor.focus();
            const cursorPosition = editor.getSelection()?.index || 0;
            editor.insertText(cursorPosition, variable);
            editor.setSelection(cursorPosition + variable.length);
        }
    };

    const handlePrintPreview = () => {
        const printWindow = window.open('', '_blank');
        if (printWindow) {
            let pageSizeCss = 'A4';
            if (paperSize === 'F4') pageSizeCss = '21.5cm 33cm';
            else if (paperSize === 'Letter') pageSizeCss = 'letter';
            else if (paperSize === 'Legal') pageSizeCss = 'legal';
            
            printWindow.document.write(`
                <html>
                    <head>
                        <title>Print Preview - Contract Template</title>
                        <style>
                            @page { 
                                size: ${pageSizeCss}; 
                                margin: ${margins.top}cm ${margins.right}cm ${margins.bottom}cm ${margins.left}cm; 
                            }
                            body { 
                                font-family: "Times New Roman", Times, serif;
                                line-height: 1.5;
                                color: #111827;
                                margin: 0; 
                                padding: 0;
                            }
                            /* Basic Quill Styles */
                            p { margin: 0 0 1em 0; }
                            h1, h2, h3, h4, h5, h6 { font-weight: bold; margin-bottom: 0.5em; }
                            strong { font-weight: bold; }
                            em { font-style: italic; }
                            ul, ol { padding-left: 1.5em; margin-bottom: 1em; }
                            .ql-align-center { text-align: center; }
                            .ql-align-right { text-align: right; }
                            .ql-align-justify { text-align: justify; }
                            table { width: 100%; border-collapse: collapse; margin-bottom: 1em; }
                            table td, table th { padding: 0.5em; vertical-align: top; }
                        </style>
                    </head>
                    <body>
                        ${content}
                        <script>
                            setTimeout(() => {
                                window.print();
                                window.close();
                            }, 500);
                        </script>
                    </body>
                </html>
            `);
            printWindow.document.close();
        }
    };

    useEffect(() => {
        fetchTemplate();
    }, []);

    const fetchTemplate = async () => {
        try {
            setLoading(true);
            const response = await apiClient.get('/contract-templates');
            setContent(response.data.content || '');
            setVariables(response.data.variables || {});
            
            if (response.data.settings) {
                if (response.data.settings.paperSize) setPaperSize(response.data.settings.paperSize);
                if (response.data.settings.marginTop !== undefined) {
                    setMargins({
                        top: response.data.settings.marginTop,
                        right: response.data.settings.marginRight,
                        bottom: response.data.settings.marginBottom,
                        left: response.data.settings.marginLeft
                    });
                }
            }
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
            const settings = {
                paperSize,
                marginTop: margins.top,
                marginRight: margins.right,
                marginBottom: margins.bottom,
                marginLeft: margins.left
            };
            await apiClient.put('/contract-templates', { content, settings });
            alert('Template saved successfully!');
        } catch (error) {
            console.error('Failed to save template:', error);
            alert('Failed to save template');
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

    const handleFileUpload = async (event: React.ChangeEvent<HTMLInputElement>) => {
        const file = event.target.files?.[0];
        if (!file) return;

        try {
            setIsExtracting(true);
            const extension = file.name.split('.').pop()?.toLowerCase();

            if (extension === 'docx') {
                const mammoth = (await import('mammoth')).default;
                const arrayBuffer = await file.arrayBuffer();
                const result = await mammoth.convertToHtml({ arrayBuffer });
                
                // Auto-remove consecutive dots or unicode ellipses usually used for manual forms
                const cleanHtml = result.value.replace(/[\.\u2026]{2,}/g, '');
                
                if (content.trim()) {
                   if (confirm('Overwrite current template with extracted DOCX content?')) {
                       setContent(cleanHtml);
                   } else {
                       setContent(content + '<br><br>' + cleanHtml);
                   }
                } else {
                   setContent(cleanHtml);
                }
            } else if (extension === 'pdf') {
                const pdfjsLib = await import('pdfjs-dist');
                // Use CDN for worker to avoid next.js build issues with canvas/worker
                pdfjsLib.GlobalWorkerOptions.workerSrc = `//cdnjs.cloudflare.com/ajax/libs/pdf.js/${pdfjsLib.version}/pdf.worker.min.js`;
                
                const arrayBuffer = await file.arrayBuffer();
                const pdf = await pdfjsLib.getDocument({ data: arrayBuffer }).promise;
                
                let extractedText = '';
                for (let i = 1; i <= pdf.numPages; i++) {
                    const page = await pdf.getPage(i);
                    const textContent = await page.getTextContent();
                    const pageText = textContent.items.map((item: any) => item.str).join(' ');
                    extractedText += `<p>${pageText}</p>`;
                }
                
                if (content.trim()) {
                   if (confirm('Overwrite current template with extracted PDF content? (Warning: formatting is lost)')) {
                       setContent(extractedText);
                   } else {
                       setContent(content + '<br><br>' + extractedText);
                   }
                } else {
                   setContent(extractedText);
                }
            } else {
                alert('Please upload a .docx or .pdf file');
            }
        } catch (error) {
            console.error('Extraction error:', error);
            alert('Failed to extract file. Please check if the file is valid.');
        } finally {
            setIsExtracting(false);
            if (fileInputRef.current) fileInputRef.current.value = '';
        }
    };

    const modules = useMemo(() => ({
        toolbar: [
            [{ 'header': [1, 2, 3, false] }],
            [{ 'font': [false, 'Arial'] }],
            [{ 'size': ['10px', '11px', '12px', '14px', '16px', '18px', '20px', '24px', '32px', '48px'] }],
            ['bold', 'italic', 'underline', 'strike'],
            [{ 'color': [] }, { 'background': [] }],
            [{ 'list': 'ordered' }, { 'list': 'bullet' }],
            [{ 'align': [] }],
            ['clean']
        ],
        table: true
    }), []);

    const handleTableAction = (action: string) => {
        if (!reactQuillRef.current) return;
        const quill = reactQuillRef.current.getEditor();
        const table = quill.getModule('table');
        
        switch (action) {
            case 'insert-table': table.insertTable(2, 2); break;
            case 'insert-row-above': table.insertRowAbove(); break;
            case 'insert-row-below': table.insertRowBelow(); break;
            case 'insert-col-left': table.insertColumnLeft(); break;
            case 'insert-col-right': table.insertColumnRight(); break;
            case 'delete-row': table.deleteRow(); break;
            case 'delete-col': table.deleteColumn(); break;
            case 'delete-table': table.deleteTable(); break;
        }
    };

    return (
        <DashboardLayout>
            <div className={`flex flex-col bg-gray-50/50 ${isFullscreen ? 'fixed inset-0 z-50 h-screen' : 'h-[calc(100vh-64px)]'}`}>

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
                            <h1 className="text-2xl font-bold text-[#419cc3]">Contract Template Editor</h1>
                            <p className="text-sm text-gray-500">Customize the layout using the rich text editor below.</p>
                        </div>
                    </div>
                    <div className="flex gap-3 items-center">
                        <button
                            onClick={() => setShowSettingsModal(true)}
                            className="px-4 py-2 text-sm font-medium text-gray-700 bg-gray-100 hover:bg-gray-200 rounded-xl transition-colors flex items-center gap-2"
                        >
                            <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z" /><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" /></svg>
                            Document Settings
                        </button>
                        <button
                            onClick={handlePrintPreview}
                            className="p-2 text-gray-500 hover:bg-gray-100 rounded-xl transition-colors hidden md:block"
                            title="Print Preview"
                        >
                            <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17 17h2a2 2 0 002-2v-4a2 2 0 00-2-2H5a2 2 0 00-2 2v4a2 2 0 002 2h2m2 4h6a2 2 0 002-2v-4a2 2 0 00-2-2H9a2 2 0 00-2 2v4a2 2 0 002 2zm8-12V5a2 2 0 00-2-2H9a2 2 0 00-2 2v4h10z" /></svg>
                        </button>
                        <button
                            onClick={() => setIsFullscreen(!isFullscreen)}
                            className="p-2 text-gray-500 hover:bg-gray-100 rounded-xl transition-colors hidden md:block"
                            title={isFullscreen ? "Exit Fullscreen" : "Fullscreen"}
                        >
                            {isFullscreen ? (
                                <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" /></svg> // Use a close/shrink icon or proper fullscreen exit icon
                            ) : (
                                <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 8V4m0 0h4M4 4l5 5m11-1V4m0 0h-4m4 0l-5 5M4 16v4m0 0h4m-4 0l5-5m11 5l-5-5m5 5v-4m0 4h-4" /></svg>
                            )}
                        </button>
                        <input 
                            type="file" 
                            accept=".docx,.pdf" 
                            className="hidden" 
                            ref={fileInputRef} 
                            onChange={handleFileUpload} 
                        />
                        <button
                            onClick={() => fileInputRef.current?.click()}
                            disabled={isExtracting || loading}
                            className="px-4 py-2 text-sm font-medium text-gray-700 bg-gray-100 hover:bg-gray-200 rounded-xl transition-colors flex items-center gap-2"
                        >
                            {isExtracting ? (
                                <svg className="animate-spin w-4 h-4 text-gray-600" fill="none" viewBox="0 0 24 24"><circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle><path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path></svg>
                            ) : (
                                <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-8l-4-4m0 0L8 8m4-4v12" /></svg>
                            )}
                            Upload Template
                        </button>
                        <button
                            onClick={handleRestore}
                            disabled={loading || isExtracting}
                            className="px-4 py-2 text-sm font-medium text-red-600 bg-red-50 hover:bg-red-100 rounded-xl transition-colors"
                        >
                            Restore Default
                        </button>
                        <button
                            onClick={handleSave}
                            disabled={loading}
                            className="px-6 py-2 bg-[#419cc3] hover:bg-[#2d1e24] text-white text-sm font-bold rounded-xl shadow-lg shadow-[#419cc3]/20 transition-all transform active:scale-95 disabled:opacity-50 disabled:cursor-not-allowed flex items-center gap-2"
                        >
                            <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8 7H5a2 2 0 00-2 2v9a2 2 0 002 2h14a2 2 0 002-2V9a2 2 0 00-2-2h-3m-1 4l-3 3m0 0l-3-3m3 3V4" /></svg>
                            {loading ? 'Saving...' : 'Save Template'}
                        </button>
                    </div>
                </div>

                {/* Table Editor Toolbar */}
                <div className="px-8 py-2 bg-gray-50 border-b border-gray-200 flex flex-wrap gap-2 items-center text-xs overflow-x-auto">
                    <span className="font-bold text-gray-500 mr-2 uppercase tracking-wider text-[10px]">Table Tools</span>
                    <button onClick={() => handleTableAction('insert-table')} className="px-3 py-1.5 bg-white border border-gray-200 text-gray-700 rounded-md hover:bg-gray-100 transition-colors">➕ Insert Table</button>
                    <div className="w-px h-4 bg-gray-300 mx-1"></div>
                    <button onClick={() => handleTableAction('insert-row-above')} className="px-3 py-1.5 bg-white border border-gray-200 text-gray-700 rounded-md hover:bg-gray-100 transition-colors">Row Above</button>
                    <button onClick={() => handleTableAction('insert-row-below')} className="px-3 py-1.5 bg-white border border-gray-200 text-gray-700 rounded-md hover:bg-gray-100 transition-colors">Row Below</button>
                    <button onClick={() => handleTableAction('delete-row')} className="px-3 py-1.5 bg-red-50 border border-red-200 text-red-600 rounded-md hover:bg-red-100 transition-colors">Delete Row</button>
                    <div className="w-px h-4 bg-gray-300 mx-1"></div>
                    <button onClick={() => handleTableAction('insert-col-left')} className="px-3 py-1.5 bg-white border border-gray-200 text-gray-700 rounded-md hover:bg-gray-100 transition-colors">Col Left</button>
                    <button onClick={() => handleTableAction('insert-col-right')} className="px-3 py-1.5 bg-white border border-gray-200 text-gray-700 rounded-md hover:bg-gray-100 transition-colors">Col Right</button>
                    <button onClick={() => handleTableAction('delete-col')} className="px-3 py-1.5 bg-red-50 border border-red-200 text-red-600 rounded-md hover:bg-red-100 transition-colors">Delete Col</button>
                    <div className="w-px h-4 bg-gray-300 mx-1"></div>
                    <button onClick={() => handleTableAction('delete-table')} className="px-3 py-1.5 bg-red-100 border border-red-300 text-red-700 rounded-md hover:bg-red-200 font-medium transition-colors">Delete Table</button>
                </div>

                {/* Editor Area */}
                <div className="flex-1 flex overflow-hidden">
                    <style>{`
                        .custom-paper-editor .ql-editor {
                            max-width: ${PAPER_SIZES[paperSize].width} !important;
                            min-height: ${PAPER_SIZES[paperSize].height} !important;
                            padding: ${margins.top}cm ${margins.right}cm ${margins.bottom}cm ${margins.left}cm !important;
                            background-image: repeating-linear-gradient(
                                to bottom,
                                transparent,
                                transparent calc(${PAPER_SIZES[paperSize].height} - 2px),
                                #93c5fd calc(${PAPER_SIZES[paperSize].height} - 2px),
                                #93c5fd ${PAPER_SIZES[paperSize].height}
                            );
                        }
                        /* Optional: add a pseudo element to label the lines, but repeating-linear-gradient is background only. We can just keep it as a blue line. */
                        .custom-paper-editor .ql-editor table {
                            width: 100%;
                            border-collapse: collapse;
                            margin-bottom: 1em;
                        }
                        .custom-paper-editor .ql-editor table td,
                        .custom-paper-editor .ql-editor table th {
                            border: 1px dashed #cbd5e1; /* Visual guide only */
                            padding: 0.5em;
                            vertical-align: top;
                        }
                        
                        @media print {
                            .custom-paper-editor .ql-editor table td,
                            .custom-paper-editor .ql-editor table th {
                                border: none !important;
                            }
                        }
                        
                        /* Set Default Font for Editor */
                        .custom-paper-editor .ql-editor {
                            font-family: "Times New Roman", Times, serif;
                        }
                        
                        /* Font Dropdown Setup */
                        .ql-snow .ql-picker.ql-font {
                            width: 140px !important;
                        }
                        .ql-snow .ql-picker.ql-font .ql-picker-label[data-value="Arial"]::before,
                        .ql-snow .ql-picker.ql-font .ql-picker-item[data-value="Arial"]::before {
                            content: "Arial" !important;
                            font-family: Arial, sans-serif;
                        }
                        .ql-snow .ql-picker.ql-font .ql-picker-label::before,
                        .ql-snow .ql-picker.ql-font .ql-picker-item::before {
                            content: 'Times New Roman' !important;
                            font-family: "Times New Roman", Times, serif;
                        }

                        /* Display numeric values in font size dropdown */
                        .ql-snow .ql-picker.ql-size .ql-picker-label[data-value]::before,
                        .ql-snow .ql-picker.ql-size .ql-picker-item[data-value]::before {
                            content: attr(data-value) !important;
                        }
                        .ql-snow .ql-picker.ql-size .ql-picker-label::before,
                        .ql-snow .ql-picker.ql-size .ql-picker-item::before {
                            content: 'Normal' !important;
                        }
                    `}</style>

                    {/* Main Editor */}
                    <div className="flex-1 p-8 flex flex-col gap-4 overflow-y-auto">
                        <div className="bg-white rounded-2xl shadow-sm border border-gray-200 flex-1 flex flex-col overflow-hidden">
                            <ReactQuill
                                forwardedRef={reactQuillRef}
                                theme="snow"
                                value={content}
                                onChange={setContent}
                                modules={modules}
                                className="custom-paper-editor h-full flex flex-col [&_.ql-toolbar]:border-none [&_.ql-toolbar]:border-b [&_.ql-toolbar]:border-gray-200 [&_.ql-toolbar]:bg-white [&_.ql-toolbar]:sticky [&_.ql-toolbar]:top-0 [&_.ql-toolbar]:z-10 [&_.ql-container]:flex-1 [&_.ql-container]:overflow-y-auto [&_.ql-container]:bg-[#f3f4f6] [&_.ql-container]:p-4 [&_.ql-container]:md:p-8 [&_.ql-editor]:bg-white [&_.ql-editor]:w-full [&_.ql-editor]:mx-auto [&_.ql-editor]:p-[2cm] [&_.ql-editor]:shadow-md [&_.ql-editor]:text-base [&_.ql-editor]:font-serif [&_.ql-editor]:text-gray-900"

                            />
                        </div>
                    </div>

                    {/* Sidebar: Variables */}
                    {!isFullscreen && (
                        <div className="w-96 bg-white border-l border-gray-200 flex flex-col">
                            <div className="p-6 border-b border-gray-100">
                                <h3 className="text-sm font-bold text-[#419cc3] uppercase tracking-wider">Variables Reference</h3>
                                <p className="text-xs text-gray-500 mt-1">Click to automatically insert placeholder at your cursor position.</p>
                            </div>

                            <div className="flex-1 overflow-y-auto p-6 space-y-3">
                                {Object.entries(variables).map(([key, desc]) => (
                                    <div key={key}
                                        className="group p-3 rounded-xl border border-gray-100 hover:border-[#419cc3]/30 hover:bg-gray-50 cursor-pointer transition-all"
                                        onClick={() => handleInsertVariable(key)}
                                    >
                                        <div className="flex items-center justify-between mb-1">
                                            <code className="text-xs font-bold text-[#419cc3] bg-gray-100 px-2 py-1 rounded-md group-hover:bg-[#419cc3] group-hover:text-white transition-colors">
                                                {key}
                                            </code>
                                            <svg className="w-4 h-4 text-gray-300 group-hover:text-[#419cc3] opacity-0 group-hover:opacity-100 transition-all" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8 16H6a2 2 0 01-2-2V6a2 2 0 012-2h8a2 2 0 012 2v2m-6 12h8a2 2 0 002-2v-8a2 2 0 00-2-2h-8a2 2 0 00-2 2v8a2 2 0 002 2z" /></svg>
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
                    )}
                </div>

            </div>

            {/* Document Settings Modal */}
            {showSettingsModal && (
                <div className="fixed inset-0 z-[60] flex items-center justify-center p-4 bg-gray-900/50 backdrop-blur-sm">
                    <div className="bg-white rounded-3xl shadow-xl w-full max-w-md overflow-hidden flex flex-col">
                        <div className="p-6 border-b border-gray-100 flex justify-between items-center">
                            <h2 className="text-lg font-bold text-gray-900">Document Settings</h2>
                            <button onClick={() => setShowSettingsModal(false)} className="text-gray-400 hover:text-gray-600 transition-colors">
                                <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" /></svg>
                            </button>
                        </div>
                        
                        <div className="p-6 space-y-6">
                            <div>
                                <label className="block text-sm font-bold text-gray-700 mb-2">Paper Size</label>
                                <select
                                    value={paperSize}
                                    onChange={(e) => setPaperSize(e.target.value as keyof typeof PAPER_SIZES)}
                                    className="w-full px-4 py-3 bg-gray-50 border border-gray-200 text-gray-900 rounded-xl focus:outline-none focus:ring-2 focus:ring-[#419cc3]/50 focus:border-[#419cc3] transition-all"
                                >
                                    {Object.entries(PAPER_SIZES).map(([key, size]) => (
                                        <option key={key} value={key}>{size.name} ({size.width} x {size.height})</option>
                                    ))}
                                </select>
                            </div>

                            <div>
                                <label className="block text-sm font-bold text-gray-700 mb-3">Margins (cm)</label>
                                <div className="grid grid-cols-2 gap-4">
                                    <div>
                                        <label className="block text-xs text-gray-500 mb-1">Top</label>
                                        <input type="number" step="0.1" value={margins.top} onChange={(e) => setMargins({...margins, top: parseFloat(e.target.value) || 0})} className="w-full px-4 py-2 bg-gray-50 border border-gray-200 rounded-xl focus:ring-2 focus:ring-[#419cc3]/50 focus:border-[#419cc3]" />
                                    </div>
                                    <div>
                                        <label className="block text-xs text-gray-500 mb-1">Bottom</label>
                                        <input type="number" step="0.1" value={margins.bottom} onChange={(e) => setMargins({...margins, bottom: parseFloat(e.target.value) || 0})} className="w-full px-4 py-2 bg-gray-50 border border-gray-200 rounded-xl focus:ring-2 focus:ring-[#419cc3]/50 focus:border-[#419cc3]" />
                                    </div>
                                    <div>
                                        <label className="block text-xs text-gray-500 mb-1">Left</label>
                                        <input type="number" step="0.1" value={margins.left} onChange={(e) => setMargins({...margins, left: parseFloat(e.target.value) || 0})} className="w-full px-4 py-2 bg-gray-50 border border-gray-200 rounded-xl focus:ring-2 focus:ring-[#419cc3]/50 focus:border-[#419cc3]" />
                                    </div>
                                    <div>
                                        <label className="block text-xs text-gray-500 mb-1">Right</label>
                                        <input type="number" step="0.1" value={margins.right} onChange={(e) => setMargins({...margins, right: parseFloat(e.target.value) || 0})} className="w-full px-4 py-2 bg-gray-50 border border-gray-200 rounded-xl focus:ring-2 focus:ring-[#419cc3]/50 focus:border-[#419cc3]" />
                                    </div>
                                </div>
                            </div>
                        </div>

                        <div className="p-6 bg-gray-50 border-t border-gray-100 flex justify-end">
                            <button
                                onClick={() => setShowSettingsModal(false)}
                                className="px-6 py-2 bg-[#419cc3] hover:bg-[#3480a3] text-white text-sm font-bold rounded-xl shadow-md transition-all"
                            >
                                Apply Settings
                            </button>
                        </div>
                    </div>
                </div>
            )}
        </DashboardLayout>
    );
}
