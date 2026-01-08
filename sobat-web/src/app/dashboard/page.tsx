'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { useAuthStore } from '@/store/auth-store';
import DashboardLayout from '@/components/DashboardLayout';
import apiClient from '@/lib/api-client';

interface ContractExpiringEmployee {
  id: number;
  employee_code: string;
  user: {
    name: string;
    email: string;
  };
  organization: {
    name: string;
  };
  position: string;
  contract_end_date: string;
  days_remaining: number;
}

export default function DashboardPage() {
  const router = useRouter();
  const { user, isAuthenticated, checkAuth } = useAuthStore();
  const [contractExpiring, setContractExpiring] = useState<ContractExpiringEmployee[]>([]);
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    checkAuth();
  }, [checkAuth]);

  useEffect(() => {
    if (!isAuthenticated) {
      router.push('/login');
    }
  }, [isAuthenticated, router]);

  useEffect(() => {
    const fetchContractExpiring = async () => {
      try {
        setLoading(true);
        const response = await apiClient.get('/dashboard/contract-expiring?days=30');
        setContractExpiring(response.data.data.employees || []);
      } catch (error) {
        console.error('Failed to fetch contract expiring:', error);
      } finally {
        setLoading(false);
      }
    };

    if (isAuthenticated) {
      fetchContractExpiring();
    }
  }, [isAuthenticated]);

  if (!isAuthenticated) {
    return null;
  }

  return (
    <DashboardLayout>
      {/* Header */}
      <div className="bg-white border-b border-gray-200 sticky top-0 z-10">
        <div className="px-8 py-6">
          <h1 className="text-3xl font-bold bg-gradient-to-r from-[#1A4D2E] to-[#2d7a4a] bg-clip-text text-transparent">
            Dashboard Overview
          </h1>
          <p className="text-gray-600 mt-1">Welcome back, {user?.name}!</p>
        </div>
      </div>

      {/* Main Content */}
      <div className="p-8">
        {/* Stats Cards */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
          {/* Total Employees */}
          <div className="bg-white rounded-2xl shadow-sm p-6 border border-gray-100 hover:shadow-md transition-shadow">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm font-semibold text-gray-600">Total Employees</p>
                <p className="text-3xl font-bold text-[#1A4D2E] mt-2">248</p>
                <p className="text-xs text-gray-500 mt-1">+12 this month</p>
              </div>
              <div className="w-12 h-12 rounded-xl bg-gradient-to-br from-[#1A4D2E] to-[#2d7a4a] flex items-center justify-center">
                <svg className="w-6 h-6 text-[#49FFB8]" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z" />
                </svg>
              </div>
            </div>
          </div>

          {/* Present Today */}
          <div className="bg-white rounded-2xl shadow-sm p-6 border border-gray-100 hover:shadow-md transition-shadow">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm font-semibold text-gray-600">Present Today</p>
                <p className="text-3xl font-bold text-[#1A4D2E] mt-2">232</p>
                <p className="text-xs text-gray-500 mt-1">93.5% attendance</p>
              </div>
              <div className="w-12 h-12 rounded-xl bg-gradient-to-br from-[#49FFB8] to-[#2d7a4a] flex items-center justify-center">
                <svg className="w-6 h-6 text-[#1A4D2E]" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
                </svg>
              </div>
            </div>
          </div>

          {/* Pending Requests */}
          <div className="bg-white rounded-2xl shadow-sm p-6 border border-gray-100 hover:shadow-md transition-shadow">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm font-semibold text-gray-600">Pending Requests</p>
                <p className="text-3xl font-bold text-[#1A4D2E] mt-2">18</p>
                <p className="text-xs text-gray-500 mt-1">Need approval</p>
              </div>
              <div className="w-12 h-12 rounded-xl bg-gradient-to-br from-orange-400 to-orange-600 flex items-center justify-center">
                <svg className="w-6 h-6 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
                </svg>
              </div>
            </div>
          </div>

          {/* This Month Payroll */}
          <div className="bg-white rounded-2xl shadow-sm p-6 border border-gray-100 hover:shadow-md transition-shadow">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm font-semibold text-gray-600">This Month Payroll</p>
                <p className="text-3xl font-bold text-[#1A4D2E] mt-2">2.4M</p>
                <p className="text-xs text-gray-500 mt-1">IDR processed</p>
              </div>
              <div className="w-12 h-12 rounded-xl bg-gradient-to-br from-blue-400 to-blue-600 flex items-center justify-center">
                <svg className="w-6 h-6 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
                </svg>
              </div>
            </div>
          </div>
        </div>

        {/* Recent Activity & Quick Actions */}
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
          {/* Recent Activity */}
          <div className="lg:col-span-2 bg-white rounded-2xl shadow-sm p-6 border border-gray-100">
            <h2 className="text-lg font-bold text-gray-900 mb-4">Recent Activity</h2>
            <div className="space-y-4">
              {[
                { name: 'John Doe', action: 'submitted leave request', time: '2 minutes ago', type: 'leave' },
                { name: 'Jane Smith', action: 'clocked in', time: '15 minutes ago', type: 'attendance' },
                { name: 'Mike Johnson', action: 'submitted reimbursement', time: '1 hour ago', type: 'reimbursement' },
                { name: 'Sarah Williams', action: 'approved overtime request', time: '2 hours ago', type: 'approval' },
              ].map((activity, idx) => (
                <div key={idx} className="flex items-center gap-4 p-3 rounded-xl hover:bg-gray-50 transition-colors">
                  <div className="w-10 h-10 rounded-full bg-gradient-to-br from-[#1A4D2E] to-[#2d7a4a] flex items-center justify-center text-[#49FFB8] font-bold">
                    {activity.name.charAt(0)}
                  </div>
                  <div className="flex-1">
                    <p className="text-sm text-gray-900">
                      <span className="font-semibold">{activity.name}</span> {activity.action}
                    </p>
                    <p className="text-xs text-gray-500">{activity.time}</p>
                  </div>
                  <span className={`text-xs px-2 py-1 rounded-full ${
                    activity.type === 'leave' ? 'bg-blue-100 text-blue-700' :
                    activity.type === 'attendance' ? 'bg-green-100 text-green-700' :
                    activity.type === 'reimbursement' ? 'bg-yellow-100 text-yellow-700' :
                    'bg-purple-100 text-purple-700'
                  }`}>
                    {activity.type}
                  </span>
                </div>
              ))}
            </div>
          </div>

          {/* Quick Actions */}
          <div className="bg-white rounded-2xl shadow-sm p-6 border border-gray-100">
            <h2 className="text-lg font-bold text-gray-900 mb-4">Quick Actions</h2>
            <div className="space-y-3">
              <button className="w-full flex items-center gap-3 p-3 rounded-xl bg-gradient-to-r from-[#1A4D2E] to-[#2d7a4a] text-white hover:shadow-lg transition-all transform hover:scale-[1.02]">
                <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 6v6m0 0v6m0-6h6m-6 0H6" />
                </svg>
                <span className="text-sm font-semibold">Add Employee</span>
              </button>
              <button className="w-full flex items-center gap-3 p-3 rounded-xl border-2 border-[#1A4D2E] text-[#1A4D2E] hover:bg-[#1A4D2E]/5 transition-colors">
                <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2" />
                </svg>
                <span className="text-sm font-semibold">Generate Report</span>
              </button>
              <button className="w-full flex items-center gap-3 p-3 rounded-xl border-2 border-[#1A4D2E] text-[#1A4D2E] hover:bg-[#1A4D2E]/5 transition-colors">
                <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
                </svg>
                <span className="text-sm font-semibold">Manage Shifts</span>
              </button>
              <button className="w-full flex items-center gap-3 p-3 rounded-xl border-2 border-[#1A4D2E] text-[#1A4D2E] hover:bg-[#1A4D2E]/5 transition-colors">
                <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
                </svg>
                <span className="text-sm font-semibold">Process Payroll</span>
              </button>
            </div>
          </div>
        </div>

        {/* Contract Expiring Soon */}
        <div className="mt-6 bg-white rounded-2xl shadow-sm p-6 border border-gray-100">
          <div className="flex items-center justify-between mb-4">
            <h2 className="text-lg font-bold text-gray-900">Contract Expiring Soon</h2>
            <span className="text-sm text-gray-500">Next 30 days</span>
          </div>

          {loading ? (
            <div className="flex items-center justify-center py-12">
              <div className="w-8 h-8 border-4 border-[#1A4D2E] border-t-transparent rounded-full animate-spin"></div>
            </div>
          ) : contractExpiring.length === 0 ? (
            <div className="text-center py-12">
              <svg className="w-16 h-16 mx-auto text-gray-300 mb-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
              </svg>
              <p className="text-gray-500">No contracts expiring in the next 30 days</p>
            </div>
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full">
                <thead>
                  <tr className="border-b border-gray-200">
                    <th className="text-left py-3 px-4 text-sm font-semibold text-gray-600">Employee</th>
                    <th className="text-left py-3 px-4 text-sm font-semibold text-gray-600">Position</th>
                    <th className="text-left py-3 px-4 text-sm font-semibold text-gray-600">Organization</th>
                    <th className="text-left py-3 px-4 text-sm font-semibold text-gray-600">Contract End</th>
                    <th className="text-left py-3 px-4 text-sm font-semibold text-gray-600">Days Remaining</th>
                    <th className="text-left py-3 px-4 text-sm font-semibold text-gray-600">Status</th>
                  </tr>
                </thead>
                <tbody>
                  {contractExpiring.map((employee) => {
                    const daysRemaining = employee.days_remaining;
                    const statusColor = 
                      daysRemaining <= 7 ? 'bg-red-100 text-red-700 border-red-200' :
                      daysRemaining <= 15 ? 'bg-yellow-100 text-yellow-700 border-yellow-200' :
                      'bg-green-100 text-green-700 border-green-200';
                    
                    const statusText = 
                      daysRemaining <= 7 ? 'Urgent' :
                      daysRemaining <= 15 ? 'Warning' :
                      'Notice';

                    return (
                      <tr key={employee.id} className="border-b border-gray-100 hover:bg-gray-50 transition-colors">
                        <td className="py-3 px-4">
                          <div className="flex items-center gap-3">
                            <div className="w-10 h-10 rounded-full bg-gradient-to-br from-[#1A4D2E] to-[#2d7a4a] flex items-center justify-center text-[#49FFB8] font-bold text-sm">
                              {employee.user.name.charAt(0)}
                            </div>
                            <div>
                              <p className="text-sm font-semibold text-gray-900">{employee.user.name}</p>
                              <p className="text-xs text-gray-500">{employee.employee_code}</p>
                            </div>
                          </div>
                        </td>
                        <td className="py-3 px-4">
                          <p className="text-sm text-gray-900">{employee.position}</p>
                        </td>
                        <td className="py-3 px-4">
                          <p className="text-sm text-gray-900">{employee.organization.name}</p>
                        </td>
                        <td className="py-3 px-4">
                          <p className="text-sm text-gray-900">
                            {new Date(employee.contract_end_date).toLocaleDateString('id-ID', {
                              day: 'numeric',
                              month: 'short',
                              year: 'numeric'
                            })}
                          </p>
                        </td>
                        <td className="py-3 px-4">
                          <p className="text-sm font-semibold text-gray-900">{daysRemaining} days</p>
                        </td>
                        <td className="py-3 px-4">
                          <span className={`inline-flex items-center px-3 py-1 rounded-full text-xs font-semibold border ${statusColor}`}>
                            {statusText}
                          </span>
                        </td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            </div>
          )}
        </div>
      </div>
    </DashboardLayout>
  );
}
