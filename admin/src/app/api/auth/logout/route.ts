import { NextResponse } from 'next/server';
import { PENDING_COOKIE, SESSION_COOKIE, cookieOptions } from '@/server/auth';

export const dynamic = 'force-dynamic';

export async function POST() {
  const res = NextResponse.json({ ok: true });
  res.cookies.set(SESSION_COOKIE, '', cookieOptions(0));
  res.cookies.set(PENDING_COOKIE, '', cookieOptions(0));
  return res;
}
