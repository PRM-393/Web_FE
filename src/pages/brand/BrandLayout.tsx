import { NavLink, Outlet } from 'react-router-dom';
import { AppShell } from '@/components/layout/AppShell';

export function BrandLayout() {
  const nav = (
    <>
      <NavLink to="/brand/campaigns" className="nav-link">
        Chien dich voucher
      </NavLink>
      <NavLink to="/brand/stores" className="nav-link">
        Chi nhanh
      </NavLink>
      <NavLink to="/brand/staff" className="nav-link">
        Nhan vien
      </NavLink>
      <NavLink to="/brand/settlements" className="nav-link">
        Doi soat
      </NavLink>
      <NavLink to="/brand/reports" className="nav-link">
        Bao cao
      </NavLink>
    </>
  );

  return (
    <AppShell nav={nav} title="Kenh thuong hieu">
      <Outlet />
    </AppShell>
  );
}
