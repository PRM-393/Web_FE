// Kieu du lieu doi tuong nghiep vu chinh, khop voi entity BE (SRS muc 7)

export type BrandStatus = 'PENDING' | 'APPROVED' | 'REJECTED';
export type CampaignStatus = 'DRAFT' | 'PENDING' | 'APPROVED' | 'PUBLISHED' | 'PAUSED' | 'ENDED';
export type VoucherType = 'DISCOUNT_CODE' | 'PREPAID_VALUE' | 'COMBO';

export interface Brand {
  id: string;
  name: string;
  logo?: string;
  description?: string;
  status: BrandStatus;
  rejectReason?: string;
}

export interface Store {
  id: string;
  brandId: string;
  name: string;
  address: string;
  latitude: number;
  longitude: number;
  status: boolean;
}

export interface VoucherCampaign {
  id: string;
  brandId: string;
  title: string;
  image?: string;
  voucherType: VoucherType;
  salePrice: number;
  faceValue: number;
  totalQuantity: number;
  soldQuantity: number;
  reservedQuantity: number;
  saleStartAt: string;
  saleEndAt: string;
  voucherExpireAt: string;
  status: CampaignStatus;
}

export interface Settlement {
  id: string;
  brandId: string;
  periodStart: string;
  periodEnd: string;
  grossRevenue: number;
  commissionAmount: number;
  payableAmount: number;
  status: 'PENDING' | 'PAID';
}
