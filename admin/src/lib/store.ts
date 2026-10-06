'use client';

import { useSyncExternalStore } from 'react';
import { faDigits, NOW } from './format';
import { seedAudit, seedChapters, seedComments, seedCoupons, seedMembers, seedPermissions, seedPlans, seedRequests, seedSent, seedTasks, seedTitles, seedTransactions, seedUsers } from './seed';
import type { AuditEntry, AuditSection, ChapterItem, CommentItem, Coupon, Member, Permission, Plan, Role, SentNotification, Task, TaskColumn, Title, TitleRequest, Transaction, User } from './types';

export interface Settings {
  freeChapters: number;
  maxDevices: number;
  autoRenewDefault: boolean;
  supportEmail: string;
  twoFactorRequired: boolean;
  gateways: { name: string; active: boolean }[];
}

export interface Automation {
  hideAfterReports: boolean;
  blockLinks: boolean;
  manualApprove: boolean;
  filterWords: string[];
}

export interface Session {
  name: string;
  email: string;
  role: Role;
}

export interface State {
  titles: Title[];
  chapters: Record<string, ChapterItem[]>;
  tasks: Task[];
  requests: TitleRequest[];
  users: User[];
  plans: Plan[];
  coupons: Coupon[];
  transactions: Transaction[];
  comments: CommentItem[];
  sent: SentNotification[];
  audit: AuditEntry[];
  members: Member[];
  permissions: Record<Permission, Role[]>;
  settings: Settings;
  automation: Automation;
  session: Session | null;
  /** First login step passed; waiting for the authenticator code. */
}

export function initialState(): State {
  return {
    titles: structuredClone(seedTitles),
    chapters: Object.fromEntries(seedTitles.map((t) => [t.id, seedChapters(t.id)])),
    tasks: structuredClone(seedTasks),
    requests: structuredClone(seedRequests),
    users: structuredClone(seedUsers),
    plans: structuredClone(seedPlans),
    coupons: structuredClone(seedCoupons),
    transactions: structuredClone(seedTransactions),
    comments: structuredClone(seedComments),
    sent: structuredClone(seedSent),
    audit: structuredClone(seedAudit),
    members: structuredClone(seedMembers),
    permissions: structuredClone(seedPermissions),
    settings: { freeChapters: 3, maxDevices: 2, autoRenewDefault: true, supportEmail: '[ایمیل پشتیبانی]', twoFactorRequired: true, gateways: [{ name: '[درگاه ۱]', active: true }, { name: '[درگاه ۲]', active: true }] },
    automation: { hideAfterReports: true, blockLinks: true, manualApprove: false, filterWords: ['[کلمه ۱]', '[کلمه ۲]', 'لینک تبلیغاتی'] },
    session: null,
  };
}

const KEY = 'miko_admin_state_v1';
const listeners = new Set<() => void>();
let state: State = initialState();
let hydrated = false;
const SERVER = initialState();

function persist() {
  try {
    sessionStorage.setItem(KEY, JSON.stringify(state));
  } catch {
    /* storage can be blocked; the panel keeps working in memory */
  }
}

/** Loads the saved state after mount (never during the first render: avoids hydration mismatches). */
export function hydrate(): void {
  if (hydrated || typeof window === 'undefined') return;
  hydrated = true;
  try {
    const raw = sessionStorage.getItem(KEY);
    if (raw) {
      state = { ...initialState(), ...(JSON.parse(raw) as State) };
      listeners.forEach((l) => l());
    }
  } catch {
    /* ignore corrupt storage */
  }
}

/** Test helper. */
export function resetStore(): void {
  state = initialState();
  hydrated = true;
  try {
    sessionStorage.removeItem(KEY);
  } catch {}
  listeners.forEach((l) => l());
}

export function getState(): State {
  return state;
}

function set(fn: (s: State) => State) {
  state = fn(state);
  persist();
  listeners.forEach((l) => l());
}

export function useStore<T>(selector: (s: State) => T): T {
  return useSyncExternalStore(
    (cb) => {
      listeners.add(cb);
      return () => listeners.delete(cb);
    },
    () => selector(state),
    () => selector(SERVER),
  );
}

