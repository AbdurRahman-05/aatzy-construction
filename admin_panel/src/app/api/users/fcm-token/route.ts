import { NextResponse } from 'next/server';
import prisma from '@/lib/prisma';

export async function POST(request: Request) {
  try {
    const body = await request.json();
    const { id, role, fcmToken } = body;

    if (!id || !fcmToken) {
      return NextResponse.json({ error: 'id and fcmToken are required' }, { status: 400 });
    }

    const normalizedRole = (role || '').toUpperCase();

    if (normalizedRole === 'PROVIDER') {
      await prisma.provider.update({
        where: { id },
        data: { fcmToken },
      });
    } else {
      await prisma.user.update({
        where: { id },
        data: { fcmToken },
      });
    }

    return NextResponse.json({ success: true, message: 'FCM Token saved successfully' });
  } catch (error) {
    console.error('Failed to save FCM Token:', error);
    return NextResponse.json({ error: 'Failed to save FCM token' }, { status: 500 });
  }
}
