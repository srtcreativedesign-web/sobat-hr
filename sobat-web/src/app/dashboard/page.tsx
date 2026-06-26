'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { useAuthStore } from '@/store/auth-store';
import DashboardLayout from '@/components/DashboardLayout';
import apiClient from '@/lib/api-client';
import LatenessChart from '@/components/dashboard/LatenessChart';
import TopLateLeaderboard from '@/components/dashboard/TopLateLeaderboard';
import TopOnTimeLeaderboard from '@/components/dashboard/TopOnTimeLeaderboard';
import MetricCard from '@/components/dashboard/MetricCard';
import TextType from '@/components/TextType';
import ContractExpiringTable, { ContractExpiringEmployee } from './components/ContractExpiringTable';
import QuickShortcuts from './components/QuickShortcuts';

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
  leaderboards?: {
    top_late: any[];
    top_on_time: any[];
  };
}

interface RecentActivity {
  id: string;
  type: string;
  message: string;
  timestamp: string;
  user: string;
  status: string;
}

import { ROLES } from '@/lib/config';

export default function DashboardPage() {
  const router = useRouter();
  const { user, isAuthenticated, isInitialized, checkAuth, logout } = useAuthStore();
  const [stats, setStats] = useState<DashboardStats | null>(null);
  const [contractExpiring, setContractExpiring] = useState<ContractExpiringEmployee[]>([]);
  const [latenessData, setLatenessData] = useState([]);
  const [lastSeenCount, setLastSeenCount] = useState(0);
  const [recentActivity, setRecentActivity] = useState<RecentActivity[]>([]);
  const [loading, setLoading] = useState(true);

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
      if (roleName === ROLES.STAFF || roleName === ROLES.CREW || roleName === ROLES.EMPLOYEE) {
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

  const getGreeting = () => {
    const hour = new Date().getHours();
    if (hour < 12) return 'Good Morning';
    if (hour < 18) return 'Good Afternoon';
    return 'Good Evening';
  };

  const dummyTrend1 = [
    { value: 40 }, { value: 45 }, { value: 42 }, { value: 50 }, { value: 48 }, { value: 55 }, { value: 58 }
  ];
  const dummyTrend2 = [
    { value: 80 }, { value: 85 }, { value: 82 }, { value: 90 }, { value: 88 }, { value: 95 }, { value: 96 }
  ];
  const dummyTrend3 = [
    { value: 5 }, { value: 8 }, { value: 6 }, { value: 10 }, { value: 7 }, { value: 4 }, { value: 2 }
  ];

  return (
    <DashboardLayout>
      {/* Header */}
      <div className="bg-white/80 backdrop-blur-md border-b border-gray-100 sticky top-0 z-20">
        <div className="px-8 py-6 flex justify-between items-center">
          <div>
            <h1 className="text-2xl font-bold text-gray-800">
              {getGreeting()}, <span className="bg-gradient-to-r from-[#419cc3] to-[#89b4e1] bg-clip-text text-transparent">{user?.name}</span> 👋
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
            <button onClick={handleNotifClick} className="p-2 text-gray-400 hover:text-[#419cc3] transition-colors relative">
              {stats && stats.requests.pending > lastSeenCount && (
                <>
                  <span className="absolute top-2 right-2 w-2 h-2 bg-red-500 rounded-full animate-ping"></span>
                  <span className="absolute top-2 right-2 w-2 h-2 bg-red-500 rounded-full"></span>
                </>
              )}
              <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 17h5l-1.405-1.405A2.032 2.032 0 0118 14.158V11a6.002 6.002 0 00-4-5.659V5a2 2 0 10-4 0v.341C7.67 6.165 6 8.388 6 11v3.159c0 .538-.214 1.055-.595 1.436L4 17h5m6 0v1a3 3 0 11-6 0v-1m6 0H9" /></svg>
            </button>
            <div className="h-10 w-10 rounded-full bg-gray-200 border-2 border-white shadow-sm overflow-hidden">
              <div className="w-full h-full bg-[#419cc3] flex items-center justify-center text-white font-bold">
                {user?.name?.charAt(0)}
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Main Content */}
      <div className="p-8 space-y-8 animate-fade-in-up">

        {/* Stats Grid */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
          <MetricCard
            title="Total Employees"
            value={stats?.employees.total || 0}
            trend={2.4}
            trendLabel="vs last month"
            data={dummyTrend1}
            dataKey="value"
            color="#8b5cf6"
          />
          <MetricCard
            title="Attendance Rate"
            value={`${attendanceRate}%`}
            trend={1.2}
            trendLabel="vs last month"
            data={dummyTrend2}
            dataKey="value"
            color="#10b981"
          />
          <MetricCard
            title="Pending Requests"
            value={stats?.requests.pending || 0}
            trend={-5.6}
            trendLabel="vs last month"
            data={dummyTrend3}
            dataKey="value"
            color="#f59e0b"
          />
        </div>

        {/* Content Grid */}
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
          {/* Left Column: Charts & Tables */}
          <div className="lg:col-span-2 space-y-8">

            {/* Lateness Chart */}
            <LatenessChart data={latenessData} loading={loading} />

            {/* Leaderboards */}
            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
              <TopLateLeaderboard data={stats?.leaderboards?.top_late} loading={loading} />
              <TopOnTimeLeaderboard data={stats?.leaderboards?.top_on_time} loading={loading} />
            </div>

            {/* Contract Expiring Table */}
            <ContractExpiringTable contractExpiring={contractExpiring} loading={loading} />

          </div>

          {/* Right Column: Quick Actions & Activity */}
          <div className="space-y-6">
            <QuickShortcuts />

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
                        <p className="text-sm text-gray-800">
                          {activity.message.split(activity.user).map((part, i, arr) => (
                            <span key={i}>
                              {part}
                              {i < arr.length - 1 && <strong>{activity.user}</strong>}
                            </span>
                          ))}
                        </p>
                        <p className="text-xs text-gray-400 mt-1">
                          {new Date(activity.timestamp).toLocaleDateString()} {new Date(activity.timestamp).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
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
    </DashboardLayout>
  );
}
