import type { ReactNode } from 'react';
import { Icon } from './Icon';
export function StatCard({ label, value, note, icon, accent = false }: { label: string; value: ReactNode; note: string; icon: string; accent?: boolean }) {
  return <div className={`stat-card ${accent ? 'stat-accent' : ''}`}><div className="stat-top"><span>{label}</span><span className="stat-icon"><Icon name={icon}/></span></div><div className="stat-value">{value}</div><div className="stat-note"><span className="tiny-dot"/>{note}</div></div>;
}
