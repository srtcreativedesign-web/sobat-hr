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
      // Role Check
      const roleName = typeof user?.role === 'string' ? user.role : (user?.role as any)?.name; // Handle object or string
      if (roleName === 'staff') {
        router.push('/attendance');
        return;
      }

      fetchContractExpiring();
    }
  }, [isAuthenticated, user, router]);

  if (!isAuthenticated) {
    return null;
  }

  // Modern Stats Card Component
  const StatsCard = ({ title, value, subtext, icon, colorClass }: any) => (
    <div className="glass-card p-6 relative overflow-hidden group">
      <div className={`absolute top-0 right-0 w-24 h-24 bg-gradient-to-br ${colorClass} opacity-10 rounded-bl-full group-hover:scale-110 transition-transform duration-500`}></div>
      <div className="relative z-10 flex justify-between items-start">
        <div>
          <p className="text-sm font-medium text-gray-500 uppercase tracking-wide">{title}</p>
          <h3 className="text-3xl font-bold text-gray-800 mt-1 mb-2 group-hover:translate-x-1 transition-transform">{value}</h3>
          <p className="text-xs text-gray-400 font-medium bg-gray-100 inline-block px-2 py-1 rounded-md">{subtext}</p>
        </div>
        <div className={`p-3 rounded-xl bg-gradient-to-br ${colorClass} text-white shadow-lg group-hover:shadow-2xl transition-all duration-300 transform group-hover:-rotate-6`}>
          {icon}
        </div>
      </div>
    </div>
  );

  return (
    <DashboardLayout>
      {/* Header */}
      <div className="bg-white/80 backdrop-blur-md border-b border-gray-100 sticky top-0 z-20">
        <div className="px-8 py-6 flex justify-between items-center">
          <div>
            <h1 className="text-2xl font-bold text-gray-800">
              Good Morning, <span className="bg-gradient-to-r from-[#1A4D2E] to-[#49FFB8] bg-clip-text text-transparent">{user?.name}</span> 👋
            </h1>
            <p className="text-sm text-gray-500 mt-1">Here's what's happening in your organization today.</p>
          </div>
          <div className="flex items-center gap-4">
            <button className="p-2 text-gray-400 hover:text-[#1A4D2E] transition-colors relative">
              <span className="absolute top-2 right-2 w-2 h-2 bg-red-500 rounded-full animate-ping"></span>
              <span className="absolute top-2 right-2 w-2 h-2 bg-red-500 rounded-full"></span>
              <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 17h5l-1.405-1.405A2.032 2.032 0 0118 14.158V11a6.002 6.002 0 00-4-5.659V5a2 2 0 10-4 0v.341C7.67 6.165 6 8.388 6 11v3.159c0 .538-.214 1.055-.595 1.436L4 17h5m6 0v1a3 3 0 11-6 0v-1m6 0H9" /></svg>
            </button>
            <div className="h-10 w-10 rounded-full bg-gray-200 border-2 border-white shadow-sm overflow-hidden">
              {/* User Avatar Placeholder */}
              <div className="w-full h-full bg-[#1A4D2E] flex items-center justify-center text-white font-bold">
                {user?.name?.charAt(0)}
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Main Content */}
      <div className="p-8 space-y-8 animate-fade-in-up">

        {/* Stats Grid */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
          <StatsCard
            title="Total Employees"
            value="248"
            subtext="+12% from last month"
            colorClass="from-[#1A4D2E] to-[#2d7a4a]"
            icon={<svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z" /></svg>}
          />
          <StatsCard
            title="Attendance"
            value="93.5%"
            subtext="232 Present Today"
            colorClass="from-[#49FFB8] to-[#2d7a4a]"
            icon={<svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" /></svg>}
          />
          <StatsCard
            title="Pending Requests"
            value="18"
            subtext="Requires Attention"
            colorClass="from-orange-400 to-orange-600"
            icon={<svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" /></svg>}
          />
          <StatsCard
            title="Payroll"
            value="2.4M"
            subtext="Processed this month"
            colorClass="from-blue-400 to-indigo-600"
            icon={<svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z" /></svg>}
          />
        </div>

        {/* Content Grid */}
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
          {/* Left Column: Contract Expiry */}
          <div className="lg:col-span-2 space-y-8">
            <div className="glass-card p-6 bg-white/50">
              <div className="flex justify-between items-center mb-6">
                <h2 className="text-xl font-bold text-gray-800 flex items-center gap-2">
                  <span className="w-2 h-8 bg-[#1A4D2E] rounded-full"></span>
                  Contract Expiring Soon
                </h2>
                <button className="text-sm font-semibold text-[#1A4D2E] hover:text-[#49FFB8] transition-colors">View All</button>
              </div>

              {loading ? (
                <div className="h-40 flex items-center justify-center">
                  <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-[#1A4D2E]"></div>
                </div>
              ) : contractExpiring.length === 0 ? (
                <div className="text-center py-8 bg-gray-50/50 rounded-xl border border-dashed border-gray-200">
                  <p className="text-gray-500">No urgent contracts expiring.</p>
                </div>
              ) : (
                <div className="overflow-x-auto">
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
                              <div className="w-8 h-8 rounded-full bg-gradient-to-br from-[#1A4D2E] to-[#2d7a4a] text-white flex items-center justify-center text-xs font-bold">
                                {emp.user.name.charAt(0)}
                              </div>
                              <div>
                                <p className="text-sm font-semibold text-gray-900 group-hover:text-[#1A4D2E]">{emp.user.name}</p>
                                <p className="text-xs text-gray-500">{emp.employee_code}</p>
                              </div>
                            </div>
                          </td>
                          <td className="px-4 py-3">
                            <p className="text-sm text-gray-700">{emp.position}</p>
                            <p className="text-xs text-gray-400">{emp.organization.name}</p>
                          </td>
                          <td className="px-4 py-3">
                            <p className="text-sm font-medium text-gray-900">
                              {new Date(emp.contract_end_date).toLocaleDateString('id-ID', { day: 'numeric', month: 'short', year: 'numeric' })}
                            </p>
                            <p className="text-xs text-red-500 font-medium">{emp.days_remaining} days left</p>
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
                </div>
              )}
            </div>
          </div>

          {/* Right Column: Quick Actions & Activity */}
          <div className="space-y-6">
            <div className="glass-card p-6 bg-gradient-to-b from-white to-gray-50/50">
              <h2 className="text-lg font-bold text-gray-800 mb-4">Quick Shortcuts</h2>
              <div className="grid grid-cols-2 gap-3">
                <button className="p-4 rounded-xl bg-white border border-gray-100 shadow-sm hover:shadow-md hover:border-[#49FFB8]/50 transition-all group text-left">
                  <div className="w-8 h-8 rounded-lg bg-green-100 text-green-700 flex items-center justify-center mb-2 group-hover:bg-[#1A4D2E] group-hover:text-[#49FFB8] transition-colors">
                    <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M18 9v3m0 0v3m0-3h3m-3 0h-3m-2-5a4 4 0 11-8 0 4 4 0 018 0zM3 20a6 6 0 0112 0v1H3v-1z" /></svg>
                  </div>
                  <span className="text-sm font-semibold text-gray-700 group-hover:text-[#1A4D2E]">Add Employee</span>
                </button>
                <button
                  onClick={() => router.push('/payroll')}
                  className="p-4 rounded-xl bg-white border border-gray-100 shadow-sm hover:shadow-md hover:border-[#49FFB8]/50 transition-all group text-left"
                >
                  <div className="w-8 h-8 rounded-lg bg-blue-100 text-blue-700 flex items-center justify-center mb-2 group-hover:bg-blue-600 group-hover:text-white transition-colors">
                    <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z" /></svg>
                  </div>
                  <span className="text-sm font-semibold text-gray-700 group-hover:text-blue-700">Import Payroll</span>
                </button>
                <button className="p-4 rounded-xl bg-white border border-gray-100 shadow-sm hover:shadow-md hover:border-[#49FFB8]/50 transition-all group text-left">
                  <div className="w-8 h-8 rounded-lg bg-yellow-100 text-yellow-700 flex items-center justify-center mb-2 group-hover:bg-yellow-600 group-hover:text-white transition-colors">
                    <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" /></svg>
                  </div>
                  <span className="text-sm font-semibold text-gray-700 group-hover:text-yellow-700">Manage Shifts</span>
                </button>
                <button className="p-4 rounded-xl bg-white border border-gray-100 shadow-sm hover:shadow-md hover:border-[#49FFB8]/50 transition-all group text-left">
                  <div className="w-8 h-8 rounded-lg bg-purple-100 text-purple-700 flex items-center justify-center mb-2 group-hover:bg-purple-600 group-hover:text-white transition-colors">
                    <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 17v-2m3 2v-4m3 4v-6m2 10H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" /></svg>
                  </div>
                  <span className="text-sm font-semibold text-gray-700 group-hover:text-purple-700">Reports</span>
                </button>
              </div>
            </div>

            <div className="glass-card p-6">
              <h2 className="text-lg font-bold text-gray-800 mb-4">Recent Activity</h2>
              <div className="space-y-4">
                {[1, 2, 3].map((_, i) => (
                  <div key={i} className="flex gap-3 pb-3 border-b border-gray-50 last:border-0 last:pb-0">
                    <div className="w-2 h-2 rounded-full bg-[#49FFB8] mt-2 shadow-[0_0_8px_#49FFB8]"></div>
                    <div>
                      <p className="text-sm text-gray-800">New employee <strong>Sarah Connor</strong> onboarded.</p>
                      <p className="text-xs text-gray-400 mt-1">2 hours ago</p>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          </div>
        </div>
      </div>
    </DashboardLayout>
  );
}
