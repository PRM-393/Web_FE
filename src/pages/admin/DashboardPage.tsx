import { useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import { apiClient } from '@/lib/api-client';
import { errorMessage } from '@/lib/error';
import { StatCard } from '@/components/ui/StatCard';
import { Icon } from '@/components/ui/Icon';
import { RevenueChart } from '@/components/ui/RevenueChart';
import { formatVND } from '@/lib/format';

interface AdminDashboard {
  totalRevenue: number; grossRevenue: number; refundedAmount: number; totalCommission: number;
  totalActiveBrands: number; totalTransactions: number;
  transactionsByDay: { date: string; count: number; revenue: number }[];
}
export function DashboardPage() {
  const [dashboard, setDashboard] = useState<AdminDashboard | null>(null);
  const [pending, setPending] = useState({ brands: 0, campaigns: 0, refunds: 0, mismatches: 0 });
  const [from, setFrom] = useState(''), [to, setTo] = useState('');
  const [loading, setLoading] = useState(true), [error, setError] = useState('');
  const [reload, setReload] = useState(0);
  useEffect(() => {
    setError(''); setDashboard(null);
    if (from && to && from > to) { setError('Khoảng thời gian không hợp lệ.'); setLoading(false); return; }
    const controller = new AbortController();
    setLoading(true);
    const config = { signal: controller.signal };
    Promise.all([
      apiClient.get<AdminDashboard>('/admin/dashboard', { ...config, params: { from: from || undefined, to: to || undefined } }),
      apiClient.get<unknown[]>('/admin/pending/brands', config),
      apiClient.get<unknown[]>('/admin/pending/campaigns', config),
      apiClient.get<unknown[]>('/refunds/manual-pending', config),
      apiClient.get<unknown[]>('/admin/payment-mismatches', config),
    ]).then(([d,b,c,r,m]) => {
      setDashboard(d.data);
      setPending({ brands: b.data.length, campaigns: c.data.length, refunds: r.data.length, mismatches: m.data.length });
    }).catch(e => { if (!controller.signal.aborted) setError(errorMessage(e)); })
      .finally(() => { if (!controller.signal.aborted) setLoading(false); });
    return () => controller.abort();
  }, [from, to, reload]);
  return <div className="dashboard-page">
    <div className="page-heading"><div><span className="eyebrow">KHÔNG GIAN QUẢN TRỊ</span><h1>Tổng quan nền tảng<span className="heading-dot">.</span></h1><p>Mọi chuyển động của nền tảng, trong một góc nhìn.</p></div><button className="btn btn-secondary" onClick={() => setReload(n => n + 1)} disabled={loading}><Icon name="refresh" size={16}/>Làm mới dữ liệu</button></div>
    <div className="overview-banner"><div><span className="banner-label"><span className="tiny-dot"/> VOUCH. BUSINESS OVERVIEW</span><h2>Nhìn rõ hôm nay.<br/>Sẵn sàng cho bước tiếp theo.</h2><p>Theo dõi hiệu quả kinh doanh và các công việc cần bạn xử lý.</p></div><div className="banner-ticket" aria-hidden="true"><Icon name="ticket" size={72}/><span>GOOD THINGS<br/>ARE CONNECTED.</span></div><span className="banner-ring"/></div>
    <div className="section-toolbar"><div className="section-title"><span className="section-marker"/>Hiệu quả kinh doanh</div><div className="report-filters compact">
      <label><span className="sr-only">Từ ngày</span><input aria-label="Từ ngày" type="date" value={from} onChange={e => setFrom(e.target.value)}/></label><span className="date-separator">—</span>
      <label><span className="sr-only">Đến ngày</span><input aria-label="Đến ngày" type="date" min={from || undefined} value={to} onChange={e => setTo(e.target.value)}/></label>
    </div></div>
    {loading && <div className="loading-state" role="status"><span className="spinner"/> Đang cập nhật số liệu của bạn...</div>}
    {error && <p role="alert" className="form-error">{error}</p>}
    {!loading && !error && dashboard && <>
      <div className="stats-grid">
        <StatCard label="Doanh thu sau hoàn tiền" value={formatVND(dashboard.totalRevenue)} note="Theo các đơn đã thanh toán" icon="wallet" accent/>
        <StatCard label="Hoa hồng nền tảng" value={formatVND(dashboard.totalCommission)} note="Theo tỷ lệ chốt trên đơn" icon="chart"/>
        <StatCard label="Thương hiệu hoạt động" value={dashboard.totalActiveBrands.toString().padStart(2,'0')} note="Đã được phê duyệt" icon="store"/>
        <StatCard label="Đơn thanh toán thành công" value={dashboard.totalTransactions.toString().padStart(2,'0')} note="Trong thời gian đã chọn" icon="ticket"/>
      </div>
      <div className="dashboard-columns">
        <section className="panel chart-panel"><div className="panel-heading"><div><h3>Doanh thu theo thời gian</h3><p>Dòng tiền từ những kết nối có giá trị.</p></div><span className="chart-legend"><span className="tiny-dot"/>Doanh thu</span></div><div className="chart-total">{formatVND(dashboard.totalRevenue)}<span>VND · sau hoàn tiền</span></div><RevenueChart rows={dashboard.transactionsByDay}/><div className="panel-footnote"><Icon name="clock" size={14}/> Ngày thanh toán theo múi giờ Việt Nam</div></section>
        <section className="panel tasks-panel"><div className="panel-heading"><div><h3>Cần bạn xử lý</h3><p>Giữ mọi hoạt động luôn thông suốt.</p></div><span className="count-bubble">{pending.brands+pending.campaigns+pending.refunds+pending.mismatches}</span></div>
          {[
            {url:'/admin/approvals/brands',icon:'store',label:'Hồ sơ thương hiệu',note:'Đang chờ phê duyệt',value:pending.brands,color:'mint'},
            {url:'/admin/approvals/campaigns',icon:'ticket',label:'Chiến dịch voucher',note:'Ưu đãi chờ lên sóng',value:pending.campaigns,color:'purple'},
            {url:'/admin/refunds',icon:'wallet',label:'Yêu cầu hoàn tiền',note:'Cần xác nhận thủ công',value:pending.refunds,color:'amber'},
            {url:'/admin/refunds',icon:'shield',label:'Giao dịch cần đối chiếu',note:'Số tiền thanh toán chưa khớp',value:pending.mismatches,color:'blue'},
          ].map(t => <Link to={t.url} className="task-row" key={t.label}><span className={'task-icon '+t.color}><Icon name={t.icon}/></span><div><strong>{t.label}</strong><small>{t.note}</small></div><b>{t.value.toString().padStart(2,'0')}</b><Icon name="chevron" size={14}/></Link>)}
          <div className="tasks-note"><Icon name="check" size={15}/>Mỗi việc hoàn tất, thêm một trải nghiệm tốt.</div>
        </section>
      </div>
      <section className="panel transactions-panel"><div className="panel-heading"><div><h3>Chi tiết giao dịch theo ngày</h3><p>Tổng hợp doanh thu thực tế của nền tảng.</p></div><span className="neutral-pill">{dashboard.transactionsByDay.length} ngày có giao dịch</span></div>
        {dashboard.transactionsByDay.length === 0 ? <div className="empty-state"><Icon name="chart" size={32}/><h3>Chưa có giao dịch</h3><p>Thử chọn một khoảng thời gian khác để xem số liệu.</p></div> :
          <div className="table-scroll"><table className="table"><thead><tr><th>Ngày thanh toán</th><th>Số đơn thành công</th><th>Doanh thu sau hoàn tiền</th><th>Trạng thái</th></tr></thead><tbody>{dashboard.transactionsByDay.map(row => <tr key={row.date}><td><span className="table-date"><Icon name="calendar" size={16}/>{row.date.split('-').reverse().join('/')}</span></td><td>{row.count} đơn hàng</td><td className="money-cell">{formatVND(row.revenue)}</td><td><span className="badge badge-active">Đã ghi nhận</span></td></tr>)}</tbody></table></div>}
        <div className="table-summary"><span>Đã hoàn tiền trong các đơn đã chọn</span><strong>{formatVND(dashboard.refundedAmount)}</strong></div>
      </section>
    </>}
  </div>;
}
