import React from 'react';
import { Request } from '@/types';

interface RequestAttachmentsProps {
    request: Request;
}

export default function RequestAttachments({ request }: RequestAttachmentsProps) {
    let attachmentsArray = request.attachments;
    if (typeof attachmentsArray === 'string') {
        try {
            attachmentsArray = JSON.parse(attachmentsArray);
        } catch (e) {
            attachmentsArray = [];
        }
    }

    if (!attachmentsArray || !Array.isArray(attachmentsArray) || attachmentsArray.length === 0) {
        return null;
    }

    return (
        <div className="bg-white rounded-3xl shadow-[0_2px_20px_rgba(0,0,0,0.04)] border border-gray-100/50 p-8">
            <h3 className="text-xl font-bold text-[#1C3ECA] mb-6 flex items-center gap-2">
                <svg className="w-5 h-5 opacity-50" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15.172 7l-6.586 6.586a2 2 0 102.828 2.828l6.414-6.586a4 4 0 00-5.656-5.656l-6.415 6.585a6 6 0 108.486 8.486L20.5 13" />
                </svg>
                Attachments
            </h3>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                {attachmentsArray.map((att: string, idx: number) => (
                    <div key={`start-${idx}`} className="relative group rounded-xl overflow-hidden border border-gray-200 bg-gray-50 flex flex-col">
                        {typeof att === 'string' && att.startsWith('data:image') ? (
                            <img
                                src={att}
                                alt={`Attachment ${idx + 1}`}
                                className="w-full aspect-square object-cover cursor-pointer hover:opacity-90 transition-opacity"
                                onClick={() => {
                                    const w = window.open("");
                                    w?.document.write('<img src="' + att + '" style="max-width:100%"/>');
                                }}
                            />
                        ) : (
                            <a href={att} target="_blank" rel="noopener noreferrer" className="flex items-center gap-3 p-4 hover:bg-gray-100 transition-colors flex-1">
                                <div className="bg-blue-100 p-2 rounded-lg text-blue-600">
                                    <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
                                    </svg>
                                </div>
                                <div className="overflow-hidden">
                                    <p className="text-sm font-semibold text-gray-900 truncate">Attachment {idx + 1}</p>
                                    <p className="text-xs text-gray-500">Click to view</p>
                                </div>
                            </a>
                        )}
                        {request.type === 'overtime' && (
                            <div className="bg-gray-100 p-2 text-center border-t border-gray-200 mt-auto">
                                <p className="text-xs font-bold text-gray-600 uppercase tracking-wider">Bukti Mulai</p>
                            </div>
                        )}
                    </div>
                ))}

                {(() => {
                    let proofDoneArray = (request.type === 'overtime' && request.detail?.proof_image_done) ? request.detail.proof_image_done : [];
                    if (!Array.isArray(proofDoneArray)) proofDoneArray = [];
                    
                    return proofDoneArray.map((att: string, idx: number) => (
                        <div key={`done-${idx}`} className="relative group rounded-xl overflow-hidden border border-gray-200 bg-gray-50 flex flex-col">
                            {typeof att === 'string' ? (
                                <img
                                    src={att.startsWith('data:image') ? att : `${process.env.NEXT_PUBLIC_API_URL}/storage/${att}`}
                                    alt={`Final Proof ${idx + 1}`}
                                    className="w-full aspect-square object-cover cursor-pointer hover:opacity-90 transition-opacity"
                                    onClick={() => {
                                        const imgUrl = att.startsWith('data:image') ? att : `${process.env.NEXT_PUBLIC_API_URL}/storage/${att}`;
                                        const w = window.open("");
                                        w?.document.write('<img src="' + imgUrl + '" style="max-width:100%"/>');
                                    }}
                                />
                            ) : null}
                            <div className="bg-gray-100 p-2 text-center border-t border-gray-200 mt-auto">
                                <p className="text-xs font-bold text-gray-600 uppercase tracking-wider">Bukti Selesai</p>
                            </div>
                        </div>
                    ));
                })()}
            </div>
        </div>
    );
}
