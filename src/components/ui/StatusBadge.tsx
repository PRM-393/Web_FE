const LABELS_VI: Record<string, string> = {
  DRAFT: 'Nhap',
  PENDING: 'Cho duyet',
  APPROVED: 'Da duyet',
  PUBLISHED: 'Dang ban',
  PAUSED: 'Tam dung',
  ENDED: 'Ket thuc',
  REJECTED: 'Tu choi',
  ACTIVE: 'Dang hieu luc',
  USED: 'Da dung',
  EXPIRED: 'Het han',
  REFUNDED: 'Da hoan',
  PAID: 'Da chi tra',
};

export function StatusBadge({ status }: { status: string }) {
  return <span className={`badge badge-${status.toLowerCase()}`}>{LABELS_VI[status] ?? status}</span>;
}
