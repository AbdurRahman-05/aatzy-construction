import { NextResponse } from 'next/server';
import prisma from '@/lib/prisma';
import { sendApprovalEmail } from '@/lib/mail';
import { sendFCMNotification } from '@/lib/fcm';

export async function PATCH(request: Request, context: { params: Promise<{ id: string }> }) {
  try {
    const { id } = await context.params;
    
    const provider = await prisma.provider.findUnique({ where: { id } });
    if (!provider) return NextResponse.json({ error: 'Provider not found' }, { status: 404 });

    const newStatus = !provider.isVerified;
    const updatedProvider = await prisma.provider.update({
      where: { id },
      data: { isVerified: newStatus },
    });

    if (newStatus) {
      // Toggled from Inactive to Active (Approved)
      sendApprovalEmail(updatedProvider.email, updatedProvider.ownerName || updatedProvider.businessName, 'PROVIDER').catch(err => {
        console.error('Provider approval email error (toggle):', err);
      });

      if (provider.fcmToken) {
        sendFCMNotification({
          token: provider.fcmToken,
          title: 'Account Activated! 🎉',
          body: 'Your partner profile is now verified and active.',
          route: '/provider-home',
          channelId: 'buildzy_general_v2',
          recipientId: id,
          action: 'ACCOUNT_ACTIVATED',
        }).catch(err => {
          console.error('Provider FCM activation error:', err);
        });
      }
    } else {
      // Toggled from Active to Inactive (Verification Pending)
      if (provider.fcmToken) {
        sendFCMNotification({
          token: provider.fcmToken,
          title: 'Account Verification Pending',
          body: 'Your account status has been changed to inactive. Please wait for verification.',
          route: '/provider-verification-pending',
          channelId: 'buildzy_general_v2',
          recipientId: id,
          action: 'ACCOUNT_DEACTIVATED',
        }).catch(err => {
          console.error('Provider FCM deactivation error:', err);
        });
      }
    }

    return NextResponse.json({ message: 'Provider status updated', provider: updatedProvider });
  } catch (error) {
    console.error('Provider toggle error:', error);
    return NextResponse.json({ error: 'Failed to update provider status' }, { status: 500 });
  }
}
