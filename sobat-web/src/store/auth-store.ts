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
  login: (email: string, password: string) => Promise<void>;
  logout: () => Promise<void>;
  checkAuth: () => Promise<void>;
  initAuth: () => void;
  setUser: (user: User | null) => void;
}

export const useAuthStore = create<AuthState>()(
  persist(
    (set, get) => ({
      user: null,
      token: null,
      isAuthenticated: false,
      isLoading: false,
      lastChecked: null,

      setUser: (user: User | null) => {
        set({ user });
        if (user) {
          localStorage.setItem(STORAGE_KEYS.USER, JSON.stringify(user));
        } else {
          localStorage.removeItem(STORAGE_KEYS.USER);
        }
      },

      initAuth: () => {
        // Initialize auth from localStorage on app start
        const token = localStorage.getItem(STORAGE_KEYS.TOKEN);
        const storedUser = localStorage.getItem(STORAGE_KEYS.USER);

        if (token && storedUser) {
          try {
            const user = JSON.parse(storedUser);
            set({
              user,
              token,
              isAuthenticated: true,
            });
          } catch (e) {
            console.error('Failed to parse stored user:', e);
          }
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

          // Save authentication data
          localStorage.setItem(STORAGE_KEYS.TOKEN, access_token);
          localStorage.setItem(STORAGE_KEYS.USER, JSON.stringify(user));

          set({
            user,
            token: access_token,
            isAuthenticated: true,
            isLoading: false,
          });
        } catch (error: any) {
          set({ isLoading: false });
          throw error;
        }
      },

      logout: async () => {
        try {
          await apiClient.post(API_ENDPOINTS.AUTH.LOGOUT);
        } catch (error) {
          console.error('Logout error:', error);
        } finally {
          // Clear storage
          localStorage.removeItem(STORAGE_KEYS.TOKEN);
          localStorage.removeItem(STORAGE_KEYS.USER);

          set({
            user: null,
            token: null,
            isAuthenticated: false,
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

        const token = localStorage.getItem(STORAGE_KEYS.TOKEN);

        if (!token) {
          set({ isAuthenticated: false, user: null, token: null });
          return;
        }

        // Verify token with backend
        try {
          const response = await apiClient.get(API_ENDPOINTS.AUTH.ME);
          set({
            user: response.data,
            token,
            isAuthenticated: true,
            lastChecked: now,
          });
          localStorage.setItem(STORAGE_KEYS.USER, JSON.stringify(response.data));
        } catch (error) {
          // Only logout if explicitly 401 Unauthorized
          if ((error as any)?.response?.status === 401) {
            localStorage.removeItem(STORAGE_KEYS.TOKEN);
            localStorage.removeItem(STORAGE_KEYS.USER);
            set({
              user: null,
              token: null,
              isAuthenticated: false,
              lastChecked: null,
            });
          } else {
            // Network error or other - keep existing session
            console.warn('Auth check failed, keeping existing session:', error);
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
      }),
    }
  )
);
