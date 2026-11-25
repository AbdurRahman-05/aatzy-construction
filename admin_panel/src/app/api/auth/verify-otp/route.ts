import { NextResponse } from 'next/server';
import { verifyOtp } from '@/lib/messageCentral';
import { issuePhoneVerificationToken, normalizePhone } from '@/lib/auth';
import { hitRateLimit } from '@/lib/rateLimit';

export async function POST(request: Request) {
  try {
    const { phone, verificationId, code } = await request.json();
    if (!phone || !verificationId || !code) {
      return NextResponse.json({ error: 'Missing required validation fields' }, { status: 400 });
    }

    const cleanPhone = normalizePhone(phone);

    // Stop OTP guessing: max 5 attempts per phone number per 10 minutes
    const attempt = hitRateLimit(`otp:verify:${cleanPhone}`, 5, 10 * 60 * 1000);
    if (!attempt.allowed) {
      return NextResponse.json(
        { error: 'Too many incorrect attempts. Please request a new OTP later.', code: 'RATE_LIMITED' },
        { status: 429, headers: { 'Retry-After': String(attempt.retryAfterSeconds) } }
      );
    }

    const result = await verifyOtp(cleanPhone, verificationId, code);
    if (result.success) {
      // Signed proof that this phone number was verified; required by partner registration
      return NextResponse.json({
        success: true,
        phoneVerificationToken: issuePhoneVerificationToken(cleanPhone),
      });
    } else {
      return NextResponse.json({ error: result.error || 'Invalid OTP code' }, { status: 400 });
    }
  } catch (error: any) {
    console.error('Verify OTP api error:', error);
    return NextResponse.json({ error: error.message || 'Verification failed' }, { status: 500 });
  }
}
