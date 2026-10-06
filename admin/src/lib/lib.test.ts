import { describe, expect, it } from 'vitest';
import { faDigits, faNumber, jalaliDate, jalaliNumeric, relative, toCsv, toJalali } from './format';
import { addTitle, getState, setSession, moderate, moveTask, resetStore, setPermission, addSubscriptionDays } from './store';

describe('format', () => {
  it('uses Persian digits and grouping', () => {
    expect(faDigits(242)).toBe('۲۴۲');
    expect(faNumber(1234567)).toBe('۱,۲۳۴,۵۶۷');
  });
  it('converts Gregorian to Jalali', () => {
    expect(toJalali(new Date(2026, 8, 28))).toEqual({ y: 1405, m: 7, d: 6 });
    expect(jalaliDate(new Date(2026, 8, 28))).toBe('۶ مهر ۱۴۰۵');
    expect(jalaliNumeric(new Date(2026, 2, 21))).toBe('۱۴۰۵/۰۱/۰۱');
  });
  it('relative time against the mock clock', () => {
    expect(relative('2026-09-28T21:30:00')).toBe('۱۰ دقیقه پیش');
    expect(relative('2026-09-27T20:00:00')).toBe('دیروز');
    expect(relative('2026-09-21T21:40:00')).toBe('۱ هفته پیش');
  });
  it('CSV is quoted, BOM-prefixed and escapes quotes', () => {
    expect(toCsv([['a"b', 1]])).toBe('﻿"a""b","1"');
  });
});

describe('store', () => {
  it('every mutation lands in the audit log', () => {
    resetStore();
    setSession({ name: 'مدیر نمونه', email: 'admin@miko.test', role: 'admin' });
    const before = getState().audit.length;
    const id = addTitle({ nameFa: 'آزمون', nameEn: 'Test Item', type: 'manga' });
    moveTask('k5', 'translating');
    moderate('c1', 'delete');
    addSubscriptionDays('u4', 7);
    expect(id).toBe('test-item');
    expect(getState().audit.length).toBe(before + 4);
    expect(getState().audit[0].action).toContain('۷ روز');
  });
  it('the admin role always keeps every permission', () => {
    resetStore();
    setPermission('مدیریت کاربران', 'admin', false);
    expect(getState().permissions['مدیریت کاربران']).toContain('admin');
    setPermission('مدیریت کاربران', 'editor', true);
    expect(getState().permissions['مدیریت کاربران']).toContain('editor');
  });
  it('adding days to a free user makes them active', () => {
    resetStore();
    addSubscriptionDays('u4', 30);
    const u = getState().users.find((x) => x.id === 'u4')!;
    expect(u.status).toBe('active');
    expect(u.endsIn).toBe(30);
  });
});
