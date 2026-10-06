import { createHmac, randomBytes, scryptSync, timingSafeEqual } from 'node:crypto';

/**
 * Server-side admin auth: scrypt password check, RFC 6238 TOTP, HMAC-signed httpOnly cookies.
 * Config comes from env (see .env.example). Without it the panel refuses to log in,
 * except in dev or with ADMIN_DEMO=1, where a clearly-labelled demo account is used.
 */

export const SESSION_COOKIE = 'miko_session';
export const PENDING_COOKIE = 'miko_pending';
export const SESSION_TTL = 8 * 3600;
export const PENDING_TTL = 5 * 60;

const DEMO = {
  email: 'admin@miko.test',
  password: 'password123',
  totpSecret: 'JBSWY3DPEHPK3PXP',
  sessionSecret: 'demo-only-session-secret-change-me-0000',
};

export type AuthConfig = { email: string; passwordHash: string; totpSecret: string; sessionSecret: string; demo: boolean };

export function hashPassword(password: string, salt = randomBytes(16).toString('hex')): string {
  return `scrypt$${salt}$${scryptSync(password, salt, 32).toString('hex')}`;
}

export function verifyPassword(password: string, stored: string): boolean {
  const [alg, salt, hash] = stored.split('$');
  if (alg !== 'scrypt' || !salt || !hash) return false;
  const a = scryptSync(password, salt, 32);
  const b = Buffer.from(hash, 'hex');
  return a.length === b.length && timingSafeEqual(a, b);
}

export function getConfig(env: NodeJS.ProcessEnv = process.env): AuthConfig | null {
  const { ADMIN_EMAIL, ADMIN_PASSWORD_HASH, ADMIN_TOTP_SECRET, SESSION_SECRET } = env;
  if (ADMIN_EMAIL && ADMIN_PASSWORD_HASH && ADMIN_TOTP_SECRET && SESSION_SECRET && SESSION_SECRET.length >= 32) {
    return { email: ADMIN_EMAIL.toLowerCase(), passwordHash: ADMIN_PASSWORD_HASH, totpSecret: ADMIN_TOTP_SECRET, sessionSecret: SESSION_SECRET, demo: false };
  }
  if (env.ADMIN_DEMO === '1' || env.NODE_ENV === 'development') {
    return { email: DEMO.email, passwordHash: hashPassword(DEMO.password, 'demo'), totpSecret: DEMO.totpSecret, sessionSecret: DEMO.sessionSecret, demo: true };
  }
  return null;
}

// ---- TOTP ----

const B32 = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';

export function base32Decode(s: string): Buffer {
  let bits = '';
  for (const ch of s.replace(/=+$/, '').replace(/\s/g, '').toUpperCase()) {
    const v = B32.indexOf(ch);
    if (v < 0) throw new Error('invalid base32');
    bits += v.toString(2).padStart(5, '0');
  }
  const bytes: number[] = [];
  for (let i = 0; i + 8 <= bits.length; i += 8) bytes.push(parseInt(bits.slice(i, i + 8), 2));
  return Buffer.from(bytes);
}

export function totp(secret: string, atMs = Date.now(), step = 30, digits = 6): string {
  const counter = Buffer.alloc(8);
  counter.writeBigUInt64BE(BigInt(Math.floor(atMs / 1000 / step)));
  const h = createHmac('sha1', base32Decode(secret)).update(counter).digest();
  const o = h[h.length - 1] & 0xf;
  const n = ((h[o] & 0x7f) << 24) | (h[o + 1] << 16) | (h[o + 2] << 8) | h[o + 3];
  return String(n % 10 ** digits).padStart(digits, '0');
}

/** Accepts the previous, current and next 30s window (clock drift). */
export function verifyTotp(secret: string, code: string, atMs = Date.now()): boolean {
  if (!/^\d{6}$/.test(code)) return false;
  return [-1, 0, 1].some((w) => {
    const a = Buffer.from(totp(secret, atMs + w * 30_000));
    return timingSafeEqual(a, Buffer.from(code));
  });
}

// ---- signed tokens ----

type Payload = { sub: string; kind: 'session' | 'pending'; exp: number };

const b64 = (b: Buffer | string) => Buffer.from(b).toString('base64url');

export function signToken(secret: string, kind: Payload['kind'], sub: string, ttlSec: number, nowMs = Date.now()): string {
  const body = b64(JSON.stringify({ sub, kind, exp: Math.floor(nowMs / 1000) + ttlSec } satisfies Payload));
  return `${body}.${b64(createHmac('sha256', secret).update(body).digest())}`;
}

export function readToken(secret: string, token: string | undefined, kind: Payload['kind'], nowMs = Date.now()): string | null {
  if (!token) return null;
  const [body, sig] = token.split('.');
  if (!body || !sig) return null;
  const want = createHmac('sha256', secret).update(body).digest();
  const got = Buffer.from(sig, 'base64url');
  if (want.length !== got.length || !timingSafeEqual(want, got)) return null;
  try {
    const p = JSON.parse(Buffer.from(body, 'base64url').toString()) as Payload;
    return p.kind === kind && p.exp * 1000 > nowMs ? p.sub : null;
  } catch {
    return null;
  }
}

// ---- rate limit (per process; use a shared store when running several instances) ----

const attempts = new Map<string, { n: number; until: number }>();
const MAX = 5;
const LOCK_MS = 15 * 60_000;

export function isLocked(key: string, now = Date.now()): boolean {
  const a = attempts.get(key);
  return !!a && a.n >= MAX && a.until > now;
}
export function recordFailure(key: string, now = Date.now()): void {
  const a = attempts.get(key);
  const n = a && a.until > now ? a.n + 1 : 1;
  attempts.set(key, { n, until: now + LOCK_MS });
}
export function clearFailures(key: string): void {
  attempts.delete(key);
}

export function cookieOptions(maxAge: number) {
  return { httpOnly: true, sameSite: 'strict' as const, secure: process.env.NODE_ENV === 'production' && process.env.INSECURE_COOKIES !== '1', path: '/', maxAge };
}

export function clientKey(req: Request): string {
  return (req.headers.get('x-forwarded-for') ?? 'local').split(',')[0].trim();
}
