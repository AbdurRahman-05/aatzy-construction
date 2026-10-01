import { NextResponse } from 'next/server';
import prisma from '@/lib/prisma';

export async function GET(request: Request) {
  try {
    const { searchParams } = new URL(request.url);
    const rawCategory = searchParams.get('category');
    let category = '';
    if (rawCategory) {
      try {
        category = decodeURIComponent(rawCategory).trim();
      } catch {
        category = rawCategory.trim();
      }
    }

    if (!category || category.toLowerCase() === 'all') {
      // If no category or "All" specified, return all active providers
      const allProviders = await prisma.provider.findMany({
        where: {
          isRejected: false,
        },
        include: {
          reviews: {
            select: {
              rating: true,
            },
          },
          quotes: {
            where: {
              isAccepted: true,
            },
            select: {
              id: true,
              project: {
                select: {
                  currentStage: true,
                },
              },
            },
          },
          portfolioImages: {
            select: {
              id: true,
            },
          },
        },
      });

      const formatted = allProviders.map((p) => {
        const avgRating = p.reviews.length > 0
          ? parseFloat((p.reviews.reduce((sum, r) => sum + r.rating, 0) / p.reviews.length).toFixed(1))
          : 0.0;

        const completedCount = p.quotes.filter((q) => {
          const stage = (q.project?.currentStage || '').toLowerCase().trim();
          return stage === 'completed' || stage === 'finished';
        }).length;

        const totalProjectsCount = p.quotes.length > 0 ? p.quotes.length : (p.portfolioImages?.length || 0);

        const expiresAt = (p as any).subscriptionExpiresAt;
        const now = new Date();
        const daysLeft = expiresAt && new Date(expiresAt) > now
          ? Math.ceil((new Date(expiresAt).getTime() - now.getTime()) / (1000 * 60 * 60 * 24))
          : 0;
        const isSubActive = (p as any).subscriptionStatus === 'ACTIVE' && daysLeft > 0;
        const subStatus = isSubActive ? 'ACTIVE' : (expiresAt ? 'EXPIRED' : ((p as any).subscriptionStatus || 'INACTIVE'));

        return {
          id: p.id,
          businessName: p.businessName,
          ownerName: p.ownerName,
          email: p.email,
          phone: p.phone,
          category: p.category,
          experience: p.experience,
          isVerified: p.isVerified,
          address: p.address,
          bio: p.bio,
          avgRating,
          reviewCount: p.reviews.length,
          projectsCount: totalProjectsCount,
          completedProjects: completedCount,
          subscriptionStatus: subStatus,
          subscriptionExpiresAt: expiresAt,
          daysLeft,
          isSubscriptionActive: isSubActive,
        };
      });

      return NextResponse.json({ providers: formatted });
    }

    // Fetch providers matching the category
    const providers = await prisma.provider.findMany({
      where: {
        category: {
          contains: category,
          mode: 'insensitive',
        },
        isRejected: false,
      },
      include: {
        reviews: {
          select: {
            rating: true,
          },
        },
        quotes: {
          where: {
            isAccepted: true,
          },
          select: {
            id: true,
            project: {
              select: {
                currentStage: true,
              },
            },
          },
        },
        portfolioImages: {
          select: {
            id: true,
          },
        },
      },
    });

    const formatted = providers.map((p) => {
      const avgRating = p.reviews.length > 0
        ? parseFloat((p.reviews.reduce((sum, r) => sum + r.rating, 0) / p.reviews.length).toFixed(1))
        : 0.0;

      const completedCount = p.quotes.filter((q) => {
        const stage = (q.project?.currentStage || '').toLowerCase().trim();
        return stage === 'completed' || stage === 'finished';
      }).length;

      const totalProjectsCount = p.quotes.length > 0 ? p.quotes.length : (p.portfolioImages?.length || 0);

      const expiresAt = (p as any).subscriptionExpiresAt;
      const now = new Date();
      const daysLeft = expiresAt && new Date(expiresAt) > now
        ? Math.ceil((new Date(expiresAt).getTime() - now.getTime()) / (1000 * 60 * 60 * 24))
        : 0;
      const isSubActive = (p as any).subscriptionStatus === 'ACTIVE' && daysLeft > 0;
      const subStatus = isSubActive ? 'ACTIVE' : (expiresAt ? 'EXPIRED' : ((p as any).subscriptionStatus || 'INACTIVE'));

      return {
        id: p.id,
        businessName: p.businessName,
        ownerName: p.ownerName,
        email: p.email,
        phone: p.phone,
        category: p.category,
        experience: p.experience,
        isVerified: p.isVerified,
        address: p.address,
        bio: p.bio,
        avgRating,
        reviewCount: p.reviews.length,
        projectsCount: totalProjectsCount,
        completedProjects: completedCount,
        subscriptionStatus: subStatus,
        subscriptionExpiresAt: expiresAt,
        daysLeft,
        isSubscriptionActive: isSubActive,
      };
    });

    return NextResponse.json({ providers: formatted });
  } catch (error) {
    console.error('Fetch providers error:', error);
    return NextResponse.json({ error: 'Failed to fetch providers' }, { status: 500 });
  }
}
