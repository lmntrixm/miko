import { NextResponse } from 'next/server';
import { PENDING_COOKIE, PENDING_TTL, clearFailures, clientKey, cookieOptions, getConfig, isLocked, recordFailure, signToken, verifyPassword } from '@/server/auth';

export const dynamic = 'force-dynamic';

export async function POST(req: Request) {
  const cfg = getConfig();
  if (!cfg) return NextResponse.json({ error: 'not_configured' }, { status: 503 });
  const key = `pw:${clientKey(req)}`;
  if (isLocked(key)) return NextResponse.json({ error: 'locked' }, { status: 429 });
  const body = (await req.json().catch(() => ({}))) as { email?: unknown; password?: unknown };
  const email = typeof body.email === 'string' ? body.email.trim().toLowerCase() : '';
  const password = typeof body.password === 'string' ? body.password : '';
  // Always run the hash check so timing doesn't reveal whether the email exists.
  const okPw = verifyPassword(password, cfg.passwordHash);
  if (!okPw || email !== cfg.email) {
    recordFailure(key);
    return NextResponse.json({ error: 'invalid' }, { status: 401 });
  }
  clearFailures(key);
  const res = NextResponse.json({ ok: true, step: 'totp' });
  res.cookies.set(PENDING_COOKIE, signToken(cfg.sessionSecret, 'pending', cfg.email, PENDING_TTL), cookieOptions(PENDING_TTL));
  return res;
}
