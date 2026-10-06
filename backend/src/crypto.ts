import { createHmac, randomBytes, randomInt, scryptSync, timingSafeEqual } from 'node:crypto';

export const newId = (): string => randomBytes(12).toString('hex');

export function hashPassword(password: string): string {
  const salt = randomBytes(16).toString('hex');
  return `scrypt$${salt}$${scryptSync(password, salt, 32).toString('hex')}`;
}

export function verifyPassword(password: string, stored: string): boolean {
  const [alg, salt, hash] = stored.split('$');
  if (alg !== 'scrypt' || !salt || !hash) return false;
  const a = scryptSync(password, salt, 32);
  const b = Buffer.from(hash, 'hex');
  return a.length === b.length && timingSafeEqual(a, b);
}

export const newCode = (): string => String(randomInt(0, 1_000_000)).padStart(6, '0');

export const hmac = (secret: string, data: string): string => createHmac('sha256', secret).update(data).digest('base64url');

export function safeEqual(a: string, b: string): boolean {
  const x = Buffer.from(a), y = Buffer.from(b);
  return x.length === y.length && timingSafeEqual(x, y);
}

/** Minimal HS256 JWT (header.payload.signature). */
export function signJwt(secret: string, sub: string, ttlSec: number, nowMs = Date.now()): string {
  const h = Buffer.from(JSON.stringify({ alg: 'HS256', typ: 'JWT' })).toString('base64url');
  const p = Buffer.from(JSON.stringify({ sub, exp: Math.floor(nowMs / 1000) + ttlSec })).toString('base64url');
  return `${h}.${p}.${hmac(secret, `${h}.${p}`)}`;
}

export function readJwt(secret: string, token: string, nowMs = Date.now()): string | null {
  const [h, p, s] = token.split('.');
  if (!h || !p || !s || !safeEqual(s, hmac(secret, `${h}.${p}`))) return null;
  try {
    const body = JSON.parse(Buffer.from(p, 'base64url').toString()) as { sub?: string; exp?: number };
    return body.sub && body.exp && body.exp * 1000 > nowMs ? body.sub : null;
  } catch {
    return null;
  }
}

/** Signed, expiring media URL (10 minutes). The storage layer verifies `sig` before serving. */
export function signMediaUrl(secret: string, path: string, userId: string, nowMs = Date.now(), ttlSec = 600): string {
  const exp = Math.floor(nowMs / 1000) + ttlSec;
  return `${path}?exp=${exp}&u=${userId}&sig=${hmac(secret, `${path}|${exp}|${userId}`)}`;
}
