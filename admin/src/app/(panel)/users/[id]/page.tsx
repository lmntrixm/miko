'use client';

import Link from 'next/link';
import { useParams } from 'next/navigation';
import { useState } from 'react';
import { useToast } from '@/components/Toast';
import { Avatar, Badge, Button, Confirm, Field, Modal, PageHead, StatTile, Tabs } from '@/components/ui';
import { amountPlaceholder, endsText, USER_STATUS } from '@/lib/labels';
import { faDigits, faNumber, jalaliNumeric, relative } from '@/lib/format';
import { addSubscriptionDays, addUserNote, logoutAllDevices, setBlocked, useStore } from '@/lib/store';

type Tab = 'history' | 'payments' | 'comments' | 'reports';

export default function UserDetailPage() {
  const { id } = useParams<{ id: string }>();
  const user = useStore((s) => s.users.find((u) => u.id === id));
  const maxDevices = useStore((s) => s.settings.maxDevices);
  const toast = useToast();
  const [tab, setTab] = useState<Tab>('history');
  const [note, setNote] = useState('');
  const [noting, setNoting] = useState(false);
  const [days, setDays] = useState(false);
  const [n, setN] = useState('7');
  const [block, setBlock] = useState(false);
  const [out, setOut] = useState(false);

  if (!user) return <p className="muted" role="status">کاربر پیدا نشد. <Link href="/users">بازگشت به فهرست</Link></p>;
  const st = USER_STATUS[user.status];

  return (
    <>
      <PageHead title={user.name} crumbs={<><Link href="/users">کاربران</Link> › {user.name}</>}>
        <Button variant="danger" onClick={() => (user.status === 'blocked' ? (setBlocked(user.id, false), toast('مسدودی برداشته شد')) : setBlock(true))}>{user.status === 'blocked' ? 'رفع مسدودی' : 'مسدود کردن'}</Button>
        <Button variant="primary" onClick={() => { setN('7'); setDays(true); }}>افزودن روز اشتراک</Button>
        <Button onClick={() => toast('ارسال پیام با بخش اعلان‌ها فعال می‌شود')}>ارسال پیام</Button>
      </PageHead>
      <div className="row" style={{ marginTop: -16, marginBottom: 'var(--space-4)' }}>
        <Avatar name={user.name} size="lg" />
        <div><Badge kind={st.kind}>{st.label}</Badge><div className="sub"><span className="ltr">{user.email}</span> · ID <span className="ltr">{faDigits(10482)}</span></div></div>
      </div>

      <div className="grid" style={{ gridTemplateColumns: 'repeat(5, minmax(0,1fr))', marginBottom: 'var(--space-4)' }}>
        <StatTile label="اشتراک" value={user.plan ?? '—'} />
        <StatTile label="انقضا" value={endsText(user)} />
        <StatTile label="چپتر خوانده‌شده" value={faNumber(user.chaptersRead)} />
        <StatTile label="عضویت" value={jalaliNumeric(user.joined)} />
        <StatTile label="مجموع پرداخت" value={amountPlaceholder} />
      </div>

      <Tabs label="بخش‌های پرونده" value={tab} onChange={setTab} items={[{ id: 'history', label: 'تاریخچهٔ خواندن' }, { id: 'payments', label: 'پرداخت‌ها' }, { id: 'comments', label: 'نظرات' }, { id: 'reports', label: 'گزارش‌ها' }]} />

      <div className="grid" style={{ gridTemplateColumns: 'minmax(0,1fr) minmax(0,2fr)', alignItems: 'start' }}>
        <div className="stack">
          <section className="card stack" aria-labelledby="dev">
            <h2 id="dev">دستگاه‌ها</h2>
            {user.devices.map((d) => (
              <div key={d.name} className="row" style={{ justifyContent: 'space-between' }}>
                <span className="ltr">{d.name}</span>
                {d.online ? <span style={{ color: 'var(--success)' }}>آنلاین</span> : <span className="sub">{relative(d.lastSeen)}</span>}
              </div>
            ))}
            <p className="sub">{faDigits(user.devices.length)} از {faDigits(maxDevices)} دستگاه مجاز</p>
            <Button onClick={() => setOut(true)}>خروج از همهٔ دستگاه‌ها</Button>
          </section>
          <section className="card stack" aria-labelledby="notes">
            <h2 id="notes">یادداشت‌های داخلی تیم</h2>
            {user.notes.map((x, i) => <div key={i} className="card" style={{ background: 'var(--surface-sunken)' }}>{x.text}<div className="sub">{x.by} · {relative(x.when)}</div></div>)}
            {noting ? (
              <div className="stack">
                <textarea className="textarea" aria-label="متن یادداشت" value={note} onChange={(e) => setNote(e.target.value)} />
                <div className="row"><Button variant="primary" onClick={() => { if (note.trim()) { addUserNote(user.id, note.trim()); setNote(''); setNoting(false); toast('یادداشت ثبت شد'); } }}>ثبت</Button><Button onClick={() => setNoting(false)}>انصراف</Button></div>
              </div>
            ) : (
              <button type="button" className="chip dashed" style={{ height: 40, justifyContent: 'center' }} onClick={() => setNoting(true)}>+ افزودن یادداشت</button>
            )}
          </section>
        </div>

        <section className="card flush" aria-label="محتوای تب">
          <div className="table-wrap">
            {tab === 'history' && (
              <table className="t"><thead><tr><th>چپتر</th><th>پیشرفت</th><th>زبان</th><th>زمان</th></tr></thead>
                <tbody>{user.history.map((h) => <tr key={h.title}><td><b>{h.title}</b></td><td>{faDigits(h.progress)}٪</td><td>{h.lang}</td><td>{relative(h.when)}</td></tr>)}</tbody></table>
            )}
            {tab === 'payments' && (user.payments.length ? <table className="t"><tbody>{user.payments.map((p) => <tr key={p}><td>{p}</td><td>{amountPlaceholder} تومان</td></tr>)}</tbody></table> : <p className="muted" style={{ padding: 24 }}>پرداختی ثبت نشده.</p>)}
            {tab === 'comments' && <p className="muted" style={{ padding: 24 }}>نظرات این کاربر از بخش «نظرات و گزارش‌ها» قابل مشاهده است.</p>}
            {tab === 'reports' && <p className="muted" style={{ padding: 24 }}>گزارشی دربارهٔ این کاربر ثبت نشده.</p>}
          </div>
        </section>
      </div>

      <Modal open={days} onClose={() => setDays(false)} title="افزودن روز اشتراک" footer={<><Button variant="primary" onClick={() => { const v = Number(n); if (v > 0) { addSubscriptionDays(user.id, v); toast(`${faDigits(v)} روز اضافه شد`); setDays(false); } }}>افزودن</Button><Button onClick={() => setDays(false)}>انصراف</Button></>}>
        <Field label="تعداد روز">{(fid) => <input id={fid} className="input" inputMode="numeric" value={n} onChange={(e) => setN(e.target.value.replace(/\D/g, ''))} />}</Field>
      </Modal>
      <Confirm open={block} danger title="مسدود کردن کاربر" confirm="مسدود کردن" onClose={() => setBlock(false)} body="کاربر دیگر نمی‌تواند وارد شود. این کار در گزارش فعالیت ثبت می‌شود." onConfirm={() => { setBlocked(user.id, true); toast('کاربر مسدود شد'); }} />
      <Confirm open={out} title="خروج از همهٔ دستگاه‌ها" confirm="خروج" onClose={() => setOut(false)} body="کاربر باید دوباره وارد شود." onConfirm={() => { logoutAllDevices(user.id); toast('همهٔ دستگاه‌ها خارج شدند'); }} />
    </>
  );
}
