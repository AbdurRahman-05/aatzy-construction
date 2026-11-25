import { NextResponse } from 'next/server';
import prisma from '@/lib/prisma';
import { calculateDaysLeft, isFreeAccessMode, YEARLY_MEMBERSHIP_FEE } from '@/lib/razorpay';
import { requireAuth, denyUnlessSelf } from '@/lib/auth';

export async function GET(request: Request) {
  try {
    const authResult = requireAuth(request, { roles: ['PROVIDER'] });
    if (!authResult.ok) return authResult.response;
    const notSelf = denyUnlessSelf(authResult.auth, new URL(request.url).searchParams.get('providerId'));
    if (notSelf) return notSelf;

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

    const freeAccessMode = isFreeAccessMode();

    // Real status from the database
    const realDaysLeft = calculateDaysLeft(provider.subscriptionExpiresAt);
    const realIsActive = provider.subscriptionStatus === 'ACTIVE' && realDaysLeft > 0;
    const realStatus = realIsActive
      ? 'ACTIVE'
      : provider.subscriptionExpiresAt
        ? 'EXPIRED'
        : provider.subscriptionStatus || 'INACTIVE';

    // FREE_ACCESS_MODE (default on while payments are disabled) grants everyone access
    const isActive = freeAccessMode || realIsActive;
    const daysLeft = freeAccessMode ? Math.max(realDaysLeft, 365) : realDaysLeft;
    const currentStatus = freeAccessMode ? 'ACTIVE' : realStatus;

    return NextResponse.json({
      providerId: provider.id,
      businessName: provider.businessName,
      isVerified: provider.isVerified,
      subscriptionStatus: currentStatus,
      isActive,
      daysLeft,
      freeAccessMode,
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
