import { NextResponse } from 'next/server';
import prisma from '@/lib/prisma';
import { sendFCMNotification } from '@/lib/fcm';

export async function DELETE(request: Request, context: { params: Promise<{ id: string }> }) {
  try {
    const { id } = await context.params;
    
    const provider = await prisma.provider.findUnique({
      where: { id },
      select: { fcmToken: true, businessName: true, email: true },
    });

    await prisma.provider.delete({
      where: { id },
    });

    if (provider?.fcmToken) {
      sendFCMNotification({
        token: provider.fcmToken,
        title: 'Account Deleted',
        body: 'Your account has been deleted by an administrator.',
        route: '/login',
        channelId: 'buildzy_general_v2',
        recipientId: id,
        action: 'FORCE_LOGOUT',
      }).catch(err => {
        console.error('FCM delete notification error:', err);
      });
    }

    return NextResponse.json({ message: 'Provider deleted successfully' });
  } catch (error) {
    console.error('Delete provider error:', error);
    return NextResponse.json({ error: 'Failed to delete provider' }, { status: 500 });
  }
}
