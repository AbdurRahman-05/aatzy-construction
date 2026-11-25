import { NextResponse } from 'next/server';
import prisma from '@/lib/prisma';
import { requireAuth, denyUnlessSelf } from '@/lib/auth';

export async function GET(request: Request, context: { params: Promise<{ id: string }> }) {
  try {
    const { id } = await context.params;

    const provider = await prisma.provider.findUnique({
      where: { id },
      select: {
        id: true,
        businessName: true,
        ownerName: true,
        email: true,
        phone: true,
        category: true,
        experience: true,
        isVerified: true,
        isRejected: true,
        address: true,
        bio: true,
        aadharCard: true,
        panCard: true,
        profileImage: true,
        profileCompletion: true,
        businessType: true,
        gstNumber: true,
        website: true,
        subscriptionStatus: true,
        subscriptionPlan: true,
        subscriptionAmount: true,
        subscriptionStartedAt: true,
        subscriptionExpiresAt: true,
        createdAt: true,
        reviews: {
          select: {
            id: true,
            rating: true,
            comment: true,
            createdAt: true,
            user: {
              select: {
                name: true
              }
            },
            project: {
              select: {
                title: true,
                type: true
              }
            }
          },
          orderBy: {
            createdAt: 'desc'
          }
        }
      } as any,
    });

    if (!provider) {
      return NextResponse.json({ error: 'Provider not found' }, { status: 404 });
    }

    const reviews = (provider as any).reviews || [];
    const avgRating = reviews.length > 0
      ? parseFloat((reviews.reduce((sum: number, r: any) => sum + (r.rating || 0), 0) / reviews.length).toFixed(1))
      : 0.0;

    const expiresAt = (provider as any).subscriptionExpiresAt;
    const now = new Date();
    const daysLeft = expiresAt && new Date(expiresAt) > now
      ? Math.ceil((new Date(expiresAt).getTime() - now.getTime()) / (1000 * 60 * 60 * 24))
      : 0;
    const isSubscriptionActive = (provider as any).subscriptionStatus === 'ACTIVE' && daysLeft > 0;

    // Aadhaar / PAN are private KYC documents: only the provider themselves may read them
    const authResult = requireAuth(request);
    const isSelf = authResult.ok && authResult.auth?.role === 'PROVIDER' && authResult.auth.id === id;
    const { aadharCard, panCard, ...publicProfile } = provider as any;

    return NextResponse.json({
      provider: {
        ...publicProfile,
        ...(isSelf ? { aadharCard, panCard } : {}),
        avgRating,
        daysLeft,
        isSubscriptionActive,
      } 
    });
  } catch (error) {
    console.error('Get provider profile error:', error);
    return NextResponse.json({ error: 'Failed to fetch provider' }, { status: 500 });
  }
}

export async function PATCH(request: Request, context: { params: Promise<{ id: string }> }) {
  try {
    const authResult = requireAuth(request, { roles: ['PROVIDER'] });
    if (!authResult.ok) return authResult.response;
    const { id: guardProviderId } = await context.params;
    const notSelf = denyUnlessSelf(authResult.auth, guardProviderId);
    if (notSelf) return notSelf;

    const { id } = await context.params;
    const body = await request.json();

    const updatedProvider = await prisma.provider.update({
      where: { id },
      data: {
        businessName: body.businessName,
        ownerName: body.ownerName,
        phone: body.phone,
        category: body.category,
        experience: body.experience ? parseInt(body.experience) : undefined,
        address: body.address,
        bio: body.bio,
        // KYC documents: only replace when a new document is sent (never wipe with null/empty)
        aadharCard: body.aadharCard ? body.aadharCard : undefined,
        panCard: body.panCard ? body.panCard : undefined,
        profileImage: body.profileImage,
        profileCompletion: body.profileCompletion,
        businessType: body.businessType,
        gstNumber: body.gstNumber,
        website: body.website,
      } as any,
    });

    return NextResponse.json(updatedProvider);
  } catch (error) {
    console.error('Update provider error:', error);
    return NextResponse.json({ error: 'Failed to update profile' }, { status: 500 });
  }
}
