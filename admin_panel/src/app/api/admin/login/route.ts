import { NextResponse } from 'next/server';
import { ADMIN_COOKIE_MAX_AGE, ADMIN_COOKIE_NAME, issueAdminToken, safeEqual } from '@/lib/auth';
import { clientIp, hitRateLimit } from '@/lib/rateLimit';

export async function POST(request: Request) {
  try {
    const limit = hitRateLimit(`admin-login:${clientIp(request)}`, 10, 15 * 60 * 1000);
    if (!limit.allowed) {
      return NextResponse.json(
        { error: 'Too many login attempts. Please wait and try again.' },
        { status: 429, headers: { 'Retry-After': String(limit.retryAfterSeconds) } }
      );
    }

    const { password } = await request.json();
    const correctPassword = process.env.ADMIN_PASSWORD;

    if (!correctPassword) {
      console.error('ADMIN_PASSWORD is not configured - admin login disabled.');
      return NextResponse.json({ error: 'Admin login is not configured on the server.' }, { status: 503 });
    }

    if (!password) {
      return NextResponse.json({ error: 'Password is required' }, { status: 400 });
    }

    if (!safeEqual(String(password), correctPassword)) {
      return NextResponse.json({ error: 'Incorrect administrator password' }, { status: 401 });
    }

    // Signed, HttpOnly session cookie (the password itself is never stored in the browser)
    const response = NextResponse.json({ success: true });
    response.cookies.set(ADMIN_COOKIE_NAME, issueAdminToken(), {
      httpOnly: true,
      secure: process.env.NODE_ENV === 'production',
      sameSite: 'lax',
      path: '/',
      maxAge: ADMIN_COOKIE_MAX_AGE,
    });
    return response;
  } catch (error: any) {
    console.error('Admin login API error:', error);
    return NextResponse.json({ error: 'Failed to process admin login' }, { status: 500 });
  }
}
