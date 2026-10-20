import { useState, type FormEvent } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { errorMessage } from '@/lib/error';
import { authApi } from '@/lib/auth.api';
import { useAuthStore } from '@/store/auth.store';
import { Icon } from '@/components/ui/Icon';
import { BrandMark } from '@/components/ui/BrandMark';

const ROLE_HOME: Record<string, string> = { BRAND_OWNER: '/brand/reports', STORE_STAFF: '/store', ADMIN: '/admin', CUSTOMER: '/login' };
const demos = [
  { label: 'Quản trị viên', email: 'admin@voucher.local', icon: 'shield' },
  { label: 'Thương hiệu', email: 'owner@highlands.local', icon: 'store' },
  { label: 'Nhân viên', email: 'staff@highlands.local', icon: 'scan' },
];

export function LoginPage() {
  const [email, setEmail] = useState(''), [password, setPassword] = useState('');
  const [error, setError] = useState<string | null>(null), [loading, setLoading] = useState(false);
  const [showPassword, setShowPassword] = useState(false);
  const setSession = useAuthStore(s => s.setSession), navigate = useNavigate();
  const handleSubmit = async (e: FormEvent) => {
    e.preventDefault(); setError(null); setLoading(true);
    try {
      const res = await authApi.login(email, password);
      setSession(res.user, { accessToken: res.accessToken, refreshToken: res.refreshToken });
      navigate(ROLE_HOME[res.user.role] ?? '/login');
    } catch (e) { setError(errorMessage(e, 'Không thể đăng nhập. Vui lòng thử lại.')); }
    finally { setLoading(false); }
  };
  return <div className="login-layout">
    <section className="login-story">
      <BrandMark light/>
      <div className="story-copy"><span className="eyebrow light"><span className="tiny-dot"/> KHÔNG GIAN KẾT NỐI THƯƠNG HIỆU</span>
        <h1>Ưu đãi tốt hơn.<br/>Kết nối <em>gần hơn.</em></h1>
        <p>Một nơi để tạo ưu đãi, quản lý chiến dịch và<br className="desktop-break"/> đồng hành cùng sự phát triển của thương hiệu.</p>
      </div>
      <div className="ticket-scene" aria-hidden="true">
        <div className="orbit orbit-one"/><div className="orbit orbit-two"/>
        <div className="floating-pill"><span className="pill-check"><Icon name="check" size={13}/></span> Kết nối bằng những ưu đãi</div>
        <div className="visual-ticket ticket-back"><div className="mini-ticket-label">YOUR NEXT LITTLE JOY</div><span>Something<br/>worth sharing.</span><Icon name="ticket" size={60}/></div>
        <div className="visual-ticket ticket-front"><div className="ticket-art"><span className="art-sun"/><span className="art-hill"/><span className="coffee-cup"/><span className="coffee-handle"/><span className="steam steam-one"/><span className="steam steam-two"/><span className="ticket-art-label">A LITTLE TREAT<br/>FOR YOUR EVERYDAY.</span></div><div className="ticket-detail"><div><small>VOUCHER MINH HỌA</small><h3>Niềm vui mỗi ngày</h3><p>Một ưu đãi, nhiều trải nghiệm.</p></div><div className="ticket-stamp"><Icon name="ticket" size={25}/></div></div><div className="ticket-tear"/><div className="ticket-barcode"/><span className="ticket-series">VOUCH. / GOOD THINGS AHEAD</span></div>
        <div className="scene-spark spark-one">✳</div><div className="scene-spark spark-two">+</div>
      </div>
      <div className="story-footer"><span>Được tạo ra để mang giá trị đến gần hơn.</span><span>© {new Date().getFullYear()} Vouch.</span></div>
    </section>
    <section className="login-panel">
      <div className="login-topline"><span>Chào mừng đến với Vouch.</span><span className="locale-badge">VI <span>·</span> Tiếng Việt</span></div>
      <div className="login-form-wrap">
        <div className="login-welcome-icon"><Icon name="ticket" size={28}/></div>
        <span className="eyebrow">BẮT ĐẦU NGÀY LÀM VIỆC</span>
        <h2>Rất vui được gặp bạn<span>.</span></h2>
        <p className="login-description">Đăng nhập để quản lý ưu đãi và những kết nối của bạn.</p>
        <form className="login-form" onSubmit={handleSubmit}>
          <label htmlFor="login-email">Địa chỉ email</label>
          <div className="input-with-icon"><Icon name="mail" size={19}/><input id="login-email" type="email" autoComplete="username" placeholder="ban@thuonghieu.vn" value={email} onChange={e => setEmail(e.target.value)} required/></div>
          <div className="label-row"><label htmlFor="login-password">Mật khẩu</label><Link to="/activate">Kích hoạt tài khoản</Link></div>
          <div className="input-with-icon"><Icon name="lock" size={19}/><input id="login-password" type={showPassword ? 'text' : 'password'} autoComplete="current-password" placeholder="Nhập mật khẩu của bạn" value={password} onChange={e => setPassword(e.target.value)} required minLength={6}/><button type="button" className="password-toggle" aria-label={showPassword ? 'Ẩn mật khẩu' : 'Hiện mật khẩu'} aria-pressed={showPassword} onClick={() => setShowPassword(v => !v)}><Icon name="eye" size={18}/></button></div>
          {error && <p className="form-error" role="alert">{error}</p>}
          <button className="btn btn-primary login-submit" type="submit" disabled={loading}>{loading ? <><span className="spinner"/> Đang đăng nhập...</> : <>Đăng nhập <Icon name="arrow" size={19}/></>}</button>
        </form>
        {import.meta.env.DEV && <div className="demo-access"><div className="demo-heading"><span>TÀI KHOẢN TRẢI NGHIỆM</span><span>Môi trường local</span></div>
          <div className="demo-roles">{demos.map(d => <button key={d.email} type="button" className={email === d.email ? 'selected' : ''} onClick={() => { setEmail(d.email); setPassword('Voucher@123'); setError(null); }}><Icon name={d.icon} size={18}/>{d.label}</button>)}</div>
          <p>Chọn vai trò để điền tài khoản mẫu, sau đó bấm Đăng nhập.</p>
        </div>}
        <div className="login-security"><Icon name="shield" size={16}/><span>Mỗi vai trò, một không gian làm việc riêng.</span></div>
      </div>
      <div className="login-bottom"><span>Voucher Platform</span><span>Thương hiệu · Cửa hàng · Quản trị</span></div>
    </section>
  </div>;
}
