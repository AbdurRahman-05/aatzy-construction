import crypto from 'crypto';
import { cookies } from 'next/headers';
import { NextResponse } from 'next/server';

/**
 * Stateless signed tokens (HS256 JWT) for:
 *  - app sessions (CONSUMER / PROVIDER)  -> sent by the Flutter app as `Authorization: Bearer <token>`
 *  - the admin panel session              -> HttpOnly `admin_session` cookie
 *  - "phone verified" proofs               -> returned by /api/auth/verify-otp, consumed by registration
 *
 * Required env:  AUTH_SECRET   (long random string, e.g. `openssl rand -hex 32`)
 * Optional env:  AUTH_ENFORCE  ("true" = reject app requests that carry no token)
 *
 * Rollout: while AUTH_ENFORCE is not "true", requests WITHOUT a token are still accepted so that
 * app versions already installed from the Play Store keep working. Requests WITH a token are always
 * verified and checked. Set AUTH_ENFORCE=true once most users have updated the app.
 */

export type AppRole = 'CONSUMER' | 'PROVIDER';

export interface AuthIdentity {
  id: string;
  role: AppRole;
}

/** `null` auth = legacy request without a token, allowed only while AUTH_ENFORCE is off. */
export type AuthResult =
  | { ok: true; auth: AuthIdentity | null }
  | { ok: false; response: NextResponse };

const SESSION_TTL_SECONDS = 60 * 60 * 24 * 90; // 90 days
const ADMIN_TTL_SECONDS = 60 * 60 * 24; // 1 day
const PHONE_PROOF_TTL_SECONDS = 60 * 30; // 30 minutes to finish registration after OTP

export const ADMIN_COOKIE_NAME = 'admin_session';
export const ADMIN_COOKIE_MAX_AGE = ADMIN_TTL_SECONDS;

let warnedDevSecret = false;

function getSecret(): string {
  const secret = process.env.AUTH_SECRET;
  if (secret && secret.length >= 32) return secret;

  if (process.env.NODE_ENV === 'production') {
    throw new Error('AUTH_SECRET is missing or shorter than 32 characters. Set it in the server environment.');
  }
  if (!warnedDevSecret) {
    console.warn('[auth] AUTH_SECRET not set - using an insecure development secret. Never deploy like this.');
    warnedDevSecret = true;
  }
  return 'dev-only-insecure-secret-change-me-dev-only-insecure';
}

export function isAuthEnforced(): boolean {
  return process.env.AUTH_ENFORCE === 'true';
}

// ---------------------------------------------------------------------------
// Token primitives
// ---------------------------------------------------------------------------

function b64url(input: Buffer | string): string {
  return Buffer.from(input).toString('base64url');
}

function hmac(data: string): string {
  return crypto.createHmac('sha256', getSecret()).update(data).digest('base64url');
}

function signToken(payload: Record<string, unknown>, ttlSeconds: number): string {
  const now = Math.floor(Date.now() / 1000);
  const header = b64url(JSON.stringify({ alg: 'HS256', typ: 'JWT' }));
  const body = b64url(JSON.stringify({ ...payload, iat: now, exp: now + ttlSeconds }));
  return `${header}.${body}.${hmac(`${header}.${body}`)}`;
}

interface TokenPayload {
  typ?: string;
  sub?: unknown;
  role?: unknown;
  phone?: unknown;
  exp?: unknown;
  iat?: unknown;
}

function verifyToken(token: string): TokenPayload | null {
  const parts = token.split('.');
  if (parts.length !== 3) return null;
  const [header, body, signature] = parts;

  const expected = Buffer.from(hmac(`${header}.${body}`));
  const actual = Buffer.from(signature);
  if (expected.length !== actual.length || !crypto.timingSafeEqual(expected, actual)) return null;

  try {
    const payload = JSON.parse(Buffer.from(body, 'base64url').toString('utf8'));
    if (typeof payload.exp !== 'number' || payload.exp < Math.floor(Date.now() / 1000)) return null;
    return payload;
  } catch {
    return null;
  }
}

/** Constant-time string comparison (for passwords / secrets). */
export function safeEqual(a: string, b: string): boolean {
  const ha = crypto.createHash('sha256').update(a).digest();
  const hb = crypto.createHash('sha256').update(b).digest();
  return crypto.timingSafeEqual(ha, hb);
}

