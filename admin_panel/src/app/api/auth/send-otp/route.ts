import { NextResponse } from 'next/server';
import { sendOtp } from '@/lib/messageCentral';
import { normalizePhone } from '@/lib/auth';
import { hitRateLimit, clientIp } from '@/lib/rateLimit';

const TEN_MINUTES = 10 * 60 * 1000;
const ONE_DAY = 24 * 60 * 60 * 1000;

function tooManyRequests(retryAfterSeconds: number) {
  const minutes = Math.max(1, Math.ceil(retryAfterSeconds / 60));
  return NextResponse.json(
    {
      error: `Too many OTP requests. Please try again in ${minutes} minute${minutes === 1 ? '' : 's'}.`,
      code: 'RATE_LIMITED',
      retryAfterSeconds,
    },
    { status: 429, headers: { 'Retry-After': String(retryAfterSeconds) } }
  );
}

export async function POST(request: Request) {
  try {
    const { phone } = await request.json();
    if (!phone) {
      return NextResponse.json({ error: 'Phone number is required' }, { status: 400 });
    }

    const cleanPhone = normalizePhone(phone);
    if (!/^\d{10}$/.test(cleanPhone)) {
      return NextResponse.json({ error: 'Please enter a valid 10-digit mobile number' }, { status: 400 });
    }

    // Limit SMS spend: per phone number and per client IP
    const ip = clientIp(request);
    const checks = [
      hitRateLimit(`otp:phone:10m:${cleanPhone}`, 3, TEN_MINUTES),
      hitRateLimit(`otp:phone:1d:${cleanPhone}`, 10, ONE_DAY),
      hitRateLimit(`otp:ip:10m:${ip}`, 10, TEN_MINUTES),
    ];
    const blocked = checks.find((c) => !c.allowed);
    if (blocked) return tooManyRequests(blocked.retryAfterSeconds);

    const result = await sendOtp(cleanPhone);
    if (result.success) {
      return NextResponse.json({ success: true, verificationId: result.verificationId });
    } else {
      return NextResponse.json({ error: result.error || 'Failed to send OTP' }, { status: 500 });
    }
  } catch (error: any) {
    console.error('Send OTP api error:', error);
    return NextResponse.json({ error: error.message || 'Failed to trigger OTP' }, { status: 500 });
  }
}
