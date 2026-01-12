import axios, { AxiosError } from 'axios';
import { API_URL, STORAGE_KEYS } from './config';

// Create axios instance
const apiClient = axios.create({
  baseURL: API_URL,
  headers: {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  },
  timeout: 30000, // 30 seconds timeout
});

// Request interceptor
apiClient.interceptors.request.use(
  (config) => {
    // Attach Bearer token if available
    if (typeof window !== 'undefined') {
      const token = localStorage.getItem(STORAGE_KEYS.TOKEN);
      if (token) {
        config.headers.Authorization = `Bearer ${token}`;
      }
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
