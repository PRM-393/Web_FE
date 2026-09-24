import type { PropsWithChildren } from 'react';

export function Card({ children, title }: PropsWithChildren<{ title?: string }>) {
  return (
    <div className="card">
      {title && <h3 className="card-title">{title}</h3>}
      <div className="card-body">{children}</div>
    </div>
  );
}
