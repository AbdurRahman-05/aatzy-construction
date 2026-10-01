import { NextResponse } from 'next/server';
import prisma from '@/lib/prisma';
import { getRazorpayClient, getRazorpayKeyId, isRazorpayConfigured, YEARLY_MEMBERSHIP_FEE } from '@/lib/razorpay';

export async function POST(request: Request) {
  try {
    const body = await request.json();
    const { providerId } = body;

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
        phone: true,
        subscriptionStatus: true,
        subscriptionExpiresAt: true,
      },
    });

    if (!provider) {
      return NextResponse.json({ error: 'Provider not found' }, { status: 404 });
    }

    const amountInPaise = YEARLY_MEMBERSHIP_FEE * 100; // 599900 paise
    const receipt = `sub_${provider.id.slice(0, 8)}_${Date.now()}`;
    const razorpay = getRazorpayClient();
    const isLive = isRazorpayConfigured();

    if (razorpay && isLive) {
      try {
        const order = await razorpay.orders.create({
          amount: amountInPaise,
          currency: 'INR',
          receipt,
          notes: {
            providerId: provider.id,
            businessName: provider.businessName,
            plan: 'YEARLY_5999',
            description: 'Annual Service Provider Membership',
          },
        });

        return NextResponse.json({
          success: true,
          orderId: order.id,
          amount: order.amount,
          currency: order.currency,
          keyId: getRazorpayKeyId(),
          provider: {
            id: provider.id,
            businessName: provider.businessName,
            ownerName: provider.ownerName,
            email: provider.email,
            phone: provider.phone,
          },
          plan: 'YEARLY_5999',
          fee: YEARLY_MEMBERSHIP_FEE,
          isSandbox: false,
        });
      } catch (razorpayErr: any) {
        console.error('Razorpay Order Creation Error:', razorpayErr);
        // Fallback to simulated order if Razorpay rejects API key or throws error
      }
    }

    // Sandbox / Development fallback if keys not configured
    const simulatedOrderId = `order_sim_${provider.id.slice(0, 6)}_${Date.now()}`;
    return NextResponse.json({
      success: true,
      orderId: simulatedOrderId,
      amount: amountInPaise,
      currency: 'INR',
      keyId: getRazorpayKeyId(),
      provider: {
        id: provider.id,
        businessName: provider.businessName,
        ownerName: provider.ownerName,
        email: provider.email,
        phone: provider.phone,
      },
      plan: 'YEARLY_5999',
      fee: YEARLY_MEMBERSHIP_FEE,
      isSandbox: true,
      note: 'Running in Test / Sandbox Mode. Set real RAZORPAY_KEY_ID & RAZORPAY_KEY_SECRET in .env for production payments.',
    });
  } catch (error: any) {
    console.error('Create Order Route Error:', error);
    return NextResponse.json({ error: error.message || 'Failed to create order' }, { status: 500 });
  }
}
