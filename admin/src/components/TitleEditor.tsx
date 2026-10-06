'use client';

import Link from 'next/link';
import { useEffect, useRef, useState } from 'react';
import { Badge, Button, Field, PageHead, Segmented } from './ui';
import { Icon } from './Icon';
import { useToast } from './Toast';
import { faDigits, faNumber, jalaliNumeric } from '@/lib/format';
import { langsText } from '@/lib/labels';
import { addChapter, updateTitle, useStore } from '@/lib/store';
import { type Lang, type Title, type WorkType } from '@/lib/types';

const MAX_MB = 200;
const GENRES = ['اکشن', 'فانتزی', 'عاشقانه', 'کمدی', 'ترسناک', 'ورزشی', 'معمایی', 'ابرقهرمانی', 'زندگی روزمره', 'تاریخی', 'علمی‌تخیلی', 'روان‌شناختی', 'ماوراء طبیعی'];
const DAYS = ['شنبه', 'یکشنبه', 'دوشنبه', 'سه‌شنبه', 'چهارشنبه', 'پنجشنبه', 'جمعه'];

interface Upload {
  id: number;
  name: string;
  size: number;
  url?: string;
}

/** Title info + chapter upload. Files stay in the browser (object URLs) until a real upload endpoint exists. */
export function TitleEditor({ titleId }: { titleId: string }) {
  const title = useStore((s) => s.titles.find((t) => t.id === titleId));
  const chapters = useStore((s) => s.chapters[titleId] ?? []);
  const freeChapters = useStore((s) => s.settings.freeChapters);
  const toast = useToast();

  const [info, setInfo] = useState<Title | null>(null);
  const [adding, setAdding] = useState(false);
  const [lang, setLang] = useState<Lang>('fa');
  const [number, setNumber] = useState('');
  const [chTitle, setChTitle] = useState('');
  const [when, setWhen] = useState('');
  const [files, setFiles] = useState<Upload[]>([]);
  const [drag, setDrag] = useState(false);
  const [err, setErr] = useState('');
  const idSeq = useRef(0);
  const input = useRef<HTMLInputElement>(null);

  useEffect(() => {
    if (title && !info) {
      setInfo(title);
      setNumber(String(title.chapters + 1));
    }
  }, [title, info]);
  useEffect(() => () => files.forEach((f) => f.url && URL.revokeObjectURL(f.url)), []); // eslint-disable-line react-hooks/exhaustive-deps

  if (!title || !info) return <p className="muted" role="status">اثر پیدا نشد.</p>;

  const totalMb = files.reduce((a, f) => a + f.size, 0) / 1048576;
  const num = Number(number);
  const isFree = Number.isInteger(num) && num >= 1 && num <= freeChapters;

  const addFiles = (list: FileList | null) => {
    if (!list) return;
    const next: Upload[] = [];
    for (const f of Array.from(list)) {
      const ok = /\.(zip|jpe?g|png|webp)$/i.test(f.name);
      if (!ok) { setErr(`«${f.name}» پذیرفته نشد؛ فقط ZIP، JPG، PNG یا WEBP.`); continue; }
      next.push({ id: ++idSeq.current, name: f.name, size: f.size, url: f.type.startsWith('image/') ? URL.createObjectURL(f) : undefined });
    }
    // Pages follow the file-name order unless the editor reorders them.
    const merged = [...files, ...next].sort((a, b) => a.name.localeCompare(b.name, undefined, { numeric: true }));
    if (merged.reduce((a, f) => a + f.size, 0) / 1048576 > MAX_MB) { setErr(`حجم کل بیش از ${faDigits(MAX_MB)} مگابایت است.`); return; }
    if (next.length) setErr('');
    setFiles(merged);
  };

  const removeFile = (id: number) => setFiles((fs) => fs.filter((f) => { if (f.id === id && f.url) URL.revokeObjectURL(f.url); return f.id !== id; }));

  const saveInfo = () => {
    if (info.nameFa.trim().length < 2 || info.nameEn.trim().length < 2) return setErr('نام فارسی و انگلیسی نباید خالی باشد.');
    setErr('');
    updateTitle(titleId, { nameFa: info.nameFa.trim(), nameEn: info.nameEn.trim(), type: info.type, status: info.status, author: info.author, weekday: info.weekday, genres: info.genres, summary: info.summary });
    toast('پیش‌نویس ذخیره شد');
  };

  const schedule = () => {
    if (!Number.isInteger(num) || num < 1) return setErr('شمارهٔ چپتر باید یک عدد صحیح مثبت باشد.');
    if (!files.length) return setErr('حداقل یک فایل صفحه یا یک ZIP را اضافه کنید.');
    setErr('');
    const iso = when ? new Date(when).toISOString() : undefined;
    const pages = files.length === 1 && /\.zip$/i.test(files[0].name) ? 0 : files.length;
    addChapter(titleId, { number: num, titleEn: chTitle || `Chapter ${num}`, langs: [lang], scheduledAt: iso, pages });
    toast(iso ? 'انتشار زمان‌بندی شد' : 'چپتر ذخیره شد');
    setFiles([]);
    setChTitle('');
    setNumber(String(Math.max(title.chapters, num) + 1));
  };

  const toggleGenre = (g: string) => setInfo({ ...info, genres: info.genres.includes(g) ? info.genres.filter((x) => x !== g) : [...info.genres, g] });

  return (
    <>
      <PageHead
        title="ویرایش اثر و آپلود چپتر"
        crumbs={<><Link href="/titles">آثار</Link> › {title.nameFa}</>}
      >
        <Button onClick={saveInfo}>ذخیره پیش‌نویس</Button>
        <Button variant="primary" onClick={() => { setAdding(true); document.getElementById('upload-card')?.scrollIntoView({ behavior: 'smooth' }); }}>زمان‌بندی انتشار</Button>
      </PageHead>
      {err && <p className="err card" role="alert" style={{ marginBottom: 'var(--space-4)' }}>{err}</p>}

      <div className="grid" style={{ gridTemplateColumns: 'minmax(0,1fr) minmax(0,1.6fr)', alignItems: 'start' }}>
        <section className="card stack" aria-labelledby="info">
          <h2 id="info">اطلاعات اثر</h2>
          <div className="row" style={{ alignItems: 'flex-start', flexWrap: 'nowrap' }}>
            <div className="stack" style={{ flex: 1 }}>
              <Field label="نام فارسی">{(id) => <input id={id} className="input" value={info.nameFa} onChange={(e) => setInfo({ ...info, nameFa: e.target.value })} />}</Field>
              <Field label="نام انگلیسی">{(id) => <input id={id} className="input" style={{ direction: 'ltr', textAlign: 'left' }} value={info.nameEn} onChange={(e) => setInfo({ ...info, nameEn: e.target.value })} />}</Field>
            </div>
            <button type="button" className="cover" style={{ width: 110, height: 150, border: 0, color: 'var(--text-muted)', fontSize: 12 }} onClick={() => toast('آپلود کاور با اتصال به بک‌اند فعال می‌شود')}>
              <Icon name="image" size={22} /><br />تغییر کاور
            </button>
          </div>
          <div className="grid g2">
            <Field label="نوع">{(id) => <select id={id} className="select" value={info.type} onChange={(e) => setInfo({ ...info, type: e.target.value as WorkType })}><option value="manga">مانگا</option><option value="manhwa">مانهوا</option><option value="comic">کامیک</option></select>}</Field>
            <Field label="وضعیت">{(id) => <select id={id} className="select" value={info.status} onChange={(e) => setInfo({ ...info, status: e.target.value as Title['status'] })}><option value="ongoing">در حال انتشار</option><option value="finished">تمام‌شده</option><option value="draft">پیش‌نویس</option></select>}</Field>
            <Field label="نویسنده / تصویرگر">{(id) => <input id={id} className="input" value={info.author} onChange={(e) => setInfo({ ...info, author: e.target.value })} />}</Field>
            <Field label="روز انتشار هفتگی">{(id) => <select id={id} className="select" value={info.weekday} onChange={(e) => setInfo({ ...info, weekday: e.target.value })}>{DAYS.map((d) => <option key={d}>{d}</option>)}</select>}</Field>
          </div>
          <div className="field">
            <span className="lbl">ژانرها</span>
            <div className="row" style={{ gap: 6 }}>
              {GENRES.map((g) => (
                <button key={g} type="button" className="chip" aria-pressed={info.genres.includes(g)} onClick={() => toggleGenre(g)}>{g}</button>
              ))}
            </div>
          </div>
          <Field label="خلاصهٔ داستان">{(id) => <textarea id={id} className="textarea" style={{ minHeight: 160 }} value={info.summary} onChange={(e) => setInfo({ ...info, summary: e.target.value })} />}</Field>
        </section>

        <div className="stack">
          <section className="card stack" id="upload-card" aria-labelledby="up" data-open={adding}>
            <div className="card-head">
              <h2 id="up">آپلود چپتر جدید</h2>
              <Segmented label="زبان چپتر" value={lang} onChange={setLang} items={[{ id: 'fa', label: 'فارسی' }, { id: 'en', label: 'انگلیسی' }]} />
            </div>
            <div className="grid g4" style={{ gridTemplateColumns: '1fr 2fr 1.4fr 1fr' }}>
              <Field label="شمارهٔ چپتر">{(id) => <input id={id} className="input" inputMode="numeric" value={number} onChange={(e) => setNumber(e.target.value.replace(/\D/g, ''))} />}</Field>
              <Field label="عنوان چپتر">{(id) => <input id={id} className="input" style={{ direction: 'ltr', textAlign: 'left' }} placeholder="e.g. Chapter title" value={chTitle} onChange={(e) => setChTitle(e.target.value)} />}</Field>
              <Field label="زمان انتشار">{(id) => <input id={id} className="input" type="datetime-local" value={when} onChange={(e) => setWhen(e.target.value)} />}</Field>
              <Field label="دسترسی">{(id) => <select id={id} className="select" value={isFree ? 'free' : 'sub'} disabled={isFree} onChange={() => {}}><option value="sub">فقط مشترکین</option><option value="free">رایگان ({faDigits(freeChapters)} چپتر اول)</option></select>}</Field>
            </div>
            <div
              className={`dropzone ${drag ? 'drag' : ''}`}
              onDragOver={(e) => { e.preventDefault(); setDrag(true); }}
              onDragLeave={() => setDrag(false)}
              onDrop={(e) => { e.preventDefault(); setDrag(false); addFiles(e.dataTransfer.files); }}
            >
              <Icon name="upload" size={28} />
              <div style={{ flex: 1 }}>
                <b>تصاویر صفحات یا فایل ZIP را اینجا رها کنید</b>
                <p className="sub">JPG، PNG، WEBP · ترتیب بر اساس نام فایل · حداکثر {faDigits(MAX_MB)} مگابایت</p>
              </div>
              <Button variant="primary" onClick={() => input.current?.click()}>انتخاب فایل</Button>
              <input ref={input} type="file" multiple accept=".zip,.jpg,.jpeg,.png,.webp,image/*" hidden aria-label="انتخاب فایل صفحات" onChange={(e) => { addFiles(e.target.files); e.target.value = ''; }} />
            </div>
            {files.length > 0 && (
              <>
                <p className="sub" aria-live="polite">{faDigits(files.length)} فایل بارگذاری شد · ترتیب نمایش بر اساس نام فایل · {faDigits(totalMb.toFixed(1).replace('.', '٫'))} مگابایت</p>
                <div className="thumbs">
                  {files.map((f, i) => (
                    <div className="thumb" key={f.id} title={f.name}>
                      {f.url ? <img src={f.url} alt={`صفحه ${faDigits(i + 1)}`} /> : <span>{faDigits(i + 1)}<br />ZIP</span>}
                      <button type="button" aria-label={`حذف ${f.name}`} onClick={() => removeFile(f.id)}><Icon name="x" size={12} /></button>
                    </div>
                  ))}
                </div>
                <div className="row"><Button variant="primary" onClick={schedule}>{when ? 'زمان‌بندی انتشار' : 'ذخیرهٔ چپتر'}</Button></div>
              </>
            )}
          </section>

          <section className="card flush" aria-labelledby="chs">
            <h2 id="chs" style={{ padding: 'var(--space-5) var(--space-5) 0' }}>چپترهای این اثر</h2>
            <div className="table-wrap">
              <table className="t">
                <thead><tr><th>شماره</th><th>عنوان</th><th>زبان‌ها</th><th>تاریخ</th><th>بازدید</th><th>نظرات</th><th /></tr></thead>
                <tbody>
                  {chapters.map((c) => (
                    <tr key={c.id}>
                      <td><b style={{ color: 'var(--red-400)' }} className="ltr">#{c.number}</b></td>
                      <td><span className="ltr">{c.titleEn}</span></td>
                      <td><span className="ltr">{langsText(c.langs)}</span></td>
                      <td>{jalaliNumeric(c.date)}</td>
                      <td>{faNumber(c.views)}</td>
                      <td>{faNumber(c.comments)}</td>
                      <td><Badge kind="neutral">منتشرشده</Badge></td>
                    </tr>
                  ))}
                </tbody>
              </table>
              {chapters.length === 0 && <p className="muted" style={{ padding: 'var(--space-5)' }}>هنوز چپتری برای این اثر ثبت نشده.</p>}
            </div>
          </section>
        </div>
      </div>
    </>
  );
}
