import { NextResponse } from 'next/server';
import prisma from '@/lib/prisma';
import { sendOtp, verifyOtp } from '@/lib/messageCentral';

export async function POST(request: Request) {
  try {
    const body = await request.json();
    const { email, password, verificationId, otpCode } = body;

    if (!email || !password) {
      return NextResponse.json({ error: 'Missing email or password' }, { status: 400 });
    }

    const user = await prisma.user.findUnique({
      where: { email },
    });

    if (!user || user.password !== password) {
      return NextResponse.json({ error: 'Invalid credentials' }, { status: 401 });
    }

    // Check if OTP verification is requested
    if (verificationId && otpCode) {
      const otpResult = await verifyOtp(user.phone || '910000000000', verificationId, otpCode);
      if (!otpResult.success) {
        return NextResponse.json({ error: otpResult.error || 'Invalid OTP code' }, { status: 400 });
      }
      
      // OTP verified successfully, complete login
      return NextResponse.json({ 
        message: 'Login successful',
        user: { id: user.id, name: user.name, email: user.email, role: user.role }
      }, { status: 200 });
    }

    // Step 1: Credentials matched, trigger OTP send
    const userPhone = user.phone || '910000000000'; // Default test phone if empty
    const otpSendResult = await sendOtp(userPhone);

    if (!otpSendResult.success) {
      return NextResponse.json({ error: otpSendResult.error || 'Failed to send OTP' }, { status: 500 });
    }

    return NextResponse.json({
      requiresOtp: true,
      verificationId: otpSendResult.verificationId,
      phone: userPhone,
      message: 'OTP sent to your registered mobile number'
    }, { status: 200 });

  } catch (error) {
    console.error('Login error:', error);
    return NextResponse.json({ error: 'Failed to login' }, { status: 500 });
  }
}
