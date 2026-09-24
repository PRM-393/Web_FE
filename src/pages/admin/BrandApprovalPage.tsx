import { useEffect, useState } from 'react';
import { apiClient } from '@/lib/api-client';
import { Card } from '@/components/ui/Card';
import { Button } from '@/components/ui/Button';
import type { Brand } from '@/types/domain';

// UC-04 (tuong tu cho ho so thuong hieu), FR-REPORT-04, FR-BRAND-03
export function BrandApprovalPage() {
  const [brands, setBrands] = useState<Brand[]>([]);

  const load = () => {
    apiClient
      .get<Brand[]>('/admin/pending/brands')
      .then((r) => setBrands(r.data))
      .catch(() => setBrands([]));
  };

  useEffect(load, []);

  const approve = async (id: string) => {
    await apiClient.patch(`/brands/${id}/approve`);
    load();
  };

  const reject = async (id: string) => {
    const reason = window.prompt('Ly do tu choi:') || '';
    await apiClient.patch(`/brands/${id}/reject`, { reason });
    load();
  };

  return (
    <div>
      <h2>Ho so thuong hieu cho duyet</h2>
      <div className="grid">
        {brands.map((b) => (
          <Card key={b.id} title={b.name}>
            <p>{b.description}</p>
            <div className="actions">
              <Button onClick={() => approve(b.id)}>Duyet</Button>
              <Button variant="danger" onClick={() => reject(b.id)}>
                Tu choi
              </Button>
            </div>
          </Card>
        ))}
        {brands.length === 0 && <p>Khong co ho so nao dang cho duyet.</p>}
      </div>
    </div>
  );
}
