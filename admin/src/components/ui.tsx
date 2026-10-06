'use client';

import { useEffect, useId, useRef, type ButtonHTMLAttributes, type ReactNode } from 'react';
import { Icon, type IconName } from './Icon';
import { faDigits } from '@/lib/format';

export function Button({ variant = 'secondary', size, block, icon, children, className = '', ...rest }: { variant?: 'primary' | 'secondary' | 'danger' | 'ok' | 'warn'; size?: 'sm'; block?: boolean; icon?: IconName } & ButtonHTMLAttributes<HTMLButtonElement>) {
  return (
    <button type="button" className={`btn ${variant} ${size ?? ''} ${block ? 'block' : ''} ${className}`} {...rest}>
      {icon && <Icon name={icon} size={size === 'sm' ? 16 : 18} />}
      {children}
    </button>
  );
}

export function IconButton({ icon, label, danger, ...rest }: { icon: IconName; label: string; danger?: boolean } & ButtonHTMLAttributes<HTMLButtonElement>) {
  return (
    <button type="button" className={`iconbtn ${danger ? 'danger' : ''}`} aria-label={label} title={label} {...rest}>
      <Icon name={icon} size={16} />
    </button>
  );
}

export type BadgeKind = 'success' | 'warning' | 'info' | 'danger' | 'neutral' | 'tag';
/** Status is always text on a matching background, never colour alone. */
export function Badge({ kind = 'neutral', children }: { kind?: BadgeKind; children: ReactNode }) {
  return <span className={`badge ${kind}`}>{children}</span>;
}

export function PageHead({ title, sub, crumbs, children }: { title: string; sub?: string; crumbs?: ReactNode; children?: ReactNode }) {
  return (
    <header className="page-head">
      <div>
        {crumbs && <div className="crumbs">{crumbs}</div>}
        <h1>{title}</h1>
        {sub && <p className="sub">{sub}</p>}
      </div>
      {children && <div className="actions">{children}</div>}
    </header>
  );
}

export function StatTile({ label, value, delta, up, foot }: { label: string; value: ReactNode; delta?: string; up?: boolean; foot?: string }) {
  return (
    <div className="tile">
      <div className="label">{label}</div>
      <div className="value">{value}</div>
      {delta && (
        <div className={`delta ${up ? 'up' : 'down'}`}>
          <span aria-hidden="true">{up ? '▲' : '▼'}</span> {delta}
        </div>
      )}
      {foot && <div className="sub">{foot}</div>}
    </div>
  );
}

export function Tabs<T extends string>({ items, value, onChange, label }: { items: { id: T; label: string }[]; value: T; onChange: (v: T) => void; label: string }) {
  return (
    <div className="tabs" role="tablist" aria-label={label}>
      {items.map((i) => (
        <button key={i.id} role="tab" aria-selected={i.id === value} onClick={() => onChange(i.id)}>
          {i.label}
        </button>
      ))}
    </div>
  );
}

export function Segmented<T extends string>({ items, value, onChange, label }: { items: { id: T; label: string }[]; value: T; onChange: (v: T) => void; label: string }) {
  return (
    <div className="seg" role="group" aria-label={label}>
      {items.map((i) => (
        <button key={i.id} aria-pressed={i.id === value} onClick={() => onChange(i.id)}>
          {i.label}
        </button>
      ))}
    </div>
  );
}

export function Toggle({ checked, onChange, label }: { checked: boolean; onChange: (v: boolean) => void; label: string }) {
  return <button type="button" role="switch" className="toggle" aria-checked={checked} aria-label={label} onClick={() => onChange(!checked)} />;
}

export function Check({ checked, onChange, label, disabled }: { checked: boolean; onChange?: (v: boolean) => void; label: string; disabled?: boolean }) {
  return (
    <button type="button" role="checkbox" className="check" aria-checked={checked} aria-label={label} disabled={disabled} onClick={() => onChange?.(!checked)}>
      {checked && <Icon name="check" size={14} strokeWidth={2.4} />}
    </button>
  );
}

export function Field({ label, children, error }: { label: string; children: (id: string) => ReactNode; error?: string }) {
  const id = useId();
  return (
    <div className="field">
      <label htmlFor={id}>{label}</label>
      {children(id)}
      {error && <span className="err" role="alert">{error}</span>}
    </div>
  );
}

export function Avatar({ name, color, size }: { name: string; color?: string; size?: 'sm' | 'lg' }) {
  const bg = color ?? `var(--av-${([...name].reduce((a, c) => a + c.charCodeAt(0), 0) % 6) + 1})`;
  return (
    <span className={`avatar ${size ?? ''}`} style={{ background: bg }} aria-hidden="true">
      {[...name.replace(/[\[\]()]/g, '').trim()][0]}
    </span>
  );
}

export function Modal({ open, onClose, title, children, footer }: { open: boolean; onClose: () => void; title: string; children: ReactNode; footer?: ReactNode }) {
  const ref = useRef<HTMLDialogElement>(null);
  useEffect(() => {
    const d = ref.current;
    if (!d) return;
    if (open && !d.open) d.showModal();
    if (!open && d.open) d.close();
  }, [open]);
  return (
    <dialog ref={ref} className="modal" onClose={onClose} onCancel={onClose} aria-label={title}>
      {open && (
        <>
          <h2>{title}</h2>
          {children}
          {footer && <div className="foot">{footer}</div>}
        </>
      )}
    </dialog>
  );
}

export function Confirm({ open, title, body, confirm, danger, onConfirm, onClose }: { open: boolean; title: string; body: ReactNode; confirm: string; danger?: boolean; onConfirm: () => void; onClose: () => void }) {
  return (
    <Modal
      open={open}
      onClose={onClose}
      title={title}
      footer={
        <>
          <Button variant={danger ? 'danger' : 'primary'} onClick={() => { onConfirm(); onClose(); }}>{confirm}</Button>
          <Button onClick={onClose}>انصراف</Button>
        </>
      }
    >
      <p className="muted">{body}</p>
    </Modal>
  );
}

export function Pagination({ page, pages, onChange }: { page: number; pages: number; onChange: (p: number) => void }) {
  if (pages <= 1) return null;
  return (
    <nav className="pager" aria-label="صفحه‌بندی">
      {Array.from({ length: pages }, (_, i) => i + 1).map((p) => (
        <button key={p} aria-current={p === page ? 'page' : undefined} aria-label={`صفحه ${faDigits(p)}`} onClick={() => onChange(p)}>
          {faDigits(p)}
        </button>
      ))}
    </nav>
  );
}

export function SearchBox({ value, onChange, placeholder }: { value: string; onChange: (v: string) => void; placeholder: string }) {
  return (
    <div className="searchbox">
      <Icon name="search" size={18} />
      <input className="input" type="search" aria-label={placeholder} placeholder={placeholder} value={value} onChange={(e) => onChange(e.target.value)} />
    </div>
  );
}

export function Empty({ children }: { children: ReactNode }) {
  return <p className="muted" style={{ padding: 'var(--space-6)', textAlign: 'center' }}>{children}</p>;
}
