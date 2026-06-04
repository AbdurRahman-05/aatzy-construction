import { NextResponse } from 'next/server';
import prisma from '@/lib/prisma';

export async function GET(request: Request) {
  try {
    const { searchParams } = new URL(request.url);
    const category = searchParams.get('category');

    if (!category) {
      // If no category specified, return all active providers
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
        },
      });

      const formatted = allProviders.map((p) => {
        const avgRating = p.reviews.length > 0
          ? parseFloat((p.reviews.reduce((sum, r) => sum + r.rating, 0) / p.reviews.length).toFixed(1))
          : 0.0;
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
      },
    });

    const formatted = providers.map((p) => {
      const avgRating = p.reviews.length > 0
        ? parseFloat((p.reviews.reduce((sum, r) => sum + r.rating, 0) / p.reviews.length).toFixed(1))
        : 0.0;
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
      };
    });

    return NextResponse.json({ providers: formatted });
  } catch (error) {
    console.error('Fetch providers error:', error);
    return NextResponse.json({ error: 'Failed to fetch providers' }, { status: 500 });
  }
}
