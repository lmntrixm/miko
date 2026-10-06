import { faDigits } from './format';
import type { Lang, Title, User, UserStatus, TaskColumn } from './types';

/** Unknown amounts stay as the placeholder instead of an invented number. */
export const amountPlaceholder = '[مبلغ]';
export const pricePlaceholder = '[قیمت]';

export const STATUS_LABEL: Record<Title['status'], string> = { ongoing: 'در حال انتشار', finished: 'تمام‌شده', draft: 'پیش‌نویس' };
export const STATUS_KIND: Record<Title['status'], 'success' | 'info' | 'neutral'> = { ongoing: 'success', finished: 'info', draft: 'neutral' };
export const USER_STATUS: Record<UserStatus, { label: string; kind: 'success' | 'warning' | 'neutral' | 'danger' }> = {
  active: { label: 'فعال', kind: 'success' },
  expired: { label: 'منقضی', kind: 'warning' },
  free: { label: 'رایگان', kind: 'neutral' },
  blocked: { label: 'مسدود', kind: 'danger' },
};
export const LANG_LABEL: Record<Lang, string> = { fa: 'FA', en: 'EN' };
export const langsText = (l: Lang[]) => (l.length ? l.map((x) => LANG_LABEL[x]).join(' · ') : '—');
export const COLUMN_LABEL: Record<TaskColumn, string> = { waiting: 'در انتظار ترجمه', translating: 'در حال ترجمه', review: 'بازبینی ویراستار', ready: 'آماده انتشار' };
export const COLUMN_DOT: Record<TaskColumn, string> = { waiting: 'var(--text-hint)', translating: 'var(--info)', review: 'var(--warning)', ready: 'var(--success)' };

export function endsText(u: User): string {
  if (u.endsIn === null) return '—';
  return u.endsIn < 0 ? `${faDigits(-u.endsIn)} روز پیش` : `${faDigits(u.endsIn)} روز دیگر`;
}
