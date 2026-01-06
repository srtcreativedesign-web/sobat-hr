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
  login: (email: string, password: string) => Promise<void>;
  logout: () => Promise<void>;
  checkAuth: () => Promise<void>;
}

export const useAuthStore = create<AuthState>()(
  persist(
    (set) => ({
      user: null,
      token: null,
      isAuthenticated: false,
      isLoading: false,

      login: async (email: string, password: string) => {
        try {
          set({ isLoading: true });
          const response = await apiClient.post(API_ENDPOINTS.AUTH.LOGIN, {
            email,
            password,
          });

          const { access_token, user } = response.data;

          // Save to localStorage
          localStorage.setItem(STORAGE_KEYS.TOKEN, access_token);
          localStorage.setItem(STORAGE_KEYS.USER, JSON.stringify(user));

          set({
            user,
            token: access_token,
            isAuthenticated: true,
            isLoading: false,
          });
        } catch (error) {
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
        const token = localStorage.getItem(STORAGE_KEYS.TOKEN);
        if (!token) {
          set({ isAuthenticated: false });
          return;
        }

        try {
          const response = await apiClient.get(API_ENDPOINTS.AUTH.ME);
          set({
            user: response.data,
            token,
            isAuthenticated: true,
          });
        } catch (error) {
          set({
            user: null,
            token: null,
            isAuthenticated: false,
          });
        }
      },
    }),
    {
      name: 'auth-storage',
      partialize: (state) => ({
        user: state.user,
        token: state.token,
        isAuthenticated: state.isAuthenticated,
      }),
    }
  )
);
