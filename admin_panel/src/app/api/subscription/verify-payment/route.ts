import { NextResponse } from 'next/server';
import prisma from '@/lib/prisma';
import {
  verifyRazorpaySignature,
  isRazorpayConfigured,
  YEARLY_MEMBERSHIP_FEE,
  calculateDaysLeft,
} from '@/lib/razorpay';
import { sendFCMNotification } from '@/lib/fcm';

export async function POST(request: Request) {
  try {
    const body = await request.json();
    const {
      providerId,
      razorpayOrderId,
      razorpayPaymentId,
      razorpaySignature,
      isSandbox,
    } = body;

    if (!providerId || !razorpayOrderId || !razorpayPaymentId) {
      return NextResponse.json(
        { error: 'Missing required parameters: providerId, razorpayOrderId, razorpayPaymentId' },
        { status: 400 }
      );
    }

    const provider = await prisma.provider.findUnique({
      where: { id: providerId },
    });

    if (!provider) {
      return NextResponse.json({ error: 'Provider not found' }, { status: 404 });
    }

    const isLive = isRazorpayConfigured();

    // Verify cryptographic signature if live mode
    if (isLive && !isSandbox) {
      if (!razorpaySignature) {
        return NextResponse.json({ error: 'razorpaySignature is required' }, { status: 400 });
      }

      const isValid = verifyRazorpaySignature(razorpayOrderId, razorpayPaymentId, razorpaySignature);
      if (!isValid) {
        return NextResponse.json({ error: 'Invalid payment signature. Verification failed.' }, { status: 400 });
      }
    }

    const now = new Date();
    // If provider already has an active subscription that hasn't expired yet, extend from existing expiry!
    let baseDate = now;
    if (provider.subscriptionExpiresAt && new Date(provider.subscriptionExpiresAt) > now) {
      baseDate = new Date(provider.subscriptionExpiresAt);
    }
    const expiresAt = new Date(baseDate.getTime() + 365 * 24 * 60 * 60 * 1000);

    // 1. Record subscription transaction
    const subscription = await prisma.subscription.create({
      data: {
        providerId: provider.id,
        plan: 'YEARLY_5999',
        amount: YEARLY_MEMBERSHIP_FEE,
        currency: 'INR',
        status: 'SUCCESS',
        razorpayOrderId,
        razorpayPaymentId,
        razorpaySignature: razorpaySignature || (isSandbox ? 'sandbox_mock_signature' : null),
        startedAt: now,
        expiresAt,
        notes: isSandbox ? 'Sandbox / Test Mode Subscription' : 'Razorpay Verified Payment',
      },
    });

    // 2. Update Provider record
    const updatedProvider = await prisma.provider.update({
      where: { id: provider.id },
      data: {
        subscriptionStatus: 'ACTIVE',
        subscriptionPlan: 'YEARLY_5999',
        subscriptionAmount: YEARLY_MEMBERSHIP_FEE,
        subscriptionStartedAt: now,
        subscriptionExpiresAt: expiresAt,
        razorpayOrderId,
        razorpayPaymentId,
      },
    });

    const daysLeft = calculateDaysLeft(expiresAt);

    // 3. Notify provider in database and via push
    try {
      await prisma.notification.create({
        data: {
          recipientId: provider.id,
          role: 'PROVIDER',
          title: '🎉 Membership Activated!',
          body: `Your Annual Pro Membership is active. You have full access for ${daysLeft} days until ${expiresAt.toLocaleDateString('en-IN')}.`,
          type: 'MEMBERSHIP_ACTIVATED',
          route: '/provider-home',
        },
      });

      if (provider.fcmToken) {
        await sendFCMNotification({
          token: provider.fcmToken,
          title: '🎉 Membership Activated!',
          body: `Your Annual Pro Membership is active for ${daysLeft} days!`,
          route: '/provider-home',
        });
      }
    } catch (notifErr) {
      console.warn('Failed to send activation notification:', notifErr);
    }

    return NextResponse.json({
      success: true,
      message: 'Subscription successfully activated!',
      daysLeft,
      subscriptionExpiresAt: expiresAt.toISOString(),
      subscription: {
        id: subscription.id,
        plan: subscription.plan,
        amount: subscription.amount,
        startedAt: subscription.startedAt.toISOString(),
        expiresAt: subscription.expiresAt.toISOString(),
        paymentId: subscription.razorpayPaymentId,
      },
      provider: {
        id: updatedProvider.id,
        businessName: updatedProvider.businessName,
        subscriptionStatus: updatedProvider.subscriptionStatus,
        subscriptionExpiresAt: updatedProvider.subscriptionExpiresAt?.toISOString(),
      },
    });
  } catch (error: any) {
    console.error('Verify Payment Error:', error);
    return NextResponse.json({ error: error.message || 'Payment verification failed' }, { status: 500 });
  }
}
