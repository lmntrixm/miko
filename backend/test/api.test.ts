import type { FastifyInstance } from 'fastify';
import { afterAll, beforeAll, describe, expect, it } from 'vitest';
import { buildApp, type Mailer } from '../src/app.js';
import { loadConfig } from '../src/config.js';
import { migrate, pgliteDb, type Db } from '../src/db.js';
import { seed } from '../src/seed.js';

let app: FastifyInstance;
let db: Db;
let clock = Date.UTC(2026, 9, 6);
const codes = new Map<string, string>();
const mailer: Mailer = { sendCode: async (e, c, p) => void codes.set(`${p}:${e}`, c) };

beforeAll(async () => {
  db = await pgliteDb();
  await migrate(db);
  await seed(db);
  app = await buildApp({ db, config: loadConfig({ FREE_MODE: '0' } as NodeJS.ProcessEnv), mailer, now: () => clock });
});
afterAll(async () => { await app.close(); await db.close(); });

const call = async (method: 'GET' | 'POST' | 'PUT' | 'PATCH' | 'DELETE', url: string, body?: unknown, token?: string) => {
  const r = await app.inject({ method, url, payload: body as object, headers: token ? { authorization: `Bearer ${token}` } : {} });
  return { status: r.statusCode, body: r.body ? JSON.parse(r.body) : null };
};

async function register(email: string, password = 'password123') {
  expect((await call('POST', '/v1/auth/signup', { name: 'کاربر آزمون', email, password })).status).toBe(200);
  const r = await call('POST', '/v1/auth/verify', { email, code: codes.get(`signup:${email}`) });
  expect(r.status).toBe(200);
  return r.body.token as string;
}

describe('auth', () => {
  it('signup → verify → me; login works; duplicate email is refused', async () => {
    const token = await register('a@example.test');
    expect((await call('GET', '/v1/me', undefined, token)).body.email).toBe('a@example.test');
    expect((await call('POST', '/v1/auth/login', { email: 'a@example.test', password: 'password123' })).status).toBe(200);
    expect((await call('POST', '/v1/auth/signup', { name: 'کاربر', email: 'a@example.test', password: 'password123' })).body.error.code).toBe('email_taken');
  });

  it('unverified accounts cannot log in; wrong code is counted and the 5th locks it', async () => {
    await call('POST', '/v1/auth/signup', { name: 'کاربر', email: 'b@example.test', password: 'password123' });
    expect((await call('POST', '/v1/auth/login', { email: 'b@example.test', password: 'password123' })).status).toBe(401);
    for (let i = 0; i < 4; i++) expect((await call('POST', '/v1/auth/verify', { email: 'b@example.test', code: '000000' })).body.error.code).toBe('code_wrong');
    expect((await call('POST', '/v1/auth/verify', { email: 'b@example.test', code: '000000' })).status).toBe(429);
    expect((await call('POST', '/v1/auth/verify', { email: 'b@example.test', code: codes.get('signup:b@example.test') })).body.error.code).toBe('code_expired');
  });

  it('codes expire after 10 minutes', async () => {
    await call('POST', '/v1/auth/signup', { name: 'کاربر', email: 'c@example.test', password: 'password123' });
    clock += 11 * 60_000;
    expect((await call('POST', '/v1/auth/verify', { email: 'c@example.test', code: codes.get('signup:c@example.test') })).body.error.code).toBe('code_expired');
  });

  it('login locks after 5 wrong passwords', async () => {
    await register('d@example.test');
    for (let i = 0; i < 5; i++) expect((await call('POST', '/v1/auth/login', { email: 'd@example.test', password: 'wrong-pass' })).status).toBe(401);
    expect((await call('POST', '/v1/auth/login', { email: 'd@example.test', password: 'password123' })).status).toBe(429);
  });

  it('password reset hides unknown emails and sets a new password', async () => {
    await register('e@example.test');
    expect((await call('POST', '/v1/auth/password/reset', { email: 'nobody@example.test' })).status).toBe(200);
    expect(codes.has('reset:nobody@example.test')).toBe(false);
    await call('POST', '/v1/auth/password/reset', { email: 'e@example.test' });
    expect((await call('POST', '/v1/auth/password/reset', { email: 'e@example.test', code: codes.get('reset:e@example.test'), password: 'brand-new-pass' })).status).toBe(200);
    expect((await call('POST', '/v1/auth/login', { email: 'e@example.test', password: 'brand-new-pass' })).status).toBe(200);
  });

  it('rejects missing/garbage tokens with 401 and a Persian message', async () => {
    const r = await call('GET', '/v1/me', undefined, 'garbage');
    expect(r.status).toBe(401);
    expect(r.body.error.message).toContain('نشست');
  });

  it('preferences, profile and account deletion', async () => {
    const t = await register('f@example.test');
    expect((await call('PUT', '/v1/me/preferences', { genres: ['اکشن'], language: 'both' }, t)).status).toBe(200);
    expect((await call('GET', '/v1/me', undefined, t)).body.genres).toEqual(['اکشن']);
    expect((await call('PATCH', '/v1/me', { password: 'another-pass-1', currentPassword: 'nope' }, t)).body.error.code).toBe('bad_current_password');
    expect((await call('DELETE', '/v1/me', { password: 'password123' }, t)).status).toBe(204);
    expect((await call('GET', '/v1/me', undefined, t)).status).toBe(401);
  });
});