let idSeq = 1000;
const nid = (p: string) => `${p}${++idSeq}`;

function log(s: State, section: AuditSection, action: string): State {
  const entry: AuditEntry = { id: nid('a'), when: NOW.toISOString(), member: s.session?.name ?? 'سیستم', section, action, device: 'این دستگاه' };
  return { ...s, audit: [entry, ...s.audit] };
}

// ---- auth (real auth lives on the server: see src/server/auth.ts and /api/auth/*) ----

/** Mirrors the server session into the UI store. Only the server cookie grants access. */
export function setSession(session: Session | null, audit = false): void {
  set((s) => {
    const next = { ...s, session };
    return audit && session ? log(next, 'settings', 'وارد پنل شد (ورود دومرحله‌ای)') : next;
  });
}

export async function loadSession(): Promise<Session | null> {
  try {
    const r = await fetch('/api/auth/me', { cache: 'no-store' });
    const session = r.ok ? ((await r.json()) as { session: Session | null }).session : null;
    if (JSON.stringify(session) !== JSON.stringify(state.session)) setSession(session);
    return session;
  } catch {
    return state.session;
  }
}

export type AuthResult = 'ok' | 'invalid' | 'locked' | 'expired' | 'unavailable';

async function post(url: string, body?: unknown): Promise<{ status: number }> {
  try {
    const r = await fetch(url, { method: 'POST', headers: { 'content-type': 'application/json' }, body: body ? JSON.stringify(body) : undefined });
    return { status: r.status };
  } catch {
    return { status: 0 };
  }
}

const toResult = (status: number): AuthResult => (status === 200 ? 'ok' : status === 401 ? 'invalid' : status === 429 ? 'locked' : status === 410 ? 'expired' : 'unavailable');

export async function loginStep1(email: string, password: string): Promise<AuthResult> {
  return toResult((await post('/api/auth/login', { email, password })).status);
}

export async function loginStep2(code: string): Promise<AuthResult> {
  const { status } = await post('/api/auth/totp', { code });
  if (status === 200) {
    await loadSession();
    setSession(state.session, true);
    return 'ok';
  }
  return toResult(status);
}

export async function logout(): Promise<void> {
  set((s) => log({ ...s, session: null }, 'settings', 'از پنل خارج شد'));
  await post('/api/auth/logout');
}

// ---- titles ----

export function addTitle(t: Partial<Title> & Pick<Title, 'nameFa' | 'nameEn' | 'type'>): string {
  const id = t.nameEn.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '') || nid('title');
  const title: Title = { status: 'draft', genres: [], langs: [], chapters: 0, views: 0, rating: null, updatedAt: NOW.toISOString(), author: '', weekday: 'دوشنبه', summary: '', ...t, id };
  set((s) => log({ ...s, titles: [title, ...s.titles], chapters: { ...s.chapters, [id]: [] } }, 'content', `اثر «${title.nameFa}» را ایجاد کرد`));
  return id;
}

export function updateTitle(id: string, patch: Partial<Title>): void {
  set((s) => {
    const cur = s.titles.find((t) => t.id === id);
    return log({ ...s, titles: s.titles.map((t) => (t.id === id ? { ...t, ...patch, updatedAt: NOW.toISOString() } : t)) }, 'content', `اطلاعات «${cur?.nameFa ?? id}» را ویرایش کرد`);
  });
}

export function deleteTitle(id: string): void {
  set((s) => {
    const cur = s.titles.find((t) => t.id === id);
    return log({ ...s, titles: s.titles.filter((t) => t.id !== id) }, 'content', `اثر «${cur?.nameFa ?? id}» را حذف کرد`);
  });
}

