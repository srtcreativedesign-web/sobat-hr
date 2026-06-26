import React from 'react';
import { useRouter } from 'next/navigation';

export interface ContractExpiringEmployee {
  id: number;
  employee_code: string;
  user: {
    name: string;
    email: string;
  };
  division?: {
    name: string;
  };
  position: string;
  contract_end_date: string;
  days_remaining: number;
}

interface ContractExpiringTableProps {
    contractExpiring: ContractExpiringEmployee[];
    loading: boolean;
}

export default function ContractExpiringTable({ contractExpiring, loading }: ContractExpiringTableProps) {
    const router = useRouter();

    return (
        <div className="glass-card p-6 bg-white/50">
            <div className="flex justify-between items-center mb-6">
                <h2 className="text-xl font-bold text-gray-800 flex items-center gap-2">
                    <span className="w-2 h-8 bg-[#419cc3] rounded-full"></span>
                    Contract Expiring Soon
                </h2>
                <button 
                    onClick={() => router.push('/employees/contracts')} 
                    className="text-sm font-semibold text-[#419cc3] hover:text-[#89b4e1] transition-colors"
                >
                    View All
                </button>
            </div>

            {loading ? (
                <div className="h-40 flex items-center justify-center">
                    <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-[#419cc3]"></div>
                </div>
            ) : contractExpiring.length === 0 ? (
                <div className="text-center py-8 bg-gray-50/50 rounded-xl border border-dashed border-gray-200">
                    <p className="text-gray-500">No urgent contracts expiring.</p>
                </div>
            ) : (
                <table className="w-full">
                    <thead className="bg-gray-50/50">
                        <tr>
                            <th className="px-4 py-3 text-left text-xs font-semibold text-gray-500 uppercase">Employee</th>
                            <th className="px-4 py-3 text-left text-xs font-semibold text-gray-500 uppercase">Role</th>
                            <th className="px-4 py-3 text-left text-xs font-semibold text-gray-500 uppercase">Expiry</th>
                            <th className="px-4 py-3 text-left text-xs font-semibold text-gray-500 uppercase">Status</th>
                        </tr>
                    </thead>
                    <tbody className="divide-y divide-gray-100">
                        {contractExpiring.map((emp) => (
                            <tr key={emp.id} className="hover:bg-green-50/30 transition-colors cursor-pointer group">
                                <td className="px-4 py-3">
                                    <div className="flex items-center gap-3">
                                        <div className="w-8 h-8 rounded-full bg-gradient-to-br from-[#419cc3] to-[#93C5FD] text-white flex items-center justify-center text-xs font-bold">
                                            {emp.user.name.charAt(0)}
                                        </div>
                                        <div>
                                            <p className="text-sm font-semibold text-gray-900 group-hover:text-[#419cc3]">{emp.user.name}</p>
                                            <p className="text-xs text-gray-500">{emp.employee_code}</p>
                                        </div>
                                    </div>
                                </td>
                                <td className="px-4 py-3">
                                    <p className="text-sm text-gray-700">{emp.position}</p>
                                    <p className="text-xs text-gray-400">{emp.division?.name || '-'}</p>
                                </td>
                                <td className="px-4 py-3">
                                    <p className="text-sm font-medium text-gray-900">
                                        {new Date(emp.contract_end_date).toLocaleDateString('id-ID', { day: 'numeric', month: 'short', year: 'numeric' })}
                                    </p>
                                    <p className="text-xs text-red-500 font-medium">{Math.round(emp.days_remaining)} days left</p>
                                </td>
                                <td className="px-4 py-3">
                                    <span className={`px-2 py-1 rounded-full text-xs font-bold ${emp.days_remaining <= 7 ? 'bg-red-100 text-red-600' : 'bg-yellow-100 text-yellow-600'
                                        }`}>
                                        {emp.days_remaining <= 7 ? 'CRITICAL' : 'WARNING'}
                                    </span>
                                </td>
                            </tr>
                        ))}
                    </tbody>
                </table>
            )}
        </div>
    );
}
