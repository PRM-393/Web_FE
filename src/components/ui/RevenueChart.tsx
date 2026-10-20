import { useId } from 'react';
import { formatVND } from '@/lib/format';

export function RevenueChart({ rows }: { rows: { date: string; revenue: number; count: number }[] }) {
  const gradient = useId().replace(/:/g, '');
  if (!rows.length) return <div className="chart-empty">Chưa có giao dịch trong khoảng thời gian này.</div>;
  const max = Math.max(...rows.map(r => r.revenue), 1);
  const minTime = new Date(rows[0].date).getTime(), maxTime = new Date(rows[rows.length - 1].date).getTime();
  const points = rows.map(r => ({ ...r, x: rows.length === 1 ? 390 : 70 + (new Date(r.date).getTime() - minTime) / (maxTime - minTime || 1) * 640, y: 190 - r.revenue / max * 140 }));
  const line = points.map((p,i) => `${i ? 'L' : 'M'} ${p.x} ${p.y}`).join(' ');
  return <div className="revenue-chart"><svg viewBox="0 0 750 245" role="img" aria-label="Biểu đồ doanh thu theo ngày thanh toán">
    <defs><linearGradient id={gradient} x1="0" y1="0" x2="0" y2="1"><stop offset="0%" stopColor="#119c88" stopOpacity=".18"/><stop offset="100%" stopColor="#119c88" stopOpacity="0"/></linearGradient></defs>
    {[0,1,2,3].map(n => <g key={n}><line x1="70" y1={50+n*47} x2="725" y2={50+n*47} stroke="#e9eeed" strokeDasharray="4 5"/><text x="0" y={55+n*47} fill="#8a9995" fontSize="11">{new Intl.NumberFormat('vi-VN', { notation: 'compact' }).format(max*(3-n)/3)}</text></g>)}
    {points.length > 1 && <><path d={`${line} L ${points[points.length-1].x} 200 L ${points[0].x} 200 Z`} fill={`url(#${gradient})`}/><path d={line} fill="none" stroke="#0f9a83" strokeWidth="3" strokeLinejoin="round"/></>}
    {points.map((p,i) => <g key={p.date}><circle cx={p.x} cy={p.y} r="6" fill="#fff" stroke="#0f9a83" strokeWidth="3"><title>{p.date}: {formatVND(p.revenue)}, {p.count} đơn</title></circle>{(rows.length <= 7 || i === 0 || i === rows.length-1) && <text x={p.x} y="230" textAnchor="middle" fill="#8a9995" fontSize="11">{p.date.slice(5).split('-').reverse().join('/')}</text>}</g>)}
  </svg></div>;
}
