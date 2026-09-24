import { NavLink, Outlet } from 'react-router-dom';
import { AppShell } from '@/components/layout/AppShell';

export function StoreLayout() {
  const nav = (
    <>
      <NavLink to="/store/redeem" className="nav-link">
        Quet ma / Redeem
      </NavLink>
      <NavLink to="/store/history" className="nav-link">
        Lich su hom nay
      </NavLink>
    </>
  );

  return (
    <AppShell nav={nav} title="Nhan vien cua hang">
      <Outlet />
    </AppShell>
  );
}
