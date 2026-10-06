'use client';

import { useRouter } from 'next/navigation';
import { useEffect, useRef, useState } from 'react';
import { Button, Field } from '@/components/ui';
import { Icon } from '@/components/Icon';
import { faNumber } from '@/lib/format';
import { hydrate, loginStep1, loginStep2, useStore } from '@/lib/store';

export default function LoginPage() {
  const router = useRouter();
  const pending = useStore((s) => s.pendingLogin);
  const session = useStore((s) => s.session);
  const titles = useStore((s) => s.titles);
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [digits, setDigits] = useState<string[]>(Array(6).fill(''));
  const refs = useRef<(HTMLInputElement | null)[]>([]);

  useEffect(() => hydrate(), []);
  useEffect(() => {
    if (session) router.replace('/dashboard');
  }, [session, router]);

  const step1 = (e: React.FormEvent) => {
    e.preventDefault();
    setError('');
    if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) return setError('ایمیل معتبر نیست؛ مثلاً name@company.com');
    if (!password) return setError('رمز عبور را وارد کنید');
    if (!loginStep1(email, password)) setError('ایمیل یا رمز عبور درست نیست. دوباره امتحان کنید.');
  };

  const step2 = (e: React.FormEvent) => {
    e.preventDefault();
    const code = digits.join('');
    if (code.length < 6) return setError('کد ۶ رقمی را کامل وارد کنید');
    if (!loginStep2(code)) {
      setError('کد درست نیست یا منقضی شده. کد جدید را از اپ Authenticator بگیرید.');
      setDigits(Array(6).fill(''));
      refs.current[0]?.focus();
    }
  };

  const onDigit = (i: number, v: string) => {
    const d = v.replace(/\D/g, '').slice(-1);
    setDigits((cur) => cur.map((x, k) => (k === i ? d : x)));
    if (d && i < 5) refs.current[i + 1]?.focus();
  };

  const chapters = titles.reduce((a, t) => a + t.chapters, 0);

  return (
    <div className="login">
      <div className="formside">
        {!pending ? (
          <form onSubmit={step1} noValidate>
            <span className="brand-mark" aria-hidden="true">م</span>
            <div>
              <h1 style={{ fontSize: 24 }}>ورود به پنل مدیریت</h1>
              <p className="sub">فقط اعضای تیم با دسترسی تأییدشده</p>
            </div>
            <Field label="ایمیل سازمانی">
              {(id) => <input id={id} className="input ltr" style={{ display: 'block', direction: 'ltr', textAlign: 'left' }} type="email" autoComplete="username" value={email} onChange={(e) => setEmail(e.target.value)} placeholder="name@[domain]" aria-invalid={!!error} />}
            </Field>
            <Field label="رمز عبور">
              {(id) => <input id={id} className="input" style={{ direction: 'ltr', textAlign: 'left' }} type="password" autoComplete="current-password" value={password} onChange={(e) => setPassword(e.target.value)} aria-invalid={!!error} />}
            </Field>
            {error && <p className="err" role="alert">{error}</p>}
            <Button variant="primary" type="submit" block style={{ height: 52 }}>ادامه</Button>
            <p className="sub row" style={{ gap: 6 }}>
              <Icon name="lock" size={14} /> ورودها در گزارش فعالیت ثبت می‌شوند · <a href="/mobile">نسخهٔ موبایل پنل</a>
            </p>
          </form>
        ) : (
          <form onSubmit={step2} noValidate>
            <span className="brand-mark" aria-hidden="true">م</span>
            <div>
              <h1 style={{ fontSize: 24 }}>کد تأیید دومرحله‌ای</h1>
              <p className="sub">کد ۶ رقمی اپ Authenticator را وارد کنید.</p>
            </div>
            <div className="otp" role="group" aria-label="کد ۶ رقمی">
              {digits.map((d, i) => (
                <input
                  key={i}
                  ref={(el) => { refs.current[i] = el; }}
                  value={d}
                  inputMode="numeric"
                  autoComplete={i === 0 ? 'one-time-code' : 'off'}
                  aria-label={`رقم ${i + 1}`}
                  autoFocus={i === 0}
                  onChange={(e) => onDigit(i, e.target.value)}
                  onKeyDown={(e) => { if (e.key === 'Backspace' && !d && i > 0) refs.current[i - 1]?.focus(); }}
                  onPaste={(e) => {
                    const t = e.clipboardData.getData('text').replace(/\D/g, '').slice(0, 6);
                    if (t) { e.preventDefault(); setDigits(Array.from({ length: 6 }, (_, k) => t[k] ?? '')); }
                  }}
                />
              ))}
            </div>
            {error && <p className="err" role="alert">{error}</p>}
            <Button variant="primary" type="submit" block style={{ height: 52 }}>ورود</Button>
          </form>
        )}
      </div>
      <div className="art" aria-hidden="true">
        <div className="tiles">{Array.from({ length: 12 }, (_, i) => <i key={i} />)}</div>
        <b>{faNumber(titles.length)} اثر<br />{faNumber(chapters)} چپتر</b>
        <span>در دو زبان فارسی و انگلیسی</span>
      </div>
    </div>
  );
}
