import { create } from 'zustand';
import { persist } from 'zustand/middleware';
import apiClient from '@/lib/api-client';
import { API_ENDPOINTS, STORAGE_KEYS } from '@/lib/config';

interface User {
  id: number;
  name: string;
  email: string;
  role: string;
  employee?: any;
}

interface AuthState {
  user: User | null;
  token: string | null;
  isAuthenticated: boolean;
  isLoading: boolean;
  lastChecked: number | null;
  lastActivity: number | null;
  isInitialized: boolean;
  login: (email: string, password: string) => Promise<void>;
  logout: () => Promise<void>;
  checkAuth: () => Promise<void>;
  initAuth: () => void;
  setUser: (user: User | null) => void;
  updateActivity: () => void;
}

export const useAuthStore = create<AuthState>()(
  persist(
    (set, get) => ({
      user: null,
      token: null,
      isAuthenticated: false,
      isLoading: false,
      lastChecked: null,
      lastActivity: null,
      isInitialized: false,

      updateActivity: () => {
        set({ lastActivity: Date.now() });
      },

      setUser: (user: User | null) => {
        set({ user });
      },

      initAuth: () => {
        // zustand/persist rehydrates state automatically;
        // just mark as initialized and validate what we have
        const state = get();
        if (state.token && state.user) {
          set({ isInitialized: true });
        } else {
          set({ isAuthenticated: false, user: null, token: null, isInitialized: true });
        }
      },

      login: async (email: string, password: string) => {
        try {
          set({ isLoading: true });

          // Direct Bearer token authentication with Sanctum
          const response = await apiClient.post(API_ENDPOINTS.AUTH.LOGIN, {
            email,
            password,
          });

          // Handle response structure: { success, data: { access_token, user } }
          const responseData = response.data?.data || response.data;
          const { access_token, user } = responseData;

          if (!access_token || !user) {
            throw new Error('Invalid response from server');
          }

          // State is persisted automatically by zustand/persist
          set({
            user,
            token: access_token,
            isAuthenticated: true,
            isLoading: false,
            lastActivity: Date.now(),
          });
        } catch (error: any) {
          set({ isLoading: false });
          throw error;
        }
      },

      logout: async () => {
        try {
          await apiClient.post(API_ENDPOINTS.AUTH.LOGOUT);
        } catch (error: any) {
          // Ignore 401 Unauthorized during logout, as it means we're already logged out
          if (error?.response?.status !== 401) {
            console.error('Logout error:', error);
          }
        } finally {
          // zustand/persist handles storage cleanup on state change
          set({
            user: null,
            token: null,
            isAuthenticated: false,
            lastActivity: null,
          });
        }
      },

      checkAuth: async () => {
        const state = get();
        const now = Date.now();

        // Don't check if we checked less than 5 minutes ago
        if (state.lastChecked && (now - state.lastChecked) < 5 * 60 * 1000) {
          return;
        }

        const { token } = get();

        if (!token) {
          set({ isAuthenticated: false, user: null, token: null });
          return;
        }

        // Verify token with backend
        try {
          const response = await apiClient.get(API_ENDPOINTS.AUTH.ME);
          const userData = response.data?.data || response.data;

          set({
            user: userData,
            token,
            isAuthenticated: true,
            lastChecked: now,
          });
        } catch (error) {
          // Only logout if explicitly 401 Unauthorized
          if ((error as any)?.response?.status === 401) {
            set({
              user: null,
              token: null,
              isAuthenticated: false,
              lastChecked: null,
            });
          } else {
            // Network error or other - keep existing session
            set({ lastChecked: now });
          }
        }
      },
    }),
    {
      name: 'auth-storage',
      partialize: (state) => ({
        user: state.user,
        token: state.token,
        isAuthenticated: state.isAuthenticated,
        lastChecked: state.lastChecked,
        lastActivity: state.lastActivity,
      }),
    }
  )
);

// Sync token to legacy localStorage key for pages that use raw fetch() with STORAGE_KEYS.TOKEN
if (typeof window !== 'undefined') {
  useAuthStore.subscribe((state) => {
    if (state.token) {
      localStorage.setItem(STORAGE_KEYS.TOKEN, state.token);
    } else {
      localStorage.removeItem(STORAGE_KEYS.TOKEN);
    }
  });
}
