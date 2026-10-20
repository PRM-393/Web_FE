import axios, { AxiosError, type InternalAxiosRequestConfig } from 'axios';
import type { LoginResponse } from '@/types/auth';
import { useAuthStore } from '@/store/auth.store';

export const API_BASE_URL = (import.meta.env.VITE_API_BASE_URL || 'http://localhost:3000/api').replace(/\/$/, '');
export const apiClient = axios.create({ baseURL: API_BASE_URL });

// Gan JWT access token vao moi request - CON theo SRS 8.3 (Authorization: Bearer)
apiClient.interceptors.request.use((config: InternalAxiosRequestConfig) => {
  const { accessToken } = useAuthStore.getState();
  if (accessToken) {
    config.headers = config.headers ?? {};
    config.headers.Authorization = `Bearer ${accessToken}`;
  }
  return config;
});

let refreshPromise: Promise<void> | null = null;

// Tu dong lam moi access token khi het han (401), retry request that bai mot lan
apiClient.interceptors.response.use(
  (response) => response,
  async (error: AxiosError) => {
    const originalRequest = error.config as (InternalAxiosRequestConfig & { _retry?: boolean }) | undefined;

    if (error.response?.status === 401 && originalRequest && !originalRequest._retry && (!originalRequest.url?.startsWith('/auth/') || originalRequest.url === '/auth/logout' || originalRequest.url === '/auth/select-store')) {
      const { refreshToken, setSession, clearSession } = useAuthStore.getState();
      if (!refreshToken) {
        clearSession();
        return Promise.reject(error);
      }

      originalRequest._retry = true;

      try {
        if (!refreshPromise) {
          refreshPromise = axios.post<LoginResponse>(`${API_BASE_URL}/auth/refresh`, { refreshToken })
            .then(({ data }) => {
              // A late refresh must not restore a session after logout or another login.
              if (useAuthStore.getState().refreshToken !== refreshToken) throw new Error('Phiên đăng nhập đã thay đổi.');
              setSession(data.user, { accessToken: data.accessToken, refreshToken: data.refreshToken });
            })
            .finally(() => { refreshPromise = null; });
        }
        await refreshPromise;
        return apiClient(originalRequest);
      } catch (refreshError) {
        if (useAuthStore.getState().refreshToken === refreshToken) clearSession();
        return Promise.reject(refreshError);
      }
    }

    return Promise.reject(error);
  },
);
