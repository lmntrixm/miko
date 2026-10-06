'use client';

import Link from 'next/link';
import { useState } from 'react';
import { useToast } from '@/components/Toast';
import { Avatar, Badge, Button, Confirm, Empty, Field, Modal, PageHead, SearchBox, StatTile } from '@/components/ui';
import { faDigits, faNumber, jalaliNumeric } from '@/lib/format';
import { endsText, USER_STATUS } from '@/lib/labels';
import { addSubscriptionDays, setBlocked, useStore } from '@/lib/store';
import type { User } from '@/lib/types';

export default function UsersPage() {
  const users = useStore((s) => s.users);
  const toast = useToast();
  const [q, setQ] = useState('');
  const [filter, setFilter] = useState<'all' | User['status']>('all');
  const [selId, setSelId] = useState<string>(users[0]?.id ?? '');
  const [days, setDays] = useState<User | null>(null);
  const [dayCount, setDayCount] = useState('7');
  const [block, setBlock] = useState<User | null>(null);

  const rows = users.filter((u) => (filter === 'all' || u.status === filter) && (!q.trim() || u.name.includes(q.trim()) || u.email.toLowerCase().includes(q.trim().toLowerCase()) || u.id === q.trim()));
  const sel = users.find((u) => u.id === selId) ?? null;
  const count = (s: User['status']) => users.filter((u) => u.status === s).length;

  return (
    <>
      <PageHead title="کاربران">
        <SearchBox value={q} onChange={setQ} placeholder="نام، ایمیل یا شناسه…" />
        <select className="select" style={{ width: 150 }} aria-label="فیلتر وضعیت" value={filter} onChange={(e) => setFilter(e.target.value as typeof filter)}>
          <option value="all">همه کاربران</option><option value="active">فعال</option><option value="expired">منقضی</option><option value="free">رایگان</option><option value="blocked">مسدود</option>
        </select>
      </PageHead>
      <div className="grid g4" style={{ marginBottom: 'var(--space-4)' }}>
        <StatTile label="کل کاربران" value={faNumber(48120)} />
        <StatTile label="مشترک فعال" value={faNumber(3215)} />
        <StatTile label="عضو جدید این هفته" value={faNumber(864)} />
        <StatTile label="مسدود" value={faNumber(count('blocked') + 20)} />
      </div>

      <div className="grid" style={{ gridTemplateColumns: 'minmax(0,2fr) minmax(0,1fr)', alignItems: 'start' }}>
        <section className="card flush" aria-label="فهرست کاربران">
          <div className="table-wrap">
            <table className="t">
              <thead><tr><th>کاربر</th><th>اشتراک</th><th>انقضا</th><th>عضویت</th><th>چپترها</th><th>وضعیت</th></tr></thead>
              <tbody>
                {rows.map((u) => (
                  <tr key={u.id} className="clickable" aria-selected={u.id === selId} onClick={() => setSelId(u.id)} onKeyDown={(e) => e.key === 'Enter' && setSelId(u.id)} tabIndex={0}>
                    <td><div className="cell-main"><Avatar name={u.name} /><div><b>{u.name}</b><span className="sub ltr">{u.email}</span></div></div></td>
                    <td>{u.plan ?? '—'}</td>
                    <td>{endsText(u)}</td>
                    <td>{jalaliNumeric(u.joined)}</td>
                    <td>{faNumber(u.chaptersRead)}</td>
                    <td><Badge kind={USER_STATUS[u.status].kind}>{USER_STATUS[u.status].label}</Badge></td>
                  </tr>
                ))}
              </tbody>
            </table>
            {rows.length === 0 && <Empty>کاربری پیدا نشد.</Empty>}
          </div>
        </section>

        {sel ? (
          <aside className="card stack" aria-label={`خلاصه ${sel.name}`} style={{ alignItems: 'stretch' }}>
            <div className="stack" style={{ alignItems: 'center', gap: 6 }}>
              <Avatar name={sel.name} size="lg" />
              <h2>{sel.name}</h2>
              <span className="sub ltr">{sel.email}</span>
              <Badge kind={USER_STATUS[sel.status].kind}>{USER_STATUS[sel.status].label}</Badge>
            </div>
            <div className="grid g2" style={{ gap: 10 }}>
              <div className="tile"><div className="label">اشتراک</div><b>{sel.plan ?? '—'}</b></div>
              <div className="tile"><div className="label">انقضا</div><b>{endsText(sel)}</b></div>
              <div className="tile"><div className="label">زبان ترجیحی</div><b>{sel.prefLang}</b></div>
              <div className="tile"><div className="label">چپتر خوانده‌شده</div><b>{faNumber(sel.chaptersRead)}</b></div>
            </div>
            <h3>فعالیت اخیر</h3>
            <ul className="stack" style={{ listStyle: 'none', margin: 0, padding: 0, gap: 6 }}>
              {sel.history.map((h) => <li key={h.title} className="sub">خواندن {h.title}</li>)}
            </ul>
            <Link href={`/users/${sel.id}`} className="btn secondary">مشاهده پروندهٔ کامل ›</Link>
            <Button variant="primary" onClick={() => { setDayCount('7'); setDays(sel); }}>افزودن روز اشتراک</Button>
            <div className="grid g2" style={{ gap: 10 }}>
              <Button onClick={() => toast('ارسال پیام با بخش اعلان‌ها فعال می‌شود')}>ارسال پیام</Button>
              <Button variant="danger" onClick={() => (sel.status === 'blocked' ? (setBlocked(sel.id, false), toast('مسدودی برداشته شد')) : setBlock(sel))}>{sel.status === 'blocked' ? 'رفع مسدودی' : 'مسدود کردن'}</Button>
            </div>
          </aside>
        ) : null}
      </div>

      <Modal open={!!days} onClose={() => setDays(null)} title="افزودن روز اشتراک" footer={<><Button variant="primary" onClick={() => { const n = Number(dayCount); if (days && n > 0) { addSubscriptionDays(days.id, n); toast(`${faDigits(n)} روز به ${days.name} اضافه شد`); setDays(null); } }}>افزودن</Button><Button onClick={() => setDays(null)}>انصراف</Button></>}>
        <Field label={`تعداد روز برای ${days?.name ?? ''}`}>{(id) => <input id={id} className="input" inputMode="numeric" value={dayCount} onChange={(e) => setDayCount(e.target.value.replace(/\D/g, ''))} />}</Field>
      </Modal>
      <Confirm open={!!block} danger title="مسدود کردن کاربر" confirm="مسدود کردن" onClose={() => setBlock(null)} body={<>«{block?.name}» دیگر نمی‌تواند وارد شود. این کار در گزارش فعالیت ثبت می‌شود.</>} onConfirm={() => { if (block) { setBlocked(block.id, true); toast('کاربر مسدود شد'); } }} />
    </>
  );
}
