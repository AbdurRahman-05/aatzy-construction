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

    if (!user.isApproved) {
      return NextResponse.json({ 
        error: 'Approval Pending', 
        message: 'Your account is currently under review by an admin. Please wait for approval before logging in.'
      }, { status: 403 });
    }

    return NextResponse.json({ 
      message: 'Login successful',
      user: { id: user.id, name: user.name, email: user.email, role: user.role }
    }, { status: 200 });

  } catch (error) {
    console.error('Login error:', error);
    return NextResponse.json({ error: 'Failed to login' }, { status: 500 });
  }
}
