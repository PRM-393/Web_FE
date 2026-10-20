import { NavLink, Outlet } from 'react-router-dom';
import { AppShell } from '@/components/layout/AppShell';
import { Icon } from '@/components/ui/Icon';

export function AdminLayout() {
 const nav = <><NavLink to="/admin/dashboard" className="nav-link"><Icon name="grid"/><span>Tổng quan</span></NavLink><NavLink to="/admin/approvals/brands" className="nav-link"><Icon name="store"/><span>Duyệt thương hiệu</span></NavLink><NavLink to="/admin/approvals/campaigns" className="nav-link"><Icon name="ticket"/><span>Duyệt chiến dịch</span></NavLink><NavLink to="/admin/refunds" className="nav-link"><Icon name="wallet"/><span>Hoàn tiền</span></NavLink><NavLink to="/admin/settlements" className="nav-link"><Icon name="chart"/><span>Đối soát</span></NavLink></>;
 return <AppShell nav={nav} title="Quản trị nền tảng"><Outlet/></AppShell>;
}
