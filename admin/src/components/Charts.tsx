import { faDigits, faNumber } from '@/lib/format';

/** Simple vertical bars; the newest bar is highlighted. Values are exposed as a table-like list for screen readers. */
export function BarChart({ data, labels, height = 240, label }: { data: number[]; labels: string[]; height?: number; label: string }) {
  const max = Math.max(...data, 1);
  return (
    <figure style={{ margin: 0 }}>
      <div className="bars" style={{ height }} role="img" aria-label={`${label}: ${data.map((v) => faNumber(v)).join('، ')}`}>
        {data.map((v, i) => (
          <i key={i} className={`bar ${i === 0 ? 'top' : ''}`} style={{ height: `${(v / max) * 100}%` }} title={faNumber(v)} />
        ))}
      </div>
      <div className="axis" aria-hidden="true">
        {labels.map((l) => (
          <span key={l}>{l}</span>
        ))}
      </div>
    </figure>
  );
}

const SERIES = ['var(--red-900)', 'var(--red-700)', 'var(--red-400)'];

/** Stacked monthly bars (finance). */
export function StackedBars({ months, series, names }: { months: string[]; series: number[][]; names: string[] }) {
  const totals = months.map((_, i) => series.reduce((a, s) => a + s[i], 0));
  const max = Math.max(...totals, 1);
  return (
    <figure style={{ margin: 0 }}>
      <div className="bars" style={{ height: 200 }} role="img" aria-label={`درآمد ماهانه به تفکیک طرح؛ ${names.join('، ')}`}>
        {months.map((m, i) => (
          <div key={m} style={{ flex: 1, height: '100%', display: 'flex', flexDirection: 'column-reverse', gap: 1 }}>
            {series.map((s, k) => (
              <i key={k} style={{ height: `${(s[i] / max) * 100}%`, background: SERIES[k], borderRadius: k === series.length - 1 ? '6px 6px 0 0' : 0 }} />
            ))}
          </div>
        ))}
      </div>
      <div className="axis" aria-hidden="true">
        {months.map((m) => (
          <span key={m}>{m}</span>
        ))}
      </div>
      <div className="row" style={{ marginTop: 'var(--space-3)' }}>
        {names.map((n, k) => (
          <span key={n} className="row" style={{ gap: 6 }}>
            <i className="dot" style={{ background: SERIES[k] }} /> {n}
          </span>
        ))}
      </div>
    </figure>
  );
}

/** Line with area fill (churn). */
export function LineChart({ points, labels, label }: { points: number[]; labels: string[]; label: string }) {
  const w = 440, h = 160, pad = 8;
  const max = Math.max(...points), min = Math.min(...points);
  const x = (i: number) => pad + (i * (w - pad * 2)) / (points.length - 1);
  const y = (v: number) => pad + (1 - (v - min) / (max - min || 1)) * (h - pad * 2);
  const d = points.map((p, i) => `${i ? 'L' : 'M'}${x(i)},${y(p)}`).join(' ');
  return (
    <figure style={{ margin: 0 }}>
      <svg viewBox={`0 0 ${w} ${h}`} width="100%" role="img" aria-label={`${label}: ${points.map((p) => faDigits(p)).join('، ')}`}>
        <path d={`${d} L${x(points.length - 1)},${h} L${x(0)},${h} Z`} fill="var(--red-900)" opacity=".7" />
        <path d={d} fill="none" stroke="var(--red-400)" strokeWidth="2" />
        <circle cx={x(points.length - 1)} cy={y(points[points.length - 1])} r="4" fill="var(--red-400)" />
      </svg>
      <div className="axis" aria-hidden="true">
        {labels.map((l) => (
          <span key={l}>{l}</span>
        ))}
      </div>
    </figure>
  );
}

/** Horizontal funnel rows. */
export function Funnel({ steps }: { steps: { label: string; value: number }[] }) {
  const max = steps[0]?.value || 1;
  return (
    <div className="stack" style={{ gap: 10 }}>
      {steps.map((s, i) => {
        const prev = steps[i - 1]?.value;
        return (
          <div key={s.label} className="row" style={{ flexWrap: 'nowrap' }}>
            <span style={{ width: 130 }}>{s.label}</span>
            <span style={{ width: 70, fontWeight: 700 }}>{faNumber(s.value)}</span>
            <div className="progress" style={{ flex: 1, height: 22, borderRadius: 6 }} role="presentation">
              <i style={{ width: `${(s.value / max) * 100}%`, background: `color-mix(in srgb, var(--red-500) ${100 - i * 15}%, var(--red-900))` }} />
            </div>
            <span className="muted" style={{ width: 44, fontSize: 12 }}>{prev ? `${faDigits(Math.round((s.value / prev) * 100))}٪` : ''}</span>
          </div>
        );
      })}
    </div>
  );
}
