'use client';

import { useState } from 'react';
import { useToast } from '@/components/Toast';
import { Avatar, Badge, Button, Check, Field, Modal, PageHead, Tabs, Toggle } from '@/components/ui';
import { faDigits } from '@/lib/format';
import { addMember, saveSettings, setPermission, useStore } from '@/lib/store';
import { PERMISSIONS, ROLE_LABEL, type Role } from '@/lib/types';

type Tab = 'general' | 'content' | 'gateway' | 'team';
const ROLES: Role[] = ['admin', 'editor', 'translator', 'moderator'];

export default function SettingsPage() {
  const s = useStore((x) => x.settings);
  const members = useStore((x) => x.members);
  const perms = useStore((x) => x.permissions);
  const toast = useToast();
  const [tab, setTab] = useState<Tab>('team');
  const [form, setForm] = useState({ freeChapters: String(s.freeChapters), maxDevices: String(s.maxDevices), supportEmail: s.supportEmail });
  const [err, setErr] = useState('');
  const [inviting, setInviting] = useState(false);
  const [inv, setInv] = useState({ name: '', role: 'translator' as Role });

  const save = () => {
    const fc = Number(form.freeChapters), md = Number(form.maxDevices);
    if (!Number.isInteger(fc) || fc < 0 || !Number.isInteger(md) || md < 1) return setErr('تعداد چپتر رایگان و دستگاه مجاز را درست وارد کنید.');
    setErr('');
    saveSettings({ freeChapters: fc, maxDevices: md, supportEmail: form.supportEmail });
    toast('تغییرات ذخیره شد');
  };

  return (
    <>
      <PageHead title="تنظیمات"><Button variant="primary" onClick={save}>ذخیره تغییرات</Button></PageHead>
      <Tabs label="بخش‌های تنظیمات" value={tab} onChange={setTab} items={[{ id: 'general', label: 'عمومی' }, { id: 'content', label: 'محتوا و مطالعه' }, { id: 'gateway', label: 'درگاه پرداخت' }, { id: 'team', label: 'مدیران و دسترسی‌ها' }]} />
      {err && <p className="err card" role="alert" style={{ marginBottom: 16 }}>{err}</p>}

      {tab === 'general' && (
        <section className="card stack" style={{ maxWidth: 560 }}>
          <Field label="ایمیل پشتیبانی">{(id) => <input id={id} className="input" style={{ direction: 'ltr', textAlign: 'left' }} value={form.supportEmail} onChange={(e) => setForm({ ...form, supportEmail: e.target.value })} />}</Field>
          <label className="row" style={{ justifyContent: 'space-between' }}>ورود دومرحله‌ای برای همهٔ اعضای تیم الزامی است <Toggle label="ورود دومرحله‌ای الزامی" checked={s.twoFactorRequired} onChange={(v) => saveSettings({ twoFactorRequired: v })} /></label>
        </section>
      )}
      {tab === 'content' && (
        <section className="card stack" style={{ maxWidth: 560 }}>
          <Field label="تعداد چپتر رایگان هر اثر">{(id) => <input id={id} className="input" inputMode="numeric" value={form.freeChapters} onChange={(e) => setForm({ ...form, freeChapters: e.target.value.replace(/\D/g, '') })} />}</Field>
          <Field label="حداکثر دستگاه برای دانلود">{(id) => <input id={id} className="input" inputMode="numeric" value={form.maxDevices} onChange={(e) => setForm({ ...form, maxDevices: e.target.value.replace(/\D/g, '') })} />}</Field>
          <label className="row" style={{ justifyContent: 'space-between' }}>تمدید خودکار به‌صورت پیش‌فرض روشن باشد <Toggle label="تمدید خودکار پیش‌فرض" checked={s.autoRenewDefault} onChange={(v) => saveSettings({ autoRenewDefault: v })} /></label>
        </section>
      )}
      {tab === 'gateway' && (
        <section className="card stack" style={{ maxWidth: 560 }}>
          <p className="sub">پرداخت فقط از درگاه بانکی بیرون از اپ انجام می‌شود. اطلاعات اتصال درگاه‌ها بعد از دریافت از بانک اینجا ثبت می‌شود.</p>
          {s.gateways.map((g, i) => (
            <label key={g.name} className="row" style={{ justifyContent: 'space-between' }}><b>{g.name}</b><Toggle label={`فعال بودن ${g.name}`} checked={g.active} onChange={(v) => saveSettings({ gateways: s.gateways.map((x, k) => (k === i ? { ...x, active: v } : x)) })} /></label>
          ))}
        </section>
      )}
      {tab === 'team' && (
        <div className="grid" style={{ gridTemplateColumns: 'minmax(0,1fr) minmax(0,2fr)', alignItems: 'start' }}>
          <section className="card stack" aria-labelledby="mem">
            <div className="card-head"><h2 id="mem">اعضای تیم</h2><Button size="sm" variant="primary" onClick={() => setInviting(true)}>+ دعوت عضو</Button></div>
            {members.map((m) => (
              <div key={m.id} className="row" style={{ flexWrap: 'nowrap' }}>
                <Avatar name={m.name} />
                <div style={{ flex: 1 }}><b>{m.name}</b><div className="sub">{m.online ? 'آنلاین' : `آخرین ورود: ${m.lastSeen}`}</div></div>
                <Badge kind="neutral">{ROLE_LABEL[m.role]}</Badge>
              </div>
            ))}
            <p className="card" style={{ background: 'var(--danger-bg)', color: 'var(--danger)', margin: 0 }}>ورود دومرحله‌ای برای همهٔ اعضای تیم الزامی است.</p>
          </section>
          <section className="card flush" aria-labelledby="mx">
            <div style={{ padding: 'var(--space-5) var(--space-5) 0' }}><h2 id="mx">سطح دسترسی نقش‌ها</h2><p className="sub">برای تغییر، روی هر خانه بزنید · نقش «مدیر کل» همیشه همهٔ دسترسی‌ها را دارد</p></div>
            <div className="table-wrap" style={{ marginTop: 'var(--space-3)' }}>
              <table className="t">
                <thead><tr><th>دسترسی</th>{ROLES.map((r) => <th key={r} style={{ textAlign: 'center' }}>{ROLE_LABEL[r]}</th>)}</tr></thead>
                <tbody>
                  {PERMISSIONS.map((p) => (
                    <tr key={p}>
                      <td>{p}</td>
                      {ROLES.map((r) => (
                        <td key={r} style={{ textAlign: 'center' }}>
                          <Check label={`${p} برای ${ROLE_LABEL[r]}`} checked={r === 'admin' || perms[p].includes(r)} disabled={r === 'admin'} onChange={(v) => setPermission(p, r, v)} />
                        </td>
                      ))}
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </section>
        </div>
      )}

      <Modal open={inviting} onClose={() => setInviting(false)} title="دعوت عضو جدید" footer={<><Button variant="primary" onClick={() => { if (inv.name.trim().length < 2) return; addMember(inv.name.trim(), inv.role); toast(`${faDigits(1)} دعوت‌نامه ثبت شد`); setInviting(false); setInv({ name: '', role: 'translator' }); }}>ارسال دعوت</Button><Button onClick={() => setInviting(false)}>انصراف</Button></>}>
        <div className="stack">
          <Field label="نام">{(id) => <input id={id} className="input" value={inv.name} onChange={(e) => setInv({ ...inv, name: e.target.value })} />}</Field>
          <Field label="نقش">{(id) => <select id={id} className="select" value={inv.role} onChange={(e) => setInv({ ...inv, role: e.target.value as Role })}>{ROLES.slice(1).map((r) => <option key={r} value={r}>{ROLE_LABEL[r]}</option>)}</select>}</Field>
        </div>
      </Modal>
    </>
  );
}
