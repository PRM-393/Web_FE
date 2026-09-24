import type { ButtonHTMLAttributes } from 'react';

type Variant = 'primary' | 'secondary' | 'danger';

export function Button({
  variant = 'primary',
  className = '',
  ...props
}: ButtonHTMLAttributes<HTMLButtonElement> & { variant?: Variant }) {
  const base = 'btn';
  const variantClass = `btn-${variant}`;
  return <button className={`${base} ${variantClass} ${className}`} {...props} />;
}
