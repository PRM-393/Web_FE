import { useEffect, useState } from 'react';
import { apiClient } from '@/lib/api-client';
import { Card } from '@/components/ui/Card';
import { Button } from '@/components/ui/Button';
import { formatVND } from '@/lib/format';
import type { VoucherCampaign } from '@/types/domain';

// UC-04: quan tri vien duyet chien dich
export function CampaignApprovalPage() {
  const [campaigns, setCampaigns] = useState<VoucherCampaign[]>([]);

  const load = () => {
    apiClient
      .get<VoucherCampaign[]>('/campaigns/pending')
      .then((r) => setCampaigns(r.data))
      .catch(() => setCampaigns([]));
  };

  useEffect(load, []);

  const approve = async (id: string) => {
    await apiClient.patch(`/campaigns/${id}/approve`);
    load();
  };

  const reject = async (id: string) => {
    const reason = window.prompt('Ly do tu choi:') || '';
    await apiClient.patch(`/campaigns/${id}/reject`, { reason });
    load();
  };

  return (
    <div>
      <h2>Chien dich cho duyet</h2>
      <div className="grid">
        {campaigns.map((c) => (
          <Card key={c.id} title={c.title}>
            <p>Gia ban: {formatVND(c.salePrice)}</p>
            <p>So luong: {c.totalQuantity}</p>
            <div className="actions">
              <Button onClick={() => approve(c.id)}>Duyet</Button>
              <Button variant="danger" onClick={() => reject(c.id)}>
                Tu choi
              </Button>
            </div>
          </Card>
        ))}
        {campaigns.length === 0 && <p>Khong co chien dich nao dang cho duyet.</p>}
      </div>
    </div>
  );
}
