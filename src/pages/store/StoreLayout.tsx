import { NavLink, Outlet } from 'react-router-dom';
import { AppShell } from '@/components/layout/AppShell';
import { Icon } from '@/components/ui/Icon';

export function StoreLayout() {
 const nav = <><NavLink to="/store/redeem" className="nav-link"><Icon name="scan"/><span>Sử dụng voucher</span></NavLink><NavLink to="/store/history" className="nav-link"><Icon name="clock"/><span>Lịch sử hôm nay</span></NavLink></>;
 return <AppShell nav={nav} title="Không gian cửa hàng"><Outlet/></AppShell>;
}
