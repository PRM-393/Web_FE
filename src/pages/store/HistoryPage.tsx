import { useEffect, useState } from 'react';
import { apiClient } from '@/lib/api-client';
import { formatDateTime } from '@/lib/format';

interface RedemptionLog {
  id: string;
  voucherItemId: string;
  redeemedAt: string;
  method: string;
}

// FR-REDEEM-10: nhan vien xem lich su redeem do chinh minh thuc hien trong ngay
export function HistoryPage() {
  const [logs, setLogs] = useState<RedemptionLog[]>([]);

  useEffect(() => {
    apiClient
      .get<RedemptionLog[]>('/redeem/history/today')
      .then((r) => setLogs(r.data))
      .catch(() => setLogs([]));
  }, []);

  return (
    <div>
      <h2>Lich su redeem hom nay</h2>
      <table className="table">
        <thead>
          <tr>
            <th>Ma voucher</th>
            <th>Thoi gian</th>
            <th>Phuong thuc</th>
          </tr>
        </thead>
        <tbody>
          {logs.map((log) => (
            <tr key={log.id}>
              <td>{log.voucherItemId}</td>
              <td>{formatDateTime(log.redeemedAt)}</td>
              <td>{log.method}</td>
            </tr>
          ))}
        </tbody>
      </table>
      {logs.length === 0 && <p>Chua co giao dich nao hom nay.</p>}
    </div>
  );
}
