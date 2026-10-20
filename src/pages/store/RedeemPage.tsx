import { useEffect, useRef, useState } from 'react';
import { apiClient } from '@/lib/api-client';
import { Icon } from '@/components/ui/Icon';
import { Button } from '@/components/ui/Button';

type RedeemResult = { message: string; voucherItemId?: string } | null;

// FR-REDEEM-05/06/07: man hinh redeem cho nhan vien cua hang - quet QR bang camera hoac nhap OTP.
// Giao dien toi gian, nut lon, uu tien thao tac mot tay - SRS 8.1.
export function RedeemPage() {
  const [mode, setMode] = useState<'qr' | 'otp'>('otp');
  const [otpCode, setOtpCode] = useState('');
  const [billAmount, setBillAmount] = useState<number | ''>('');
  const [result, setResult] = useState<RedeemResult>(null);
  const [error, setError] = useState<string | null>(null);
  const videoRef = useRef<HTMLVideoElement>(null);
  const [stores, setStores] = useState<{ id: string; name: string }[]>([]);
  const [storeId, setStoreId] = useState('');
  const [selectedStore, setSelectedStore] = useState('');
  const [selectingStore, setSelectingStore] = useState(false);
  useEffect(() => {
    const controller = new AbortController();
    apiClient.get('/redeem/my-stores', { signal: controller.signal })
      .then(({ data }) => { setStores(data); setSelectedStore(data[0]?.id || ''); })
      .catch(() => { if (!controller.signal.aborted) setError('Không tải được danh sách chi nhánh. Vui lòng thử lại.'); });
    return () => controller.abort();
  }, []);
  const selectStore = async () => {
    setSelectingStore(true); setError(null); setStoreId('');
    try {
      await apiClient.post('/auth/select-store', { storeId: selectedStore });
      setStoreId(selectedStore);
    } catch { setError('Không thể chọn chi nhánh. Vui lòng thử lại.'); }
    finally { setSelectingStore(false); }
  };

  // TODO: tich hop thu vien quet QR (vd. @zxing/browser hoac html5-qrcode), doc payload tu camera
  // qua videoRef, giai ma chuoi "voucherItemId.nonce.expiresAt.signature" va goi submitRedeem(nonce).
  const startCamera = async () => {
    try {
      const stream = await navigator.mediaDevices.getUserMedia({ video: { facingMode: 'environment' } });
      if (videoRef.current) videoRef.current.srcObject = stream;
    } catch {
      setError('Không thể truy cập camera. Vui lòng dùng mã OTP.');
    }
  };

  const submitRedeem = async (payload: { nonce?: string; otpCode?: string }) => {
    setError(null);
    setResult(null);
    try {
      const { data } = await apiClient.post('/redeem', {
        storeId,
        billAmount: billAmount === '' ? undefined : billAmount,
        ...payload,
      });
      setResult(data);
    } catch (e: any) {
      setError(e?.response?.data?.message || 'Chưa xác nhận được voucher. Vui lòng thử lại.');
    }
  };

  return (
    <div className="redeem-page">
      <div className="page-heading"><div><span className="eyebrow">TRẢI NGHIỆM TẠI QUẦY</span><h1>Một mã nhỏ. Một niềm vui<span className="heading-dot">.</span></h1><p>Chọn chi nhánh làm việc và xác nhận voucher của khách hàng.</p></div><span className="neutral-pill"><Icon name="shield" size={14}/> Xác nhận một lần</span></div>
      <div className="report-filters">
        <label>Chi nhánh làm việc<select value={selectedStore} onChange={e => { setSelectedStore(e.target.value); setStoreId(''); }}>
          {stores.map(s => <option key={s.id} value={s.id}>{s.name}</option>)}
        </select></label>
        <Button onClick={selectStore} disabled={!selectedStore || selectingStore}>{selectingStore ? 'Đang chọn...' : 'Chọn chi nhánh'}</Button>
        {storeId && <span role="status">Đã chọn chi nhánh làm việc</span>}
      </div>

      <div className="redeem-workspace"><section className="redeem-main-panel"><div className="panel-heading"><div><h3>Xác nhận voucher</h3><p>Sử dụng mã đang hiển thị trên thiết bị khách hàng.</p></div><Icon name="scan"/></div>
      <div className="tabs">
        <button className={mode === 'qr' ? 'tab active' : 'tab'} onClick={() => setMode('qr')}>
          Quét QR
        </button>
        <button className={mode === 'otp' ? 'tab active' : 'tab'} onClick={() => setMode('otp')}>
          Nhập OTP
        </button>
      </div>

      {mode === 'qr' ? (
        <div className="qr-scanner">
          <video ref={videoRef} autoPlay playsInline className="qr-video" />
          <Button onClick={startCamera}>Bật camera</Button>
        </div>
      ) : (
        <div className="otp-input">
          <input
            inputMode="numeric"
            maxLength={6}
            placeholder="Mã OTP 6 chữ số"
            value={otpCode}
            onChange={(e) => setOtpCode(e.target.value)}
          />
          <input
            type="number"
            placeholder="Giá trị hóa đơn (nếu có)"
            value={billAmount}
            onChange={(e) => setBillAmount(e.target.value === '' ? '' : Number(e.target.value))}
          />
          <Button onClick={() => submitRedeem({ otpCode })} disabled={!storeId || !/^\d{6}$/.test(otpCode)}>
            Xác nhận sử dụng
          </Button>
        </div>
      )}

      </section><aside className="redeem-guide panel"><span className="guide-ticket"><Icon name="ticket" size={40}/></span><span className="eyebrow">MỘT TRẢI NGHIỆM TRỌN VẸN</span><h3>Chỉ vài bước,<br/>ưu đãi được trao.</h3><ol><li><strong>Chọn đúng chi nhánh</strong><p>Chi nhánh nơi bạn đang làm việc.</p></li><li><strong>Nhận mã từ khách hàng</strong><p>Mã OTP có 6 chữ số và hiệu lực 60 giây.</p></li><li><strong>Xác nhận & áp dụng ưu đãi</strong><p>Kiểm tra kết quả trước khi áp dụng voucher.</p></li></ol><div className="guide-note"><Icon name="clock" size={16}/>Mã hết hạn? Nhờ khách hàng làm mới mã.</div></aside></div>
      {result && (
        <div className="redeem-result success">
          <p>Hợp lệ · {result.message}</p>
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
