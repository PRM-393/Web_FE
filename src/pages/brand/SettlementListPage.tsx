import { useBrandCollection } from '@/lib/use-brand-collection';
import { StatusBadge } from '@/components/ui/StatusBadge';
import { Icon } from '@/components/ui/Icon';
import { formatVND, formatDateTime } from '@/lib/format';
import type { Settlement } from '@/types/domain';
const endpoint = (id: string) => '/brands/' + id + '/settlements';
export function SettlementListPage() {
  const { items, loading, error } = useBrandCollection<Settlement>(endpoint);
  return <div><div className="page-heading"><div><span className="eyebrow">DÒNG TIỀN THƯƠNG HIỆU</span><h1>Đối soát & chi trả<span className="heading-dot">.</span></h1><p>Minh bạch doanh thu. Rõ ràng từng kỳ thanh toán.</p></div><span className="neutral-pill">{items.length} phiếu đối soát</span></div>
    {loading && <div className="loading-state" role="status"><span className="spinner"/>Đang tải phiếu đối soát...</div>}
    {error && <p className="form-error" role="alert">{error}</p>}
    {!loading && !error && <section className="panel"><div className="panel-heading" style={{paddingBottom:22}}><h3>Lịch sử đối soát</h3><Icon name="wallet"/></div>
      {items.length ? <div className="table-scroll"><table className="table"><thead><tr><th>Kỳ đối soát</th><th>Doanh thu gộp</th><th>Hoa hồng</th><th>Thực nhận</th><th>Trạng thái</th></tr></thead><tbody>{items.map(s => <tr key={s.id}><td>{formatDateTime(s.periodStart)} – {formatDateTime(s.periodEnd)}</td><td>{formatVND(s.grossRevenue)}</td><td>{formatVND(s.commissionAmount)}</td><td className="money-cell">{formatVND(s.payableAmount)}</td><td><StatusBadge status={s.status}/></td></tr>)}</tbody></table></div> : <div className="empty-state"><Icon name="wallet" size={35}/><h3>Chưa có phiếu đối soát</h3><p>Phiếu sẽ xuất hiện khi có doanh thu đủ điều kiện đối soát.</p></div>}
    </section>}
  </div>;
}
