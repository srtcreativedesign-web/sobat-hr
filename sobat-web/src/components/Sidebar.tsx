'use client';

import { usePathname, useRouter } from 'next/navigation';
import { useAuthStore } from '@/store/auth-store';
import { useState } from 'react';
import { Role } from '@/types';

interface MenuItem {
  name: string;
  href: string;
  icon: React.ReactNode;
  roles?: string[];
}

export default function Sidebar() {
  const pathname = usePathname();
  const router = useRouter();
  const { user, logout } = useAuthStore();
  const [isCollapsed, setIsCollapsed] = useState(false);

  const menuItems: MenuItem[] = [
    {
      name: 'Dashboard',
      href: '/dashboard',
      icon: (
        <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6" />
        </svg>
      ),
    },
    {
      name: 'Employees',
      href: '/employees',
      icon: (
        <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z" />
        </svg>
      ),
      roles: ['super_admin', 'admin_cabang'],
    },
    {
      name: 'Invite Staff',
      href: '/employees/invite',
      icon: (
        <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M18 9v3m0 0v3m0-3h3m-3 0h-3m-2-5a4 4 0 11-8 0 4 4 0 018 0zM3 20a6 6 0 0112 0v1H3v-1z" />
        </svg>
      ),
      roles: ['super_admin', 'admin_cabang'],
    },
    {
      name: 'Organizations',
      href: '/organizations',
      icon: (
        <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4" />
        </svg>
      ),
      roles: ['super_admin'],
    },
    {
      name: 'Attendance',
      href: '/attendance',
      icon: (
        <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-6 9l2 2 4-4" />
        </svg>
      ),
    },
    {
      name: 'Shifts',
      href: '/shifts',
      icon: (
        <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
        </svg>
      ),
      roles: ['super_admin', 'admin_cabang'],
    },
    {
      name: 'Requests',
      href: '/requests',
      icon: (
        <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
        </svg>
      ),
    },
    {
      name: 'Payroll',
      href: '/payroll',
      icon: (
        <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
        </svg>
      ),
      roles: ['super_admin', 'admin_cabang'],
    },
    {
      name: 'Approvals',
      href: '/approvals',
      icon: (
        <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
        </svg>
      ),
      roles: ['super_admin', 'admin_cabang', 'manager'],
    },
    {
      name: 'Roles',
      href: '/roles',
      icon: (
        <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 7a2 2 0 012 2m4 0a6 6 0 01-7.743 5.743L11 17H9v2H7v2H4a1 1 0 01-1-1v-2.586a1 1 0 01.293-.707l5.964-5.964A6 6 0 1121 9z" />
        </svg>
      ),
      roles: ['super_admin'],
    },
  ];

  const handleLogout = () => {
    logout();
    router.push('/login');
  };

  const filteredMenuItems = menuItems.filter(item => {
    if (!item.roles) return true;
    const roleName = typeof user?.role === 'string'
      ? user.role
      : (user?.role && typeof user.role === 'object' ? (user.role as Role).name : '');
    return item.roles.includes(roleName || '');
  });

  return (
    <div className={`${isCollapsed ? 'w-20' : 'w-72'} h-screen sticky top-0 bg-gradient-to-b from-[#1A4D2E] to-[#041a0d] text-white transition-all duration-300 flex flex-col border-r border-[#49FFB8]/10 shadow-[4px_0_24px_rgba(0,0,0,0.2)]`}>
      {/* Header */}
      <div className="p-6 flex items-center justify-between border-b border-[#49FFB8]/10 bg-black/10 backdrop-blur-sm">
        {!isCollapsed && (
          <div className="flex items-center gap-3 animate-fade-in-up">
            <div className="w-10 h-10 rounded-xl bg-gradient-to-br from-[#49FFB8] to-[#2d7a4a] flex items-center justify-center shadow-[0_0_15px_rgba(73,255,184,0.3)]">
              <svg className="w-6 h-6 text-[#1A4D2E]" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2.5} d="M13 10V3L4 14h7v7l9-11h-7z" />
              </svg>
            </div>
            <div>
              <h1 className="text-xl font-bold tracking-tight text-white drop-shadow-md">SOBAT <span className="text-[#49FFB8]">HR</span></h1>
              <p className="text-[10px] uppercase tracking-widest text-gray-400 font-semibold">Admin Panel</p>
            </div>
          </div>
        )}
        <button
          onClick={() => setIsCollapsed(!isCollapsed)}
          className="p-2 rounded-lg text-gray-400 hover:text-[#49FFB8] hover:bg-white/5 transition-all"
        >
          <svg className="w-5 h-5 transform transition-transform" style={{ transform: isCollapsed ? 'rotate(180deg)' : 'rotate(0deg)' }} fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 19l-7-7 7-7" />
          </svg>
        </button>
      </div>

      {/* User Info */}
      <div className="p-4 mx-4 mt-6 mb-4 rounded-2xl bg-[#49FFB8]/5 border border-[#49FFB8]/10 backdrop-blur-sm">
        <div className={`flex items-center gap-3 ${isCollapsed ? 'justify-center' : ''}`}>
          <div className="relative">
            <div className="w-10 h-10 rounded-full bg-gradient-to-b from-gray-700 to-gray-900 border-2 border-[#49FFB8]/50 flex items-center justify-center font-bold text-white shadow-lg">
              {user?.name?.charAt(0).toUpperCase() || 'A'}
            </div>
            <div className="absolute bottom-0 right-0 w-3 h-3 bg-[#49FFB8] border-2 border-[#1A4D2E] rounded-full"></div>
          </div>
          {!isCollapsed && (
            <div className="flex-1 min-w-0 overflow-hidden">
              <p className="font-bold text-sm truncate text-white">{user?.name || 'Admin'}</p>
              <p className="text-xs text-[#49FFB8] truncate font-medium">
                {typeof user?.role === 'string'
                  ? user.role
                  : (user?.role && typeof user.role === 'object' ? (user.role as Role).display_name : 'Administrator')}
              </p>
            </div>
          )}
        </div>
      </div>

      {/* Navigation */}
      <nav className="flex-1 px-4 py-2 space-y-1 overflow-y-auto custom-scrollbar">
        {filteredMenuItems.map((item) => {
          const isActive = pathname === item.href;
          return (
            <button
              key={item.href}
              onClick={() => router.push(item.href)}
              className={`group w-full flex items-center gap-3 px-4 py-3 rounded-xl transition-all duration-300 relative overflow-hidden ${isActive
                  ? 'bg-[#49FFB8] text-[#1A4D2E] shadow-[0_0_20px_rgba(73,255,184,0.3)] font-bold'
                  : 'text-gray-400 hover:text-white hover:bg-white/5'
                } ${isCollapsed ? 'justify-center' : ''}`}
            >
              {isActive && (
                <div className="absolute inset-0 bg-white/20 mix-blend-overlay"></div>
              )}

              <span className={`transform transition-transform duration-300 ${isActive ? 'scale-110' : 'group-hover:scale-110'}`}>
                {item.icon}
              </span>

              {!isCollapsed && (
                <span className="text-sm tracking-wide">{item.name}</span>
              )}

              {!isCollapsed && isActive && (
                <div className="absolute right-3 w-1.5 h-1.5 rounded-full bg-[#1A4D2E]"></div>
              )}
            </button>
          );
        })}
      </nav>

      {/* Footer Actions */}
      <div className="p-4 mx-4 mb-4 mt-2 space-y-2 border-t border-[#49FFB8]/10">
        <button
          onClick={() => router.push('/settings')}
          className={`w-full flex items-center gap-3 px-4 py-3 rounded-xl text-gray-400 hover:text-white hover:bg-white/5 transition-all text-sm font-medium ${isCollapsed ? 'justify-center' : ''}`}
        >
          <svg className="w-5 h-5 opacity-70" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z" />
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
          </svg>
          {!isCollapsed && <span>Settings</span>}
        </button>
        <button
          onClick={handleLogout}
          className={`w-full flex items-center gap-3 px-4 py-3 rounded-xl bg-red-500/10 hover:bg-red-500/20 text-red-400 hover:text-red-300 transition-all text-sm font-medium border border-red-500/10 hover:border-red-500/30 ${isCollapsed ? 'justify-center' : ''}`}
        >
          <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h4a3 3 0 013 3v1" />
          </svg>
          {!isCollapsed && <span>Logout</span>}
        </button>
      </div>
    </div>
  );
}
