import { NextResponse } from 'next/server';
import prisma from '@/lib/prisma';
import { sendPasswordResetEmail } from '@/lib/mail';
import { storePasswordResetOtp } from '@/lib/otpStore';

export async function POST(request: Request) {
  try {
    const { email, role } = await request.json();

    if (!email || !email.trim()) {
      return NextResponse.json({ error: 'Email address is required' }, { status: 400 });
    }

    const normalizedEmail = email.trim().toLowerCase();
    let accountName = 'User';
    let resolvedRole = role;

    if (role === 'PROVIDER') {
      const provider = await prisma.provider.findFirst({
        where: { email: { equals: normalizedEmail, mode: 'insensitive' } },
      });
      if (!provider) {
        return NextResponse.json(
          { error: 'No provider account found with this email address.' },
          { status: 404 }
        );
      }
      accountName = provider.ownerName || provider.businessName || 'Provider';
      resolvedRole = 'PROVIDER';
    } else if (role === 'CONSUMER') {
      const user = await prisma.user.findFirst({
        where: { email: { equals: normalizedEmail, mode: 'insensitive' } },
      });
      if (!user) {
        return NextResponse.json(
          { error: 'No user account found with this email address.' },
          { status: 404 }
        );
      }
      accountName = user.name || 'User';
      resolvedRole = 'CONSUMER';
    } else {
      // Auto-detect role
      const user = await prisma.user.findFirst({
        where: { email: { equals: normalizedEmail, mode: 'insensitive' } },
      });
      if (user) {
        accountName = user.name || 'User';
        resolvedRole = 'CONSUMER';
      } else {
        const provider = await prisma.provider.findFirst({
          where: { email: { equals: normalizedEmail, mode: 'insensitive' } },
        });
        if (provider) {
          accountName = provider.ownerName || provider.businessName || 'Provider';
          resolvedRole = 'PROVIDER';
        } else {
          return NextResponse.json(
            { error: 'No account found with this email address.' },
            { status: 404 }
          );
        }
      }
    }

    // Generate 6-digit numeric OTP
    const otp = Math.floor(100000 + Math.random() * 900000).toString();

    // Store in memory cache with 10-minute expiry
    storePasswordResetOtp(normalizedEmail, otp, resolvedRole, 10);

    // Send email to user
    const mailResult = await sendPasswordResetEmail(normalizedEmail, otp, accountName);

    if (!mailResult.success) {
      return NextResponse.json(
        { error: 'Failed to send verification email. Please try again later.' },
        { status: 500 }
      );
    }

    return NextResponse.json({
      success: true,
      message: `A 6-digit verification code has been sent to ${normalizedEmail}.`,
      role: resolvedRole,
    });
  } catch (error: any) {
    console.error('Forgot password API error:', error);
    return NextResponse.json(
      { error: error.message || 'Internal server error while processing request.' },
      { status: 500 }
    );
  }
}
