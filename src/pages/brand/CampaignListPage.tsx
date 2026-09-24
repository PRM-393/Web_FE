import { useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import { apiClient } from '@/lib/api-client';
import { Card } from '@/components/ui/Card';
import { Button } from '@/components/ui/Button';
import { StatusBadge } from '@/components/ui/StatusBadge';
import { formatVND } from '@/lib/format';
import type { VoucherCampaign } from '@/types/domain';

// FR-CAMP-*: danh sach chien dich cua thuong hieu kem trang thai duyet
export function CampaignListPage() {
  const [campaigns, setCampaigns] = useState<VoucherCampaign[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    // TODO: thay BRAND_ID bang brandId that cua thuong hieu dang dang nhap (goi GET /brands/me truoc)
    apiClient
      .get<VoucherCampaign[]>('/campaigns/brand/BRAND_ID')
      .then((r) => setCampaigns(r.data))
      .catch(() => setCampaigns([]))
      .finally(() => setLoading(false));
  }, []);

  return (
    <div>
      <div className="page-header">
        <h2>Chien dich voucher</h2>
        <Link to="/brand/campaigns/new">
          <Button>+ Tao chien dich</Button>
        </Link>
      </div>

      {loading && <p>Dang tai...</p>}

      <div className="grid">
        {campaigns.map((c) => (
          <Card key={c.id} title={c.title}>
            <p>Gia ban: {formatVND(c.salePrice)}</p>
            <p>
              Da ban: {c.soldQuantity}/{c.totalQuantity}
            </p>
            <StatusBadge status={c.status} />
          </Card>
        ))}
        {!loading && campaigns.length === 0 && <p>Chua co chien dich nao.</p>}
      </div>
    </div>
  );
}
