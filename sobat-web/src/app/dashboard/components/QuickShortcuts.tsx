import React from 'react';
import { useRouter } from 'next/navigation';

export default function QuickShortcuts() {
    const router = useRouter();

    return (
        <div className="glass-card p-6 bg-gradient-to-b from-white to-gray-50/50">
            <h2 className="text-lg font-bold text-gray-800 mb-4">Quick Shortcuts</h2>
            <div className="grid grid-cols-2 gap-3">
                <button
                    onClick={() => router.push('/employees')}
                    className="p-4 rounded-xl bg-white border border-gray-100 shadow-sm hover:shadow-md hover:border-[#89b4e1]/50 transition-all group text-left"
                >
                    <div className="w-8 h-8 rounded-lg bg-green-100 text-green-700 flex items-center justify-center mb-2 group-hover:bg-[#419cc3] group-hover:text-[#89b4e1] transition-colors">
                        <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M18 9v3m0 0v3m0-3h3m-3 0h-3m-2-5a4 4 0 11-8 0 4 4 0 018 0zM3 20a6 6 0 0112 0v1H3v-1z" /></svg>
                    </div>
                    <span className="text-sm font-semibold text-gray-700 group-hover:text-[#419cc3]">Add Employee</span>
                </button>
                <button
                    onClick={() => router.push('/payroll')}
                    className="p-4 rounded-xl bg-white border border-gray-100 shadow-sm hover:shadow-md hover:border-[#89b4e1]/50 transition-all group text-left"
                >
                    <div className="w-8 h-8 rounded-lg bg-blue-100 text-blue-700 flex items-center justify-center mb-2 group-hover:bg-blue-600 group-hover:text-white transition-colors">
                        <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z" /></svg>
                    </div>
                    <span className="text-sm font-semibold text-gray-700 group-hover:text-blue-700">Import Payroll</span>
                </button>
                <button
                    onClick={() => router.push('/admin/feedbacks')}
                    className="p-4 rounded-xl bg-white border border-gray-100 shadow-sm hover:shadow-md hover:border-[#89b4e1]/50 transition-all group text-left">
                    <div className="w-8 h-8 rounded-lg bg-yellow-100 text-yellow-700 flex items-center justify-center mb-2 group-hover:bg-yellow-600 group-hover:text-white transition-colors">
                        <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M7 8h10M7 12h4m1 8l-4-4H5a2 2 0 01-2-2V6a2 2 0 012-2h14a2 2 0 012 2v8a2 2 0 01-2 2h-3l-4 4z" /></svg>
                    </div>
                    <span className="text-sm font-semibold text-gray-700 group-hover:text-yellow-700">Feedback</span>
                </button>
                <button className="p-4 rounded-xl bg-white border border-gray-100 shadow-sm hover:shadow-md hover:border-[#89b4e1]/50 transition-all group text-left">
                    <div className="w-8 h-8 rounded-lg bg-purple-100 text-purple-700 flex items-center justify-center mb-2 group-hover:bg-purple-600 group-hover:text-white transition-colors">
                        <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 17v-2m3 2v-4m3 4v-6m2 10H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" /></svg>
                    </div>
                    <span className="text-sm font-semibold text-gray-700 group-hover:text-purple-700">Reports</span>
                </button>
            </div>
        </div>
    );
}
