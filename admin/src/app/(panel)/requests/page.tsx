'use client';

import { useState } from 'react';
import { useToast } from '@/components/Toast';
import { Badge, Button, Confirm, Empty, PageHead, Segmented } from '@/components/ui';
import { faDigits, jalaliDate } from '@/lib/format';
import { acceptRequest, rejectRequest, useStore } from '@/lib/store';
import { TYPE_LABEL, type TitleRequest } from '@/lib/types';

type Tab = TitleRequest['status'] | 'all';

const RIGHT = { has: { l: 'دارد', k: 'success' as const }, none: { l: 'ندارد', k: 'danger' as const }, negotiating: { l: 'در حال مذاکره', k: 'warning' as const } };
const STATUS = { open: { l: 'باز', k: 'neutral' as const }, added: { l: 'اضافه‌شده', k: 'success' as const }, rejected: { l: 'ردشده', k: 'danger' as const } };

export default function RequestsPage() {
  const requests = useStore((s) => s.requests);
  const toast = useToast();
  const [tab, setTab] = useState<Tab>('open');
  const [rej, setRej] = useState<TitleRequest | null>(null);
  const rows = requests.filter((r) => tab === 'all' || r.status === tab).sort((a, b) => b.votes - a.votes);

  return (
    <>
      <PageHead title="درخواست آثار از کاربران" sub="مرتب‌شده بر اساس تعداد رأی · قبل از افزودن، وضعیت مجوز نشر را بررسی کنید">
        <Segmented label="وضعیت درخواست" value={tab} onChange={setTab} items={[{ id: 'open', label: 'باز' }, { id: 'added', label: 'اضافه‌شده' }, { id: 'rejected', label: 'ردشده' }, { id: 'all', label: 'همه' }]} />
      </PageHead>
      <section className="card flush" aria-label="درخواست‌ها">
        <div className="table-wrap">
          <table className="t">
            <thead><tr><th>رأی</th><th>اثر درخواستی</th><th>نوع</th><th>زبان</th><th>مجوز نشر</th><th>وضعیت</th><th>اقدام</th></tr></thead>
            <tbody>
              {rows.map((r) => (
                <tr key={r.id}>
                  <td><b style={{ color: 'var(--red-400)', fontSize: 20 }}>{faDigits(r.votes)}</b></td>
                  <td><b className="ltr">{r.nameEn}</b><div className="sub">اولین درخواست: {jalaliDate(r.firstRequested)}</div></td>
                  <td>{TYPE_LABEL[r.type]}</td>
                  <td><span className="ltr">{r.lang}</span></td>
                  <td><Badge kind={RIGHT[r.publishRight].k}>{RIGHT[r.publishRight].l}</Badge></td>
                  <td><Badge kind={STATUS[r.status].k}>{STATUS[r.status].l}</Badge></td>
                  <td>
                    {r.status === 'open' && (
                      <div className="row" style={{ gap: 6 }}>
                        <Button size="sm" variant="primary" disabled={r.publishRight !== 'has'} title={r.publishRight !== 'has' ? 'بدون مجوز نشر نمی‌توان اثر را اضافه کرد' : undefined} onClick={() => { acceptRequest(r.id); toast(`«${r.nameEn}» به آثار (پیش‌نویس) اضافه شد`); }}>افزودن به آثار</Button>
                        <Button size="sm" onClick={() => setRej(r)}>رد و اطلاع</Button>
                      </div>
                    )}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
          {rows.length === 0 && <Empty>درخواستی در این بخش نیست.</Empty>}
        </div>
      </section>
      <Confirm open={!!rej} title="رد درخواست" confirm="رد و اطلاع‌رسانی" danger onClose={() => setRej(null)} body={<>درخواست «{rej?.nameEn}» رد می‌شود و به {faDigits(rej?.votes ?? 0)} رأی‌دهنده اطلاع داده می‌شود.</>} onConfirm={() => { if (rej) { rejectRequest(rej.id); toast('درخواست رد شد'); } }} />
    </>
  );
}
