'use client';

import * as React from 'react';
import Image from 'next/image';
import { usePathname, useRouter } from 'next/navigation';
import { useState, useEffect } from 'react';
import { useAuthStore } from '@/store/auth-store';
import { Role } from '@/types';
import {
  Sidebar,
  SidebarContent,
  SidebarFooter,
  SidebarGroup,
  SidebarHeader,
  SidebarMenu,
  SidebarMenuButton,
  SidebarMenuItem,
  SidebarMenuSub,
  SidebarMenuSubButton,
  SidebarMenuSubItem,
  useSidebar,
} from '@/components/animate-ui/components/radix/sidebar';
import {
  Collapsible,
  CollapsibleContent,
  CollapsibleTrigger,
} from '@/components/ui/collapsible';
import { 
  LogOut, 
  Settings, 
  ChevronRight,
  LayoutDashboard,
  Users,
  Building2,
  Store,
  Database,
  CalendarCheck,
  Banknote,
  Gift,
  CheckSquare,
  ShieldCheck,
  RotateCcw,
  Megaphone,
  FileText,
  MessageSquare
} from 'lucide-react';

interface MenuItem {
  name: string;
  href: string;
  icon: React.ReactNode;
  roles?: string[];
  subItems?: {
    name: string;
    href: string;
  }[];
}

