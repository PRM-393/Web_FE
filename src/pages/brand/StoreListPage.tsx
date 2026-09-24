import { useEffect, useState } from 'react';
import { apiClient } from '@/lib/api-client';
import { Card } from '@/components/ui/Card';
import type { Store } from '@/types/domain';

// FR-BRAND-04: danh sach chi nhanh
export function StoreListPage() {
  const [stores, setStores] = useState<Store[]>([]);

  useEffect(() => {
    apiClient
      .get<Store[]>('/brands/BRAND_ID/stores')
      .then((r) => setStores(r.data))
      .catch(() => setStores([]));
  }, []);

  return (
    <div>
      <h2>Chi nhanh</h2>
      <div className="grid">
        {stores.map((s) => (
          <Card key={s.id} title={s.name}>
            <p>{s.address}</p>
            <p>{s.status ? 'Dang hoat dong' : 'Da vo hieu hoa'}</p>
          </Card>
        ))}
        {stores.length === 0 && <p>Chua co chi nhanh nao.</p>}
      </div>
    </div>
  );
}
