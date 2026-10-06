'use client';

import { Funnel, LineChart } from '@/components/Charts';
import { useToast } from '@/components/Toast';
import { Button, PageHead } from '@/components/ui';
import { downloadCsv, faDigits, faNumber } from '@/lib/format';
import { churn, churnLabels, dropOff, funnel, languageSplit } from '@/lib/stats';

export default function AnalyticsPage() {
  const toast = useToast();
  return (
    <>
      <PageHead title="تحلیل‌ها" sub="شهریور ۱۴۰۵ · داده‌های نمونه">
        <Button onClick={() => { downloadCsv('analytics.csv', [['مرحله', 'تعداد'], ...funnel.map((f) => [f.label, f.value])]); toast('گزارش ذخیره شد'); }}>خروجی گزارش</Button>
      </PageHead>
      <div className="grid g2" style={{ marginBottom: 'var(--space-4)' }}>
        <section className="card stack" aria-labelledby="fn">
          <h2 id="fn">قیف تبدیل به مشترک</h2>
          <Funnel steps={funnel} />
          <p style={{ color: 'var(--warning)' }} className="sub">بیشترین ریزش: بین «دیدن Paywall» و «خرید». پیشنهاد: آزمون قیمت یا ۷ روز رایگان.</p>
        </section>
        <section className="card stack" aria-labelledby="ch">
          <div className="card-head"><h2 id="ch">نرخ ریزش ماهانه مشترکین</h2><b style={{ color: 'var(--success)', fontSize: 22 }}>{faDigits(churn[churn.length - 1].toFixed(1).replace('.', '٫'))}٪</b></div>
          <LineChart points={churn} labels={churnLabels} label="نرخ ریزش ماهانه" />
        </section>
      </div>
      <div className="grid g2">
        <section className="card stack" aria-labelledby="lg">
          <h2 id="lg">زبان خواندن</h2>
          <div className="row" style={{ gap: 0, height: 32, borderRadius: 8, overflow: 'hidden', flexWrap: 'nowrap' }} role="img" aria-label={languageSplit.map((l) => `${l.label} ${faDigits(l.pct)} درصد`).join('، ')}>
            {languageSplit.map((l) => <i key={l.label} style={{ width: `${l.pct}%`, background: l.color, height: '100%' }} />)}
          </div>
          {languageSplit.map((l) => <div key={l.label} className="row" style={{ justifyContent: 'space-between' }}><span className="row" style={{ gap: 6 }}><i className="dot" style={{ background: l.color }} />{l.label}</span><b>{faDigits(l.pct)}٪</b></div>)}
          <p className="sub">خوانندگان دوزبانه ۲٫۳ برابر بیشتر تمدید می‌کنند؛ این ویژگی را در Paywall برجسته کنید.</p>
        </section>
        <section className="card flush" aria-labelledby="dr">
          <h2 id="dr" style={{ padding: 'var(--space-5) var(--space-5) 0' }}>چپترهایی که خوانندگان وسطشان رها می‌کنند</h2>
          <div className="table-wrap" style={{ marginTop: 'var(--space-3)' }}>
            <table className="t">
              <thead><tr><th>اثر / چپتر</th><th>تکمیل</th><th>علت احتمالی</th></tr></thead>
              <tbody>
                {dropOff.map((d) => (
                  <tr key={d.work}>
                    <td><b>{d.work}</b></td>
                    <td style={{ color: d.completion < 60 ? 'var(--danger)' : d.completion < 80 ? 'var(--warning)' : 'var(--success)', fontWeight: 700 }}>{faNumber(d.completion)}٪</td>
                    <td className="sub">{d.cause}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </section>
      </div>
    </>
  );
}
