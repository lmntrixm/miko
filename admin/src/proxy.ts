import { NextResponse, type NextRequest } from 'next/server';
import { SESSION_COOKIE, getConfig, readToken } from '@/server/auth';

/** Server-side gate: every page except /login needs a valid signed session cookie. */
export function proxy(req: NextRequest) {
  const cfg = getConfig();
  const ok = !!cfg && !!readToken(cfg.sessionSecret, req.cookies.get(SESSION_COOKIE)?.value, 'session');
  if (!ok) {
    const url = req.nextUrl.clone();
    url.pathname = '/login';
    url.search = '';
    return NextResponse.redirect(url);
  }
  return NextResponse.next();
}

export const config = {
  matcher: ['/((?!login|api/auth|_next|fonts|icon.svg|favicon.ico).*)'],
};
