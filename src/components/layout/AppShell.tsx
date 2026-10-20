import type { PropsWithChildren, ReactNode } from 'react';
import { useAuthStore } from '@/store/auth.store';
import { Link, useLocation, useNavigate } from 'react-router-dom';
import { useState } from 'react';
import { authApi } from '@/lib/auth.api';
import { Icon } from '@/components/ui/Icon';
import { BrandMark } from '@/components/ui/BrandMark';

const titles: Record<string, string> = {
  '/admin/dashboard': 'Tổng quan', '/admin/approvals/brands': 'Duyệt thương hiệu',
  '/admin/approvals/campaigns': 'Duyệt chiến dịch', '/admin/settlements': 'Đối soát',
  '/admin/refunds': 'Hoàn tiền', '/brand/campaigns': 'Chiến dịch voucher',
  '/brand/campaigns/new': 'Tạo chiến dịch', '/brand/stores': 'Chi nhánh',
  '/brand/staff': 'Đội ngũ nhân viên', '/brand/settlements': 'Đối soát',
  '/brand/reports': 'Báo cáo', '/store/redeem': 'Sử dụng voucher', '/store/history': 'Lịch sử giao dịch',
};
export function AppShell({ children, nav, title }: PropsWithChildren<{ nav: ReactNode; title: string }>) {
  const { user, clearSession } = useAuthStore();
  const navigate = useNavigate(), location = useLocation();
  const [loggingOut, setLoggingOut] = useState(false), [logoutError, setLogoutError] = useState('');
  const [menuOpen, setMenuOpen] = useState(false);
  const handleLogout = async () => {
    setLoggingOut(true); setLogoutError('');
    try { await authApi.logout(); clearSession(); navigate('/login'); }
    catch (error: any) {
      if (error.response?.status === 401) { clearSession(); navigate('/login'); }
      else setLogoutError('Chưa đăng xuất được. Kiểm tra kết nối và thử lại.');
    } finally { setLoggingOut(false); }
  };
  const name = user?.fullName || user?.email.split('@')[0] || 'Bạn';
  const today = new Intl.DateTimeFormat('vi-VN', { day: '2-digit', month: 'long', year: 'numeric', timeZone: 'Asia/Ho_Chi_Minh' }).format(new Date());
  const home = user?.role === 'ADMIN' ? '/admin/dashboard' : user?.role === 'BRAND_OWNER' ? '/brand/reports' : '/store/redeem';
  return <div className="app-shell">
    {menuOpen && <button className="sidebar-backdrop" aria-label="Đóng menu" onClick={() => setMenuOpen(false)}/>}
    <aside className={'app-sidebar ' + (menuOpen ? 'is-open' : '')}>
      <Link to={home} className="logo-link" onClick={() => setMenuOpen(false)}><BrandMark/></Link>
      <div className="workspace-chip"><span className="workspace-avatar"><Icon name={user?.role === 'ADMIN' ? 'shield' : 'store'} size={18}/></span><div><strong>{title}</strong><small>Voucher Platform</small></div><span className="workspace-dot"/></div>
      <div className="app-section-title">KHÔNG GIAN LÀM VIỆC</div>
      <nav onClick={() => setMenuOpen(false)}>{nav}</nav>
      <div className="sidebar-bottom">
        <div className="sidebar-note"><span className="note-icon"><Icon name="ticket"/></span><strong>Mỗi voucher.<br/>Một kết nối mới.</strong><p>Quản lý ưu đãi, mang giá trị đến gần khách hàng hơn.</p></div>
        <div className="sidebar-profile"><span className="user-avatar">{name.charAt(0).toUpperCase()}</span><div><strong>{name}</strong><small>{user?.email}</small></div></div>
      </div>
    </aside>
    <div className="app-main">
      <header className="app-header">
        <button className="icon-button mobile-menu" aria-label="Mở menu" onClick={() => setMenuOpen(true)}><Icon name="menu"/></button>
        <div className="breadcrumbs"><span>Không gian làm việc</span><Icon name="chevron" size={13}/><strong>{titles[location.pathname] || title}</strong></div>
        <div className="header-right"><span className="header-date"><Icon name="calendar" size={16}/>{today}</span><span className="header-divider"/>
          <span className="header-avatar">{name.charAt(0).toUpperCase()}</span>
          <button className="icon-button logout-button" title="Đăng xuất" aria-label="Đăng xuất" onClick={handleLogout} disabled={loggingOut}><Icon name="logout" size={19}/></button>
        </div>
      </header>
      {logoutError && <p role="alert" className="form-error">{logoutError}</p>}
      <main className="app-content" key={location.pathname}>{children}<footer className="app-footer"><span>© {new Date().getFullYear()} Vouch. Voucher Platform</span><span>Kết nối thương hiệu. Trao gửi giá trị.</span></footer></main>
    </div>
  </div>;
}
