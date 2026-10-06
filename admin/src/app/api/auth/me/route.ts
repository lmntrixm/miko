import { NextResponse } from 'next/server';
import { SESSION_COOKIE, getConfig, readToken } from '@/server/auth';

export const dynamic = 'force-dynamic';

export async function GET(req: Request) {
  const cfg = getConfig();
  const cookie = req.headers.get('cookie')?.match(new RegExp(`${SESSION_COOKIE}=([^;]+)`))?.[1];
  const sub = cfg && readToken(cfg.sessionSecret, cookie, 'session');
  if (!sub) return NextResponse.json({ session: null });
  return NextResponse.json({ session: { name: 'مدیر نمونه', email: sub, role: 'admin' } });
}
