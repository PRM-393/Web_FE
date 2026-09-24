import { NavLink, Outlet } from 'react-router-dom';
import { AppShell } from '@/components/layout/AppShell';

export function AdminLayout() {
  const nav = (
    <>
      <NavLink to="/admin/dashboard" className="nav-link">
        Bang dieu khien
      </NavLink>
      <NavLink to="/admin/approvals/brands" className="nav-link">
        Duyet thuong hieu
      </NavLink>
      <NavLink to="/admin/approvals/campaigns" className="nav-link">
        Duyet chien dich
      </NavLink>
      <NavLink to="/admin/settlements" className="nav-link">
        Doi soat
      </NavLink>
    </>
  );

  return (
    <AppShell nav={nav} title="Quan tri he thong">
      <Outlet />
    </AppShell>
  );
}
