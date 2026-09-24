import { useEffect, useState } from 'react';
import { apiClient } from '@/lib/api-client';
import { Card } from '@/components/ui/Card';
import { StatusBadge } from '@/components/ui/StatusBadge';
import { formatVND, formatDateTime } from '@/lib/format';
import type { Settlement } from '@/types/domain';

// FR-SETTLE-08: thuong hieu xem phieu doi soat cua minh
export function SettlementListPage() {
  const [settlements, setSettlements] = useState<Settlement[]>([]);

  useEffect(() => {
    apiClient
      .get<Settlement[]>('/brands/BRAND_ID/settlements')
      .then((r) => setSettlements(r.data))
      .catch(() => setSettlements([]));
  }, []);

  return (
    <div>
      <h2>Phieu doi soat</h2>
      <div className="grid">
        {settlements.map((s) => (
          <Card key={s.id} title={`${formatDateTime(s.periodStart)} - ${formatDateTime(s.periodEnd)}`}>
            <p>Doanh thu gop: {formatVND(s.grossRevenue)}</p>
            <p>Hoa hong: {formatVND(s.commissionAmount)}</p>
            <p>Con lai: {formatVND(s.payableAmount)}</p>
            <StatusBadge status={s.status} />
          </Card>
        ))}
        {settlements.length === 0 && <p>Chua co phieu doi soat nao.</p>}
      </div>
    </div>
  );
}
