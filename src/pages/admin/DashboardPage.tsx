import { useEffect, useState } from 'react';
import { apiClient } from '@/lib/api-client';
import { Card } from '@/components/ui/Card';
import { formatVND } from '@/lib/format';

interface AdminDashboard {
  totalRevenue: number;
  totalCommission: number;
  totalActiveBrands: number;
}

// FR-REPORT-03
export function DashboardPage() {
  const [dashboard, setDashboard] = useState<AdminDashboard | null>(null);

  useEffect(() => {
    apiClient
      .get<AdminDashboard>('/admin/dashboard')
      .then((r) => setDashboard(r.data))
      .catch(() => setDashboard(null));
  }, []);

  return (
    <div>
      <h2>Bang dieu khien</h2>
      {dashboard && (
        <div className="grid">
          <Card title="Tong doanh thu san">{formatVND(dashboard.totalRevenue)}</Card>
          <Card title="Tong hoa hong">{formatVND(dashboard.totalCommission)}</Card>
          <Card title="Thuong hieu dang hoat dong">{dashboard.totalActiveBrands}</Card>
        </div>
      )}
    </div>
  );
}
