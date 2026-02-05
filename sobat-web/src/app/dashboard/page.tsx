'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { useAuthStore } from '@/store/auth-store';
import DashboardLayout from '@/components/DashboardLayout';
import apiClient from '@/lib/api-client';
import LatenessChart from '@/components/dashboard/LatenessChart';
import TextType from '@/components/TextType';

interface DashboardStats {
  employees: {
    total: number;
    active: number;
  };
  attendance: {
    [key: string]: number; // present, late, absent, etc.
  };
  requests: {
    pending: number;
    approved: number;
    rejected: number;
  };
  payroll: {
    total: number;
    period_month: number;
    period_year: number;
  };
}

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

interface RecentActivity {
  id: string;
  type: string;
  message: string;
  timestamp: string;
  user: string;
  status: string;
}

export default function DashboardPage() {
  const router = useRouter();
  const { user, isAuthenticated, isInitialized, checkAuth, logout } = useAuthStore();
  const [stats, setStats] = useState<DashboardStats | null>(null);
  const [contractExpiring, setContractExpiring] = useState<ContractExpiringEmployee[]>([]);
  const [latenessData, setLatenessData] = useState([]);
  const [lastSeenCount, setLastSeenCount] = useState(0);

  useEffect(() => {
    const saved = localStorage.getItem('notif_seen_count');
    if (saved) setLastSeenCount(parseInt(saved));
  }, []);

  const handleNotifClick = () => {
    if (stats) {
      localStorage.setItem('notif_seen_count', stats.requests.pending.toString());
      setLastSeenCount(stats.requests.pending);
    }
    router.push('/notifications');
  };
  const [recentActivity, setRecentActivity] = useState<RecentActivity[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    checkAuth();
  }, [checkAuth]);

  useEffect(() => {
    const fetchData = async () => {
      try {
        setLoading(true);

        // Parallel Fetch
        const [analyticsRes, contractsRes, trendRes, recentRes] = await Promise.all([
          apiClient.get('/dashboard/analytics'),
          apiClient.get('/dashboard/contract-expiring?days=30'),
          apiClient.get('/dashboard/attendance-trend'),
          apiClient.get('/dashboard/recent-activity')
        ]);

        setStats(analyticsRes.data);
        setContractExpiring(contractsRes.data.data.employees || []);
        setLatenessData(trendRes.data.data || []);
        setRecentActivity(recentRes.data.data || []);


      } catch (error: any) {
        console.error('Failed to fetch dashboard data:', error);
        if (error.response?.status === 401) {
          await logout();
          router.push('/login');
        }
      } finally {
        setLoading(false);
      }
    };

    // Role Check
    if (isInitialized && isAuthenticated) {
      const roleName = typeof user?.role === 'string' ? user.role : (user?.role as any)?.name;
      if (roleName === 'staff') {
        router.push('/attendance');
      } else {
        fetchData();
      }
    }
  }, [user, router, logout, isInitialized, isAuthenticated]);


  // Calculators
  const presentCount = stats?.attendance['present'] || 0;
  const lateCount = stats?.attendance['late'] || 0;
  const totalAttendance = presentCount + lateCount;
  const totalEmployees = stats?.employees.total || 1; // Avoid div by 0
  const attendanceRate = ((totalAttendance / totalEmployees) * 100).toFixed(1);

  const formatCompactCurrency = (number: number) => {
    return new Intl.NumberFormat('id-ID', {
      notation: "compact",
      compactDisplay: "short",
      style: "currency",
      currency: "IDR",
      maximumFractionDigits: 2
    }).format(number);
  }

  // Modern Stats Card Component
  const StatsCard = ({ title, value, subtext, icon, colorClass }: any) => (
    <div className="glass-card p-6 relative overflow-hidden group">
      <div className={`absolute top-0 right-0 w-24 h-24 bg-gradient-to-br ${colorClass} opacity-10 rounded-bl-full group-hover:scale-110 transition-transform duration-500`}></div>
      <div className="relative z-10 flex justify-between items-start">
        <div>
          <p className="text-sm font-medium text-gray-500 uppercase tracking-wide">{title}</p>
          <h3 className="text-3xl font-bold text-gray-800 mt-1 mb-2 group-hover:translate-x-1 transition-transform">
            {loading ? '...' : value}
          </h3>
          <p className="text-xs text-gray-400 font-medium bg-gray-100 inline-block px-2 py-1 rounded-md">{subtext}</p>
        </div>
        <div className={`p-3 rounded-xl bg-gradient-to-br ${colorClass} text-white shadow-lg group-hover:shadow-2xl transition-all duration-300 transform group-hover:-rotate-6`}>
          {icon}
        </div>
      </div>
    </div>
  );

  const getGreeting = () => {
    const hour = new Date().getHours();
    if (hour < 12) return 'Good Morning';
    if (hour < 18) return 'Good Afternoon';
    return 'Good Evening';
  };





  return (
    <DashboardLayout>
      {/* Header */}
      <div className="bg-white/80 backdrop-blur-md border-b border-gray-100 sticky top-0 z-20">
        <div className="px-8 py-6 flex justify-between items-center">
          <div>
            <h1 className="text-2xl font-bold text-gray-800">
              {getGreeting()}, <span className="bg-gradient-to-r from-[#1C3ECA] to-[#60A5FA] bg-clip-text text-transparent">{user?.name}</span> 👋
            </h1>
            <div className="mt-1">
              <TextType
                text={[
                  "Here's what's happening in your organization today.",
                  "Don't forget to check pending requests.",
                  "Have a productive day!"
                ]}
                typingSpeed={75}
                pauseDuration={1500}
                showCursor
                cursorCharacter="▎"
                deletingSpeed={50}
                className="text-sm text-gray-500"
              />
            </div>
          </div>
          <div className="flex items-center gap-4">
            <button onClick={handleNotifClick} className="p-2 text-gray-400 hover:text-[#1C3ECA] transition-colors relative">
              {stats && stats.requests.pending > lastSeenCount && (
                <>
                  <span className="absolute top-2 right-2 w-2 h-2 bg-red-500 rounded-full animate-ping"></span>
                  <span className="absolute top-2 right-2 w-2 h-2 bg-red-500 rounded-full"></span>
                </>
              )}
              <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 17h5l-1.405-1.405A2.032 2.032 0 0118 14.158V11a6.002 6.002 0 00-4-5.659V5a2 2 0 10-4 0v.341C7.67 6.165 6 8.388 6 11v3.159c0 .538-.214 1.055-.595 1.436L4 17h5m6 0v1a3 3 0 11-6 0v-1m6 0H9" /></svg>
            </button>
            <div className="h-10 w-10 rounded-full bg-gray-200 border-2 border-white shadow-sm overflow-hidden">
              <div className="w-full h-full bg-[#1C3ECA] flex items-center justify-center text-white font-bold">
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
            value={stats?.employees.total || 0}
            subtext={`${stats?.employees.active || 0} Active`}
            colorClass="from-[#1C3ECA] to-[#93C5FD]"
            icon={<svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z" /></svg>}
          />
          <StatsCard
            title="Attendance"
            value={`${attendanceRate}%`}
            subtext={`${totalAttendance} Present Today`}
            colorClass="from-[#60A5FA] to-[#93C5FD]"
            icon={<svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" /></svg>}
          />
          <StatsCard
            title="Pending Requests"
            value={stats?.requests.pending || 0}
            subtext="Requires Attention"
            colorClass="from-orange-400 to-orange-600"
            icon={<svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" /></svg>}
          />
          <StatsCard
            title="Payroll"
            value={formatCompactCurrency(stats?.payroll.total || 0)}
            subtext="Processed this month"
            colorClass="from-blue-400 to-indigo-600"
            icon={<svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z" /></svg>}
          />
        </div>

        {/* Content Grid */}
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
          {/* Left Column: Charts & Tables */}
          <div className="lg:col-span-2 space-y-8">

            {/* Lateness Chart */}
            <LatenessChart data={latenessData} loading={loading} />

            <div className="glass-card p-6 bg-white/50">
              <div className="flex justify-between items-center mb-6">
                <h2 className="text-xl font-bold text-gray-800 flex items-center gap-2">
                  <span className="w-2 h-8 bg-[#1C3ECA] rounded-full"></span>
                  Contract Expiring Soon
                </h2>
                <button onClick={() => router.push('/employees/contracts')} className="text-sm font-semibold text-[#1C3ECA] hover:text-[#60A5FA] transition-colors">View All</button>
              </div>

              {loading ? (
                <div className="h-40 flex items-center justify-center">
                  <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-[#1C3ECA]"></div>
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
                            <div className="w-8 h-8 rounded-full bg-gradient-to-br from-[#1C3ECA] to-[#93C5FD] text-white flex items-center justify-center text-xs font-bold">
                              {emp.user.name.charAt(0)}
                            </div>
                            <div>
                              <p className="text-sm font-semibold text-gray-900 group-hover:text-[#1C3ECA]">{emp.user.name}</p>
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
          </div>

          {/* Right Column: Quick Actions & Activity */}
          <div className="space-y-6">
            <div className="glass-card p-6 bg-gradient-to-b from-white to-gray-50/50">
              <h2 className="text-lg font-bold text-gray-800 mb-4">Quick Shortcuts</h2>
              <div className="grid grid-cols-2 gap-3">
                <button
                  onClick={() => router.push('/employees')}
                  className="p-4 rounded-xl bg-white border border-gray-100 shadow-sm hover:shadow-md hover:border-[#60A5FA]/50 transition-all group text-left"
                >
                  <div className="w-8 h-8 rounded-lg bg-green-100 text-green-700 flex items-center justify-center mb-2 group-hover:bg-[#1C3ECA] group-hover:text-[#60A5FA] transition-colors">
                    <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M18 9v3m0 0v3m0-3h3m-3 0h-3m-2-5a4 4 0 11-8 0 4 4 0 018 0zM3 20a6 6 0 0112 0v1H3v-1z" /></svg>
                  </div>
                  <span className="text-sm font-semibold text-gray-700 group-hover:text-[#1C3ECA]">Add Employee</span>
                </button>
                <button
                  onClick={() => router.push('/payroll')}
                  className="p-4 rounded-xl bg-white border border-gray-100 shadow-sm hover:shadow-md hover:border-[#60A5FA]/50 transition-all group text-left"
                >
                  <div className="w-8 h-8 rounded-lg bg-blue-100 text-blue-700 flex items-center justify-center mb-2 group-hover:bg-blue-600 group-hover:text-white transition-colors">
                    <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z" /></svg>
                  </div>
                  <span className="text-sm font-semibold text-gray-700 group-hover:text-blue-700">Import Payroll</span>
                </button>
                <button
                  onClick={() => router.push('/admin/feedbacks')}
                  className="p-4 rounded-xl bg-white border border-gray-100 shadow-sm hover:shadow-md hover:border-[#60A5FA]/50 transition-all group text-left">
                  <div className="w-8 h-8 rounded-lg bg-yellow-100 text-yellow-700 flex items-center justify-center mb-2 group-hover:bg-yellow-600 group-hover:text-white transition-colors">
                    <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M7 8h10M7 12h4m1 8l-4-4H5a2 2 0 01-2-2V6a2 2 0 012-2h14a2 2 0 012 2v8a2 2 0 01-2 2h-3l-4 4z" /></svg>
                  </div>
                  <span className="text-sm font-semibold text-gray-700 group-hover:text-yellow-700">Feedback</span>
                </button>
                <button className="p-4 rounded-xl bg-white border border-gray-100 shadow-sm hover:shadow-md hover:border-[#60A5FA]/50 transition-all group text-left">
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
                {recentActivity.length === 0 ? (
                  <p className="text-sm text-gray-500">No recent activity.</p>
                ) : (
                  recentActivity.map((activity) => (
                    <div key={activity.id} className="flex gap-3 pb-3 border-b border-gray-50 last:border-0 last:pb-0">
                      <div className={`w-2 h-2 rounded-full mt-2 shadow-[0_0_8px] ${activity.type === 'employee_onboarding' ? 'bg-[#93C5FD] shadow-[#93C5FD]' : 'bg-orange-400 shadow-orange-400'
                        }`}></div>
                      <div>
                        <p className="text-sm text-gray-800" dangerouslySetInnerHTML={{
                          // Bold the user name if present in message
                          __html: activity.message.replace(activity.user, `<strong>${activity.user}</strong>`)
                        }}></p>
                        <p className="text-xs text-gray-400 mt-1">
                          {new Date(activity.timestamp).toLocaleDateString()} {new Date(activity.timestamp).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
                          {/* We could use a TimeAgo library if available, but simple date/time is fine for now */}
                        </p>
                      </div>
                    </div>
                  ))
                )}
              </div>
            </div>
          </div>
        </div>
      </div>
    </DashboardLayout >
  );
}


