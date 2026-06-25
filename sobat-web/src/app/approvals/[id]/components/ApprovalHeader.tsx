import React from 'react';
import { format } from 'date-fns';
import { Request } from '@/types';

interface ApprovalHeaderProps {
    request: Request;
    onBack: () => void;
    onDownloadProof: () => void;
}

export default function ApprovalHeader({ request, onBack, onDownloadProof }: ApprovalHeaderProps) {
    return (
        <div className="flex flex-col md:flex-row justify-between items-start md:items-center mb-10 gap-4">
            <div>
                <div className="flex items-center justify-between w-full">
                    <button
                        onClick={onBack}
                        className="group flex items-center text-sm font-medium text-gray-500 hover:text-[#1C3ECA] mb-4 transition-colors"
                    >
                        <svg className="w-4 h-4 mr-1 transition-transform group-hover:-translate-x-1" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M10 19l-7-7m0 0l7-7m-7 7h18" />
                        </svg>
                        Back to Inbox
                    </button>
                    <button
                        onClick={onDownloadProof}
                        className="inline-flex items-center px-4 py-2 bg-white border border-gray-200 rounded-xl text-sm font-semibold text-gray-600 hover:bg-gray-50 shadow-sm transition-all mb-4"
                    >
                        <svg className="w-4 h-4 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-4l-4 4m0 0l-4-4m4 4V4" />
                        </svg>
                        Export Proof
                    </button>
                </div>
                <h1 className="text-3xl md:text-4xl font-extrabold text-[#1C3ECA] tracking-tight mb-2">{request.title}</h1>
                <div className="flex items-center gap-3 text-gray-500 text-sm">
                    <span className="flex items-center gap-1 bg-gray-100 px-2 py-0.5 rounded-md font-medium text-gray-700">
                        <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
                        </svg>
                        {request.employee?.full_name}
                    </span>
                    <span>•</span>
                    <span>Submitted on {request.submitted_at ? format(new Date(request.submitted_at), 'dd MMM yyyy') : '-'}</span>
                </div>
            </div>

            <div className={`px-5 py-2 rounded-full text-sm font-bold tracking-wide uppercase shadow-sm border
                ${request.status === 'approved' ? 'bg-green-50 text-green-700 border-green-100' :
                    request.status === 'spl_open' ? 'bg-emerald-50 text-emerald-700 border-emerald-100' :
                    request.status === 'spl_approved' ? 'bg-blue-50 text-blue-700 border-blue-100' :
                    request.status === 'rejected' ? 'bg-red-50 text-red-700 border-red-100' :
                        request.status === 'pending' ? 'bg-amber-50 text-amber-700 border-amber-100' : 'bg-gray-50 text-gray-700 border-gray-200'
                }`}>
                {request.status === 'spl_open' ? 'Lembur Berjalan' : request.status === 'spl_approved' ? 'Menunggu Mulai' : request.status}
            </div>
        </div>
    );
}
