import { useState } from 'react';
import { apiClient } from '@/lib/api-client';
import { Button } from '@/components/ui/Button';

// FR-SETTLE-01/03/07: cau hinh hoa hong va chay chot doi soat thang (UC-05)
export function SettlementAdminPage() {
  const [rate, setRate] = useState(0.1);
  const [message, setMessage] = useState<string | null>(null);

  const saveRate = async () => {
    await apiClient.post('/admin/commission-rate', { rate });
    setMessage('Da cap nhat ty le hoa hong.');
  };

  const runSettlement = async () => {
    const now = new Date();
    const periodStart = new Date(now.getFullYear(), now.getMonth() - 1, 1).toISOString();
    const periodEnd = new Date(now.getFullYear(), now.getMonth(), 0).toISOString();
    await apiClient.post('/admin/settlements/run', { periodStart, periodEnd });
    setMessage('Da chay chot doi soat cho ky truoc.');
  };

  return (
    <div>
      <h2>Doi soat va hoa hong</h2>
      <div className="form">
        <label>
          Ty le hoa hong (0 - 1)
          <input
            type="number"
            step="0.01"
            min={0}
            max={1}
            value={rate}
            onChange={(e) => setRate(Number(e.target.value))}
          />
        </label>
        <Button onClick={saveRate}>Luu ty le</Button>
        <Button onClick={runSettlement}>Chay chot doi soat thang truoc</Button>
        {message && <p>{message}</p>}
      </div>
    </div>
  );
}
