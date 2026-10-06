/** Persian digits, grouping and Jalali dates. Latin text (emails, codes, English titles) must not pass through these. */
const FA = '۰۱۲۳۴۵۶۷۸۹';

export const faDigits = (v: string | number): string => String(v).replace(/\d/g, (d) => FA[Number(d)]);

/** 1234567 → ۱,۲۳۴,۵۶۷ (design shows the Latin comma between Persian digits). */
export const faNumber = (n: number): string => faDigits(Math.round(n).toString().replace(/\B(?=(\d{3})+(?!\d))/g, ','));

export const faPercent = (n: number, digits = 1): string => `${faDigits(n.toFixed(digits).replace('.', '٫'))}٪`;

const MONTHS = ['فروردین', 'اردیبهشت', 'خرداد', 'تیر', 'مرداد', 'شهریور', 'مهر', 'آبان', 'آذر', 'دی', 'بهمن', 'اسفند'];
export const jalaliMonths = MONTHS;

/** Gregorian → Jalali (algorithm of jalaali-js). */
export function toJalali(d: Date): { y: number; m: number; d: number } {
  const gy = d.getFullYear(), gm = d.getMonth() + 1, gd = d.getDate();
  const gdm = [0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334];
  const gy2 = gm > 2 ? gy + 1 : gy;
  let days = 355666 + 365 * gy + Math.floor((gy2 + 3) / 4) - Math.floor((gy2 + 99) / 100) + Math.floor((gy2 + 399) / 400) + gd + gdm[gm - 1];
  let jy = -1595 + 33 * Math.floor(days / 12053);
  days %= 12053;
  jy += 4 * Math.floor(days / 1461);
  days %= 1461;
  if (days > 365) {
    jy += Math.floor((days - 1) / 365);
    days = (days - 1) % 365;
  }
  const jm = days < 186 ? 1 + Math.floor(days / 31) : 7 + Math.floor((days - 186) / 30);
  const jd = 1 + (days < 186 ? days % 31 : (days - 186) % 30);
  return { y: jy, m: jm, d: jd };
}

/** ۶ مهر ۱۴۰۵ */
export function jalaliDate(iso: string | Date): string {
  const j = toJalali(new Date(iso));
  return `${faDigits(j.d)} ${MONTHS[j.m - 1]} ${faDigits(j.y)}`;
}

/** ۱۴۰۵/۰۷/۰۶ */
export function jalaliNumeric(iso: string | Date): string {
  const j = toJalali(new Date(iso));
  return faDigits(`${j.y}/${String(j.m).padStart(2, '0')}/${String(j.d).padStart(2, '0')}`);
}

export function clock(iso: string | Date): string {
  const d = new Date(iso);
  return faDigits(`${String(d.getHours()).padStart(2, '0')}:${String(d.getMinutes()).padStart(2, '0')}`);
}

/** The mock "now" (۶ مهر ۱۴۰۵، ۲۱:۴۰) so seeded relative times stay stable. */
export const NOW = new Date('2026-09-28T21:40:00');

/** «۱۰ دقیقه پیش», «دیروز», «۲ روز پیش» relative to [NOW]. */
export function relative(iso: string | Date, now: Date = NOW): string {
  const mins = Math.round((now.getTime() - new Date(iso).getTime()) / 60000);
  if (mins < 1) return 'همین الان';
  if (mins < 60) return `${faDigits(mins)} دقیقه پیش`;
  if (mins < 1440) return `${faDigits(Math.floor(mins / 60))} ساعت پیش`;
  const days = Math.floor(mins / 1440);
  if (days === 1) return 'دیروز';
  if (days < 7) return `${faDigits(days)} روز پیش`;
  if (days < 30) return `${faDigits(Math.floor(days / 7))} هفته پیش`;
  return `${faDigits(Math.floor(days / 30))} ماه پیش`;
}

/** RFC 4180 CSV with a BOM so Excel reads Persian text correctly. */
export function toCsv(rows: (string | number)[][]): string {
  const esc = (v: string | number) => `"${String(v).replace(/"/g, '""')}"`;
  return '﻿' + rows.map((r) => r.map(esc).join(',')).join('\r\n');
}

export function downloadCsv(name: string, rows: (string | number)[][]): void {
  const url = URL.createObjectURL(new Blob([toCsv(rows)], { type: 'text/csv;charset=utf-8' }));
  const a = document.createElement('a');
  a.href = url;
  a.download = name;
  a.click();
  URL.revokeObjectURL(url);
}
