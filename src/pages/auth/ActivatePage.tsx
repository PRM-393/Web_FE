import { useState, type FormEvent } from 'react';
import { Link, useSearchParams } from 'react-router-dom';
import { authApi } from '@/lib/auth.api';
import { errorMessage } from '@/lib/error';

export function ActivatePage() {
  const [params] = useSearchParams();
  const [email, setEmail] = useState(params.get('email') || '');
  const token = params.get('token') || '';
  const [password, setPassword] = useState('');
  const [confirm, setConfirm] = useState('');
  const [message, setMessage] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);
  const submit = async (event: FormEvent) => {
    event.preventDefault(); setError(''); setMessage('');
    if (token && password !== confirm) { setError('Mật khẩu xác nhận chưa khớp.'); return; }
    setLoading(true);
    try {
      if (token) { await authApi.activate(email, token, password); setMessage('Đã kích hoạt tài khoản. Bạn có thể đăng nhập.'); }
      else { await authApi.requestActivation(email); setMessage('Nếu tài khoản cần kích hoạt, liên kết sẽ được gửi qua email.'); }
    } catch (e) { setError(errorMessage(e, 'Không thể kích hoạt tài khoản. Vui lòng thử lại.')); }
    finally { setLoading(false); }
  };
  return <div className="auth-page"><form className="auth-card" onSubmit={submit}>
    <h1>Kích hoạt tài khoản</h1>
    <label>Email<input type="email" value={email} onChange={e => setEmail(e.target.value)} required readOnly={!!token} /></label>
    {token && <>
      <label>Mật khẩu mới<input type="password" autoComplete="new-password" minLength={8} maxLength={128} value={password} onChange={e => setPassword(e.target.value)} required /></label>
      <label>Xác nhận mật khẩu<input type="password" autoComplete="new-password" value={confirm} onChange={e => setConfirm(e.target.value)} required /></label>
    </>}
    {error && <p role="alert" className="form-error">{error}</p>}
    {message && <p role="status">{message}</p>}
    <button className="btn btn-primary" disabled={loading}>{loading ? 'Đang xử lý...' : token ? 'Đặt mật khẩu' : 'Gửi liên kết kích hoạt'}</button>
    <Link to="/login">Đăng nhập</Link>
  </form></div>;
}
