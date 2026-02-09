// API Configuration
//export const API_URL = 'http://192.168.1.19:8000/api';
// Hardcode production URL to ensure it works
export const API_URL = 'https://api.sobat-hr.com/api';
// export const API_URL = process.env.NEXT_PUBLIC_API_URL || 'https://api.sobat-hr.com/api';
export const APP_NAME = process.env.NEXT_PUBLIC_APP_NAME || 'SOBAT HR';

// API Endpoints
export const API_ENDPOINTS = {
  AUTH: {
    LOGIN: '/auth/login',
    REGISTER: '/auth/register',
    LOGOUT: '/auth/logout',
    ME: '/auth/me',
  },
  EMPLOYEES: '/employees',
  ORGANIZATIONS: '/organizations',
  ATTENDANCES: '/attendances',
  SHIFTS: '/shifts',
  REQUESTS: '/requests',
  APPROVALS: '/approvals',
  PAYROLLS: '/payrolls',
  ROLES: '/roles',
  DASHBOARD: {
    ANALYTICS: '/dashboard/analytics',
    TURNOVER: '/dashboard/turnover',
    HEATMAP: '/dashboard/attendance-heatmap',
  },
};

// Local Storage Keys
export const STORAGE_KEYS = {
  TOKEN: 'sobat_token',
  USER: 'sobat_user',
};
