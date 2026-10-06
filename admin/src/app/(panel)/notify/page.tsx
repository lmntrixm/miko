'use client';

import { useState } from 'react';
import { useToast } from '@/components/Toast';
import { Badge, Button, Check, Field, PageHead } from '@/components/ui';
import { Icon } from '@/components/Icon';
import { clock, faDigits, faNumber, relative } from '@/lib/format';
import { audienceSizes } from '@/lib/stats';
import { sendNotification, useStore } from '@/lib/store';

const AUDIENCES = [{ id: 'all', label: 'همه کاربران' }, { id: 'active', label: 'مشترکین فعال' }, { id: 'expiring', label: 'اشتراک رو به انقضا' }, { id: 'followers', label: 'دنبال‌کنندگان این اثر' }];
const CHANNELS = ['پوش', 'درون‌برنامه', 'ایمیل'];
const TITLE_MAX = 65;

export default function NotifyPage() {
  const sent = useStore((s) => s.sent);
  const titles = useStore((s) => s.titles);
  const toast = useToast();
  const [title, setTitle] = useState('');
  const [body, setBody] = useState('');
  const [link, setLink] = useState('');
  const [aud, setAud] = useState('all');
  const [chs, setChs] = useState<string[]>(['پوش', 'درون‌برنامه']);
  const [when, setWhen] = useState('now');
  const [err, setErr] = useState('');

  const audience = AUDIENCES.find((a) => a.id === aud)!;
  const size = audienceSizes[aud];

  const send = () => {
    if (!title.trim()) return setErr('عنوان اعلان را بنویسید.');
    if (title.length > TITLE_MAX) return setErr(`عنوان حداکثر ${faDigits(TITLE_MAX)} نویسه باشد.`);
    if (!body.trim()) return setErr('متن اعلان را بنویسید.');
    if (!chs.length) return setErr('حداقل یک کانال ارسال را انتخاب کنید.');
    setErr('');
    sendNotification({ title: title.trim(), audience: audience.label, channels: chs, sent: size, scheduled: when !== 'now' });
    toast(when === 'now' ? `اعلان برای ${faNumber(size)} کاربر ارسال شد` : 'اعلان زمان‌بندی شد');
    setTitle(''); setBody(''); setLink('');
  };

  return (
    <>
      <PageHead title="ارسال اعلان" sub="پوش‌نوتیفیکیشن، اعلان درون‌برنامه و ایمیل" />
      <div className="grid" style={{ gridTemplateColumns: 'minmax(0,1fr) minmax(0,2.2fr)', alignItems: 'start' }}>
        <aside className="card stack" aria-labelledby="pv">
          <h2 id="pv">پیش‌نمایش روی گوشی</h2>
          <div className="phone" aria-hidden="true">
            <div className="clock">{clock(new Date('2026-09-28T21:40:00'))}</div>
            <div className="push">
              <span className="brand-mark" style={{ width: 32, height: 32, fontSize: 14 }}>م</span>
              <div style={{ flex: 1 }}>
                <div className="row" style={{ justifyContent: 'space-between', fontSize: 11, opacity: .7 }}><span>میکو</span><span>اکنون</span></div>
                <b style={{ display: 'block' }}>{title || 'عنوان اعلان'}</b>
                <span style={{ fontSize: 12, opacity: .85 }}>{body || 'متن اعلان اینجا دیده می‌شود'}</span>
              </div>
            </div>
          </div>
          <p className="sub">تخمین دریافت‌کنندگان: <b>{faNumber(size)}</b> کاربر</p>
        </aside>

        <div className="stack">
          <section className="card stack" aria-labelledby="nw">
            <h2 id="nw">اعلان جدید</h2>
            <div className="grid g2" style={{ gridTemplateColumns: '2fr 1fr' }}>
              <Field label={`عنوان (${faDigits(title.length)}/${faDigits(TITLE_MAX)})`}>{(id) => <input id={id} className="input" value={title} onChange={(e) => setTitle(e.target.value)} />}</Field>
              <Field label="لینک مقصد در اپ">{(id) => <select id={id} className="select" value={link} onChange={(e) => setLink(e.target.value)}><option value="">بدون لینک</option>{titles.slice(0, 8).map((t) => <option key={t.id} value={t.id}>{t.nameFa}</option>)}</select>}</Field>
            </div>
            <Field label="متن اعلان">{(id) => <textarea id={id} className="textarea" value={body} onChange={(e) => setBody(e.target.value)} />}</Field>
            <div className="field">
              <span className="lbl">مخاطبان</span>
              <div className="row" style={{ gap: 6 }} role="group" aria-label="مخاطبان">
                {AUDIENCES.map((a) => <button key={a.id} className="chip" aria-pressed={aud === a.id} onClick={() => setAud(a.id)}>{a.label} ({faNumber(audienceSizes[a.id])})</button>)}
              </div>
            </div>
            <div className="row" style={{ alignItems: 'flex-end' }}>
              <div className="field">
                <span className="lbl">کانال ارسال</span>
                <div className="row">{CHANNELS.map((c) => <label key={c} className="chip"><Check label={c} checked={chs.includes(c)} onChange={(v) => setChs(v ? [...chs, c] : chs.filter((x) => x !== c))} />{c}</label>)}</div>
              </div>
              <Field label="زمان ارسال">{(id) => <select id={id} className="select" value={when} onChange={(e) => setWhen(e.target.value)}><option value="now">همین حالا</option><option value="tonight">امشب ساعت ۲۰:۰۰</option><option value="tomorrow">فردا ساعت ۱۰:۰۰</option></select>}</Field>
              <span className="spacer" />
              <Button variant="primary" onClick={send}><Icon name="send" size={18} /> {when === 'now' ? 'ارسال اعلان' : 'زمان‌بندی اعلان'}</Button>
            </div>
            {err && <p className="err" role="alert">{err}</p>}
          </section>

          <section className="card flush" aria-labelledby="sl">
            <h2 id="sl" style={{ padding: 'var(--space-5) var(--space-5) 0' }}>اعلان‌های ارسال‌شده</h2>
            <div className="table-wrap" style={{ marginTop: 'var(--space-3)' }}>
              <table className="t">
                <thead><tr><th>عنوان</th><th>مخاطبان</th><th>کانال</th><th>ارسال</th><th>نرخ باز شدن</th><th>زمان</th></tr></thead>
                <tbody>
                  {sent.map((n) => (
                    <tr key={n.id}>
                      <td><b>{n.title}</b></td><td>{n.audience}</td><td>{n.channels.join(' · ')}</td><td>{faNumber(n.sent)}</td>
                      <td>{n.openRate ? <div className="row" style={{ gap: 8, flexWrap: 'nowrap' }}><span>{faDigits(n.openRate)}٪</span><div className="progress" style={{ width: 60 }}><i style={{ width: `${n.openRate}%` }} /></div></div> : <Badge kind="neutral">تازه</Badge>}</td>
                      <td>{relative(n.when)}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </section>
        </div>
      </div>
    </>
  );
}
