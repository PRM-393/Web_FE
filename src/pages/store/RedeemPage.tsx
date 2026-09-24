import { useRef, useState } from 'react';
import { apiClient } from '@/lib/api-client';
import { Button } from '@/components/ui/Button';

type RedeemResult = { message: string; voucherItemId?: string } | null;

// FR-REDEEM-05/06/07: man hinh redeem cho nhan vien cua hang - quet QR bang camera hoac nhap OTP.
// Giao dien toi gian, nut lon, uu tien thao tac mot tay - SRS 8.1.
export function RedeemPage() {
  const [mode, setMode] = useState<'qr' | 'otp'>('qr');
  const [otpCode, setOtpCode] = useState('');
  const [billAmount, setBillAmount] = useState<number | ''>('');
  const [result, setResult] = useState<RedeemResult>(null);
  const [error, setError] = useState<string | null>(null);
  const videoRef = useRef<HTMLVideoElement>(null);

  // TODO: tich hop thu vien quet QR (vd. @zxing/browser hoac html5-qrcode), doc payload tu camera
  // qua videoRef, giai ma chuoi "voucherItemId.nonce.expiresAt.signature" va goi submitRedeem(nonce).
  const startCamera = async () => {
    try {
      const stream = await navigator.mediaDevices.getUserMedia({ video: { facingMode: 'environment' } });
      if (videoRef.current) videoRef.current.srcObject = stream;
    } catch {
      setError('Khong the truy cap camera. Vui long dung ma OTP.');
    }
  };

  const submitRedeem = async (payload: { nonce?: string; otpCode?: string }) => {
    setError(null);
    setResult(null);
    try {
      const { data } = await apiClient.post('/redeem', {
        storeId: 'STORE_ID', // TODO: lay tu StaffAssignment cua nhan vien dang dang nhap
        billAmount: billAmount === '' ? undefined : billAmount,
        ...payload,
      });
      setResult(data);
    } catch (e: any) {
      setError(e?.response?.data?.message || 'Redeem that bai, vui long thu lai.');
    }
  };

  return (
    <div className="redeem-page">
      <h2>Su dung voucher</h2>

      <div className="tabs">
        <button className={mode === 'qr' ? 'tab active' : 'tab'} onClick={() => setMode('qr')}>
          Quet QR
        </button>
        <button className={mode === 'otp' ? 'tab active' : 'tab'} onClick={() => setMode('otp')}>
          Nhap OTP
        </button>
      </div>

      {mode === 'qr' ? (
        <div className="qr-scanner">
          <video ref={videoRef} autoPlay playsInline className="qr-video" />
          <Button onClick={startCamera}>Bat camera</Button>
        </div>
      ) : (
        <div className="otp-input">
          <input
            inputMode="numeric"
            maxLength={6}
            placeholder="Ma OTP 6 so"
            value={otpCode}
            onChange={(e) => setOtpCode(e.target.value)}
          />
          <input
            type="number"
            placeholder="Gia tri hoa don (khong bat buoc)"
            value={billAmount}
            onChange={(e) => setBillAmount(e.target.value === '' ? '' : Number(e.target.value))}
          />
          <Button onClick={() => submitRedeem({ otpCode })} disabled={otpCode.length !== 6}>
            Xac nhan su dung
          </Button>
        </div>
      )}

      {result && (
        <div className="redeem-result success">
          <p>Hop le - {result.message}</p>
        </div>
      )}
      {error && (
        <div className="redeem-result error">
          <p>{error}</p>
        </div>
      )}
    </div>
  );
}
