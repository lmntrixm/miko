'use client';

import { StackedBars } from '@/components/Charts';
import { useToast } from '@/components/Toast';
import { Badge, Button, PageHead, StatTile } from '@/components/ui';
import { downloadCsv, faDigits, jalaliDate } from '@/lib/format';
import { amountPlaceholder } from '@/lib/labels';
import { financeMonths, financeNames, financeSeries, invoices, settlements } from '@/lib/stats';

export default function FinancePage() {
  const toast = useToast();
  return (
    <>
      <PageHead title="گزارش مالی" sub="همهٔ مبالغ به تومان · مقادیر واقعی بعد از اتصال درگاه">
        <select className="select" style={{ width: 130 }} aria-label="ماه گزارش" defaultValue="شهریور ۱۴۰۵"><option>شهریور ۱۴۰۵</option><option>مرداد ۱۴۰۵</option></select>
        <Button onClick={() => { downloadCsv('finance.csv', [['شماره', 'کاربر', 'طرح', 'مبلغ', 'تاریخ'], ...invoices.map((i) => [i.no, i.user, i.plan, amountPlaceholder, jalaliDate(i.date)])]); toast('فایل حسابداری ذخیره شد'); }}>خروجی برای حسابداری</Button>
      </PageHead>
      <div className="grid g4" style={{ marginBottom: 'var(--space-4)' }}>
        <StatTile label="درآمد ناخالص" value={amountPlaceholder} delta="۱۲٪ نسبت به مرداد" up />
        <StatTile label="درآمد خالص" value={amountPlaceholder} foot="پس از کارمزد و مالیات" />
        <StatTile label="میانگین درآمد هر مشترک" value={amountPlaceholder} foot="ARPU ماهانه" />
        <StatTile label="برگشتی‌ها" value="۱۸ مورد" foot="۰٫۶٪ تراکنش‌ها" />
      </div>
      <div className="grid" style={{ gridTemplateColumns: 'minmax(0,1fr) minmax(0,1.6fr)', marginBottom: 'var(--space-4)' }}>
        <section className="card stack" aria-labelledby="st">
          <h2 id="st">تسویهٔ درگاه‌ها</h2>
          {settlements.map((s) => (
            <div key={s.gateway} className="card" style={{ background: 'var(--surface-sunken)' }}>
              <div className="row" style={{ justifyContent: 'space-between' }}><b>{s.gateway}</b><Badge kind={s.status === 'settled' ? 'success' : 'warning'}>{s.status === 'settled' ? 'تسویه شد' : 'در انتظار'}</Badge></div>
              <div className="sub">{s.text}</div>
            </div>
          ))}
          <p className="sub">کارمزد درگاه، مالیات بر ارزش افزوده و برگشتی‌ها از مبلغ ناخالص کسر می‌شوند.</p>
        </section>
        <section className="card" aria-labelledby="by">
          <h2 id="by">درآمد به تفکیک طرح — ۶ ماه اخیر</h2>
          <StackedBars months={financeMonths} series={financeSeries} names={financeNames} />
          <p className="sub" style={{ marginTop: 8 }}>نمودار نسبت‌ها را نشان می‌دهد؛ مبلغ‌ها پس از اتصال درگاه پر می‌شوند.</p>
        </section>
      </div>
      <section className="card flush" aria-labelledby="inv">
        <div className="card-head" style={{ padding: 'var(--space-5) var(--space-5) 0' }}><h2 id="inv">فاکتورها</h2><a href="/subscriptions" className="sub">همه تراکنش‌ها ›</a></div>
        <div className="table-wrap">
          <table className="t">
            <thead><tr><th>شماره</th><th>کاربر</th><th>طرح</th><th>مبلغ</th><th>تاریخ</th><th /></tr></thead>
            <tbody>
              {invoices.map((i) => (
                <tr key={i.no}><td><span className="ltr">{i.no}</span></td><td>{i.user}</td><td>{i.plan}</td><td>{amountPlaceholder}</td><td>{jalaliDate(i.date)}</td><td><button className="sub" style={{ background: 'none', border: 0, color: 'var(--red-300)' }} onClick={() => toast(`فاکتور ${faDigits(i.no.slice(-4))} هنگام اتصال درگاه PDF می‌شود`)}>فاکتور PDF</button></td></tr>
              ))}
            </tbody>
          </table>
        </div>
      </section>
    </>
  );
}