export function addChapter(titleId: string, c: { number: number; titleEn: string; langs: ChapterItem['langs']; scheduledAt?: string; pages: number }): void {
  set((s) => {
    const t = s.titles.find((x) => x.id === titleId);
    if (!t) return s;
    const item: ChapterItem = { id: `${titleId}~${c.number}`, titleId, number: c.number, titleEn: c.titleEn, date: c.scheduledAt ?? NOW.toISOString(), langs: c.langs, views: 0, comments: 0 };
    const list = [item, ...(s.chapters[titleId] ?? []).filter((x) => x.number !== c.number)].sort((a, b) => b.number - a.number);
    const next = {
      ...s,
      chapters: { ...s.chapters, [titleId]: list },
      titles: s.titles.map((x) => (x.id === titleId ? { ...x, chapters: Math.max(x.chapters, c.number), status: x.status === 'draft' ? 'ongoing' : x.status, langs: Array.from(new Set([...x.langs, ...c.langs])), updatedAt: NOW.toISOString() } : x)),
    } satisfies State;
    return log(next, 'content', `${faDigits(c.pages)} صفحه چپتر ${faDigits(c.number)} «${t.nameFa}» را ${c.scheduledAt ? 'زمان‌بندی' : 'آپلود'} کرد`);
  });
}

// ---- translation flow ----

export const COLUMN_ORDER: TaskColumn[] = ['waiting', 'translating', 'review', 'ready'];

export function moveTask(id: string, column: TaskColumn): void {
  set((s) => {
    const task = s.tasks.find((t) => t.id === id);
    if (!task || task.column === column) return s;
    return log({ ...s, tasks: s.tasks.map((t) => (t.id === id ? { ...t, column } : t)) }, 'content', `کار «${task.titleName} ${faDigits(task.chapter)}» را به مرحلهٔ بعد برد`);
  });
}

export function addTask(t: { titleName: string; chapter: number; direction: string; assignee: string; due: string }): void {
  set((s) => log({ ...s, tasks: [...s.tasks, { id: nid('k'), column: 'waiting', ...t }] }, 'content', `کار ترجمهٔ «${t.titleName} ${faDigits(t.chapter)}» را ثبت کرد`));
}

// ---- requests ----

export function acceptRequest(id: string): void {
  set((s) => {
    const r = s.requests.find((x) => x.id === id);
    if (!r || r.publishRight !== 'has') return s;
    const tid = r.nameEn.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '');
    const title: Title = { id: tid, nameFa: `[${r.nameEn}]`, nameEn: r.nameEn, type: r.type, status: 'draft', genres: [], langs: [], chapters: 0, views: 0, rating: null, updatedAt: NOW.toISOString(), author: '', weekday: 'دوشنبه', summary: '' };
    return log({ ...s, requests: s.requests.map((x) => (x.id === id ? { ...x, status: 'added' } : x)), titles: [title, ...s.titles], chapters: { ...s.chapters, [tid]: [] } }, 'content', `درخواست «${r.nameEn}» را به آثار (پیش‌نویس) اضافه کرد`);
  });
}

export function rejectRequest(id: string): void {
  set((s) => {
    const r = s.requests.find((x) => x.id === id);
    return log({ ...s, requests: s.requests.map((x) => (x.id === id ? { ...x, status: 'rejected' } : x)) }, 'content', `درخواست «${r?.nameEn ?? id}» را رد کرد و به رأی‌دهندگان اطلاع داد`);
  });
}

// ---- users ----

export function addSubscriptionDays(id: string, days: number): void {
  set((s) => {
    const u = s.users.find((x) => x.id === id);
    if (!u) return s;
    return log({ ...s, users: s.users.map((x) => (x.id === id ? { ...x, endsIn: (x.endsIn ?? 0) + days, status: x.status === 'blocked' ? 'blocked' : 'active', plan: x.plan ?? 'هدیه' } : x)) }, 'users', `${faDigits(days)} روز اشتراک به «${u.name}» اضافه کرد`);
  });
}

export function setBlocked(id: string, blocked: boolean): void {
  set((s) => {
    const u = s.users.find((x) => x.id === id);
    if (!u) return s;
    const status: User['status'] = blocked ? 'blocked' : u.plan ? (u.endsIn !== null && u.endsIn < 0 ? 'expired' : 'active') : 'free';
    return log({ ...s, users: s.users.map((x) => (x.id === id ? { ...x, status } : x)) }, 'users', `کاربر «${u.name}» را ${blocked ? 'مسدود' : 'رفع مسدودی'} کرد`);
  });
}

export function addUserNote(id: string, text: string): void {
  set((s) => log({ ...s, users: s.users.map((x) => (x.id === id ? { ...x, notes: [...x.notes, { text, by: s.session?.name ?? '—', when: NOW.toISOString() }] } : x)) }, 'users', 'یادداشت داخلی برای کاربر ثبت کرد'));
}

