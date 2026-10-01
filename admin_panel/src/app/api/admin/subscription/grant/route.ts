import { NextResponse } from 'next/server';
import prisma from '@/lib/prisma';
import { calculateDaysLeft, YEARLY_MEMBERSHIP_FEE } from '@/lib/razorpay';

export async function POST(request: Request) {
  try {
    const body = await request.json();
    const { providerId, action, days = 365, note } = body;

    if (!providerId) {
      return NextResponse.json({ error: 'providerId is required' }, { status: 400 });
    }

    const provider = await prisma.provider.findUnique({
      where: { id: providerId },
    });

    if (!provider) {
      return NextResponse.json({ error: 'Provider not found' }, { status: 404 });
    }

    const now = new Date();

    if (action === 'cancel' || action === 'revoke') {
      const updated = await prisma.provider.update({
        where: { id: providerId },
        data: {
          subscriptionStatus: 'INACTIVE',
          subscriptionExpiresAt: now,
        },
      });

      return NextResponse.json({
        success: true,
        message: 'Subscription revoked',
        subscriptionStatus: 'INACTIVE',
        daysLeft: 0,
      });
    }

    // Grant or Extend
    const daysToAdd = Number(days) || 365;
    let baseDate = now;
    if (provider.subscriptionExpiresAt && new Date(provider.subscriptionExpiresAt) > now) {
      baseDate = new Date(provider.subscriptionExpiresAt);
    }
    const newExpiresAt = new Date(baseDate.getTime() + daysToAdd * 24 * 60 * 60 * 1000);

    const subscription = await prisma.subscription.create({
      data: {
        providerId: provider.id,
        plan: 'YEARLY_5999',
        amount: YEARLY_MEMBERSHIP_FEE,
        currency: 'INR',
        status: 'SUCCESS',
        razorpayOrderId: `admin_grant_${Date.now()}`,
        razorpayPaymentId: `admin_override_${Date.now()}`,
        startedAt: now,
        expiresAt: newExpiresAt,
        notes: note || 'Manually granted or extended by Administrator',
      },
    });

    const updated = await prisma.provider.update({
      where: { id: providerId },
      data: {
        subscriptionStatus: 'ACTIVE',
        subscriptionPlan: 'YEARLY_5999',
        subscriptionAmount: YEARLY_MEMBERSHIP_FEE,
        subscriptionStartedAt: provider.subscriptionStartedAt || now,
        subscriptionExpiresAt: newExpiresAt,
      },
    });

    const daysLeft = calculateDaysLeft(newExpiresAt);

    return NextResponse.json({
      success: true,
      message: `Successfully granted ${daysToAdd} days membership to ${provider.businessName}`,
      subscriptionStatus: 'ACTIVE',
      daysLeft,
      subscriptionExpiresAt: newExpiresAt.toISOString(),
    });
  } catch (error: any) {
    console.error('Admin Grant Subscription Error:', error);
    return NextResponse.json({ error: error.message || 'Failed to modify subscription' }, { status: 500 });
  }
}
