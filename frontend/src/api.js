import axios from 'axios';

const API_BASE_URL = '';  // Empty because we use proxy in vite.config

const api = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    'Content-Type': 'application/json',
  },
});

// Request interceptor to add auth token
api.interceptors.request.use(
  (config) => {
    const token = localStorage.getItem('access_token');
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
  },
  (error) => Promise.reject(error)
);

// Response interceptor to handle token refresh
api.interceptors.response.use(
  (response) => response,
  async (error) => {
    const originalRequest = error.config;

    // If 401 and not already retried, try to refresh token
    if (error.response?.status === 401 && !originalRequest._retry) {
      originalRequest._retry = true;

      const refreshToken = localStorage.getItem('refresh_token');
      if (refreshToken) {
        try {
          const response = await axios.post('/auth/refresh', {
            refresh_token: refreshToken,
          });

          const { access_token, refresh_token: newRefreshToken } = response.data;
          localStorage.setItem('access_token', access_token);
          localStorage.setItem('refresh_token', newRefreshToken);

          originalRequest.headers.Authorization = `Bearer ${access_token}`;
          return api(originalRequest);
        } catch (refreshError) {
          // Refresh failed, logout user
          localStorage.clear();
          window.location.href = '/login';
          return Promise.reject(refreshError);
        }
      }
    }

    return Promise.reject(error);
  }
);

// Auth API
export const authAPI = {
  register: (email, password) => 
    api.post('/auth/register', { email, password }),
  
  login: (email, password) =>
    api.post('/auth/login', { email, password }),
  
  verifyMFA: (ticket, otp_code) =>
    api.post('/auth/mfa/verify', { ticket, otp_code }),
  
  enrollMFA: () =>
    api.post('/auth/mfa/enroll'),
  
  activateMFA: (otp_code) =>
    api.post('/auth/mfa/activate', { otp_code }),
  
  logout: (refresh_token) =>
    api.post('/auth/logout', { refresh_token }),
  
  getCurrentUser: () =>
    api.get('/auth/me'),
};

// Dashboard API
export const dashboardAPI = {
  getMetrics: () =>
    api.get('/api/metrics'),
  
  getKPIs: () =>
    api.get('/api/kpis'),
  
  getAlerts: (params) =>
    api.get('/api/alerts', { params }),
  
  updateAlertStatus: (alertId, status) =>
    api.patch(`/api/alerts/${alertId}/status`, { status }),
  
  getThreshold: () =>
    api.get('/api/threshold'),
  
  updateThreshold: (new_value) =>
    api.put('/api/threshold', { new_value }),
  
  getActiveBlocks: () =>
    api.get('/api/blocks/active'),
  
  createBlock: (src_ip, reason) =>
    api.post('/api/blocks', { src_ip, reason }),
  
  deactivateBlock: (blockId) =>
    api.patch(`/api/blocks/${blockId}/deactivate`),
  
  getAuditLogs: (params) =>
    api.get('/api/audit', { params }),
};

// Users API
export const usersAPI = {
  listUsers: (query) =>
    api.get('/users', { params: { query } }),
  
  getUser: (userId) =>
    api.get(`/users/${userId}`),
  
  createUser: (email, password, role) =>
    api.post('/users', { email, password, role }),
  
  updateUser: (userId, data) =>
    api.patch(`/users/${userId}`, data),
  
  resetPassword: (userId, new_password) =>
    api.post(`/users/${userId}/reset-password`, { new_password }),
};

export default api;

