import { useMemo, useState } from 'react';
import { Link } from 'react-router-dom';
import { useBrandCollection } from '@/lib/use-brand-collection';
import { StatusBadge } from '@/components/ui/StatusBadge';
import { Icon } from '@/components/ui/Icon';
import { formatVND } from '@/lib/format';
import type { VoucherCampaign } from '@/types/domain';

const endpoint = (id: string) => '/campaigns/brand/' + id;
export function CampaignListPage() {
  const { items: campaigns, loading, error } = useBrandCollection<VoucherCampaign>(endpoint);
  const [keyword, setKeyword] = useState(''), [status, setStatus] = useState('');
  const filtered = useMemo(() => campaigns.filter(c => c.title.toLocaleLowerCase('vi').includes(keyword.toLocaleLowerCase('vi')) && (!status || c.status === status)), [campaigns, keyword, status]);
  return <div>
    <div className="page-heading"><div><span className="eyebrow">KHÔNG GIAN THƯƠNG HIỆU</span><h1>Những ưu đãi của bạn<span className="heading-dot">.</span></h1><p>Tạo trải nghiệm đáng nhớ, bắt đầu từ một voucher.</p></div><Link to="/brand/campaigns/new" className="btn btn-primary"><Icon name="plus" size={17}/>Tạo chiến dịch</Link></div>
    <div className="report-filters"><label>Tìm kiếm chiến dịch<input placeholder="Nhập tên chiến dịch..." value={keyword} onChange={e => setKeyword(e.target.value)}/></label><label>Trạng thái<select value={status} onChange={e => setStatus(e.target.value)}><option value="">Tất cả trạng thái</option><option value="PUBLISHED">Đang bán</option><option value="DRAFT">Bản nháp</option><option value="PENDING">Chờ duyệt</option><option value="APPROVED">Đã duyệt</option><option value="SOLD_OUT">Hết hàng</option><option value="PAUSED">Tạm dừng</option><option value="ENDED">Kết thúc</option></select></label><span className="neutral-pill">{filtered.length} chiến dịch</span></div>
    {loading && <div className="loading-state" role="status"><span className="spinner"/>Đang tải các chiến dịch...</div>}
    {error && <p className="form-error" role="alert">{error}</p>}
    <div className="grid">{!loading && !error && filtered.map((c,i) => <article className="card campaign-card" key={c.id}>
      <div className={'campaign-visual '+['mint','purple','amber'][i%3]}><span>VOUCH.<br/>GOOD THINGS AHEAD</span><Icon name="ticket" size={65}/></div>
      <StatusBadge status={c.status}/><h3 className="card-title" style={{marginTop:14}}>{c.title}</h3><div className="campaign-price">{formatVND(c.salePrice)}</div>
      <div className="campaign-meta"><span>Voucher đã bán</span><strong>{c.soldQuantity} / {c.totalQuantity}</strong></div><div className="inventory-track"><span style={{width: Math.min(100,c.soldQuantity / Math.max(1,c.totalQuantity)*100)+'%'}}/></div>
    </article>)}</div>
    {!loading && !error && !filtered.length && <div className="empty-state"><Icon name="ticket" size={35}/><h3>Chưa có chiến dịch phù hợp</h3><p>Thử thay đổi bộ lọc hoặc tạo ưu đãi đầu tiên của bạn.</p></div>}
  </div>;
}
