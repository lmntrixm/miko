import { describe, expect, it } from 'vitest';
import { base32Decode, getConfig, hashPassword, isLocked, readToken, recordFailure, signToken, totp, verifyPassword, verifyTotp } from './auth';

describe('totp (RFC 6238 vector)', () => {
  const secret = 'GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ'; // "12345678901234567890"
  it('matches the SHA-1 test vector', () => {
    expect(base32Decode(secret).toString()).toBe('12345678901234567890');
    expect(totp(secret, 59_000, 30, 8)).toBe('94287082');
  });
  it('accepts one window of drift, not two', () => {
    const now = 1_700_000_000_000;
    expect(verifyTotp(secret, totp(secret, now), now + 30_000)).toBe(true);
    expect(verifyTotp(secret, totp(secret, now), now + 90_000)).toBe(false);
    expect(verifyTotp(secret, 'abcdef', now)).toBe(false);
  });
});

describe('password and tokens', () => {
  it('verifies scrypt hashes', () => {
    const h = hashPassword('s3cret');
    expect(verifyPassword('s3cret', h)).toBe(true);
    expect(verifyPassword('nope', h)).toBe(false);
    expect(verifyPassword('x', 'garbage')).toBe(false);
  });
  it('rejects tampered, expired and wrong-kind tokens', () => {
    const t = signToken('k'.repeat(32), 'session', 'a@b.c', 60, 0);
    expect(readToken('k'.repeat(32), t, 'session', 1000)).toBe('a@b.c');
    expect(readToken('k'.repeat(32), t, 'pending', 1000)).toBeNull();
    expect(readToken('k'.repeat(32), t, 'session', 61_000)).toBeNull();
    expect(readToken('z'.repeat(32), t, 'session', 1000)).toBeNull();
    expect(readToken('k'.repeat(32), t.replace(/.$/, 'A'), 'session', 1000)).toBeNull();
  });
  it('locks after 5 failures', () => {
    for (let i = 0; i < 5; i++) recordFailure('k1', 0);
    expect(isLocked('k1', 1000)).toBe(true);
    expect(isLocked('k1', 16 * 60_000)).toBe(false);
  });
  it('refuses to run in production without config', () => {
    expect(getConfig({ NODE_ENV: 'production' } as NodeJS.ProcessEnv)).toBeNull();
    expect(getConfig({ NODE_ENV: 'production', ADMIN_DEMO: '1' } as NodeJS.ProcessEnv)?.demo).toBe(true);
  });
});
