import React from 'react';
import { format, differenceInDays } from 'date-fns';
import { Request } from '@/types';
import LiveTimer from './LiveTimer';

interface RequestDetailCardProps {
    request: Request;
}

export default function RequestDetailCard({ request }: RequestDetailCardProps) {
    return (
        <div className="bg-white rounded-3xl shadow-[0_2px_20px_rgba(0,0,0,0.04)] border border-gray-100/50 p-8 overflow-hidden relative">
            <div className="absolute top-0 left-0 w-full h-1 bg-gradient-to-r from-[#1C3ECA] to-[#8a5d6e] opacity-20"></div>
            <h3 className="text-xl font-bold text-[#1C3ECA] mb-8 flex items-center gap-2">
                <svg className="w-5 h-5 opacity-50" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
                </svg>
                Request Details
            </h3>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-y-8 gap-x-12">
                <div className="space-y-1">
                    <label className="text-xs uppercase tracking-wider text-gray-400 font-bold">Request Type</label>
                    <div className="font-semibold text-lg text-gray-900 capitalize flex items-center gap-2">
                        {request.type === 'leave' && '🌴'}
                        {request.type === 'business_trip' && '✈️'}
                        {request.type === 'overtime' && '⏰'}
                        {request.type === 'asset' && '💻'}
                        {request.type === 'resignation' && '🚪'}
                        {request.type.replace('_', ' ')}
                    </div>
                </div>

                {!['resignation', 'exit_permit'].includes(request.type) && (
                    <div className="space-y-1">
                        <label className="text-xs uppercase tracking-wider text-gray-400 font-bold">
                            {request.type === 'asset' ? 'Estimated Cost' : 'Duration / Amount'}
                        </label>
                        <div className="font-semibold text-lg text-gray-900">
                            {request.type === 'asset'
                                ? `IDR ${request.amount?.toLocaleString('id-ID')}`
                                : (() => {
                                    if (request.type === 'overtime') {
                                        if (request.status === 'spl_open') {
                                            return <LiveTimer startTime={request.detail?.start_time} date={request.detail?.date} />;
                                        }
                                        if (['pending', 'spl_approved'].includes(request.status)) {
                                            return '-';
                                        }
                                        const val = request.amount || 0;
                                        const h = Math.floor(val);
                                        const m = Math.round((val - h) * 60);
                                        return (
                                            <span className="flex items-baseline gap-1">
                                                {h > 0 && <><span className="font-semibold">{h}</span><span className="text-sm text-gray-500 font-normal mr-1">h</span></>}
                                                {m > 0 && <><span className="font-semibold">{m}</span><span className="text-sm text-gray-500 font-normal">m</span></>}
                                                {h === 0 && m === 0 && <><span className="font-semibold">0</span><span className="text-sm text-gray-500 font-normal">m</span></>}
                                            </span>
                                        );
                                    }
                                    const val = request.amount || (request.start_date && request.end_date ? differenceInDays(new Date(request.end_date), new Date(request.start_date)) + 1 : 1);
                                    return Number(val).toLocaleString('id-ID', { maximumFractionDigits: 0 });
                                })()
                            }
                            <span className="text-sm text-gray-500 ml-1 font-normal">
                                {(() => {
                                    if (request.type === 'overtime') return '';
                                    if (['leave', 'business_trip', 'sick_leave'].includes(request.type)) return 'Days';
                                    if (['reimbursement', 'asset', 'resignation'].includes(request.type)) return '';
                                    return 'Units';
                                })()}
                            </span>
                        </div>
                    </div>
                )}

                {request.type === 'resignation' && request.detail ? (
                    <>
                        <div className="space-y-1">
                            <label className="text-xs uppercase tracking-wider text-gray-400 font-bold">Last Working Date</label>
                            <div className="font-semibold text-lg text-gray-900">
                                {request.detail.last_working_date ? format(new Date(request.detail.last_working_date), 'dd MMM yyyy') : '-'}
                            </div>
                        </div>
                        <div className="space-y-1">
                            <label className="text-xs uppercase tracking-wider text-gray-400 font-bold">Type</label>
                            <div className="font-semibold text-lg text-gray-900 capitalize">
                                {request.detail.resign_type === '1_month_notice' ? 'One Month Notice' : 'Normal'}
                            </div>
                        </div>
                    </>
                ) : request.type === 'asset' && request.detail ? (
                    <>
                        <div className="space-y-1">
                            <label className="text-xs uppercase tracking-wider text-gray-400 font-bold">Brand / Item</label>
                            <div className="font-semibold text-lg text-gray-900">{request.detail.brand || '-'}</div>
                        </div>
                        <div className="space-y-1">
                            <label className="text-xs uppercase tracking-wider text-gray-400 font-bold">Specification</label>
                            <div className="font-semibold text-lg text-gray-900">{request.detail.specification || '-'}</div>
                        </div>
                        <div className="space-y-1">
                            <label className="text-xs uppercase tracking-wider text-gray-400 font-bold">Urgency</label>
                            <div className={`font-semibold text-lg px-3 py-1 inline-flex rounded-full text-sm ${request.detail.is_urgent ? 'bg-red-100 text-red-700' : 'bg-green-100 text-green-700'}`}>
                                {request.detail.is_urgent ? '🔥 Urgent' : 'Regular'}
                            </div>
                        </div>
                    </>
                ) : request.type === 'overtime' && request.detail ? (
                    <>
                        <div className="space-y-1">
                            <label className="text-xs uppercase tracking-wider text-gray-400 font-bold">Start Time</label>
                            <div className="font-semibold text-lg text-gray-900">{request.detail.start_time || '-'}</div>
                        </div>
                        <div className="space-y-1">
                            <label className="text-xs uppercase tracking-wider text-gray-400 font-bold">End Time (Actual)</label>
                            <div className="font-semibold text-lg text-gray-900">{request.detail.end_time || '-'}</div>
                        </div>
                    </>
                ) : request.type === 'exit_permit' && request.detail ? (
                    <div className="col-span-1 md:col-span-2 bg-gradient-to-br from-indigo-50/80 to-blue-50/40 rounded-2xl p-6 border border-indigo-100/50 mt-2">
                        <div className="flex flex-col md:flex-row md:items-center justify-between gap-6">
                            {/* Left side: Permit details */}
                            <div className="flex-1 space-y-6">
                                <div className="grid grid-cols-2 gap-6">
                                    <div>
                                        <label className="text-[10px] uppercase tracking-widest text-indigo-400 font-bold mb-2 block">Keperluan</label>
                                        <div className={`inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-sm font-bold ${request.detail.permit_type?.toLowerCase() === 'dinas' ? 'bg-blue-100 text-blue-700' : 'bg-purple-100 text-purple-700'}`}>
                                            {request.detail.permit_type?.toLowerCase() === 'dinas' ? '🏢 Dinas' : '👤 Pribadi'}
                                        </div>
                                    </div>
                                    <div>
                                        <label className="text-[10px] uppercase tracking-widest text-indigo-400 font-bold mb-1 block">Tujuan</label>
                                        <div className="font-bold text-gray-900 flex items-center gap-2">
                                            <svg className="w-5 h-5 text-indigo-400" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z" /><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 11a3 3 0 11-6 0 3 3 0 016 0z" /></svg>
                                            {request.detail.destination || '-'}
                                        </div>
                                    </div>
                                </div>
                                <div className="grid grid-cols-2 gap-6">
                                    <div>
                                        <label className="text-[10px] uppercase tracking-widest text-indigo-400 font-bold mb-1 block">Waktu Keluar</label>
                                        <div className="font-semibold text-gray-800 flex flex-col gap-1 text-sm">
                                            <div className="flex items-center gap-1.5">
                                                <svg className="w-4 h-4 text-indigo-400 shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z" /></svg>
                                                <span>{request.detail.date ? format(new Date(request.detail.date), 'dd MMM yyyy') : '-'}</span>
                                            </div>
                                            <div className="flex items-center gap-1.5">
                                                <svg className="w-4 h-4 text-indigo-400 shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" /></svg>
                                                <span>{request.detail.start_time || '-'} - {request.detail.end_time || 'Selesai'}</span>
                                            </div>
                                        </div>
                                    </div>
                                    <div>
                                        <label className="text-[10px] uppercase tracking-widest text-indigo-400 font-bold mb-1 block">No Polisi</label>
                                        <div className="font-semibold text-gray-800 flex items-center gap-1.5 text-sm">
                                            <svg className="w-4 h-4 text-indigo-400" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8 14v3m4-3v3m4-3v3M3 21h18M3 10h18M3 7l9-4 9 4M4 10h16v11H4V10z" /></svg>
                                            {request.detail.vehicle_plate || '-'}
                                        </div>
                                    </div>
                                </div>
                            </div>
                            
                            {/* Right side: Signature */}
                            {request.detail.signature && (
                                <div className="shrink-0 bg-white/80 p-5 rounded-2xl border border-indigo-100/60 shadow-sm flex flex-col items-center min-w-[160px]">
                                    <span className="text-[10px] uppercase tracking-widest text-indigo-400 font-bold mb-3">Tanda Tangan</span>
                                    <img src={request.detail.signature} alt="Signature" className="h-16 object-contain mix-blend-multiply" />
                                </div>
                            )}
                        </div>
                    </div>
                ) : (
                    <>
                        <div className="space-y-1">
                            <label className="text-xs uppercase tracking-wider text-gray-400 font-bold">Start Date</label>
                            <div className="font-semibold text-lg text-gray-900">{request.start_date ? format(new Date(request.start_date), 'dd MMM yyyy') : '-'}</div>
                        </div>
                        <div className="space-y-1">
                            <label className="text-xs uppercase tracking-wider text-gray-400 font-bold">End Date</label>
                            <div className="font-semibold text-lg text-gray-900">{request.end_date ? format(new Date(request.end_date), 'dd MMM yyyy') : '-'}</div>
                        </div>
                    </>
                )}
            </div>
            <div className="mt-8 pt-8 border-t border-gray-100">
                <label className="text-xs uppercase tracking-wider text-gray-400 font-bold mb-3 block">Description / Reason</label>
                <div className="bg-gray-50 rounded-2xl p-6 text-gray-700 leading-relaxed text-sm md:text-base border border-gray-100">
                    {request.description}
                </div>
            </div>
        </div>
    );
}
