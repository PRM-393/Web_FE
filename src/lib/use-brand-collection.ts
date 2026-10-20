import { useEffect, useState } from 'react';
import { apiClient } from './api-client';
import { errorMessage } from './error';

// Resolve actual owned brands before requesting a collection.
export function useBrandCollection<T>(endpoint: (brandId: string) => string) {
  const [items, setItems] = useState<T[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  useEffect(() => {
    const controller = new AbortController();
    (async () => {
      try {
        const { data: brands } = await apiClient.get<{ id: string }[]>('/brands/me', { signal: controller.signal });
        const results = await Promise.all(brands.map(b => apiClient.get<T[]>(endpoint(b.id), { signal: controller.signal })));
        setItems(results.flatMap(r => r.data));
      } catch (e) { if (!controller.signal.aborted) setError(errorMessage(e)); }
      finally { if (!controller.signal.aborted) setLoading(false); }
    })();
    return () => controller.abort();
  }, [endpoint]);
  return { items, loading, error };
}