export function logoutAllDevices(id: string): void {
  set((s) => log({ ...s, users: s.users.map((x) => (x.id === id ? { ...x, devices: x.devices.map((d) => ({ ...d, online: false })) } : x)) }, 'users', 'کاربر را از همهٔ دستگاه‌ها خارج کرد'));
}

// ---- payments ----

export function updatePlan(id: string, patch: Partial<Plan>): void {
  set((s) => log({ ...s, plans: s.plans.map((p) => (p.id === id ? { ...p, ...patch } : p)) }, 'payment', `طرح «${s.plans.find((p) => p.id === id)?.name}» را ویرایش کرد`));
}

export function addPlan(p: Omit<Plan, 'id' | 'subscribers'>): void {
  set((s) => log({ ...s, plans: [...s.plans, { ...p, id: nid('plan'), subscribers: 0 }] }, 'payment', `طرح «${p.name}» را ساخت`));
}

export function addCoupon(code: string, note: string): void {
  set((s) => log({ ...s, coupons: [{ code: code.toUpperCase(), note, uses: 0, expired: false }, ...s.coupons] }, 'payment', `کد تخفیف ${code.toUpperCase()} را ساخت`));
}

// ---- comments ----

export function moderate(id: string, action: 'approve' | 'spoiler' | 'delete' | 'blockUser'): void {
  set((s) => {
    const c = s.comments.find((x) => x.id === id);
    if (!c) return s;
    const labels = { approve: 'تأیید و نگه داشت', spoiler: 'علامت اسپویل زد', delete: 'حذف کرد', blockUser: 'کاربر آن را مسدود کرد' } as const;
    const status: CommentItem['status'] = action === 'delete' ? 'deleted' : 'approved';
    const next = { ...s, comments: s.comments.map((x) => (x.id === id ? { ...x, status, tags: action === 'spoiler' && !x.tags.includes('spoiler') ? [...x.tags, 'spoiler' as const] : x.tags, reports: action === 'approve' ? 0 : x.reports } : x)) };
    return log(next, 'content', `نظر «${c.user}» در ${c.work} ${faDigits(c.chapter)} را ${labels[action]}`);
  });
}

export function setAutomation(patch: Partial<Automation>): void {
  set((s) => log({ ...s, automation: { ...s.automation, ...patch } }, 'settings', 'قوانین خودکار نظرات را تغییر داد'));
}

// ---- notify ----

export function sendNotification(n: Omit<SentNotification, 'id' | 'openRate' | 'when'> & { scheduled?: boolean }): void {
  set((s) => log({ ...s, sent: [{ id: nid('s'), title: n.title, audience: n.audience, channels: n.channels, sent: n.sent, openRate: 0, when: NOW.toISOString() }, ...s.sent] }, 'content', `اعلان «${n.title}» را برای ${n.audience} ${n.scheduled ? 'زمان‌بندی' : 'ارسال'} کرد`));
}

// ---- settings ----

export function setPermission(perm: Permission, role: Role, on: boolean): void {
  set((s) => {
    if (role === 'admin') return s; // the admin role always keeps every permission
    const cur = s.permissions[perm];
    const next = on ? Array.from(new Set([...cur, role])) : cur.filter((r) => r !== role);
    return log({ ...s, permissions: { ...s.permissions, [perm]: next } }, 'settings', `دسترسی «${perm}» را برای نقش ${on ? 'داد' : 'برداشت'}`);
  });
}

export function addMember(name: string, role: Role): void {
  set((s) => log({ ...s, members: [...s.members, { id: nid('m'), name, role, lastSeen: 'دعوت‌شده' }] }, 'settings', `عضو «${name}» را دعوت کرد`));
}

export function saveSettings(patch: Partial<Settings>): void {
  set((s) => log({ ...s, settings: { ...s.settings, ...patch } }, 'settings', 'تنظیمات را ذخیره کرد'));
}

export function setTheme(theme: 'dark' | 'light'): void {
  try {
    localStorage.setItem('miko_admin_theme', theme);
  } catch {}
  document.documentElement.dataset.theme = theme;
}
