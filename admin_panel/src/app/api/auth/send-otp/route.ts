import { NextResponse } from 'next/server';
import { sendOtp } from '@/lib/messageCentral';

export async function POST(request: Request) {
  try {
    const { phone } = await request.json();
    if (!phone) {
      return NextResponse.json({ error: 'Phone number is required' }, { status: 400 });
    }

    const result = await sendOtp(phone);
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
