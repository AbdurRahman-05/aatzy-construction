import { NextResponse } from 'next/server';
import prisma from '@/lib/prisma';
import { calculateDaysLeft, YEARLY_MEMBERSHIP_FEE } from '@/lib/razorpay';

export async function GET(request: Request) {
  try {
    const { searchParams } = new URL(request.url);
    const providerId = searchParams.get('providerId');

    if (!providerId) {
      return NextResponse.json({ error: 'providerId is required' }, { status: 400 });
    }

    const provider = await prisma.provider.findUnique({
      where: { id: providerId },
      select: {
        id: true,
        businessName: true,
        ownerName: true,
        email: true,
        isVerified: true,
        subscriptionStatus: true,
        subscriptionPlan: true,
        subscriptionAmount: true,
        subscriptionStartedAt: true,
        subscriptionExpiresAt: true,
        subscriptions: {
          orderBy: { createdAt: 'desc' },
          take: 5,
        },
      },
    });

    if (!provider) {
      return NextResponse.json({ error: 'Provider not found' }, { status: 404 });
    }

    const now = new Date();
    const daysLeft = calculateDaysLeft(provider.subscriptionExpiresAt);
    const isExpired = provider.subscriptionExpiresAt ? new Date(provider.subscriptionExpiresAt) < now : true;
    const isActive = provider.subscriptionStatus === 'ACTIVE' && !isExpired;

    // Automatically synchronize status if expired
    let currentStatus = provider.subscriptionStatus;
    if (provider.subscriptionStatus === 'ACTIVE' && isExpired) {
      currentStatus = 'EXPIRED';
      await prisma.provider.update({
        where: { id: provider.id },
        data: { subscriptionStatus: 'EXPIRED' },
      });
    }

    return NextResponse.json({
      providerId: provider.id,
      businessName: provider.businessName,
      isVerified: provider.isVerified,
      subscriptionStatus: currentStatus,
      isActive,
      daysLeft,
      subscriptionExpiresAt: provider.subscriptionExpiresAt ? provider.subscriptionExpiresAt.toISOString() : null,
      subscriptionStartedAt: provider.subscriptionStartedAt ? provider.subscriptionStartedAt.toISOString() : null,
      plan: provider.subscriptionPlan || 'YEARLY_5999',
      fee: YEARLY_MEMBERSHIP_FEE,
      history: provider.subscriptions.map((s) => ({
        id: s.id,
        amount: s.amount,
        status: s.status,
        startedAt: s.startedAt.toISOString(),
        expiresAt: s.expiresAt.toISOString(),
        paymentId: s.razorpayPaymentId,
      })),
    });
  } catch (error: any) {
    console.error('Subscription Status Error:', error);
    return NextResponse.json({ error: error.message || 'Failed to fetch subscription status' }, { status: 500 });
  }
}
