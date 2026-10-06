import { NextResponse } from 'next/server';
import { PENDING_COOKIE, SESSION_COOKIE, SESSION_TTL, clearFailures, clientKey, cookieOptions, getConfig, isLocked, readToken, recordFailure, signToken, verifyTotp } from '@/server/auth';

export const dynamic = 'force-dynamic';

export async function POST(req: Request) {
  const cfg = getConfig();
  if (!cfg) return NextResponse.json({ error: 'not_configured' }, { status: 503 });
  const key = `otp:${clientKey(req)}`;
  if (isLocked(key)) return NextResponse.json({ error: 'locked' }, { status: 429 });
  const cookie = req.headers.get('cookie')?.match(new RegExp(`${PENDING_COOKIE}=([^;]+)`))?.[1];
  const sub = readToken(cfg.sessionSecret, cookie, 'pending');
  if (!sub) return NextResponse.json({ error: 'expired' }, { status: 410 });
  const body = (await req.json().catch(() => ({}))) as { code?: unknown };
  if (typeof body.code !== 'string' || !verifyTotp(cfg.totpSecret, body.code)) {
    recordFailure(key);
    return NextResponse.json({ error: 'invalid' }, { status: 401 });
  }
  clearFailures(key);
  const res = NextResponse.json({ ok: true, session: { name: 'مدیر نمونه', email: sub, role: 'admin' } });
  res.cookies.set(SESSION_COOKIE, signToken(cfg.sessionSecret, 'session', sub, SESSION_TTL), cookieOptions(SESSION_TTL));
  res.cookies.set(PENDING_COOKIE, '', cookieOptions(0));
  return res;
}
