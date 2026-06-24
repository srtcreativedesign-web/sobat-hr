'use client';

import { ReactNode, useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { useAuthStore } from '@/store/auth-store';
import { AppSidebar } from './AppSidebar';
import { SidebarProvider, SidebarInset, SidebarTrigger } from '@/components/animate-ui/components/radix/sidebar';
import { Button } from '@nextui-org/react';

interface DashboardLayoutProps {
  children: ReactNode;
}

export default function DashboardLayout({ children }: DashboardLayoutProps) {
  const { isAuthenticated, isInitialized } = useAuthStore();
  const router = useRouter();
  const [isAdminImpersonating, setIsAdminImpersonating] = useState(false);

  useEffect(() => {
    if (isInitialized && !isAuthenticated) {
      router.push('/login');
    }
  }, [isInitialized, isAuthenticated, router]);

  useEffect(() => {
    if (typeof window !== 'undefined') {
      setIsAdminImpersonating(!!localStorage.getItem('admin_token'));
    }
  }, []);

  const handleStopImpersonating = () => {
    const adminToken = localStorage.getItem('admin_token');
    if (adminToken) {
      localStorage.setItem('token', adminToken);
      localStorage.removeItem('admin_token');
      // Forcing a full page reload to clear store states and re-fetch admin data
      window.location.href = '/dashboard';
    }
  };

  if (!isInitialized) {
    return null; // Or a loading spinner
  }

  if (!isAuthenticated) {
    return null; // Will redirect via useEffect
  }

  return (
    <SidebarProvider>
      <AppSidebar />
      <SidebarInset>
        {isAdminImpersonating && (
          <div className="bg-danger text-white px-4 py-2 flex items-center justify-between z-50 shadow-md relative">
            <div className="flex items-center gap-2">
              <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" /><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z" /></svg>
              <span className="font-semibold text-sm">
                Mode Remote Akun: Anda sedang login sebagai karyawan.
              </span>
            </div>
            <Button 
              size="sm" 
              color="default" 
              variant="flat" 
              className="bg-white/20 text-white hover:bg-white/30 border-none"
              onPress={handleStopImpersonating}
            >
              Kembali ke Admin
            </Button>
          </div>
        )}
        <header className="flex h-14 shrink-0 items-center gap-2 border-b bg-white px-4">
          <SidebarTrigger />
        </header>
        <main className="flex-1 overflow-auto bg-gray-50">
          {children}
        </main>
      </SidebarInset>
    </SidebarProvider>
  );
}
