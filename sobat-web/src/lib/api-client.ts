import axios, { AxiosError } from 'axios';
import { API_URL, STORAGE_KEYS } from './config';

// Create axios instance
const apiClient = axios.create({
  baseURL: API_URL,
  headers: {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  },
  timeout: 60000, // 60 seconds timeout (Consistent with Mobile)
});

// Helper to read token from zustand persisted state
function getPersistedToken(): string | null {
  if (typeof window === 'undefined') return null;
  try {
    const raw = localStorage.getItem('auth-storage');
    if (!raw) return null;
    const parsed = JSON.parse(raw);
    return parsed?.state?.token ?? null;
  } catch {
    return null;
  }
}

// Request interceptor
apiClient.interceptors.request.use(
  (config) => {
    // Attach Bearer token from zustand persisted state
    const token = getPersistedToken();
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
  },
  (error) => Promise.reject(error)
);

// Response interceptor
apiClient.interceptors.response.use(
  (response) => response,
  (error: AxiosError) => {
    // Don't auto-logout on 401 - let the auth store handle it
    // This prevents aggressive logout on network issues or temporary errors
    return Promise.reject(error);
  }
);

export default apiClient;
