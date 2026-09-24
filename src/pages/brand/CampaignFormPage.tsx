import { useState, type FormEvent } from 'react';
import { useNavigate } from 'react-router-dom';
import { apiClient } from '@/lib/api-client';
import { Button } from '@/components/ui/Button';

// FR-CAMP-01..05: form tao chien dich (stub - can bo sung chon chi nhanh ap dung, upload anh...)
export function CampaignFormPage() {
  const [title, setTitle] = useState('');
  const [salePrice, setSalePrice] = useState(0);
  const [faceValue, setFaceValue] = useState(0);
  const [totalQuantity, setTotalQuantity] = useState(100);
  const [submitting, setSubmitting] = useState(false);
  const navigate = useNavigate();

  const handleSubmit = async (e: FormEvent) => {
    e.preventDefault();
    setSubmitting(true);
    try {
      // TODO: bo sung day du cac truong theo CreateCampaignDto (voucherType, saleStartAt/EndAt, storeIds...)
      await apiClient.post('/campaigns/brand/BRAND_ID', {
        title,
        salePrice,
        faceValue,
        totalQuantity,
        voucherType: 'DISCOUNT_CODE',
        saleStartAt: new Date().toISOString(),
        saleEndAt: new Date(Date.now() + 30 * 86400000).toISOString(),
        voucherExpireAt: new Date(Date.now() + 60 * 86400000).toISOString(),
        storeIds: [],
      });
      navigate('/brand/campaigns');
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <form className="form" onSubmit={handleSubmit}>
      <h2>Tao chien dich moi</h2>
      <label>
        Tieu de
        <input value={title} onChange={(e) => setTitle(e.target.value)} required />
      </label>
      <label>
        Gia ban (VND)
        <input type="number" value={salePrice} onChange={(e) => setSalePrice(Number(e.target.value))} min={0} />
      </label>
      <label>
        Gia tri voucher (VND)
        <input type="number" value={faceValue} onChange={(e) => setFaceValue(Number(e.target.value))} min={0} />
      </label>
      <label>
        So luong phat hanh
        <input
          type="number"
          value={totalQuantity}
          onChange={(e) => setTotalQuantity(Number(e.target.value))}
          min={1}
        />
      </label>
      <Button type="submit" disabled={submitting}>
        Luu nhap
      </Button>
    </form>
  );
}
