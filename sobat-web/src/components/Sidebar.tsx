'use client';

import Image from 'next/image';

import { usePathname, useRouter } from 'next/navigation';
import { useState, useEffect } from 'react';
import { useAuthStore } from '@/store/auth-store';
import { Role } from '@/types';

interface MenuItem {
  name: string;
  href: string;
  icon: React.ReactNode;
  roles?: string[];
  subItems?: {
    name: string;
    href: string;
    icon: React.ReactNode | null;
  }[];
}

export default function Sidebar() {
  const pathname = usePathname();
  const router = useRouter();
  const { user, logout } = useAuthStore();
  const [isCollapsed, setIsCollapsed] = useState(false);
  const [expandedMenus, setExpandedMenus] = useState<string[]>(['Employees']);
  const [pendingAttendanceCount, setPendingAttendanceCount] = useState(0);

  // Fetch Pending Count on Mount
  useEffect(() => {
    const fetchPendingCount = async () => {
      try {
        // Only fetch if user has access (Super Admin & Admin Cabang & Developer)
        if (
          user?.role === 'super_admin' ||
          user?.role === 'developer' ||
          (typeof user?.role === 'object' && user.role !== null && (user.role as Role).name === 'admin_cabang')
        ) {
          const token = localStorage.getItem('token');
          const response = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/attendance/pending-count`, {
            headers: {
              'Authorization': `Bearer ${token}`
            }
          });
          if (response.ok) {
            const data = await response.json();
            setPendingAttendanceCount(data.count);
          }
        }
      } catch (error) {
        console.error("Failed to fetch pending attendance count", error);
      }
    };

    fetchPendingCount();

    // Optional: Poll every 1 minute
    const interval = setInterval(fetchPendingCount, 60000);
    return () => clearInterval(interval);
  }, [user]);

  // Auto-expand menu based on active route
  useEffect(() => {
    menuItems.forEach(item => {
      if (item.subItems?.some(sub => pathname.startsWith(sub.href))) {
        setExpandedMenus(prev => prev.includes(item.name) ? prev : [...prev, item.name]);
      }
    });
  }, [pathname]);

  const toggleMenu = (name: string) => {
    if (isCollapsed) setIsCollapsed(false);
    setExpandedMenus(prev =>
      prev.includes(name)
        ? prev.filter(item => item !== name)
        : [...prev, name]
    );
  };

  const menuItems: MenuItem[] = [
    {
      name: 'Dashboard',
      href: '/dashboard',
      icon: (
        <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6" />
        </svg>
      ),
      roles: ['super_admin', 'admin_cabang', 'developer'],
    },
    {
      name: 'Employees',
      href: '/employees',
      icon: (
        <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z" />
        </svg>
      ),
      roles: ['super_admin', 'admin_cabang', 'manager', 'developer'],
      subItems: [
        {
          name: 'Employee List',
          href: '/employees',
          icon: null
        },
        {
          name: 'Master Data',
          href: '/employees/master',
          icon: null
        },
        {
          name: 'Invite Staff',
          href: '/employees/invite',
          icon: null
        },
        {
          name: 'Contract Digital',
          href: '/employees/contracts',
          icon: null
        }
      ]
    },
    {
      name: 'Organizations',
      href: '/organizations',
      icon: (
        <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4" />
        </svg>
      ),
      roles: ['super_admin', 'developer'],
      subItems: [
        {
          name: 'Struktur Global',
          href: '/organizations',
          icon: null
        },
        {
          name: 'Per Divisi',
          href: '/organizations/divisions',
          icon: null
        }
      ]
    },
    {
      name: 'Master Data',
      href: '/master-data',
      icon: (
        <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 11H5m14 0a2 2 0 012 2v6a2 2 0 01-2 2H5a2 2 0 01-2-2v-6a2 2 0 012-2m14 0V9a2 2 0 00-2-2M5 11V9a2 2 0 012-2m0 0V5a2 2 0 012-2h6a2 2 0 012 2v2M7 7h10" />
        </svg>
      ),
      roles: ['super_admin', 'developer'],
      subItems: [
        {
          name: 'Departemen',
          href: '/master-data/departments',
          icon: null
        },
        {
          name: 'Divisi',
          href: '/master-data/divisions',
          icon: null
        },
        {
          name: 'Jabatan',
          href: '/master-data/job-positions',
          icon: null
        }
      ]
    },
    {
      name: 'Attendance',
      href: '/attendance',
      icon: (
        <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-6 9l2 2 4-4" />
        </svg>
      ),
      // Add logic to display badge in render loop, passing it here as a property if interface allows, 
      // OR handle it in the mapping below. since interface is strict, let's just use the state variable in the map function.
    },


    {
      name: 'Payroll',
      href: '/payroll',
      icon: (
        <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
        </svg>
      ),
      roles: ['super_admin', 'admin_cabang', 'developer'],
      subItems: [
        {
          name: 'Payroll List',
          href: '/payroll',
          icon: null
        },
        {
          name: 'Overtime',
          href: '/payroll/overtime',
          icon: null
        }
      ]
    },
    {
      name: 'Approvals',
      href: '/approvals',
      icon: (
        <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
        </svg>
      ),
      roles: ['super_admin', 'admin_cabang', 'manager', 'developer'],
    },
    {
      name: 'Roles',
      href: '/roles',
      icon: (
        <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 7a2 2 0 012 2m4 0a6 6 0 01-7.743 5.743L11 17H9v2H7v2H4a1 1 0 01-1-1v-2.586a1 1 0 01.293-.707l5.964-5.964A6 6 0 1121 9z" />
        </svg>
      ),
      roles: ['super_admin', 'developer'],
    },
    {
      name: 'Reset Requests',
      href: '/admin/reset-requests',
      icon: (
        <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 7a2 2 0 012 2m4 0a6 6 0 01-7.743 5.743L11 17H9v2H7v2H4a1 1 0 01-1-1v-2.586a1 1 0 01.293-.707l5.964-5.964A6 6 0 1121 9z" />
        </svg>
      ),
      roles: ['super_admin', 'admin_cabang', 'developer'],
    },
    {
      name: 'Announcements',
      href: '/announcements',
      icon: (
        <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M11 5.882V19.24a1.76 1.76 0 01-3.417.592l-2.147-6.15M18 13a3 3 0 100-6M5.436 13.683A4.001 4.001 0 017 6h1.832c4.1 0 7.625-1.234 9.168-3v14c-1.543-1.766-5.067-3-9.168-3H7a3.988 3.988 0 01-1.564-.317z" /></svg>
      ),
      roles: ['super_admin', 'admin_cabang', 'hr', 'developer'],
    },
    {
      name: 'HR Policies',
      href: '/hr-policies',
      icon: (
        <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" /></svg>
      ),
      roles: ['super_admin', 'admin_cabang', 'developer'],
    },
    {
      name: 'Feedback',
      href: '/feedback',
      icon: (
        <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M7 8h10M7 12h4m1 8l-4-4H5a2 2 0 01-2-2V6a2 2 0 012-2h14a2 2 0 012 2v8a2 2 0 01-2 2h-3l-4 4z" /></svg>
      ),
      roles: ['super_admin', 'admin_cabang', 'developer'],
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

    // DEBUG: Check what's happening
    console.log('Sidebar Debug:', { roleName, item: item.name, allowed: item.roles, hasAccess: item.roles.includes(roleName || '') });

    return item.roles.includes(roleName || '');
  });

  return (
    <div className={`${isCollapsed ? 'w-20' : 'w-72'} h-screen sticky top-0 bg-[#60A5FA] text-white transition-all duration-300 flex flex-col border-r border-white/10 shadow-xl`}>
      {/* Header */}
      <div className="p-6 flex items-center justify-between border-b border-white/10 bg-white/5 backdrop-blur-sm">
        {!isCollapsed && (
          <div className="flex items-center gap-3 animate-fade-in-up">
            <div className="w-10 h-10 rounded-xl bg-white flex items-center justify-center shadow-lg">
              <div className="relative w-6 h-6">
                <Image
                  src="/logo/logo.png"
                  alt="Logo"
                  fill
                  className="object-contain"
                />
              </div>
            </div>
            <div>
              <h1 className="text-xl font-bold tracking-tight text-white drop-shadow-sm">SOBAT <span className="text-[#1C3ECA]">HR</span></h1>
              <p className="text-[10px] uppercase tracking-widest text-white/90 font-semibold">Admin Panel</p>
            </div>
          </div>
        )}
        <button
          onClick={() => setIsCollapsed(!isCollapsed)}
          className="p-2 rounded-lg text-white/60 hover:text-white hover:bg-white/10 transition-all"
        >
          <svg className="w-5 h-5 transform transition-transform" style={{ transform: isCollapsed ? 'rotate(180deg)' : 'rotate(0deg)' }} fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 19l-7-7 7-7" />
          </svg>
        </button>
      </div>

      {/* User Info */}
      <div className="p-4 mx-4 mt-6 mb-4 rounded-2xl bg-white/10 border border-white/10 backdrop-blur-sm">
        <div className={`flex items-center gap-3 ${isCollapsed ? 'justify-center' : ''}`}>
          <div className="relative">
            <div className="w-10 h-10 rounded-full bg-white/20 flex items-center justify-center text-white font-bold ring-2 ring-[#1C3ECA]">
              {user?.name?.charAt(0).toUpperCase() || 'A'}
            </div>
            <div className="absolute bottom-0 right-0 w-3 h-3 bg-green-400 rounded-full border-2 border-[#1C3ECA]"></div>
          </div>
          {!isCollapsed && (
            <div className="flex-1 min-w-0">
              <p className="text-sm font-bold text-white truncate">{user?.name || 'Admin'}</p>
              <p className="text-xs text-[#93C5FD] truncate capitalize">
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
          const isActive = pathname === item.href || (item.subItems && item.subItems.some(sub => pathname === sub.href));
          const isExpanded = expandedMenus.includes(item.name);
          const hasSubItems = item.subItems && item.subItems.length > 0;

          // Badge Logic
          const showBadge = item.name === 'Attendance' && pendingAttendanceCount > 0;

          return (
            <div key={item.name}>
              <button
                onClick={() => hasSubItems ? toggleMenu(item.name) : router.push(item.href)}
                className={`group w-full flex items-center gap-3 px-4 py-3 rounded-xl transition-all duration-300 relative overflow-hidden ${isActive
                  ? 'bg-white text-[#1C3ECA] shadow-lg font-bold'
                  : 'text-white/70 hover:text-white hover:bg-white/10'
                  } ${isCollapsed ? 'justify-center' : ''}`}
              >
                {isActive && (
                  <div className="absolute left-0 top-0 bottom-0 w-1 bg-[#1C3ECA]"></div>
                )}

                <span className={`transform transition-transform duration-300 ${isActive ? 'scale-110' : 'group-hover:scale-110'}`}>
                  {item.icon}
                </span>

                {!isCollapsed && (
                  <>
                    <span className="text-sm tracking-wide flex-1 text-left">{item.name}</span>

                    {/* Badge */}
                    {showBadge && (
                      <span className="bg-red-500 text-white text-[10px] font-bold px-1.5 py-0.5 rounded-full animate-pulse">
                        {pendingAttendanceCount}
                      </span>
                    )}

                    {hasSubItems && (
                      <svg className={`w-4 h-4 transition-transform ${isExpanded ? 'rotate-180' : ''}`} fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 9l-7 7-7-7" />
                      </svg>
                    )}
                  </>
                )}

                {/* Collapsed Badge (Dot) */}
                {isCollapsed && showBadge && (
                  <div className="absolute top-2 right-2 w-2 h-2 bg-red-500 rounded-full border border-white"></div>
                )}
              </button>

              {/* Submenu */}
              {!isCollapsed && hasSubItems && isExpanded && (
                <div className="ml-4 mt-1 space-y-1 border-l-2 border-white/10 pl-2">
                  {item.subItems?.map((sub) => {
                    const isSubActive = pathname === sub.href;
                    return (
                      <button
                        key={sub.href}
                        onClick={() => router.push(sub.href)}
                        className={`w-full flex items-center gap-3 px-4 py-2 rounded-lg text-sm transition-all ${isSubActive
                          ? 'bg-white/10 text-white shadow-sm font-bold border border-white/20'
                          : 'text-white/60 hover:text-white hover:bg-white/5'
                          }`}
                      >
                        {sub.name}
                      </button>
                    )
                  })}
                </div>
              )}
            </div>
          );
        })}
      </nav>

      {/* Footer Actions */}
      <div className="p-4 mx-4 mb-4 mt-2 space-y-2 border-t border-white/10">
        <button
          onClick={() => router.push('/settings')}
          className={`w-full flex items-center gap-3 px-4 py-3 rounded-xl text-white/70 hover:text-white hover:bg-white/10 transition-all text-sm font-medium ${isCollapsed ? 'justify-center' : ''}`}
        >
          <svg className="w-5 h-5 opacity-70" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z" />
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
          </svg>
          {!isCollapsed && <span>Settings</span>}
        </button>
        <button
          onClick={handleLogout}
          className={`w-full flex items-center gap-3 px-4 py-3 rounded-xl bg-red-400/10 hover:bg-red-500/20 text-red-200 hover:text-red-100 transition-all text-sm font-medium border border-red-400/10 hover:border-red-500/30 ${isCollapsed ? 'justify-center' : ''}`}
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
