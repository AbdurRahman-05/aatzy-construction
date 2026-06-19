import { NextResponse } from 'next/server';
import { verifyOtp } from '@/lib/messageCentral';

export async function POST(request: Request) {
  try {
    const { phone, verificationId, code } = await request.json();
    if (!phone || !verificationId || !code) {
      return NextResponse.json({ error: 'Missing required validation fields' }, { status: 400 });
    }

    const result = await verifyOtp(phone, verificationId, code);
    if (result.success) {
      return NextResponse.json({ success: true });
    } else {
      return NextResponse.json({ error: result.error || 'Invalid OTP code' }, { status: 400 });
    }
  } catch (error: any) {
    console.error('Verify OTP api error:', error);
    return NextResponse.json({ error: error.message || 'Verification failed' }, { status: 500 });
  }
}
