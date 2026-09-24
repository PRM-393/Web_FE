import { create } from 'zustand';
import type { AuthTokens, AuthUser } from '@/types/auth';

interface AuthState {
  user: AuthUser | null;
  accessToken: string | null;
  refreshToken: string | null;
  setSession: (user: AuthUser, tokens: AuthTokens) => void;
  clearSession: () => void;
}

const STORAGE_KEY = 'voucher_platform_auth';

function loadPersisted(): Pick<AuthState, 'user' | 'accessToken' | 'refreshToken'> {
  try {
    const raw = localStorage.getItem(STORAGE_KEY);
    if (!raw) return { user: null, accessToken: null, refreshToken: null };
    return JSON.parse(raw);
  } catch {
    return { user: null, accessToken: null, refreshToken: null };
  }
}

export const useAuthStore = create<AuthState>((set) => ({
  ...loadPersisted(),
  setSession: (user, tokens) => {
    const next = { user, accessToken: tokens.accessToken, refreshToken: tokens.refreshToken };
    localStorage.setItem(STORAGE_KEY, JSON.stringify(next));
    set(next);
  },
  clearSession: () => {
    localStorage.removeItem(STORAGE_KEY);
    set({ user: null, accessToken: null, refreshToken: null });
  },
}));
