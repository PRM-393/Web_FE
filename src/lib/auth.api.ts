import { apiClient } from './api-client';
import type { LoginResponse } from '@/types/auth';

export const authApi = {
  login: (email: string, password: string) =>
    apiClient.post<LoginResponse>('/auth/login', { email, password }).then((r) => r.data),

  requestOtp: (email: string) => apiClient.post('/auth/otp/request', { email }).then((r) => r.data),

  verifyOtp: (email: string, otp: string) =>
    apiClient.post<LoginResponse>('/auth/otp/verify', { email, otp }).then((r) => r.data),

  logout: () => apiClient.post('/auth/logout'),
};