export function AppSidebar(props: React.ComponentProps<typeof Sidebar>) {
  const pathname = usePathname();
  const router = useRouter();
  const { user, logout } = useAuthStore();
  const { state, setOpen } = useSidebar();
  const [pendingAttendanceCount, setPendingAttendanceCount] = useState(0);

  // Fetch Pending Count on Mount
  useEffect(() => {
    const fetchPendingCount = async () => {
      try {
        if (user?.role === 'super_admin' || (typeof user?.role === 'object' && (user.role as Role).name === 'admin_cabang')) {
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
    const interval = setInterval(fetchPendingCount, 60000);
    return () => clearInterval(interval);
  }, [user]);

  const menuItems: MenuItem[] = [
    {
      name: 'Dashboard',
      href: '/dashboard',
      icon: <LayoutDashboard />,
      roles: ['super_admin', 'admin_cabang', 'personalia', 'admin_hr'],
    },
    {
      name: 'Employees',
      href: '/employees',
      icon: <Users />,
      roles: ['super_admin', 'admin_cabang', 'manager', 'personalia', 'admin_hr'],
      subItems: [
        { name: 'Employee List', href: '/employees' },
        { name: 'Master Data', href: '/employees/master' },
        { name: 'Invite Staff', href: '/employees/invite' },
        { name: 'Contract Digital', href: '/employees/contracts' }
      ]
    },
    {
      name: 'Struktur Organisasi',
      href: '/organizations',
      icon: <Building2 />,
      roles: ['super_admin', 'admin_cabang', 'personalia', 'admin_hr'],
    },
    {
      name: 'Manajemen Outlet',
      href: '/organizations/outlets',
      icon: <Store />,
      roles: ['super_admin', 'admin_cabang', 'personalia', 'admin_hr'],
      subItems: [
        { name: 'Daftar Outlet', href: '/organizations/outlets' }
      ]
    },
    {
      name: 'Master Data',
      href: '/master-data',
      icon: <Database />,
      roles: ['super_admin', 'personalia'],
      subItems: [
        { name: 'Departemen', href: '/master-data/departments' },
        { name: 'Divisi', href: '/master-data/divisions' },
        { name: 'Jabatan', href: '/master-data/job-positions' }
      ]
    },
    {
      name: 'Attendance',
      href: '/attendance',
      icon: <CalendarCheck />,
      roles: ['super_admin', 'admin_cabang', 'hr', 'personalia', 'admin_hr'],
      subItems: [
        { name: 'Head Office', href: '/attendance' },
        { name: 'Operasional', href: '/attendance/operasional' }
      ]
    },
    {
      name: 'Payroll',
      href: '/payroll',
      icon: <Banknote />,
      roles: ['super_admin', 'admin_cabang', 'admin_hr'],
      subItems: [
        { name: 'Payroll List', href: '/payroll' },
        { name: 'Overtime', href: '/payroll/overtime' }
      ]
    },
    {
      name: 'THR (Holiday Bonus)',
      href: '/payroll/thr',
      icon: <Gift />,
      roles: ['super_admin', 'admin_cabang', 'personalia', 'admin_hr'],
    },
    {
      name: 'Approvals',
      href: '/approvals',
      icon: <CheckSquare />,
      roles: ['super_admin', 'admin_cabang', 'manager', 'personalia', 'admin_hr'],
    },
    {
      name: 'Roles',
      href: '/roles',
      icon: <ShieldCheck />,
      roles: ['super_admin'],
    },
    {
      name: 'Announcements',
      href: '/announcements',
      icon: <Megaphone />,
      roles: ['super_admin', 'admin_cabang', 'hr', 'personalia', 'admin_hr'],
    },
    {
      name: 'HR Policies',
      href: '/hr-policies',
      icon: <FileText />,
      roles: ['super_admin', 'admin_cabang', 'personalia', 'admin_hr'],
    },
    {
      name: 'Feedback',
      href: '/feedback',
      icon: <MessageSquare />,
      roles: ['super_admin', 'admin_cabang', 'personalia', 'admin_hr'],
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
    <Sidebar collapsible="icon" {...props}>
      <SidebarHeader className="border-b border-sidebar-border bg-sidebar pt-6 pb-4">
        <div className="flex items-center gap-3 px-2">
          <div className="w-10 h-10 rounded-xl bg-white flex items-center justify-center shadow-sm">
            <div className="relative w-6 h-6">
              <Image
                src="/logo/favicon.png"
                alt="Logo"
                fill
                sizes="24px"
                className="object-contain"
              />
            </div>
          </div>
          {state !== 'collapsed' && (
            <div>
              <h1 className="text-xl font-bold tracking-tight text-[#419cc3] drop-shadow-sm">SOBAT HR</h1>
              <p className="text-[10px] uppercase tracking-widest text-slate-500 font-semibold">Admin Panel</p>
            </div>
          )}
        </div>
      </SidebarHeader>

      <SidebarContent>
        {state !== 'collapsed' && (
          <div className="p-4 mx-2 mt-4 mb-2 rounded-2xl bg-blue-50 border border-blue-100">
            <div className="flex items-center gap-3">
              <div className="relative shrink-0">
                <div className="w-10 h-10 rounded-full bg-[#419cc3] flex items-center justify-center text-white font-bold ring-2 ring-white">
                  {user?.name?.charAt(0).toUpperCase() || 'A'}
                </div>
                <div className="absolute bottom-0 right-0 w-3 h-3 bg-green-400 rounded-full border-2 border-white"></div>
              </div>
              <div className="flex-1 min-w-0">
                <p className="text-sm font-bold text-slate-800 truncate">{user?.name || 'Admin'}</p>
                <p className="text-xs text-[#419cc3] truncate capitalize">
                  {typeof user?.role === 'string'
                    ? user.role
                    : (user?.role && typeof user.role === 'object' ? (user.role as Role).display_name : 'Administrator')}
                </p>
              </div>
            </div>
          </div>
        )}

        <SidebarGroup>
          <SidebarMenu>
            {filteredMenuItems.map((item) => {
              const isActive = pathname === item.href || (item.subItems && item.subItems.some(sub => pathname.startsWith(sub.href)));
              const hasSubItems = item.subItems && item.subItems.length > 0;
              const showBadge = item.name === 'Attendance' && pendingAttendanceCount > 0;

              return (
                <Collapsible 
                  key={item.name} 
                  asChild 
                  defaultOpen={isActive}
                  className="group/collapsible"
                >
                  <SidebarMenuItem>
                    {hasSubItems ? (
                      <>
                        <CollapsibleTrigger asChild>
                          <SidebarMenuButton 
                            isActive={false} 
                            tooltip={item.name}
                            className={isActive ? "text-sidebar-primary font-semibold" : ""}
                            onClick={() => {
                              if (state === 'collapsed') {
                                setOpen(true);
                              }
                            }}
                          >
                            {item.icon}
                            <span>{item.name}</span>
                            {showBadge && (
                              <span className="ml-auto bg-red-500 text-white text-[10px] font-bold px-1.5 py-0.5 rounded-full animate-pulse">
                                {pendingAttendanceCount}
                              </span>
                            )}
                            {!showBadge && <ChevronRight className="ml-auto transition-transform group-data-[state=open]/collapsible:rotate-90" />}
                          </SidebarMenuButton>
                        </CollapsibleTrigger>
                        
                        <CollapsibleContent>
                          <SidebarMenuSub>
                            {item.subItems?.map((sub) => {
                              const isSubActive = pathname === sub.href;
                              return (
                                <SidebarMenuSubItem key={sub.href}>
                                  <SidebarMenuSubButton 
                                    asChild 
                                    isActive={isSubActive}
                                  >
                                    <a href={sub.href}>{sub.name}</a>
                                  </SidebarMenuSubButton>
                                </SidebarMenuSubItem>
                              );
                            })}
                          </SidebarMenuSub>
                        </CollapsibleContent>
                      </>
                    ) : (
                      <SidebarMenuButton 
                        asChild 
                        isActive={isActive} 
                        tooltip={item.name}
                      >
                        <a href={item.href}>
                          {item.icon}
                          <span>{item.name}</span>
                          {showBadge && (
                            <span className="ml-auto bg-red-500 text-white text-[10px] font-bold px-1.5 py-0.5 rounded-full animate-pulse">
                              {pendingAttendanceCount}
                            </span>
                          )}
                        </a>
                      </SidebarMenuButton>
                    )}
                  </SidebarMenuItem>
                </Collapsible>
              );
            })}
          </SidebarMenu>
        </SidebarGroup>
      </SidebarContent>

      <SidebarFooter className="border-t border-sidebar-border p-2">
        <SidebarMenu>
          <SidebarMenuItem>
            <SidebarMenuButton onClick={() => router.push('/settings')} tooltip="Settings">
              <Settings />
              <span>Settings</span>
            </SidebarMenuButton>
          </SidebarMenuItem>
          <SidebarMenuItem>
            <SidebarMenuButton onClick={handleLogout} tooltip="Logout" className="text-red-500 hover:text-red-600 hover:bg-red-50">
              <LogOut />
              <span>Logout</span>
            </SidebarMenuButton>
          </SidebarMenuItem>
        </SidebarMenu>
      </SidebarFooter>
    </Sidebar>
  );
}
