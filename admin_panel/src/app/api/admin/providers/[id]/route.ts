import { NextResponse } from 'next/server';
import prisma from '@/lib/prisma';
import { requireAdmin } from '@/lib/auth';
import { providerDeleteImpact } from '@/lib/adminImpact';

/** Full partner profile for the admin side panel / approvals inbox (KYC included). */
export async function GET(request: Request, context: { params: Promise<{ id: string }> }) {
  try {
    const notAdmin = await requireAdmin();
    if (notAdmin) return notAdmin;

    const { id } = await context.params;
    const url = new URL(request.url);
    const impactOnly = url.searchParams.get('impact') === '1';

    if (impactOnly) {
      const exists = await prisma.provider.findUnique({ where: { id }, select: { id: true } });
      if (!exists) return NextResponse.json({ error: 'Partner not found' }, { status: 404 });
      return NextResponse.json({ impact: await providerDeleteImpact(id) });
    }

    const p = await prisma.provider.findUnique({
      where: { id },
      select: {
        id: true, businessName: true, ownerName: true, email: true, phone: true, category: true,
        experience: true, isVerified: true, isRejected: true, address: true, bio: true,
        aadharCard: true, panCard: true, profileImage: true, profileCompletion: true,
        businessType: true, gstNumber: true, website: true,
        subscriptionStatus: true, subscriptionPlan: true, subscriptionAmount: true,
        subscriptionStartedAt: true, subscriptionExpiresAt: true, razorpayPaymentId: true,
        createdAt: true, updatedAt: true,
        portfolioImages: { select: { id: true, title: true, imageData: true }, orderBy: { createdAt: 'desc' } },
      },
    });
    if (!p) return NextResponse.json({ error: 'Partner not found' }, { status: 404 });

    const [quotes, acceptedQuotes, productsLive, productsTotal, orders, reviews] = await Promise.all([
      prisma.quote.count({ where: { providerId: id } }),
      prisma.quote.findMany({
        where: { providerId: id, isAccepted: true },
        select: { estimatedCost: true, project: { select: { id: true, title: true, currentStage: true } } },
        orderBy: { updatedAt: 'desc' },
      }),
      prisma.product.count({ where: { providerId: id, deletedAt: null, status: 'Approved' } }),
      prisma.product.count({ where: { providerId: id, deletedAt: null } }),
      prisma.inquiry.count({ where: { providerId: id } }),
      prisma.review.aggregate({ where: { providerId: id }, _avg: { rating: true }, _count: true }),
    ]);

    const now = Date.now();
    const exp = p.subscriptionExpiresAt ? p.subscriptionExpiresAt.getTime() : 0;
    const daysLeft = exp > now ? Math.ceil((exp - now) / 86_400_000) : 0;

    return NextResponse.json({
      ...p,
      createdAt: p.createdAt.toISOString(),
      updatedAt: p.updatedAt.toISOString(),
      subscriptionStartedAt: p.subscriptionStartedAt?.toISOString() ?? null,
      subscriptionExpiresAt: p.subscriptionExpiresAt?.toISOString() ?? null,
      subscriptionStatus: p.subscriptionStatus === 'ACTIVE' && daysLeft > 0 ? 'ACTIVE' : p.subscriptionExpiresAt ? 'EXPIRED' : p.subscriptionStatus,
      daysLeft,
      stats: {
        quotes,
        won: acceptedQuotes.length,
        wonValue: acceptedQuotes.reduce((s, q) => s + (q.estimatedCost || 0), 0),
        productsLive,
        productsTotal,
        orders,
        reviews: reviews._count,
        rating: reviews._avg.rating ? Math.round(reviews._avg.rating * 10) / 10 : null,
      },
      projects: acceptedQuotes.slice(0, 8).map(q => ({ id: q.project.id, title: q.project.title, stage: q.project.currentStage, value: q.estimatedCost })),
    });
  } catch (error) {
    console.error('Admin provider detail error:', error);
    return NextResponse.json({ error: 'Failed to load partner' }, { status: 500 });
  }
}
