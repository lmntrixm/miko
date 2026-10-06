'use client';

import { useState } from 'react';
import { Modal, Badge, Button, PageHead, Segmented } from '@/components/ui';
import { useToast } from '@/components/Toast';
import { clock, downloadCsv, faDigits, jalaliNumeric, relative } from '@/lib/format';
import { useStore } from '@/lib/store';
import type { AuditEntry, AuditSection } from '@/lib/types';

const SECTIONS: Record<AuditSection, { label: string; kind: 'info' | 'warning' | 'success' | 'danger' }> = {
  content: { label: 'محتوا', kind: 'info' },
  users: { label: 'کاربران', kind: 'warning' },
  payment: { label: 'پرداخت', kind: 'success' },
  settings: { label: 'تنظیمات', kind: 'danger' },
};

export default function ActivityLogPage() {
  const audit = useStore((s) => s.audit);
  const toast = useToast();
  const [sec, setSec] = useState<'all' | AuditSection>('all');
  const [member, setMember] = useState('all');
  const [detail, setDetail] = useState<AuditEntry | null>(null);
  const members = Array.from(new Set(audit.map((a) => a.member)));
  const rows = audit.filter((a) => (sec === 'all' || a.section === sec) && (member === 'all' || a.member === member));

  return (
    <>
      <PageHead title="گزارش فعالیت مدیران" sub="هر تغییر در محتوا، کاربران، پرداخت و تنظیمات ثبت می‌شود و قابل ویرایش نیست">
        <select className="select" style={{ width: 150 }} aria-label="فیلتر عضو" value={member} onChange={(e) => setMember(e.target.value)}>
          <option value="all">همه اعضا</option>{members.map((m) => <option key={m}>{m}</option>)}
        </select>
        <Segmented label="بخش" value={sec} onChange={setSec} items={[{ id: 'all', label: 'همه' }, { id: 'content', label: 'محتوا' }, { id: 'users', label: 'کاربران' }, { id: 'payment', label: 'پرداخت' }, { id: 'settings', label: 'تنظیمات' }]} />
        <Button onClick={() => { downloadCsv('audit-log.csv', [['زمان', 'عضو', 'بخش', 'اقدام'], ...rows.map((r) => [`${jalaliNumeric(r.when)} ${clock(r.when)}`, r.member, SECTIONS[r.section].label, r.action])]); toast('فایل CSV ذخیره شد'); }}>خروجی CSV</Button>
      </PageHead>
      <section className="card flush" aria-label="گزارش فعالیت">
        <div className="table-wrap">
          <table className="t">
            <thead><tr><th>زمان</th><th>عضو</th><th>بخش</th><th>اقدام</th><th>IP / دستگاه</th><th /></tr></thead>
            <tbody>
              {rows.map((r) => (
                <tr key={r.id}>
                  <td className="sub">{relative(r.when)} · {clock(r.when)}</td>
                  <td><b>{r.member}</b></td>
                  <td><Badge kind={SECTIONS[r.section].kind}>{SECTIONS[r.section].label}</Badge></td>
                  <td>{r.action}</td>
                  <td className="sub"><span className="ltr">{r.device}</span></td>
                  <td><button className="sub" style={{ background: 'none', border: 0, color: 'var(--red-300)' }} onClick={() => setDetail(r)}>جزئیات</button></td>
                </tr>
              ))}
            </tbody>
          </table>
          {rows.length === 0 && <p className="muted" style={{ padding: 24 }}>موردی ثبت نشده.</p>}
        </div>
      </section>
      <Modal open={!!detail} onClose={() => setDetail(null)} title="جزئیات رویداد" footer={<Button onClick={() => setDetail(null)}>بستن</Button>}>
        {detail && (
          <dl className="stack" style={{ margin: 0, gap: 8 }}>
            <div><dt className="sub">زمان</dt><dd style={{ margin: 0 }}>{jalaliNumeric(detail.when)} {clock(detail.when)}</dd></div>
            <div><dt className="sub">عضو</dt><dd style={{ margin: 0 }}>{detail.member}</dd></div>
            <div><dt className="sub">بخش</dt><dd style={{ margin: 0 }}>{SECTIONS[detail.section].label}</dd></div>
            <div><dt className="sub">اقدام</dt><dd style={{ margin: 0 }}>{detail.action}</dd></div>
            <div><dt className="sub">دستگاه</dt><dd style={{ margin: 0 }} className="ltr">{detail.device}</dd></div>
            <p className="sub">شناسه: <span className="ltr">{faDigits(detail.id)}</span></p>
          </dl>
        )}
      </Modal>
    </>
  );
}
