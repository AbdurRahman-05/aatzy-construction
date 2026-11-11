import { NextResponse } from 'next/server';
import prisma from '@/lib/prisma';
import { sendApprovalEmail } from '@/lib/mail';
import { sendFCMNotification } from '@/lib/fcm';

export async function PATCH(request: Request, context: { params: Promise<{ id: string }> }) {
  try {
    const { id } = await context.params;
    
    const user = await prisma.user.findUnique({ where: { id } });
    if (!user) return NextResponse.json({ error: 'User not found' }, { status: 404 });

    const newStatus = !user.isApproved;
    const updatedUser = await prisma.user.update({
      where: { id },
      data: { isApproved: newStatus },
    });

    if (newStatus) {
      sendApprovalEmail(updatedUser.email, updatedUser.name, 'CONSUMER').catch(err => {
        console.error('User approval email error (toggle):', err);
      });
    } else {
      if (user.fcmToken) {
        sendFCMNotification({
          token: user.fcmToken,
          title: 'Account Deactivated',
          body: 'Your account has been deactivated by an administrator.',
          route: '/login',
          channelId: 'buildzy_general_v2',
          recipientId: id,
          action: 'FORCE_LOGOUT',
        }).catch(err => {
          console.error('User FCM deactivation error:', err);
        });
      }
    }

    return NextResponse.json({ message: 'User status updated', user: updatedUser });
  } catch (error) {
    console.error('User toggle error:', error);
    return NextResponse.json({ error: 'Failed to update user status' }, { status: 500 });
  }
}
