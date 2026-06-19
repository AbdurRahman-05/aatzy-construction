import { NextResponse } from 'next/server';
import { sendOtp, verifyOtp } from '@/lib/messageCentral';

export async function POST(request: Request) {
  try {
    const { password, verificationId, otpCode } = await request.json();
    const correctPassword = process.env.ADMIN_PASSWORD || 'admin123';
    const adminPhone = process.env.ADMIN_PHONE || '910000000000'; // Default test admin phone if empty

    if (!password) {
      return NextResponse.json({ error: 'Password is required' }, { status: 400 });
    }

    if (password !== correctPassword) {
      return NextResponse.json({ error: 'Incorrect administrator password' }, { status: 401 });
    }

    // Step 2: Verify OTP
    if (verificationId && otpCode) {
      const otpResult = await verifyOtp(adminPhone, verificationId, otpCode);
      if (!otpResult.success) {
        return NextResponse.json({ error: otpResult.error || 'Invalid OTP code' }, { status: 400 });
      }

      // Success!
      return NextResponse.json({ success: true });
    }

    // Step 1: Password matched, dispatch OTP
    const otpSendResult = await sendOtp(adminPhone);
    if (!otpSendResult.success) {
      return NextResponse.json({ error: otpSendResult.error || 'Failed to send OTP to Admin' }, { status: 500 });
    }

    return NextResponse.json({
      requiresOtp: true,
      verificationId: otpSendResult.verificationId,
      phone: adminPhone,
      message: 'OTP sent to administrator mobile number'
    });

  } catch (error: any) {
    console.error('Admin login API error:', error);
    return NextResponse.json({ error: 'Failed to process admin login' }, { status: 500 });
  }
}
