'use client';

import { useState } from 'react';
import { useToast } from '@/components/Toast';
import { Badge, Button, Field, Modal, PageHead, Toggle } from '@/components/ui';
import { faDigits, faNumber, clock, jalaliNumeric } from '@/lib/format';
import { amountPlaceholder, pricePlaceholder } from '@/lib/labels';
import { addCoupon, addPlan, updatePlan, useStore } from '@/lib/store';
import type { Plan } from '@/lib/types';

export default function SubscriptionsPage() {
  const plans = useStore((s) => s.plans);
  const coupons = useStore((s) => s.coupons);
  const tx = useStore((s) => s.transactions);
  const toast = useToast();
  const [filter, setFilter] = useState<'all' | 'success' | 'failed'>('all');
  const [edit, setEdit] = useState<Plan | 'new' | null>(null);
  const [form, setForm] = useState({ name: '', days: '30', price: '' });
  const [newCoupon, setNewCoupon] = useState(false);
  const [cc, setCc] = useState({ code: '', note: '' });
  const [err, setErr] = useState('');

  const rows = tx.filter((t) => filter === 'all' || t.status === filter);
  const open = (p: Plan | 'new') => { setErr(''); setEdit(p); setForm(p === 'new' ? { name: '', days: '30', price: '' } : { name: p.name, days: String(p.days), price: p.priceToman ? String(p.priceToman) : '' }); };

  const save = () => {
    const days = Number(form.days);
    if (form.name.trim().length < 2 || !Number.isInteger(days) || days < 1) return setErr('نام طرح و مدت (روز) را درست وارد کنید.');
    const priceToman = form.price ? Number(form.price) : null;
    if (edit === 'new') addPlan({ name: form.name.trim(), days, priceToman, active: true });
    else if (edit) updatePlan(edit.id, { name: form.name.trim(), days, priceToman });
    toast('طرح ذخیره شد');
    setEdit(null);
  };

  return (
    <>
      <PageHead title="اشتراک و پرداخت‌ها" sub="مدیریت طرح‌ها، کدهای تخفیف و تراکنش‌ها">
        <Button variant="primary" icon="plus" onClick={() => open('new')}>طرح جدید</Button>
      </PageHead>

      <div className="grid g4" style={{ gridTemplateColumns: '1.1fr repeat(3, minmax(0,1fr))', marginBottom: 'var(--space-4)' }}>
        <section className="card stack" aria-labelledby="cp" style={{ gridRow: 1 }}>
          <div className="card-head"><h2 id="cp">کدهای تخفیف</h2><button className="sub" style={{ background: 'none', border: 0, color: 'var(--red-300)' }} onClick={() => { setCc({ code: '', note: '' }); setErr(''); setNewCoupon(true); }}>+ کد جدید</button></div>
          {coupons.map((c) => (
            <div key={c.code} className="row" style={{ justifyContent: 'space-between' }}>
              <b className="ltr">{c.code}</b>
              <span className="sub">{c.expired ? 'منقضی' : c.note}</span>
            </div>
          ))}
        </section>
        {plans.map((p) => (
          <section key={p.id} className="card stack" aria-label={`طرح ${p.name}`} style={{ borderColor: p.active ? 'var(--red-800)' : undefined }}>
            <div className="card-head"><h2>{p.name}</h2><Toggle label={`فعال بودن طرح ${p.name}`} checked={p.active} onChange={(v) => { updatePlan(p.id, { active: v }); toast(v ? 'طرح فعال شد' : 'طرح غیرفعال شد'); }} /></div>
            <div style={{ fontSize: 26, fontWeight: 900 }}>{p.priceToman ? faNumber(p.priceToman) : pricePlaceholder} <span className="sub" style={{ fontSize: 13, fontWeight: 400 }}>تومان</span></div>
            <div className="row" style={{ justifyContent: 'space-between' }}><span className="sub">{faDigits(p.days)} روز</span><span className="sub">{faNumber(p.subscribers)} مشترک فعال</span></div>
            <Button onClick={() => open(p)}>ویرایش طرح</Button>
          </section>
        ))}
      </div>

      <section className="card flush" aria-labelledby="tx">
        <div className="row" style={{ padding: 'var(--space-5) var(--space-5) 0' }}>
          <h2 id="tx">تراکنش‌های اخیر</h2>
          <span className="spacer" />
          <div className="seg" role="group" aria-label="فیلتر تراکنش">
            {([['all', 'همه'], ['success', 'موفق'], ['failed', 'ناموفق']] as const).map(([k, l]) => <button key={k} aria-pressed={filter === k} onClick={() => setFilter(k)}>{l}</button>)}
          </div>
        </div>
        <div className="table-wrap" style={{ marginTop: 'var(--space-3)' }}>
          <table className="t">
            <thead><tr><th>کاربر</th><th>طرح</th><th>مبلغ</th><th>درگاه</th><th>تاریخ</th><th>کد پیگیری</th><th>وضعیت</th></tr></thead>
            <tbody>
              {rows.map((t) => (
                <tr key={t.code}>
                  <td><b>{t.user}</b></td><td>{t.plan}</td><td>{amountPlaceholder} تومان</td><td>{t.gateway}</td>
                  <td>{clock(t.date)} {jalaliNumeric(t.date)}</td>
                  <td><span className="ltr">{t.code}</span></td>
                  <td><Badge kind={t.status === 'success' ? 'success' : 'danger'}>{t.status === 'success' ? 'موفق' : 'ناموفق'}</Badge></td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </section>

      <Modal open={!!edit} onClose={() => setEdit(null)} title={edit === 'new' ? 'طرح جدید' : 'ویرایش طرح'} footer={<><Button variant="primary" onClick={save}>ذخیره</Button><Button onClick={() => setEdit(null)}>انصراف</Button></>}>
        <div className="stack">
          <Field label="نام طرح">{(id) => <input id={id} className="input" value={form.name} onChange={(e) => setForm({ ...form, name: e.target.value })} />}</Field>
          <div className="grid g2">
            <Field label="مدت (روز)">{(id) => <input id={id} className="input" inputMode="numeric" value={form.days} onChange={(e) => setForm({ ...form, days: e.target.value.replace(/\D/g, '') })} />}</Field>
            <Field label="قیمت (تومان)">{(id) => <input id={id} className="input" inputMode="numeric" placeholder="[قیمت]" value={form.price} onChange={(e) => setForm({ ...form, price: e.target.value.replace(/\D/g, '') })} />}</Field>
          </div>
          {err && <p className="err" role="alert">{err}</p>}
        </div>
      </Modal>
      <Modal open={newCoupon} onClose={() => setNewCoupon(false)} title="کد تخفیف جدید" footer={<><Button variant="primary" onClick={() => { if (!/^[A-Za-z0-9-]{3,20}$/.test(cc.code)) return setErr('کد باید ۳ تا ۲۰ حرف یا عدد لاتین باشد.'); addCoupon(cc.code, cc.note || '—'); toast('کد تخفیف ساخته شد'); setNewCoupon(false); }}>ساخت</Button><Button onClick={() => setNewCoupon(false)}>انصراف</Button></>}>
        <div className="stack">
          <Field label="کد">{(id) => <input id={id} className="input" style={{ direction: 'ltr', textAlign: 'left' }} value={cc.code} onChange={(e) => setCc({ ...cc, code: e.target.value })} />}</Field>
          <Field label="توضیح">{(id) => <input id={id} className="input" value={cc.note} onChange={(e) => setCc({ ...cc, note: e.target.value })} />}</Field>
          {err && <p className="err" role="alert">{err}</p>}
        </div>
      </Modal>
    </>
  );
}
