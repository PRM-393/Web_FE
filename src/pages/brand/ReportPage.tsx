import { useEffect, useState } from 'react';
import { apiClient } from '@/lib/api-client';
import { errorMessage } from '@/lib/error';
import { StatCard } from '@/components/ui/StatCard';
import { Icon } from '@/components/ui/Icon';
import { formatVND } from '@/lib/format';

interface Choice { id: string; name?: string; title?: string; }
interface BrandReport {
  totalCampaigns: number; totalVoucherSold: number; totalRevenue: number;
  grossRevenue: number; refundedAmount: number;
  totalVoucherUsed: number; totalVoucherExpired: number; totalVoucherRefunded: number; usageRate: number;
}

export function ReportPage() {
  const [brands, setBrands] = useState<Choice[]>([]);
  const [brandId, setBrandId] = useState('');
  const [campaigns, setCampaigns] = useState<Choice[]>([]);
  const [stores, setStores] = useState<Choice[]>([]);
  const [campaignId, setCampaignId] = useState('');
  const [storeId, setStoreId] = useState('');
  const [from, setFrom] = useState('');
  const [to, setTo] = useState('');
  const [report, setReport] = useState<BrandReport | null>(null);
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(true);
  const [reload, setReload] = useState(0);
  useEffect(() => {
    const controller = new AbortController();
    setError(''); setLoading(true);
    apiClient.get<Choice[]>('/brands/me', { signal: controller.signal }).then(({data}) => {
      setBrands(data); setBrandId(current => data.some(b => b.id === current) ? current : data[0]?.id || '');
      if (!data.length) setLoading(false);
    }).catch(e => { if (!controller.signal.aborted) { setError(errorMessage(e)); setLoading(false); } });
    return () => controller.abort();
  }, [reload]);
  useEffect(() => {
    if (!brandId) return;
    const controller = new AbortController();
    setCampaigns([]); setStores([]);
    Promise.all([
      apiClient.get<Choice[]>('/campaigns/brand/' + brandId, { signal: controller.signal }),
      apiClient.get<Choice[]>('/brands/' + brandId + '/stores', { signal: controller.signal }),
    ]).then(([c,s]) => { setCampaigns(c.data); setStores(s.data); })
      .catch(e => { if (!controller.signal.aborted) setError(errorMessage(e)); });
    return () => controller.abort();
  }, [brandId, reload]);
  useEffect(() => {
    if (!brandId) return;
    setReport(null); setError('');
    if (from && to && from > to) { setError('Ngày bắt đầu phải trước hoặc bằng ngày kết thúc.'); setLoading(false); return; }
    const controller = new AbortController();
    setLoading(true);
    apiClient.get<BrandReport>('/brands/' + brandId + '/report', {
      signal: controller.signal, params: { campaignId: campaignId || undefined, storeId: storeId || undefined, from: from || undefined, to: to || undefined },
    }).then(({data}) => setReport(data)).catch(e => {
      if (!controller.signal.aborted) setError(errorMessage(e));
    }).finally(() => { if (!controller.signal.aborted) setLoading(false); });
    return () => controller.abort();
  }, [brandId, campaignId, storeId, from, to, reload]);
  return <div className="metric-report">
    <div className="page-heading"><div><span className="eyebrow">HIỆU QUẢ THƯƠNG HIỆU</span><h1>Tổng quan kinh doanh<span className="heading-dot">.</span></h1><p>Hiểu rõ những con số. Tạo thêm những cơ hội.</p></div></div>
    <div className="report-filters">
      <label>Thương hiệu<select value={brandId} onChange={e => { setBrandId(e.target.value); setCampaignId(''); setStoreId(''); }}>
        {brands.map(b => <option key={b.id} value={b.id}>{b.name}</option>)}
      </select></label>
      <label>Chiến dịch<select value={campaignId} onChange={e => setCampaignId(e.target.value)}>
        <option value="">Tất cả chiến dịch</option>{campaigns.map(c => <option key={c.id} value={c.id}>{c.title}</option>)}
      </select></label>
      <label>Chi nhánh<select value={storeId} onChange={e => setStoreId(e.target.value)}>
        <option value="">Tất cả chi nhánh</option>{stores.map(s => <option key={s.id} value={s.id}>{s.name}</option>)}
      </select></label>
      <label>Từ ngày<input type="date" value={from} onChange={e => setFrom(e.target.value)} /></label>
      <label>Đến ngày<input type="date" value={to} min={from || undefined} onChange={e => setTo(e.target.value)} /></label>
      <button className="btn btn-secondary" onClick={() => setReload(n => n + 1)}>Tải lại</button>
    </div>
    <p>Số liệu theo ngày thanh toán (giờ Việt Nam). Khi lọc chi nhánh, chỉ tính voucher đã sử dụng tại chi nhánh đó.</p>
    {loading && <p role="status">Đang tải báo cáo...</p>}
    {error && <p role="alert" className="form-error">{error}</p>}
    {!loading && !error && !brands.length && <p>Bạn chưa có thương hiệu.</p>}
    {!loading && report && !error && <>
      {report.totalVoucherSold === 0 && <p>Chưa có giao dịch trong khoảng thời gian đã chọn.</p>}
      <div className="stats-grid">
        <StatCard label="Doanh thu sau hoàn tiền" value={formatVND(report.totalRevenue)} note="Từ các đơn đã thanh toán" icon="wallet" accent/>
        <StatCard label="Voucher đã bán" value={report.totalVoucherSold.toString().padStart(2,'0')} note="Theo khoảng thời gian đã chọn" icon="ticket"/>
        <StatCard label="Voucher đã sử dụng" value={report.totalVoucherUsed.toString().padStart(2,'0')} note="Đã xác nhận tại chi nhánh" icon="scan"/>
        <StatCard label="Chiến dịch thương hiệu" value={report.totalCampaigns.toString().padStart(2,'0')} note="Tổng chiến dịch trong bộ lọc" icon="chart"/>
      </div>
      <div className="dashboard-columns">
        <section className="panel"><div className="panel-heading"><div><h3>Hành trình của những voucher</h3><p>Từ một ưu đãi đến một trải nghiệm thực tế.</p></div><Icon name="ticket"/></div>
          <div className="usage-content"><div className="usage-ring" style={{background: 'conic-gradient(#138b70 ' + Math.min(100,Math.max(0,report.usageRate)) + '%, #edf3e9 0)'}}><div><strong>{report.usageRate.toFixed(1)}<small>%</small></strong><span>Tỷ lệ sử dụng</span></div></div>
            <div className="usage-legend">
              <div><span><i className="legend-dot" style={{background:'#138b70'}}/>Đã sử dụng</span><strong>{report.totalVoucherUsed}</strong></div>
              <div><span><i className="legend-dot" style={{background:'#c2d5b4'}}/>Voucher còn lại</span><strong>{Math.max(0,report.totalVoucherSold-report.totalVoucherUsed-report.totalVoucherExpired-report.totalVoucherRefunded)}</strong></div>
              <div><span><i className="legend-dot" style={{background:'#d7c294'}}/>Đã hết hạn</span><strong>{report.totalVoucherExpired}</strong></div>
              <div><span><i className="legend-dot" style={{background:'#baa8cf'}}/>Đã hoàn tiền</span><strong>{report.totalVoucherRefunded}</strong></div>
            </div>
          </div><div className="panel-footnote"><Icon name="shield" size={14}/> Tỷ lệ sử dụng được tính trên voucher chưa hoàn tiền.</div>
        </section>
        <section className="panel"><div className="panel-heading"><div><h3>Bức tranh doanh thu</h3><p>Rõ ràng trong từng giao dịch.</p></div><Icon name="wallet"/></div><div className="revenue-breakdown">
          <div><span>Doanh thu gộp</span><strong>{formatVND(report.grossRevenue)}</strong></div>
          <div><span>Đã hoàn cho khách hàng</span><strong>− {formatVND(report.refundedAmount)}</strong></div>
          <div className="breakdown-total"><span>Doanh thu sau hoàn tiền</span><strong>{formatVND(report.totalRevenue)}</strong></div>
          <p><Icon name="check" size={15}/> Số liệu được tổng hợp từ các đơn đã thanh toán.</p>
        </div></section>
      </div>
    </>}
  </div>;
}
