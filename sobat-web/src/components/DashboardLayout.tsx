'use client';

import { ReactNode } from 'react';
import Sidebar from './Sidebar';
import VirtualAssistant from './VirtualAssistant';

interface DashboardLayoutProps {
  children: ReactNode;
}

export default function DashboardLayout({ children }: DashboardLayoutProps) {
  return (
    <div className="flex min-h-screen bg-gray-50">
      <Sidebar />
      <main className="flex-1 overflow-auto">
        {children}
      </main>
      <VirtualAssistant />
    </div>
  );
}
