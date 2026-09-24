import type { PropsWithChildren } from 'react';
import { Navigate } from 'react-router-dom';
import { useAuthStore } from '@/store/auth.store';
import type { Role } from '@/types/auth';

// Bao ve route theo vai tro (FR-AUTH-07). Chua dang nhap -> /login; sai vai tro -> /forbidden.
export function RequireRole({ roles, children }: PropsWithChildren<{ roles: Role[] }>) {
  const { user } = useAuthStore();

  if (!user) return <Navigate to="/login" replace />;
  if (!roles.includes(user.role)) return <Navigate to="/forbidden" replace />;

  return <>{children}</>;
}
