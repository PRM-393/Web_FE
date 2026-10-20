const LABELS_VI: Record<string, string> = {
  DRAFT: 'Bản nháp', PENDING: 'Chờ duyệt', APPROVED: 'Đã duyệt', PUBLISHED: 'Đang bán',
  PAUSED: 'Tạm dừng', ENDED: 'Kết thúc', REJECTED: 'Từ chối', ACTIVE: 'Đang hoạt động',
  INACTIVE: 'Ngừng hoạt động', USED: 'Đã sử dụng', EXPIRED: 'Hết hạn', REFUNDED: 'Đã hoàn tiền',
  REFUND_PENDING: 'Đang chờ hoàn', PAID: 'Đã chi trả', SOLD_OUT: 'Hết hàng', SUSPENDED: 'Đình chỉ',
};
export function StatusBadge({ status }: { status: string }) {
  return <span className={'badge badge-' + status.toLowerCase()}>{LABELS_VI[status] ?? status}</span>;
}
