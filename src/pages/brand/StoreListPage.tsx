import { useBrandCollection } from '@/lib/use-brand-collection';
import { Icon } from '@/components/ui/Icon';
import { StatusBadge } from '@/components/ui/StatusBadge';
import type { Store } from '@/types/domain';
const endpoint = (id: string) => '/brands/' + id + '/stores';
export function StoreListPage() {
  const { items: stores, loading, error } = useBrandCollection<Store>(endpoint);
  return <div><div className="page-heading"><div><span className="eyebrow">ĐIỂM CHẠM THƯƠNG HIỆU</span><h1>Mạng lưới chi nhánh<span className="heading-dot">.</span></h1><p>Những nơi khách hàng bắt đầu trải nghiệm ưu đãi của bạn.</p></div><span className="neutral-pill">{stores.length} chi nhánh</span></div>
    {loading && <div role="status" className="loading-state"><span className="spinner"/>Đang tải chi nhánh...</div>}
    {error && <p role="alert" className="form-error">{error}</p>}
    <div className="grid">{stores.map((s,i) => <article className="card" key={s.id}><div className={'campaign-visual '+(i%2?'purple':'mint')}><span>YOUR BRAND.<br/>CLOSER TO EVERYONE.</span><Icon name="store" size={60}/></div><h3 style={{fontSize:17,marginBottom:14}}>{s.name}</h3><p style={{fontSize:11,color:'#8b9d89',minHeight:40}}><Icon name="pin" size={15}/> {s.address}</p><StatusBadge status={s.status ? 'ACTIVE' : 'INACTIVE'}/></article>)}</div>
    {!loading && !error && !stores.length && <div className="empty-state"><Icon name="store" size={32}/><h3>Chưa có chi nhánh</h3><p>Các chi nhánh của thương hiệu sẽ xuất hiện tại đây.</p></div>}
  </div>;
}
