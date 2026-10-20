import { useEffect, useState, type FormEvent } from 'react';
import { apiClient } from '@/lib/api-client';
import { errorMessage } from '@/lib/error';
import { formatVND } from '@/lib/format';

interface Refund { id: string; voucherItemId: string; reason: string; }
interface Mismatch { id: string; totalAmount: number; payments: { id: string; amount: number; gatewayTxnId: string }[]; }
export function RefundQueuePage() {
  const [refunds, setRefunds] = useState<Refund[]>([]), [orders, setOrders] = useState<Mismatch[]>([]);
  const [loading, setLoading] = useState(true), [error, setError] = useState('');
  const [message, setMessage] = useState(''), [reload, setReload] = useState(0);
  const [selected, setSelected] = useState<{type: 'refund' | 'mismatch'; id: string} | null>(null);
  const [reference, setReference] = useState(''), [confirmed, setConfirmed] = useState(false), [saving, setSaving] = useState(false);
  useEffect(() => {
    const controller = new AbortController(); setLoading(true); setError('');
    Promise.all([
      apiClient.get<Refund[]>('/refunds/manual-pending', { signal: controller.signal }),
      apiClient.get<Mismatch[]>('/admin/payment-mismatches', { signal: controller.signal }),
    ]).then(([r,o]) => { setRefunds(r.data); setOrders(o.data); })
      .catch(e => { if (!controller.signal.aborted) setError(errorMessage(e)); })
      .finally(() => { if (!controller.signal.aborted) setLoading(false); });
    return () => controller.abort();
  }, [reload]);
  const choose = (type: 'refund' | 'mismatch', id: string) => { setSelected({type,id}); setReference(''); setConfirmed(false); setMessage(''); };
  const submit = async (event: FormEvent) => {
    event.preventDefault(); if (!selected || !confirmed || !reference.trim()) return;
    setSaving(true); setError('');
    try {
      const url = selected.type === 'refund' ? '/refunds/' + selected.id + '/confirm-manual' : '/admin/payment-mismatches/' + selected.id + '/confirm-refund';
      await apiClient.patch(url, { gatewayRefundId: reference.trim() });
      setMessage('Đã ghi nhận hoàn tiền.'); setSelected(null); setReload(n => n + 1);
    } catch (e) { setError(errorMessage(e, 'Không thể ghi nhận hoàn tiền. Vui lòng kiểm tra và thử lại.')); }
    finally { setSaving(false); }
  };
  return <div>
    <h2>Hàng đợi hoàn tiền</h2>
    <p>Thực hiện hoàn trên cổng thanh toán trước, sau đó nhập mã giao dịch để ghi nhận kết quả.</p>
    <button className="btn btn-secondary" disabled={loading || saving} onClick={() => setReload(n => n + 1)}>Tải lại</button>
    {loading && <p role="status">Đang tải...</p>}
    {error && <p role="alert" className="form-error">{error}</p>}
    {message && <p role="status">{message}</p>}
    {!loading && !error && <>
      <h3>Yêu cầu hoàn thủ công</h3>
      {!refunds.length ? <p>Không có yêu cầu đang chờ.</p> :
        <div className="table-scroll"><table className="table"><thead><tr><th>Mã yêu cầu</th><th>Voucher</th><th>Lý do</th><th>Thao tác</th></tr></thead>
          <tbody>{refunds.map(r => <tr key={r.id}><td>{r.id}</td><td>{r.voucherItemId}</td><td>{r.reason}</td><td><button disabled={saving} className="btn btn-secondary" onClick={() => choose('refund', r.id)}>Ghi nhận đã hoàn</button></td></tr>)}</tbody>
        </table></div>}
      <h3>Đơn lệch số tiền</h3>
      {!orders.length ? <p>Không có đơn cần xử lý.</p> :
        <div className="table-scroll"><table className="table"><thead><tr><th>Mã đơn</th><th>Tổng tiền đơn</th><th>Giao dịch đã nhận</th><th>Thao tác</th></tr></thead>
          <tbody>{orders.map(o => <tr key={o.id}><td>{o.id}</td><td>{formatVND(o.totalAmount)}</td>
            <td>{o.payments.map(p => <div key={p.id}>{p.gatewayTxnId}: {formatVND(p.amount)}</div>)}</td>
            <td><button disabled={saving || o.payments.length !== 1} className="btn btn-secondary" onClick={() => choose('mismatch', o.id)}>Ghi nhận đã hoàn</button></td></tr>)}</tbody>
        </table></div>}
    </>}
    {selected && <form className="form card" onSubmit={submit}>
      <h3>Ghi nhận hoàn tiền cho {selected.id}</h3>
      <label>Mã giao dịch hoàn<input value={reference} maxLength={200} onChange={e => setReference(e.target.value)} required /></label>
      <label><span><input type="checkbox" checked={confirmed} onChange={e => setConfirmed(e.target.checked)} required /> Tôi đã hoàn tiền trên cổng thanh toán và đã kiểm tra kết quả.</span></label>
      <div className="actions"><button className="btn btn-primary" disabled={saving || !confirmed || !reference.trim()}>{saving ? 'Đang lưu...' : 'Lưu kết quả'}</button>
        <button type="button" className="btn btn-secondary" disabled={saving} onClick={() => setSelected(null)}>Hủy</button></div>
    </form>}
  </div>;
}