describe('catalog', () => {
  it('lists, searches and filters by type with cursor paging', async () => {
    const all = await call('GET', '/v1/titles?limit=2');
    expect(all.body.items).toHaveLength(2);
    expect(all.body.nextCursor).toBeTruthy();
    const next = await call('GET', `/v1/titles?limit=2&after=${all.body.nextCursor}`);
    expect(next.body.items).toHaveLength(1);
    expect((await call('GET', '/v1/titles?type=comic')).body.items.map((t: { id: string }) => t.id)).toEqual(['sample-hero']);
    expect((await call('GET', '/v1/titles?q=' + encodeURIComponent('برج'))).body.items).toHaveLength(1);
    expect((await call('GET', '/v1/titles?type=nope')).status).toBe(400);
  });

  it('ranked, genres, plans (price stays null until decided)', async () => {
    expect((await call('GET', '/v1/titles/ranked')).body.items[0]).toMatchObject({ rank: 1, id: 'sample-tower' });
    expect((await call('GET', '/v1/genres')).body.items.length).toBeGreaterThan(0);
    expect((await call('GET', '/v1/plans')).body.items[0].priceToman).toBeNull();
  });

  it('chapter list marks everything past the 3rd as locked without a subscription', async () => {
    const r = await call('GET', '/v1/titles/sample-moon/chapters');
    expect(r.body.items.filter((c: { locked: boolean }) => !c.locked).map((c: { number: number }) => c.number).sort()).toEqual([1, 2, 3]);
    expect((await call('GET', '/v1/titles/missing')).status).toBe(404);
  });
});

describe('reading rules', () => {
  it('free chapters open, locked ones give 402, subscribers get signed pages', async () => {
    const t = await register('g@example.test');
    expect((await call('GET', '/v1/chapters/sample-moon-1/pages', undefined, t)).body.pages).toHaveLength(8);
    expect((await call('GET', '/v1/chapters/sample-moon-4/pages', undefined, t)).status).toBe(402);
    expect((await call('GET', '/v1/chapters/sample-moon-1/pages')).status).toBe(401);
    await db.query(`UPDATE users SET subscription_ends_at = $1 WHERE email = 'g@example.test'`, [new Date(clock + 86_400_000)]);
    const r = await call('GET', '/v1/chapters/sample-moon-4/pages', undefined, t);
    expect(r.status).toBe(200);
    expect(r.body.pages[0]).toMatch(/exp=\d+&u=.+&sig=/);
  });

  it('progress syncs and shows as read', async () => {
    const t = await register('h@example.test');
    expect((await call('PUT', '/v1/me/progress/sample-moon-1', { page: 99 }, t)).status).toBe(400);
    expect((await call('PUT', '/v1/me/progress/sample-moon-1', { page: 3 }, t)).status).toBe(200);
    const list = await call('GET', '/v1/titles/sample-moon/chapters', undefined, t);
    expect(list.body.items.find((c: { number: number }) => c.number === 1).read).toBe(true);
  });

  it('downloads need a subscription and stop at 2 devices (409)', async () => {
    const t = await register('i@example.test');
    const dl = (deviceId: string) => call('POST', '/v1/chapters/sample-moon-1/download', { deviceId, deviceName: 'گوشی' }, t);
    expect((await dl('device-aaaa')).status).toBe(402);
    await db.query(`UPDATE users SET subscription_ends_at = $1 WHERE email = 'i@example.test'`, [new Date(clock + 86_400_000)]);
    expect((await dl('device-aaaa')).status).toBe(200);
    expect((await dl('device-bbbb')).status).toBe(200);
    expect((await dl('device-aaaa')).status).toBe(200); // known device again: fine
    expect((await dl('device-cccc')).body.error.code).toBe('device_limit');
    expect((await call('DELETE', '/v1/me/devices/device-bbbb', undefined, t)).status).toBe(204);
    expect((await dl('device-cccc')).status).toBe(200);
  });
});

describe('free mode', () => {
  it('is on by default: locked chapters open and downloads need no subscription; /v1/config says so', async () => {
    const free = await buildApp({ db, config: loadConfig({} as NodeJS.ProcessEnv), mailer, now: () => clock });
    const t = await register('free@example.test');
    const h = { authorization: `Bearer ${t}` };
    expect((await free.inject({ method: 'GET', url: '/v1/config' })).json().freeMode).toBe(true);
    expect((await free.inject({ method: 'GET', url: '/v1/chapters/sample-moon-6/pages', headers: h })).statusCode).toBe(200);
    expect((await free.inject({ method: 'POST', url: '/v1/chapters/sample-moon-6/download', headers: h, payload: { deviceId: 'device-free1' } })).statusCode).toBe(200);
    const list = (await free.inject({ method: 'GET', url: '/v1/titles/sample-moon/chapters', headers: h })).json();
    expect(list.items.every((c: { locked: boolean }) => !c.locked)).toBe(true);
    // The 2-device limit still applies for free.
    await free.inject({ method: 'POST', url: '/v1/chapters/sample-moon-6/download', headers: h, payload: { deviceId: 'device-free2' } });
    expect((await free.inject({ method: 'POST', url: '/v1/chapters/sample-moon-6/download', headers: h, payload: { deviceId: 'device-free3' } })).statusCode).toBe(409);
    await free.close();
  });
});
