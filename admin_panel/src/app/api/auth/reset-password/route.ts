import { NextResponse } from 'next/server';
import prisma from '@/lib/prisma';
import { verifyPasswordResetOtp, clearPasswordResetOtp } from '@/lib/otpStore';

export async function POST(request: Request) {
  try {
    const { email, otp, newPassword, role } = await request.json();

    if (!email || !email.trim()) {
      return NextResponse.json({ error: 'Email address is required' }, { status: 400 });
    }

    if (!otp || !otp.trim()) {
      return NextResponse.json({ error: 'Verification code is required' }, { status: 400 });
    }

    if (!newPassword || newPassword.length < 6) {
      return NextResponse.json(
        { error: 'New password must be at least 6 characters long' },
        { status: 400 }
      );
    }

    const normalizedEmail = email.trim().toLowerCase();

    // Verify the OTP
    const verification = verifyPasswordResetOtp(normalizedEmail, otp);
    if (!verification.valid) {
      return NextResponse.json({ error: verification.error }, { status: 400 });
    }

    const targetRole = role || verification.role;

    let updated = false;

    if (targetRole === 'PROVIDER') {
      const result = await prisma.provider.updateMany({
        where: { email: { equals: normalizedEmail, mode: 'insensitive' } },
        data: { password: newPassword },
      });
      updated = result.count > 0;
    } else if (targetRole === 'CONSUMER') {
      const result = await prisma.user.updateMany({
        where: { email: { equals: normalizedEmail, mode: 'insensitive' } },
        data: { password: newPassword },
      });
      updated = result.count > 0;
    } else {
      // Try user first
      const userUpdate = await prisma.user.updateMany({
        where: { email: { equals: normalizedEmail, mode: 'insensitive' } },
        data: { password: newPassword },
      });
      if (userUpdate.count > 0) {
        updated = true;
      } else {
        const providerUpdate = await prisma.provider.updateMany({
          where: { email: { equals: normalizedEmail, mode: 'insensitive' } },
          data: { password: newPassword },
        });
        updated = providerUpdate.count > 0;
      }
    }

    if (!updated) {
      return NextResponse.json({ error: 'Failed to find account to update password' }, { status: 404 });
    }

    // Clear OTP on successful reset
    clearPasswordResetOtp(normalizedEmail);

    return NextResponse.json({
      success: true,
      message: 'Password reset successfully. You can now log in with your new password.',
    });
  } catch (error: any) {
    console.error('Reset password API error:', error);
    return NextResponse.json(
      { error: error.message || 'Internal server error while resetting password.' },
      { status: 500 }
    );
  }
}
