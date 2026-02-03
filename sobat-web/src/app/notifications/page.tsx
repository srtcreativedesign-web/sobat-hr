'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { useAuthStore } from '@/store/auth-store';
import DashboardLayout from '@/components/DashboardLayout';
import apiClient from '@/lib/api-client';

interface Notification {
    id: string;
    type: string;
    data: {
        title?: string;
        message?: string;
        [key: string]: any;
    };
    read_at: string | null;
    created_at: string;
}

export default function NotificationsPage() {
    const router = useRouter();
    const { isAuthenticated, isInitialized, checkAuth, logout } = useAuthStore();
    const [notifications, setNotifications] = useState<Notification[]>([]);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        checkAuth();
    }, [checkAuth]);

    useEffect(() => {
        const fetchNotifications = async () => {
            try {
                setLoading(true);
                const response = await apiClient.get('/notifications');
                setNotifications(response.data.data || []);
            } catch (error: any) {
                console.error('Failed to fetch notifications:', error);
                if (error.response?.status === 401) {
                    await logout();
                    router.push('/login');
                }
            } finally {
                setLoading(false);
            }
        };

        if (isInitialized && isAuthenticated) {
            fetchNotifications();
        }
    }, [isInitialized, isAuthenticated, router, logout]);

    const handleMarkAsRead = async (id?: string) => {
        try {
            await apiClient.post('/notifications/read', id ? { id } : {});
            // Refresh the list
            const response = await apiClient.get('/notifications');
            setNotifications(response.data.data || []);
        } catch (error) {
            console.error('Failed to mark as read:', error);
        }
    };

    const getNotificationIcon = (type: string) => {
        if (type.includes('Request')) {
            return (
                <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
                </svg>
            );
        }
        if (type.includes('Attendance')) {
            return (
                <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
                </svg>
            );
        }
        return (
            <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 17h5l-1.405-1.405A2.032 2.032 0 0118 14.158V11a6.002 6.002 0 00-4-5.659V5a2 2 0 10-4 0v.341C7.67 6.165 6 8.388 6 11v3.159c0 .538-.214 1.055-.595 1.436L4 17h5m6 0v1a3 3 0 11-6 0v-1m6 0H9" />
            </svg>
        );
    };

    const unreadCount = notifications.filter(n => !n.read_at).length;

    return (
        <DashboardLayout>
            {/* Header */}
            <div className="bg-white/80 backdrop-blur-md border-b border-gray-100 sticky top-0 z-20">
                <div className="px-8 py-6 flex justify-between items-center">
                    <div>
                        <h1 className="text-2xl font-bold text-gray-800">Notifications</h1>
                        <p className="text-sm text-gray-500 mt-1">
                            {unreadCount > 0 ? `${unreadCount} unread notifications` : 'All caught up!'}
                        </p>
                    </div>
                    {unreadCount > 0 && (
                        <button
                            onClick={() => handleMarkAsRead()}
                            className="px-4 py-2 bg-[#462e37] text-white text-sm font-medium rounded-lg hover:bg-[#2d1e24] transition-colors"
                        >
                            Mark All as Read
                        </button>
                    )}
                </div>
            </div>

            {/* Content */}
            <div className="p-8">
                <div className="glass-card p-6 bg-white/50">
                    {loading ? (
                        <div className="h-40 flex items-center justify-center">
                            <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-[#462e37]"></div>
                        </div>
                    ) : notifications.length === 0 ? (
                        <div className="text-center py-12">
                            <div className="w-16 h-16 mx-auto bg-gray-100 rounded-full flex items-center justify-center mb-4">
                                <svg className="w-8 h-8 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 17h5l-1.405-1.405A2.032 2.032 0 0118 14.158V11a6.002 6.002 0 00-4-5.659V5a2 2 0 10-4 0v.341C7.67 6.165 6 8.388 6 11v3.159c0 .538-.214 1.055-.595 1.436L4 17h5m6 0v1a3 3 0 11-6 0v-1m6 0H9" />
                                </svg>
                            </div>
                            <p className="text-gray-500 font-medium">No notifications yet</p>
                            <p className="text-gray-400 text-sm mt-1">When you receive notifications, they will appear here.</p>
                        </div>
                    ) : (
                        <div className="divide-y divide-gray-100">
                            {notifications.map((notification) => (
                                <div
                                    key={notification.id}
                                    className={`flex items-start gap-4 py-4 px-2 rounded-lg transition-colors cursor-pointer hover:bg-gray-50 ${!notification.read_at ? 'bg-blue-50/50' : ''}`}
                                    onClick={() => !notification.read_at && handleMarkAsRead(notification.id)}
                                >
                                    {/* Icon */}
                                    <div className={`p-2 rounded-lg ${!notification.read_at ? 'bg-[#462e37] text-white' : 'bg-gray-100 text-gray-500'}`}>
                                        {getNotificationIcon(notification.type)}
                                    </div>

                                    {/* Content */}
                                    <div className="flex-1 min-w-0">
                                        <p className={`text-sm ${!notification.read_at ? 'font-semibold text-gray-900' : 'text-gray-700'}`}>
                                            {notification.data?.title || notification.data?.message || 'Notification'}
                                        </p>
                                        {notification.data?.message && notification.data?.title && (
                                            <p className="text-sm text-gray-500 mt-1">{notification.data.message}</p>
                                        )}
                                        <p className="text-xs text-gray-400 mt-2">
                                            {new Date(notification.created_at).toLocaleDateString('id-ID', {
                                                day: 'numeric',
                                                month: 'short',
                                                year: 'numeric',
                                                hour: '2-digit',
                                                minute: '2-digit'
                                            })}
                                        </p>
                                    </div>

                                    {/* Unread Indicator */}
                                    {!notification.read_at && (
                                        <div className="w-2 h-2 bg-[#462e37] rounded-full mt-2"></div>
                                    )}
                                </div>
                            ))}
                        </div>
                    )}
                </div>
            </div>
        </DashboardLayout>
    );
}
