import { Icon } from './Icon';
export function BrandMark({ light = false }: { light?: boolean }) {
  return <div className={`brand-mark ${light ? 'light' : ''}`}><span className="brand-symbol"><Icon name="ticket" size={24}/></span><span>vouch<span className="brand-dot">.</span></span></div>;
}
