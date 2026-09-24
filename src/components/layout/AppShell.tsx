import type { PropsWithChildren, ReactNode } from 'react';
import { useAuthStore } from '@/store/auth.store';
import { useNavigate } from 'react-router-dom';

// Layout chung: thanh dieu huong ben trai + noi dung. Dung lai cho ca 3 khu vuc /brand, /store, /admin.
export function AppShell({
  children,
  nav,
  title,
}: PropsWithChildren<{ nav: ReactNode; title: string }>) {
  const { user, clearSession } = useAuthStore();
  const navigate = useNavigate();

  const handleLogout = () => {
    clearSession();
    navigate('/login');
  };

  return (
    <div className="app-shell">
      <aside className="app-sidebar">
        <div className="app-logo">Voucher Platform</div>
        <div className="app-section-title">{title}</div>
        <nav>{nav}</nav>
      </aside>
      <div className="app-main">
        <header className="app-header">
          <span>{user?.fullName || user?.email}</span>
          <button className="btn btn-secondary" onClick={handleLogout}>
            Dang xuat
          </button>
        </header>
        <main className="app-content">{children}</main>
      </div>
    </div>
  );
}
