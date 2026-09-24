import { useState, type FormEvent } from 'react';
import { useNavigate } from 'react-router-dom';
import { authApi } from '@/lib/auth.api';
import { useAuthStore } from '@/store/auth.store';
import { Button } from '@/components/ui/Button';

const ROLE_HOME: Record<string, string> = {
  BRAND_OWNER: '/brand',
  STORE_STAFF: '/store',
  ADMIN: '/admin',
  CUSTOMER: '/login',
};

// FR-AUTH-06: dang nhap bang email + mat khau (danh cho BrandOwner / StoreStaff / Admin).
// Khach hang (Customer) dang nhap OTP tren ung dung di dong, khong thuoc pham vi web nay.
export function LoginPage() {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);
  const setSession = useAuthStore((s) => s.setSession);
  const navigate = useNavigate();

  const handleSubmit = async (e: FormEvent) => {
    e.preventDefault();
    setError(null);
    setLoading(true);
    try {
      const res = await authApi.login(email, password);
      setSession(res.user, { accessToken: res.accessToken, refreshToken: res.refreshToken });
      navigate(ROLE_HOME[res.user.role] ?? '/login');
    } catch {
      setError('Sai email hoac mat khau. Vui long thu lai.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="auth-page">
      <form className="auth-card" onSubmit={handleSubmit}>
        <h1>Dang nhap</h1>
        <p className="auth-subtitle">Danh cho chu thuong hieu, nhan vien cua hang va quan tri vien</p>

        <label>
          Email
          <input type="email" value={email} onChange={(e) => setEmail(e.target.value)} required />
        </label>
        <label>
          Mat khau
          <input
            type="password"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            required
            minLength={6}
          />
        </label>

        {error && <p className="form-error">{error}</p>}

        <Button type="submit" disabled={loading}>
          {loading ? 'Dang xu ly...' : 'Dang nhap'}
        </Button>
      </form>
    </div>
  );
}
