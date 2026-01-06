'use client';

import { useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { useAuthStore } from '@/store/auth-store';

export default function DashboardPage() {
  const router = useRouter();
  const { user, isAuthenticated, checkAuth, logout } = useAuthStore();

  useEffect(() => {
    checkAuth();
  }, [checkAuth]);

  useEffect(() => {
    if (!isAuthenticated) {
      router.push('/login');
    }
  }, [isAuthenticated, router]);

  const handleLogout = async () => {
    await logout();
    router.push('/login');
  };

  if (!isAuthenticated) {
    return null;
  }

  return (
    <div className="min-h-screen bg-gray-100">
      {/* Header */}
      <header className="bg-white shadow-sm">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-4 flex justify-between items-center">
          <h1 className="text-2xl font-bold text-gray-900">SOBAT HR Dashboard</h1>
          <div className="flex items-center gap-4">
            <div className="text-right">
              <p className="text-sm font-medium text-gray-900">{user?.name}</p>
              <p className="text-xs text-gray-500">{user?.role}</p>
            </div>
            <button
              onClick={handleLogout}
              className="px-4 py-2 bg-red-600 text-white rounded-lg hover:bg-red-700 transition"
            >
              Logout
            </button>
          </div>
        </div>
      </header>

      {/* Main Content */}
      <main className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <div className="bg-white rounded-lg shadow p-6">
          <h2 className="text-xl font-semibold mb-4">Welcome to SOBAT HR Dashboard</h2>
          
          <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mt-6">
            {/* Card 1 */}
            <div className="border border-gray-200 rounded-lg p-6 hover:shadow-md transition">
              <h3 className="text-lg font-semibold text-gray-900 mb-2">Employees</h3>
              <p className="text-gray-600 text-sm">Manage employee data and profiles</p>
              <button className="mt-4 text-blue-600 hover:text-blue-700 font-medium text-sm">
                View →
              </button>
            </div>

            {/* Card 2 */}
            <div className="border border-gray-200 rounded-lg p-6 hover:shadow-md transition">
              <h3 className="text-lg font-semibold text-gray-900 mb-2">Attendance</h3>
              <p className="text-gray-600 text-sm">Track employee attendance records</p>
              <button className="mt-4 text-blue-600 hover:text-blue-700 font-medium text-sm">
                View →
              </button>
            </div>

            {/* Card 3 */}
            <div className="border border-gray-200 rounded-lg p-6 hover:shadow-md transition">
              <h3 className="text-lg font-semibold text-gray-900 mb-2">Payroll</h3>
              <p className="text-gray-600 text-sm">Process monthly payroll calculations</p>
              <button className="mt-4 text-blue-600 hover:text-blue-700 font-medium text-sm">
                View →
              </button>
            </div>
          </div>

          {/* Status Info */}
          <div className="mt-8 p-4 bg-blue-50 border border-blue-200 rounded-lg">
            <p className="text-sm text-blue-800">
              <strong>Status:</strong> Frontend initialized successfully!
            </p>
            <p className="text-xs text-blue-600 mt-1">
              Connected to API: {process.env.NEXT_PUBLIC_API_URL}
            </p>
          </div>
        </div>
      </main>
    </div>
  );
}
