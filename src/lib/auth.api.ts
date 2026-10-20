import { apiClient } from './api-client';
import type { LoginResponse } from '@/types/auth';

export const authApi = {
  login: (email: string, password: string) =>
    apiClient.post<LoginResponse>('/auth/login', { email, password, deviceId: getDeviceId() }).then((r) => r.data),

  requestOtp: (email: string) => apiClient.post('/auth/otp/request', { email }).then((r) => r.data),

  verifyOtp: (email: string, otp: string) =>
    apiClient.post<LoginResponse>('/auth/otp/verify', { email, otp, deviceId: getDeviceId() }).then((r) => r.data),

  logout: () => apiClient.post('/auth/logout'),
  requestActivation: (email: string) => apiClient.post('/auth/activation/request', { email }),
  activate: (email: string, token: string, password: string) => apiClient.post('/auth/activate', { email, token, password }),
};

function getDeviceId() {
  const key = 'voucher_platform_device';
  let id = localStorage.getItem(key);
  if (!id) { id = crypto.randomUUID(); localStorage.setItem(key, id); }
  return id;
}