// ---------------------------------------------------------------------------
// App session tokens
// ---------------------------------------------------------------------------

export function issueSessionToken(id: string, role: AppRole): string {
  return signToken({ typ: 'session', sub: id, role }, SESSION_TTL_SECONDS);
}

function authError(status: 401 | 403, code: string, error: string): NextResponse {
  return NextResponse.json({ error, code }, { status });
}

/**
 * Resolve who is calling. Optionally restrict to roles.
 * - valid token            -> { ok, auth }
 * - invalid/expired token  -> 401 AUTH_INVALID (always)
 * - no token               -> 401 AUTH_REQUIRED if enforced, otherwise { ok, auth: null } (legacy)
 */
export function requireAuth(request: Request, opts: { roles?: AppRole[] } = {}): AuthResult {
  const header = request.headers.get('authorization') || '';
  const match = header.match(/^Bearer\s+(.+)$/i);

  if (!match) {
    if (isAuthEnforced()) {
      return { ok: false, response: authError(401, 'AUTH_REQUIRED', 'Please log in again to continue.') };
    }
    return { ok: true, auth: null };
  }

  const payload = verifyToken(match[1].trim());
  if (!payload || payload.typ !== 'session' || typeof payload.sub !== 'string' ||
      (payload.role !== 'CONSUMER' && payload.role !== 'PROVIDER')) {
    return { ok: false, response: authError(401, 'AUTH_INVALID', 'Your session has expired. Please log in again.') };
  }

  const auth: AuthIdentity = { id: payload.sub, role: payload.role as AppRole };
  if (opts.roles && !opts.roles.includes(auth.role)) {
    return { ok: false, response: authError(403, 'FORBIDDEN_ROLE', 'Your account type is not allowed to do this.') };
  }
  return { ok: true, auth };
}

/**
 * Ensure the caller acts only as themselves. Returns a 403 response on mismatch, otherwise null.
 * Legacy (token-less) requests pass through while AUTH_ENFORCE is off.
 */
export function denyUnlessSelf(auth: AuthIdentity | null, claimedId: string | null | undefined): NextResponse | null {
  if (!auth) return null;
  if (!claimedId || claimedId !== auth.id) {
    return authError(403, 'FORBIDDEN', 'You can only perform this action on your own account.');
  }
  return null;
}

export function forbidden(message = 'You are not allowed to perform this action.'): NextResponse {
  return authError(403, 'FORBIDDEN', message);
}

// ---------------------------------------------------------------------------
// Admin session (HttpOnly cookie)
// ---------------------------------------------------------------------------

export function issueAdminToken(): string {
  return signToken({ typ: 'admin', sub: 'admin' }, ADMIN_TTL_SECONDS);
}

export function isValidAdminToken(token: string | undefined | null): boolean {
  if (!token) return false;
  const payload = verifyToken(token);
  return !!payload && payload.typ === 'admin';
}

/** For admin-only API routes. Returns a 401 response when the admin cookie is missing/invalid. */
export async function requireAdmin(): Promise<NextResponse | null> {
  const cookieStore = await cookies();
  if (isValidAdminToken(cookieStore.get(ADMIN_COOKIE_NAME)?.value)) return null;
  return authError(401, 'ADMIN_REQUIRED', 'Administrator login required.');
}

// ---------------------------------------------------------------------------
// Phone verification proof (issued after a successful OTP check)
// ---------------------------------------------------------------------------

export function normalizePhone(phone: string): string {
  let clean = String(phone || '').replace(/[^\d]/g, '');
  if (clean.startsWith('91') && clean.length > 10) clean = clean.substring(2);
  if (clean.startsWith('0') && clean.length === 11) clean = clean.substring(1);
  return clean;
}

export function issuePhoneVerificationToken(phone: string): string {
  return signToken({ typ: 'phone', phone: normalizePhone(phone) }, PHONE_PROOF_TTL_SECONDS);
}

export function isValidPhoneVerificationToken(token: string | undefined | null, phone: string): boolean {
  if (!token) return false;
  const payload = verifyToken(token);
  return !!payload && payload.typ === 'phone' && payload.phone === normalizePhone(phone);
}
