import { useEffect, useState } from 'react';
import { apiClient } from '@/lib/api-client';
import { Card } from '@/components/ui/Card';
import { formatVND } from '@/lib/format';

interface BrandReport {
  totalCampaigns: number;
  totalVoucherSold: number;
  totalRevenue: number;
}

// FR-REPORT-01/02
export function ReportPage() {
  const [report, setReport] = useState<BrandReport | null>(null);

  useEffect(() => {
    apiClient
      .get<BrandReport>('/brands/BRAND_ID/report')
      .then((r) => setReport(r.data))
      .catch(() => setReport(null));
  }, []);

  return (
    <div>
      <h2>Bao cao</h2>
      {report && (
        <div className="grid">
          <Card title="Tong chien dich">{report.totalCampaigns}</Card>
          <Card title="Voucher da ban">{report.totalVoucherSold}</Card>
          <Card title="Doanh thu">{formatVND(report.totalRevenue)}</Card>
        </div>
      )}
    </div>
  );
}
