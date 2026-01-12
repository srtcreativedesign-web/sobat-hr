'use client';

import { useEffect } from 'react';
import { useAuthStore } from '@/store/auth-store';

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const initAuth = useAuthStore((state) => state.initAuth);

  useEffect(() => {
    // Initialize auth from localStorage on app start
    initAuth();
  }, [initAuth]);

  return <>{children}</>;
}
