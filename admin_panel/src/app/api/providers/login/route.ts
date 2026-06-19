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

    const provider = await prisma.provider.findUnique({
      where: { email },
    });

    if (!provider || provider.password !== password) {
      return NextResponse.json({ error: 'Invalid credentials' }, { status: 401 });
    }

    if (!provider.isVerified) {
      return NextResponse.json({ 
        error: 'Approval Pending', 
        message: 'Your provider account is currently under review by an admin. Please wait for approval before logging in.'
      }, { status: 403 });
    }

    // Check if OTP verification is requested
    if (verificationId && otpCode) {
      const otpResult = await verifyOtp(provider.phone || '910000000000', verificationId, otpCode);
      if (!otpResult.success) {
        return NextResponse.json({ error: otpResult.error || 'Invalid OTP code' }, { status: 400 });
      }
      
      // OTP verified successfully, complete login
      return NextResponse.json({ 
        message: 'Login successful',
        provider: { 
          id: provider.id, 
          businessName: provider.businessName, 
          ownerName: provider.ownerName,
          email: provider.email 
        }
      }, { status: 200 });
    }

    // Step 1: Credentials matched, trigger OTP send
    const providerPhone = provider.phone || '910000000000';
    const otpSendResult = await sendOtp(providerPhone);

    if (!otpSendResult.success) {
      return NextResponse.json({ error: otpSendResult.error || 'Failed to send OTP' }, { status: 500 });
    }

    return NextResponse.json({
      requiresOtp: true,
      verificationId: otpSendResult.verificationId,
      phone: providerPhone,
      message: 'OTP sent to your registered mobile number'
    }, { status: 200 });

  } catch (error) {
    console.error('Provider Login error:', error);
    return NextResponse.json({ error: 'Failed to login' }, { status: 500 });
  }
}
