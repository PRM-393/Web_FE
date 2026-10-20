import { NavLink, Outlet } from 'react-router-dom';
import { AppShell } from '@/components/layout/AppShell';
import { Icon } from '@/components/ui/Icon';

export function BrandLayout() {
 const nav = <><NavLink to="/brand/reports" className="nav-link"><Icon name="grid"/><span>Tổng quan & báo cáo</span></NavLink><NavLink to="/brand/campaigns" className="nav-link"><Icon name="ticket"/><span>Chiến dịch voucher</span></NavLink><NavLink to="/brand/stores" className="nav-link"><Icon name="store"/><span>Chi nhánh</span></NavLink><NavLink to="/brand/staff" className="nav-link"><Icon name="users"/><span>Đội ngũ nhân viên</span></NavLink><NavLink to="/brand/settlements" className="nav-link"><Icon name="wallet"/><span>Đối soát</span></NavLink></>;
 return <AppShell nav={nav} title="Kênh thương hiệu"><Outlet/></AppShell>;
}
