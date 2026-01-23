'use client';

import { useEffect, useCallback } from 'react';
import { useAuthStore } from '@/store/auth-store';
import { useRouter, usePathname } from 'next/navigation';

const INACTIVITY_LIMIT = 10 * 60 * 1000; // 10 minutes
const CHECK_INTERVAL = 60 * 1000; // Check every 1 minute
const THROTTLE_LIMIT = 30 * 1000; // Update activity at most every 30 seconds

export default function SessionProvider({ children }: { children: React.ReactNode }) {
    const { lastActivity, updateActivity, logout, isAuthenticated } = useAuthStore();
    const router = useRouter();
    const pathname = usePathname();

    // Throttled activity updater
    const handleActivity = useCallback(() => {
        if (!useAuthStore.getState().isAuthenticated) return;

        const currentLastActivity = useAuthStore.getState().lastActivity;
        const now = Date.now();

        // Only update if it's been a while to reduce state updates
        if (!currentLastActivity || (now - currentLastActivity > THROTTLE_LIMIT)) {
            useAuthStore.getState().updateActivity();
        }
    }, []);

    useEffect(() => {
        if (!isAuthenticated) return;

        // Attach listeners
        window.addEventListener('mousemove', handleActivity);
        window.addEventListener('click', handleActivity);
        window.addEventListener('keydown', handleActivity);
        window.addEventListener('scroll', handleActivity);

        // Initial update - only run on mount/auth change
        handleActivity();

        return () => {
            window.removeEventListener('mousemove', handleActivity);
            window.removeEventListener('click', handleActivity);
            window.removeEventListener('keydown', handleActivity);
            window.removeEventListener('scroll', handleActivity);
        };
    }, [isAuthenticated, handleActivity]);

    // Periodic check for timeout
    useEffect(() => {
        if (!isAuthenticated) return;

        const interval = setInterval(() => {
            const now = Date.now();
            if (lastActivity && (now - lastActivity > INACTIVITY_LIMIT)) {
                console.log('Session timed out due to inactivity');
                logout();
                router.push('/login');
            }
        }, CHECK_INTERVAL);

        return () => clearInterval(interval);
    }, [isAuthenticated, lastActivity, logout, router]);

    // Don't enforce on public routes (login), but provider is usually global
    return <>{children}</>;
}
