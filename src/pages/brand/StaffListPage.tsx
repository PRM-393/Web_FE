import { useBrandCollection } from '@/lib/use-brand-collection';
import { StatusBadge } from '@/components/ui/StatusBadge';
import { Icon } from '@/components/ui/Icon';
interface Staff { id: string; email: string; fullName: string; storeName: string; active: boolean; }
const endpoint = (id: string) => '/brands/' + id + '/staff';
export function StaffListPage() {
  const { items, loading, error } = useBrandCollection<Staff>(endpoint);
  return <div><div className="page-heading"><div><span className="eyebrow">ĐỒNG HÀNH CÙNG THƯƠNG HIỆU</span><h1>Đội ngũ của bạn<span className="heading-dot">.</span></h1><p>Những người tạo nên trải nghiệm tốt tại mỗi chi nhánh.</p></div><span className="neutral-pill">{items.length} phân công</span></div>
    {loading && <div className="loading-state" role="status"><span className="spinner"/>Đang tải đội ngũ...</div>}
    {error && <p className="form-error" role="alert">{error}</p>}
    {!loading && !error && <section className="panel"><div className="panel-heading" style={{paddingBottom:22}}><h3>Danh sách nhân viên</h3><Icon name="users"/></div><div className="table-scroll"><table className="table"><thead><tr><th>Nhân viên</th><th>Email</th><th>Chi nhánh làm việc</th><th>Trạng thái</th></tr></thead><tbody>{items.map(s => <tr key={s.id}><td><span className="staff-avatar">{(s.fullName || s.email).charAt(0).toUpperCase()}</span>{s.fullName || s.email.split('@')[0]}</td><td>{s.email}</td><td>{s.storeName}</td><td><StatusBadge status={s.active ? 'ACTIVE' : 'INACTIVE'}/></td></tr>)}</tbody></table></div>{!items.length && <div className="empty-state">Chưa có nhân viên được phân công.</div>}</section>}
  </div>;
}
